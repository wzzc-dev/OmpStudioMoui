# 视觉验收工具：截图与回归检查

`scripts/shot.sh` 和 `scripts/check.sh` 负责把 omp_studio_moui（MoUI + MoonBit 原生 macOS / Skia 应用）构建、启动、截取**应用自己的窗口**，并给出可判定的退出码。验收时只认这两个脚本的输出，不需要手动点窗口。

- 不碰 `app/` 和 `macos_skia/` 下的源码。
- 截图只含应用窗口（`screencapture -l <CGWindowID>` + `-o` 去阴影），不是全屏。
- 脚本自带两道防呆：窗口尺寸自检、进程存活检查，避免「截到全屏/黑图/进程已崩」还报成功。

## 文件

| 路径 | 作用 |
| --- | --- |
| `scripts/shot.sh` | 构建（可跳过）→ 启动 → 等窗口 → 截图，输出截图绝对路径 |
| `scripts/check.sh` | 构建 + 启动 + 截图 + 进程存活 5 秒不退出，退出码表示通过/失败 |
| `scripts/winid.swift` | 通过 CoreGraphics `CGWindowListCopyWindowInfo` 找目标进程的主窗口 id；由 shot.sh 自动编译到 `_build/qa/winid` 并缓存 |
| `shots/app-<timestamp>.png` | 截图产物目录 |

`shots/` 里还可能有其他验收流程的图片，本工具生成的统一是 `app-YYYYmmdd-HHMMSS.png`。

## 依赖

- macOS GUI 会话（有真实登录用户、屏幕已解锁；SSH/无人值守环境没有窗口服务，脚本无法工作）。
- `moon`（0.1.20261119 验证通过）。找不到 PATH 时会退回 `~/.moon/bin/moon`。
- Xcode 或 Command Line Tools：需要 `xcrun swiftc` 来编译 `winid.swift`。**不要**用 swiftly 装的自定义 toolchain 跑，Swift 和 Xcode SDK 版本不匹配会直接编译失败；脚本固定用 `xcrun` 调 Xcode 自带工具链。
- `screencapture`、`sips`、`stat`：macOS 自带。
- **屏幕录制权限**：系统设置 → 隐私与安全性 → 屏幕录制，给终端 / DS Bot 打开。没有权限时 `screencapture` 可能返回 0 但产出黑图或直接失败。
- **写权限**：`moon build` 需要写 `~/.moon/cache/deps`（锁文件）和项目内 `_build/`。如果 DSH 会话是 `workspace-write` 沙箱，构建会报
  `Unable to lock dependency source cache ... Operation not permitted`，需要换成有完整磁盘权限的终端执行，或先手动构建再用 `--no-build` 截图。

## 用法

```sh
cd /Users/zc/.dsh/bot/workspace/omp_studio_moui

# 构建 + 启动 + 截一张
scripts/shot.sh
# -> stdout: /…/shots/app-20261122-111854.png
#    stderr: 构建/窗口/终止过程日志

# 已经构建过，只要截图
scripts/shot.sh --no-build

# 回归检查：构建 + 截图 + 进程必须活过 5 秒
scripts/check.sh
echo $?          # 0 = 通过
```

### shot.sh 参数

| 参数 | 默认 | 说明 |
| --- | --- | --- |
| `--no-build` | 否 | 跳过 `moon build macos_skia --target native`，直接用现有产物 |
| `--timeout <秒>` | 20 | 等窗口出现的最长时间 |
| `--settle <秒>` | 0.8 | 窗口出现后等首帧渲染稳定再截图 |
| `--out-dir <目录>` | `shots/` | 输出目录，相对路径按项目根解析 |
| `--keep` | 否 | 截图后保留应用进程（默认截图完成即终止） |
| `--activate` | 否 | 截图前把应用窗口置前（默认不抢焦点；后台窗口也能截到画面） |
| `--pid-file <路径>` | 无 | 写入应用 pid，供 check.sh 或排查使用 |
| `--log-file <路径>` | 临时文件 | 把应用 stdout/stderr 写到指定文件 |
| `--min-bytes <n>` | 1024 | 截图小于这个字节数视为空白/失败 |
| `--verbose` | 否 | 显示完整构建输出 |

### check.sh 参数

| 参数 | 默认 | 说明 |
| --- | --- | --- |
| `--no-build` | 否 | 跳过构建 |
| `--alive-seconds <秒>` | 5 | 截图后要求进程继续存活的时长 |
| `--timeout <秒>` | 20 | 透传 shot.sh |
| `--settle <秒>` | 0.8 | 透传 shot.sh |
| `--shot-dir <目录>` | `shots/` | 透传 shot.sh 的 `--out-dir` |
| `--verbose` | 否 | 完整构建输出 |

### 输出约定

两个脚本都是 **stdout 只有一行：截图的绝对路径**（便于 `path=$(scripts/shot.sh)`），过程日志和诊断全部走 stderr。

