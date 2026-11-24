#!/usr/bin/env bash
# shot.sh — 构建并启动 omp_studio_moui（macos_skia 原生目标），只截应用窗口。
#
# 用法:
#   scripts/shot.sh [选项]
#
# 选项:
#   --no-build            跳过 moon build，直接用现有产物
#   --timeout <秒>        等待窗口出现的最长时间，默认 20
#   --settle <秒>         窗口出现后等首帧渲染稳定，默认 0.8
#   --out-dir <目录>      截图输出目录，默认 <项目>/shots
#   --keep                截图后保留应用进程（默认会终止）
#   --activate            截图前把应用窗口置前（默认不抢焦点）
#   --pid-file <路径>     把应用 pid 写进该文件（给 check.sh 用）
#   --log-file <路径>     把应用 stdout/stderr 写到该文件（默认临时文件）
#   --min-bytes <n>       截图文件最小字节数，低于它视为空白/失败，默认 1024
#   --verbose             显示完整构建输出
#   -h, --help            显示帮助
#
# 输出约定:
#   stdout 只有一行：截图的绝对路径
#   stderr 是过程日志和错误说明
#
# 退出码:
#   0 成功 / 1 用法错误 / 2 构建失败 / 3 应用启动即崩溃（没出现窗口）
#   4 等待窗口超时 / 5 截图失败或截图空白 / 6 运行环境不满足（缺工具/产物）

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
APP_BIN="$ROOT/_build/native/debug/build/macos_skia/macos_skia.exe"
TOOLS_DIR="$ROOT/_build/qa"
WINID_SRC="$ROOT/scripts/winid.swift"

BUILD=1
TIMEOUT=20
SETTLE=0.8
OUT_DIR="$ROOT/shots"
KEEP=0
ACTIVATE=0
PID_FILE=""
APP_LOG=""
MIN_BYTES=1024
VERBOSE=0

log() { printf '[shot] %s\n' "$*" >&2; }

usage() {
  sed -n '2,26p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

die() {
  local message="$1" code="${2:-1}"
  log "ERROR: $message"
  exit "$code"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --no-build) BUILD=0 ;;
    --timeout) TIMEOUT="${2:?--timeout 需要参数}"; shift ;;
    --settle) SETTLE="${2:?--settle 需要参数}"; shift ;;
    --out-dir) OUT_DIR="${2:?--out-dir 需要参数}"; shift ;;
    --keep) KEEP=1 ;;
    --activate) ACTIVATE=1 ;;
    --pid-file) PID_FILE="${2:?--pid-file 需要参数}"; shift ;;
    --log-file) APP_LOG="${2:?--log-file 需要参数}"; shift ;;
    --min-bytes) MIN_BYTES="${2:?--min-bytes 需要参数}"; shift ;;
    --verbose) VERBOSE=1 ;;
    -h|--help) usage 0 ;;
    *) die "未知参数: $1（-h 看用法）" 1 ;;
  esac
  shift
done

