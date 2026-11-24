#!/usr/bin/env bash
# build-site.sh — 把 wasm-gc 构建产物 + MoUI 网页运行时拼成可直接托管的静态站点。
#
# 用法:
#   scripts/build-site.sh [--out <目录>]
#
# 默认先跑 `moon build web_wasm --target wasm-gc`，输出到 <项目>/_site：
#
#   _site/index.html
#   _site/app.wasm
#   _site/runtime/moui_web_renderer/{runtime,canvas2d_runtime}.js
#   _site/runtime/moui/backend/web/browser_runtime.js
#   _site/.nojekyll
#
# 源模板 web_wasm/index.html 里的相对路径是相对项目根的（../.mooncakes、
# ../_build），直接整目录搬到 Pages 会越过站点根，所以这里重写成本站内的路径。
#
# 退出码: 0 成功 / 1 用法错误 / 2 构建失败 / 3 缺产物

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
OUT="$ROOT/_site"
SKIP_BUILD=0

usage() {
  sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --out) OUT="${2:?--out 需要目录参数}"; shift ;;
    --no-build) SKIP_BUILD=1 ;;
    -h|--help) usage 0 ;;
    *) echo "未知参数: $1" >&2; exit 1 ;;
  esac
  shift
done

WASM="$ROOT/_build/wasm-gc/debug/build/web_wasm/web_wasm.wasm"
RENDERER="$ROOT/.mooncakes/wzzc-dev/moui_web_renderer"
WEB_BACKEND="$ROOT/.mooncakes/wzzc-dev/moui/backend/web"
TEMPLATE="$ROOT/web_wasm/index.html"

if [ "$SKIP_BUILD" -eq 0 ]; then
  echo "[site] moon build web_wasm --target wasm-gc" >&2
  if ! (cd "$ROOT" && moon build web_wasm --target wasm-gc); then
    echo "[site] 构建失败" >&2
    exit 2
  fi
fi

for f in "$WASM" "$TEMPLATE" "$RENDERER/runtime.js" "$RENDERER/canvas2d_runtime.js" "$WEB_BACKEND/browser_runtime.js"; do
  if [ ! -f "$f" ]; then
    echo "[site] 缺文件: $f" >&2
    exit 3
  fi
done

rm -rf "$OUT"
mkdir -p "$OUT/runtime/moui_web_renderer" "$OUT/runtime/moui/backend/web"

cp "$WASM" "$OUT/app.wasm"
cp "$RENDERER/runtime.js" "$RENDERER/canvas2d_runtime.js" "$OUT/runtime/moui_web_renderer/"
cp "$WEB_BACKEND/browser_runtime.js" "$OUT/runtime/moui/backend/web/"
: > "$OUT/.nojekyll"

sed \
  -e 's|\.\./\.mooncakes/wzzc-dev/moui_web_renderer/runtime\.js|./runtime/moui_web_renderer/runtime.js|' \
  -e 's|\.\./_build/wasm-gc/debug/build/web_wasm/web_wasm\.wasm|./app.wasm|' \
  "$TEMPLATE" > "$OUT/index.html"

if grep -qE '\.\./(\.mooncakes|_build)' "$OUT/index.html"; then
  echo "[site] index.html 还有越出站点根的路径，请检查模板或重写规则" >&2
  exit 3
fi

echo "[site] 完成：$OUT" >&2
du -sh "$OUT" >&2