### 退出码

| 码 | 含义 | 脚本 |
| --- | --- | --- |
| 0 | 成功 / 检查通过 | 两者 |
| 1 | 用法错误 | 两者 |
| 2 | 构建失败 | 两者 |
| 3 | 应用启动即崩溃，没出现窗口 | 两者 |
| 4 | 等待窗口超时 | 两者 |
| 5 | 截图失败、空白，或尺寸与窗口不符 | 两者 |
| 6 | 环境不满足（缺 moon / xcrun / 产物） | 两者 |
| 7 | 存活检查失败：进程在 N 秒内退出 | check.sh |
| 8 | 进程活着但窗口消失 | check.sh |

## 截图直达某个状态（QA 环境变量）

应用入口读几个 `OMP_*` 变量，配合 `shot.sh` / `check.sh` 可直接把某一层状态放进帧里，不用真的用鼠标键盘走一遍。变量原样传给启动的应用进程：

```sh
OMP_MODAL=rename scripts/shot.sh --no-build --out-dir shots/interact
OMP_HOVER_X=32 OMP_HOVER_Y=28 OMP_TIP=1 scripts/shot.sh --no-build
```

| 变量 | 取值 | 作用 |
| --- | --- | --- |
| `OMP_ROUTE` | `workbench`（默认）/ `home` / `history` / `capabilities` / `model-config` / `settings` / `diagnostics` / `evaluation` / `media` / `statistics` / `agent-hub` | 启动直接落到该页面，等价于点导航栏 |
| `OMP_WIN_W` / `OMP_WIN_H` | 逻辑像素，默认 `1440` / `900`（允许 320..3840） | 窗口尺寸 |
| `OMP_PALETTE` | `1` | 启动时 ⌘K 命令面板已打开 |
| `OMP_PALETTE_QUERY` | 任意文字 | 预输入过滤词；`zzz` 得到空态 |
| `OMP_HOVER_X` / `OMP_HOVER_Y` | 逻辑像素，负数表示指针不在任何控件上 | 把指针停在指定点，hover 态入帧 |
| `OMP_MODAL` | `confirm` / `rename` / `shortcuts` | 打开对应 sheet，并把时钟推到入场动画结束 |
| `OMP_FOCUS` | `1` | 键盘焦点环停在第一个可聚焦控件 |
| `OMP_TOAST` | 任意文字 | 一条 toast 停在停留期（3s 内） |
| `OMP_TIP` | `1` | 在 `OMP_HOVER` 的位置把 tip 落定（跳过 500ms dwell） |

注意 `OMP_TIP` 需要指针停在一个带 tip 的控件上；`OMP_MODAL` 会清掉 hover tip 与 ⌘K 面板。

## 一次真实运行

`scripts/shot.sh --no-build`：

```text
[shot] 启动应用：/…/omp_studio_moui/_build/native/debug/build/macos_skia/macos_skia.exe
[shot] 应用 pid=40795
[shot] 窗口出现：id=53537 size=1440x900 title=OmpStudioMoui
[shot] 截图：screencapture -l 53537 -> /…/shots/app-20261122-111854.png
[shot] 完成：/…/shots/app-20261122-111854.png（830129 字节，窗口 1440x900 -> 图片 2880x1800）
[shot] 终止应用 pid=40795
```

stdout：`/Users/zc/.dsh/bot/workspace/omp_studio_moui/shots/app-20261122-111854.png`，退出码 0，耗时约 2.2 秒。

`scripts/check.sh`：

```text
[check] 运行: /…/scripts/shot.sh  --keep
[shot] 构建: /Users/zc/.moon/bin/moon build macos_skia --target native
[shot] 构建成功（1s）
[shot] 启动应用：/…/macos_skia.exe
[shot] 应用 pid=41593
[shot] 窗口出现：id=53554 size=1442x902 title=OmpStudioMoui
[shot] 截图：screencapture -l 53554 -> /…/shots/app-20261122-111900.png
[shot] 完成：/…/shots/app-20261122-111900.png（830129 字节，窗口 1440x900 -> 图片 2880x1800）
[check] 截图完成：/…/shots/app-20261122-111900.png
[check] 应用 pid=41593，开始 5s 存活检查
[check] 通过：进程存活 5s 未退出，总耗时 8s
[check] 截图：/…/shots/app-20261122-111900.png
[check] 应用已退出
```

退出码 0。注意窗口出现时是 `1442x902`，截图前脚本会重新确认一次窗口（尺寸/id 可能因布局动画变化），最终以 `1440x900` 为准。

## 常见失败排查

### 1. 构建失败（退出码 2）

先看 stderr 里打印的构建输出尾部。

- `Unable to lock dependency source cache .../<user>/.moon/cache/deps: Operation not permitted`
  这是没有写 `~/.moon/cache` 的权限（常见于受限沙箱），不是代码问题。换一个有完整磁盘权限的终端跑，或先在正常终端 `moon build macos_skia --target native`，再用 `scripts/shot.sh --no-build`。