# 相对路径按项目根解析，保证从任意目录调用都落在同一处。
abs_path() {
  case "$1" in
    /*) printf '%s\n' "$1" ;;
    *) printf '%s\n' "$ROOT/$1" ;;
  esac
}
OUT_DIR="$(abs_path "$OUT_DIR")"
[ -n "$PID_FILE" ] && PID_FILE="$(abs_path "$PID_FILE")"
[ -n "$APP_LOG" ] && APP_LOG="$(abs_path "$APP_LOG")"

APP_PID=""
WIN_ID=""
SHOT_PATH=""
# 由 trap 统一收尾，避免失败时留下野进程。
cleanup() {
  local rc=$?
  if [ -n "$APP_PID" ] && [ "$KEEP" -ne 1 ]; then
    stop_app
  fi
  exit "$rc"
}
trap cleanup EXIT INT TERM

# 找 moon：优先环境变量 MOON，其次 PATH，最后 ~/.moon/bin/moon。
find_moon() {
  local candidate="${MOON:-}"
  if [ -z "$candidate" ]; then
    candidate="$(command -v moon 2>/dev/null || true)"
  fi
  if [ -z "$candidate" ] && [ -x "$HOME/.moon/bin/moon" ]; then
    candidate="$HOME/.moon/bin/moon"
  fi
  [ -n "$candidate" ] && [ -x "$candidate" ] && printf '%s\n' "$candidate"
}

build_app() {
  local moon_bin
  moon_bin="$(find_moon)" || true
  [ -n "$moon_bin" ] || die "找不到 moon 可执行文件（PATH 里没有，~/.moon/bin/moon 也不存在）" 6

  local build_log
  build_log="$(mktemp -t ompstudio-build.XXXXXX)"
  log "构建: $moon_bin build macos_skia --target native"
  local started
  started="$(date +%s)"
  ( cd "$ROOT" && "$moon_bin" build macos_skia --target native ) >"$build_log" 2>&1
  local rc=$?
  local elapsed=$(( $(date +%s) - started ))
  if [ "$rc" -ne 0 ]; then
    log "构建失败（exit ${rc}），输出尾部："
    tail -n 60 "$build_log" >&2
    rm -f "$build_log"
    exit 2
  fi
  if [ "$VERBOSE" -eq 1 ]; then
    cat "$build_log" >&2
  else
    local warnings
    warnings="$(grep -c -i -E 'warning|error' "$build_log" 2>/dev/null || true)"
    if [ "${warnings:-0}" -gt 0 ]; then
      log "构建成功（${elapsed}s，日志里有 ${warnings} 条 warning/error 字样，加 --verbose 查看）"
    else
      log "构建成功（${elapsed}s）"
    fi
  fi
  rm -f "$build_log"
}

# 编译窗口探测工具（带 mtime 缓存），编译失败给出明确提示。
ensure_winid() {
  local out="$TOOLS_DIR/winid"
  mkdir -p "$TOOLS_DIR/module-cache" "$TOOLS_DIR/tmp"
  if [ -x "$out" ] && [ -f "$WINID_SRC" ] && [ "$out" -nt "$WINID_SRC" ]; then
    printf '%s\n' "$out"
    return 0
  fi
  command -v xcrun >/dev/null 2>&1 || die "找不到 xcrun，需要安装 Xcode 或 Command Line Tools" 6
  [ -f "$WINID_SRC" ] || die "缺少 $WINID_SRC" 6
  log "编译窗口探测工具（首次约 1-2 秒）"
  local compile_log="$TOOLS_DIR/winid-build.log"
  ( cd "$ROOT" && TMPDIR="$TOOLS_DIR/tmp" xcrun swiftc -O \
      -module-cache-path "$TOOLS_DIR/module-cache" \
      -o "$out" "$WINID_SRC" ) >"$compile_log" 2>&1
  if [ $? -ne 0 ]; then
    log "编译 winid.swift 失败，输出："
    tail -n 40 "$compile_log" >&2
    exit 6
  fi
  printf '%s\n' "$out"
}

stop_app() {
  [ -n "$APP_PID" ] || return 0
  if ! kill -0 "$APP_PID" 2>/dev/null; then
    APP_PID=""
    return 0
  fi
  log "终止应用 pid=$APP_PID"
  kill -TERM "$APP_PID" 2>/dev/null || true
  local i=0
  while [ "$i" -lt 30 ]; do
    kill -0 "$APP_PID" 2>/dev/null || { APP_PID=""; return 0; }
    sleep 0.1
    i=$((i + 1))
  done
  kill -KILL "$APP_PID" 2>/dev/null || true
  APP_PID=""
}

on_crash() {
  local code="$1"
  log "应用进程已退出（exit ${code}），不会再出现窗口。应用输出尾部："
  if [ -n "$APP_LOG" ] && [ -f "$APP_LOG" ]; then
    tail -n 40 "$APP_LOG" >&2
  else
    log "（没有捕获到应用输出）"
  fi
  exit 3
}

if [ "$BUILD" -eq 1 ]; then
  build_app
fi
[ -x "$APP_BIN" ] || die "产物不存在：${APP_BIN}（去掉 --no-build 先构建）" 6

WINID="$(ensure_winid)" || exit $?

if [ -z "$APP_LOG" ]; then
  APP_LOG="$(mktemp -t ompstudio-app.XXXXXX)"
fi
mkdir -p "$(cd "$(dirname "$APP_LOG")" && pwd -P)" 2>/dev/null || true

log "启动应用：$APP_BIN"
# stdin 接 /dev/null，避免子进程继承调用方的 stdin 导致外层管道不返回。
"$APP_BIN" </dev/null >"$APP_LOG" 2>&1 &
APP_PID=$!
log "应用 pid=$APP_PID"

if [ -n "$PID_FILE" ]; then
  mkdir -p "$(dirname "$PID_FILE")" 2>/dev/null || true
  printf '%s\n' "$APP_PID" >"$PID_FILE"
fi
[ "$KEEP" -eq 1 ] && log "进程会保留（--keep）"

# 等窗口：优先 onScreen 且边长 >=200 的 layer0 窗口（winid 内部已按此筛选）。
deadline=$(( $(date +%s) + TIMEOUT ))
while [ "$(date +%s)" -lt "$deadline" ]; do
  if ! kill -0 "$APP_PID" 2>/dev/null; then
    wait "$APP_PID"
    on_crash $?
  fi
  info="$("$WINID" "$APP_PID" 2>/dev/null | head -n 1)"
  if [ -n "$info" ]; then
    WIN_ID="$(printf '%s\n' "$info" | awk '{print $1}')"
    WIN_SIZE="$(printf '%s\n' "$info" | awk '{print $2}')"
    WIN_TITLE="$(printf '%s\n' "$info" | awk '{for (i=3;i<=NF;i++) printf "%s%s", $i, (i<NF?" ":"")}')"
    log "窗口出现：id=$WIN_ID size=$WIN_SIZE title=${WIN_TITLE:-<无标题>}"
    break
  fi
  sleep 0.15
done

if [ -z "$WIN_ID" ]; then
  if kill -0 "$APP_PID" 2>/dev/null; then
    log "进程还活着，但 ${TIMEOUT}s 内没等到窗口。应用输出尾部："
    tail -n 20 "$APP_LOG" >&2
    log "排查方向：窗口被最小化/在别的 Space、应用卡在首帧渲染、或屏幕录制权限被收回（见 docs/qa.md）"
    exit 4
  fi
  wait "$APP_PID"
  on_crash $?
fi

if [ "$ACTIVATE" -eq 1 ]; then
  "$WINID" "$APP_PID" --activate >/dev/null 2>&1 || log "置前失败（不影响截图）"
fi

# 等首帧渲染稳定；期间进程若崩了，截图多半是空白，先报崩溃。
if [ "$SETTLE" != "0" ]; then
  sleep "$SETTLE"
fi
if ! kill -0 "$APP_PID" 2>/dev/null; then
  wait "$APP_PID"
  on_crash $?
fi

# 首帧等待期间窗口可能被重建（CGWindowID 会变），截图前再确认一次，避免抓错。
info="$("$WINID" "$APP_PID" 2>/dev/null | head -n 1)"
if [ -z "$info" ]; then
  log "等待首帧后窗口不见了，无法截图"
  exit 4
fi
new_id="$(printf '%s\n' "$info" | awk '{print $1}')"
WIN_SIZE="$(printf '%s\n' "$info" | awk '{print $2}')"
if [ "$new_id" != "$WIN_ID" ]; then
  log "窗口 id 有变化：$WIN_ID -> $new_id，用新的"
  WIN_ID="$new_id"
fi

mkdir -p "$OUT_DIR" || die "无法创建输出目录: $OUT_DIR" 5
OUT_DIR="$(cd "$OUT_DIR" && pwd -P)"
stamp="$(date +%Y%m%d-%H%M%S)"
SHOT_PATH="$OUT_DIR/app-$stamp.png"
n=1
while [ -e "$SHOT_PATH" ]; do
  SHOT_PATH="$OUT_DIR/app-$stamp-$n.png"
  n=$((n + 1))
done

log "截图：screencapture -l $WIN_ID -> $SHOT_PATH"
screencapture -x -o -t png -l "$WIN_ID" "$SHOT_PATH"
rc=$?
if [ "$rc" -ne 0 ]; then
  log "screencapture 失败（exit ${rc}）。常见原因：屏幕录制权限被收回、窗口已关闭"
  exit 5
fi
if [ ! -f "$SHOT_PATH" ]; then
  die "screencapture 返回 0 但没有生成文件（多半是屏幕录制权限问题）" 5
fi

bytes="$(stat -f%z "$SHOT_PATH" 2>/dev/null || echo 0)"
if [ "${bytes:-0}" -lt "$MIN_BYTES" ]; then
  log "截图文件只有 ${bytes} 字节，疑似空白/全黑（阈值 ${MIN_BYTES}）"
  exit 5
fi

# 尺寸自检：截图像素尺寸应当是窗口逻辑尺寸的 Retina 倍数（通常 2x）。
# 如果 -l 的窗口 id 失效，screencapture 会静默退回截全屏，这里能抓出来。
pw="$(sips -g pixelWidth "$SHOT_PATH" 2>/dev/null | awk '/pixelWidth/{print $2}')"
ph="$(sips -g pixelHeight "$SHOT_PATH" 2>/dev/null | awk '/pixelHeight/{print $2}')"
win_w="${WIN_SIZE%x*}"
win_h="${WIN_SIZE#*x}"
if ! awk -v pw="${pw:-0}" -v ph="${ph:-0}" -v ww="${win_w:-0}" -v wh="${win_h:-0}" 'BEGIN {
  if (ww <= 0 || wh <= 0 || pw <= 0 || ph <= 0) exit 1
  rw = pw / ww; rh = ph / wh
  if (rw < 0.85 || rh < 0.85) exit 1
  if (rw > 2.6 || rh > 2.6) exit 1
  d = rw - rh; if (d < 0) d = -d
  if (d > 0.25) exit 1
  exit 0
}'; then
  log "截图尺寸异常：图片 ${pw}x${ph}，窗口 ${WIN_SIZE}（期望约 1x/2x 关系）。"
  log "多半是 -l 的窗口 id 在截图时失效、掉回了全屏截图，或抓到了别的窗口。"
  exit 5
fi

log "完成：${SHOT_PATH}（${bytes} 字节，窗口 ${WIN_SIZE} -> 图片 ${pw}x${ph}）"
printf '%s\n' "$SHOT_PATH"
exit 0
