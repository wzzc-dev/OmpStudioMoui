#!/usr/bin/env bash
# check.sh — 回归检查：构建 + 启动 + 截图 + 进程存活检查。
#
# 用法:
#   scripts/check.sh [选项]
#
# 选项:
#   --no-build            跳过构建，直接用现有产物
#   --alive-seconds <秒>  截图后要求进程继续存活的时长，默认 5
#   --timeout <秒>        等待窗口出现的最长时间，默认 20（透传给 shot.sh）
#   --settle <秒>         首帧渲染等待，默认 0.8（透传给 shot.sh）
#   --shot-dir <目录>     截图输出目录，默认 <项目>/shots
#   --verbose             显示完整构建输出
#   -h, --help            显示帮助
#
# 输出约定:
#   stdout 只打印截图绝对路径（一行）
#   stderr 打印过程与诊断
#
# 退出码:
#   0 通过 / 1 用法错误
#   2 构建失败 / 3 应用启动即崩溃 / 4 等待窗口超时
#   5 截图失败或空白 / 6 运行环境不满足
#   7 存活检查失败（进程在 N 秒内退出） / 8 窗口消失

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SHOT="$ROOT/scripts/shot.sh"
ALIVE_SECONDS=5
PASSTHRU=()

log() { printf '[check] %s\n' "$*" >&2; }

usage() {
  sed -n '2,24p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --no-build) PASSTHRU+=("--no-build") ;;
    --alive-seconds) ALIVE_SECONDS="${2:?--alive-seconds 需要参数}"; shift ;;
    --timeout) PASSTHRU+=("--timeout" "${2:?--timeout 需要参数}"); shift ;;
    --settle) PASSTHRU+=("--settle" "${2:?--settle 需要参数}"); shift ;;
    --shot-dir) PASSTHRU+=("--out-dir" "${2:?--shot-dir 需要参数}"); shift ;;
    --verbose) PASSTHRU+=("--verbose") ;;
    -h|--help) usage 0 ;;
    *) log "未知参数: $1"; exit 1 ;;
  esac
  shift
done

case "$ALIVE_SECONDS" in
  ''|*[!0-9]*) log "--alive-seconds 需要非负整数"; exit 1 ;;
esac

PID_FILE="$(mktemp -t ompstudio-check-pid.XXXXXX)"
APP_LOG="$(mktemp -t ompstudio-check-app.XXXXXX)"
cleanup() { rm -f "$PID_FILE"; }
trap cleanup EXIT INT TERM

stop_app() {
  local pid="${1:-}" i=0
  [ -n "$pid" ] || return 0
  kill -TERM "$pid" 2>/dev/null || return 0
  while [ "$i" -lt 30 ]; do
    kill -0 "$pid" 2>/dev/null || { log "应用已退出"; return 0; }
    sleep 0.1
    i=$((i + 1))
  done
  kill -KILL "$pid" 2>/dev/null || true
  log "应用未响应 SIGTERM，已强杀"
}

log "运行: $SHOT ${PASSTHRU[*]:-} --keep"

START="$(date +%s)"
SHOT_PATH="$("$SHOT" ${PASSTHRU[@]+"${PASSTHRU[@]}"} --keep --pid-file "$PID_FILE" --log-file "$APP_LOG")"
SHOT_RC=$?

if [ "$SHOT_RC" -ne 0 ] || [ -z "$SHOT_PATH" ]; then
  log "截图阶段失败（exit ${SHOT_RC}），应用输出："
  [ -f "$APP_LOG" ] && tail -n 40 "$APP_LOG" >&2
  if [ -s "$PID_FILE" ]; then
    stop_app "$(cat "$PID_FILE")"
  fi
  exit "${SHOT_RC:-1}"
fi

APP_PID="$(cat "$PID_FILE")"
if [ -z "$APP_PID" ]; then
  log "没有拿到应用 pid（--pid-file 未写入）"
  exit 1
fi
log "截图完成：$SHOT_PATH"
log "应用 pid=${APP_PID}，开始 ${ALIVE_SECONDS}s 存活检查"

if [ "$ALIVE_SECONDS" -gt 0 ]; then
  CHECKS=$((ALIVE_SECONDS * 4))
  i=0
  while [ "$i" -lt "$CHECKS" ]; do
    if ! kill -0 "$APP_PID" 2>/dev/null; then
      log "存活检查失败：应用在约 $((i / 4))s 时退出（不足 ${ALIVE_SECONDS}s）"
      log "应用输出尾巴："
      tail -n 40 "$APP_LOG" >&2
      wait "$APP_PID" 2>/dev/null || true
      exit 7
    fi
    sleep 0.25
    i=$((i + 1))
  done
fi

# 存活通过后再确认窗口还在（进程活着但窗口没了同样算失败）。
WINID="$ROOT/_build/qa/winid"
if [ -x "$WINID" ]; then
  if ! "$WINID" "$APP_PID" >/dev/null 2>&1; then
    log "存活检查通过，但窗口已经不存在了（winid 找不到 layer0 窗口）"
    stop_app "$APP_PID"
    exit 8
  fi
fi

ELAPSED=$(( $(date +%s) - START ))
log "通过：进程存活 ${ALIVE_SECONDS}s 未退出，总耗时 ${ELAPSED}s"
log "截图：$SHOT_PATH"

stop_app "$APP_PID"
printf '%s\n' "$SHOT_PATH"
exit 0