- `Failed to run prebuild script for module wzzc-dev/moui_skia_renderer`
  通常是 Skia 预编译包没下载。**不要删除** `.mooncakes/` 下的 `.skia-cache`。需要从 GitHub release 拉包时，用代理前缀：`https://gh-proxy.com/` + 原始 release 地址。网络恢复后重跑即可。
- 找不到 `moon`：确认 `which moon`，或 `MOON=/path/to/moon scripts/shot.sh`。
- 构建很慢（首次 5–10 分钟）属正常；增量构建通常在 1–2 秒。`--no-build` 只在确认产物已是最新时使用。

### 2. 等不到窗口（退出码 4）

- 应用进程还活着但没窗口：看 stderr 里应用自己的输出（脚本会打尾部 20 行）。
- 窗口被最小化或在别的 Space：脚本用 `CGWindowListCopyWindowInfo` 匹配 layer 0 且在屏的窗口，最小化的窗口会被跳过。切回对应 Space 或重启应用。
- 应用卡在首帧：当前 `macos_skia/main.mbt` 用 `show_after_first_present=true`，首帧渲染失败时窗口根本不会出现。这时多半是渲染崩溃或 Skia 初始化失败，需要看应用 stderr，用更大 `--timeout` 复现。
- 无人值守/SSH：没有 GUI 会话时不会出现窗口，这是环境限制。

### 3. 截图失败 / 空白（退出码 5）

- 系统设置 → 隐私与安全性 → 屏幕录制，确认调用方（终端、DS Bot）已授权。改权限后要重启对应进程。
- `screencapture` 返回 0 但生成黑图：`--min-bytes` 会兜底（默认 1024）。如果画面本身大面积纯色导致文件很小，可临时调低阈值，但要人工看图确认。
- **尺寸自检报错**（`截图尺寸异常`）：说明 `-l` 的窗口 id 在截图前失效，`screencapture` 静默退回全屏截图。脚本已经做了两件事：settle 后重新取窗口 id；把图片像素尺寸和窗口逻辑尺寸做比例校验（约 1x/2x）。如果仍出现，通常是窗口刚重建或应用在截图瞬间退出，重跑一次；持续出现就记 bug。
- Retina 下逻辑 720×512 的窗口截出来是 1440×1024 像素，这是正常的 2x（早期 counter 脚手架实测值）。

### 4. 截图抓到了别的窗口

脚本严格按启动时的 pid 过滤窗口，不会抓到其他进程。如果画面不对，确认是不是有多个应用实例：`pgrep -fl macos_skia.exe`，把旧实例杀掉再跑。`check.sh` 结束时一定会清理它启动的进程；`shot.sh --keep` 才会留下。

### 5. 和开发流程并行

`moon build` 会锁 `~/.moon/cache/deps`，同一时间只应有一个构建。如果另一个终端正在改代码/构建，先等它结束，否则会出现锁等待或拿到半成品产物。跑截图前最好确认没有别人正在 `moon build`。

### 6. 调试窗口匹配

```sh
# 列出所有 layer 0 窗口（id、尺寸、是否在屏、进程名、标题）
_build/qa/winid --list

# 查某个 pid 的主窗口
_build/qa/winid <pid>
_build/qa/winid <pid> --activate   # 顺带置前
```

`winid` 的挑选规则：同 pid、layer 0、宽高 ≥ 200，优先在屏窗口，再取面积最大的。窗口标题需要屏幕录制权限才能读到；读不到标题不影响截图。

## 已知环境坑

1. **bash 3.2 的变量展开**：`$var` 后面紧跟中文（如 `）`、`，`）时，bash 会把多字节字符当成变量名的一部分，报 `unbound variable`。脚本里所有中文紧邻的变量都已写成 `${var}`，后续修改请保持这个习惯。
2. **工具链冲突**：`~/.swiftly/bin/swift`（Swift 6.1.2）配 Xcode 26.3 的 SDK 会报 `this SDK is not supported by the compiler`。脚本固定用 `xcrun swiftc`，不要改成裸 `swift`/`swiftc`。
3. **模块缓存**：Swift 编译需要可写 module cache，脚本放在 `_build/qa/module-cache` 并把 `TMPDIR` 指到 `_build/qa/tmp`，避免沙箱拒绝写 `/var/folders`。
4. **透明标题栏窗口**：当前主窗口 1440×900（逻辑），`CGWindowBounds` 可能报 1442×902 之类的边界差异，尺寸校验放行 0.85x–2.6x 的比例，并要求宽、高比例一致（差值 ≤0.25），所以 1x、2x 都能过。
5. **窗口 id 不是永久的**：应用重启或窗口重建后 `CGWindowID` 会变，脚本每次运行重新查询，不要缓存 id。
