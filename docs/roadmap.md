# OMP Studio 复刻 · 全功能路线图

> 目标：把 `/tmp/omp-studio`（v0.2.8）的功能**逐块做成可用的真功能**，不是画出来的壳。
> 本文是唯一进度口径：每完成一个阶段，勾掉勾选框并补「验收证据」。
> 视觉量的出处仍以 [inventory.md](../design/inventory.md)、[tokens.md](../design/tokens.md)、[copy.md](../design/copy.md) 为准。

## 0. 现状口径

| 层 | 现在 | 说明 |
|---|---|---|
| 窗口系统 | ✅ 真交互 | 拖动/缩放/吸附/最大化/最小化/胶囊/Tab/布局预设 |
| 工作台壳 | ✅ 视觉对齐 + hover | 顶栏、窗口 Tab、左图标栏、会话侧栏、画布、右缘工具坞 |
| 会话窗 | 🟡 视觉有了、行为是本地状态 | 消息流/工具卡/审批卡/composer 都是 mock 数据 |
| 二级页面 | ✅ 10 页 + 页内交互 | 首页/历史/能力中心/模型配置/设置/评测/媒体/诊断/统计/Agent Hub，页内筛选/开关/选中都是真状态 |
| 数据层 | ⬜ 无 | 全部 `demo_*` 常量，没有持久化、没有宿主进程 |
| 交互补完 | 🟡 过半 | 有 hover、滚轮、⌘K、Tab 关闭；缺 pressed/focus 环、tooltip/toast/模态、键盘环、拖拽改宽 |

规模参考：参考仓库 `apps/renderer/src` 有 49 个功能目录、约 200k 行 TS；`packages/studio-host` 是一整套真实宿主（会话运行时、pty、审批、账本、回放）。我们当前 `app/` 约 10.0k 行 MoonBit。

## 1. 功能面清单（参考 → 我们的落点）

### 1.1 页面 / 路由

参考的 10 个二级路由（`SecondaryPage.tsx` 的 `PageRoute`）与页头导航（9 个入口，统计页从首页 Token 卡进）：

| 路由 | 参考文件 | LOC | 主要功能 | 我们的落点 |
|---|---|---:|---|---|
| `workbench` | `workbench/*`、`conversationWorkspace/*` | 12k | 多浮窗工作台 | `app/`（已有） |
| `home` | `HomePage.tsx` | 1.7k | 问候/身份、快捷入口、最近项目、Token 卡 | `app/pages.mbt` · home |
| `history` | `HistoryPage.tsx`、`history/*` | 3k | 会话历史、搜索、归档/删除/导入、恢复 | pages · history |
| `capabilities` | `CapabilitiesPage.tsx`、`capabilities/*` | 2.5k | 技能/插件/MCP/命令清单、启停 | pages · capabilities |
| `model-config` | `ModelConfigPage.tsx`、`models/*` | 9k | 供应商、模型目录、角色分配、密钥 | pages · model-config |
| `settings` | `SettingsPage.tsx`、`settings/*` | 8.7k | 通用/外观/编辑器/快捷键/关于 | pages · settings |
| `diagnostics` | `DiagnosticsPage.tsx`、`diagnostics/*` | 1.1k | 运行时连通、环境检查、事件 | pages · diagnostics |
| `evaluation` | `evaluation/*` | 3.6k | 评测运行、评分、对比 | pages · evaluation |
| `media` | `MediaPage.tsx`、`media/*` | 2.7k | 图片/录音/视频、预览 | pages · media |
| `statistics` | `StatisticsPage.tsx`、`usage/*` | 1.2k | Token 用量、趋势、按模型 | pages · statistics |
| `agent-hub` | `AgentHub.tsx`、`agents/*` | 6.4k | Agent 目录/会话预览 | pages · agent-hub |

### 1.2 工作台子系统

| 子系统 | 参考 | LOC | 要做的真功能 |
|---|---|---:|---|
| 会话运行时 | `conversation/*` | 25.7k | 会话生命周期、流式消息、中断/重试、队列、fork、compact、导出 |
| Composer | `composer/*` | 12.9k | 富文本输入、@ 引用、/ 命令、模型/模式选择、附件、草稿 |
| Dock | `dock/*` | 11k | 三区面板注册表、Tab、拖拽入坞、浮动窗、尺寸记忆 |
| 审批/交互 Deck | `deck/*` | 5.9k | 审批、表单、提问、计划评审、批量决议 |
| 侧栏 | `sidebar/*` | 3.6k | 项目树、worktree、状态徽章、运行点、搜索 |
| 文件 | `files/*`、`fileBrowser/*` | 5k | 文件树、查看器、diff、外部打开、拖放 |
| 浏览器 | `browser/*` | 2.9k | 托管浏览器窗、标签、导航、截图 |
| 终端 | `TerminalPane.tsx`、`terminalSessions.tsx`、`tmux/*` | 2k+ | PTY 会话、多标签、主题、滚动回放 |
| Git | `git/*`、`commit/*` | 5k | 状态、diff、暂存、提交、分支、worktree |
| 预览/图形 | `preview/*`、`graphics/*`、`highlight/*` | 12k | Markdown/Mermaid/图表/代码高亮 |
| Agent | `agents/*`、`SubagentsPanel` | 6.4k | 子 Agent、编队、deck、模型委派 |
| 后台任务 | `background/*`、`backgroundTasks/*` | 4.3k | 任务队列、进度、取消 |
| 其他 | `btw`、`annotations`、`judgments`、`contextViewer`、`recordings`、`mobile`、`computer`、`embed`、`telemetry`、`onboarding`、`lux`、`i18n` | 约 8k | 侧问、标注、判定、上下文查看器、录屏、移动端、计算机控制、网页嵌入、遥测、引导、光效、国际化 |

### 1.3 宿主 / 协议（`packages/`）

`studio-host`（运行时、pty、审批、账本、回放）、`studio-protocol`（类型契约）、`client` / `client-contract`、`transport-desktop` / `transport-web`、`platform-*`。

复刻不必逐字移植 TS 宿主，但**协议形状要对齐**：会话、消息、审批、工具调用、Token 账本这五类对象是我们数据层的骨架。

## 2. 架构决定（复刻版）

1. **单画布自绘**：保持现在的 MoUI measured-canvas + 统一 `paint_scene`，所有页面共用一套命中测试，不做 DOM。
2. **一个 Model + 一个 Msg reducer**：新增 `Route` 和页面状态进 `Model`，页面动作走 `Msg`，`update` 是唯一变更点。
3. **布局即真值**：每块可点区域都从 `layout.mbt` / `pages*.mbt` 的槽位函数算出来，paint 与 hit-test 共用。
4. **数据层分层**：`page_data.mbt`（当前 demo 数据）→ 阶段 6 换成 `store.mbt`（JSON 持久化 + 宿主适配器），页面只读接口。
5. **视觉量值优先**：新页面先按 `pages.css` 的页头/正文规范落地，再谈动效。

## 3. 阶段与验收

### 阶段 1 · 路由骨架 + 二级页面 ✅
- [x] `Route` 枚举 + 左图标栏/页头导航双向切换 + 返回
- [x] 页头chrome：返回钮、标题 186 宽槽、9 个导航气泡、主题钮（页头 44 / 正文 24+32 内边距 / 1080 内容宽）
- [x] 10 个页面全部有真实内容与数据，不再是空壳
- [x] 页面滚动（滚轮 + 滚条）、历史/能力/设置的本地交互
- **证据**：`shots/pages/p1..p10`；`moon test app --target native` 12/12；`scripts/check.sh` 退出 0；`OMP_ROUTE=<slug>` 可直达任一页。

### 阶段 2 · 交互基础设施（进行中）
- [x] hover 态按区命中：顶栏菜单/导航钮、窗口 Tab 与关闭圆、左图标栏、右缘坞、窗口 chrome（含红色关闭）、页面标题栏气泡/主题钮、`.btn`、审批 deck、composer 药丸与发送钮
- [x] hover 令牌与参考一致：`surface_hover` / `surface_active` 半透明覆盖、`accent_hover` 主钮 hover
- [x] pressed / focus 两态：按下给 `surface_active` tint + 顶边 1px hairline（画布不能移动已画内容，用 tint 代替 1px 位移），松开 80ms（`--dur-tactile`）衰减，指针按下即清键盘环；焦点环按参考 `:focus-visible` 的 2px accent + 2px offset
- [x] 面板壳按参考 `.cmdk-*` 落值：`min(680,100vw-40) × min(680,100vh-48)` 居中、28 圆角、1.5px conic 光环（blue→accent→accent/red 循环）＋三层外发光＋`0 18 48` 投影、遮罩按主题 0.45/0.28、输入行 53px（14/18 内边距、16px 字段、Esc 键帽）、列表 8/8/12 内边距、组标 24px＋组间 6px、行 34px（7/10、6 圆角、14px 标签、键帽右对齐）、空态居中
- [x] ⌘K 命令目录与行为（`palette.mbt`，42 条命令分 5 组：最近会话 / 推荐操作 / 页面导航 / 面板与视图 / 配置与设置；沿用参考 `commandPaletteCatalog` 的分组顺序与中文词表；大小写无关子串过滤按 label+meta+keys+keywords，空组自动消失；最近会话发 ⌘1..⌘9 直跳，↑↓/Home/End/⏎/Esc/⌫ 齐备；hover 移位高亮、滚轮滚列表并夹紧、点行执行、点遮罩关闭）
- [x] Tooltip / Toast / 模态：tip 悬停 500ms（`--tip-delay`）后 120ms 淡入、移开即清、贴在控件上方且遇到窗口边缘翻面；toast 3s 停留 + 250ms 淡出上移，`needs_frames` 到点停止要帧；三张 sheet（重置布局确认 / F2 重命名 / ⌘/ 快捷键表）带遮罩（暗 0.6、亮 0.5）、180ms 入 / 120ms 出（translate 8 + scale .98→1）、边框与 46px 投影、点遮罩关闭、Esc 先关 sheet
- [x] 键盘导航：Tab / Shift-Tab 在全部可聚焦控件上环走并回绕，←/↑ 与 →/↓ 走同一环，Esc 逐层关闭（⌘K 面板 / sheet → picker → 键盘环 → tip），焦点只在键盘操作时出现、指针按下即清
- [x] 滚轮：会话窗（从底部起算的偏移 + 回到最新药丸）与页面正文（夹到内容高）
- [x] Tab 上的关闭圆可关闭窗口（paint 与命中测试共用 `tab_close_rect`）
- [x] 侧栏与项目/Explorer 分栏拖拽改宽：侧栏夹在 200..400，Explorer 46:54 分栏夹在 0.15..0.85，拖动实时落到 Model 并重绘，松开结束；窗口内命中与 paint 用同一组 rect
- [ ] 右坞 6 面板真内容（当前只有 5 个图标钮 + active 态，点击只改高亮）
- **验收**：每条命令可从 ⌘K 执行（有测试）；面板壳 680×680 与组间 6 有布局测试；滚轮两端夹紧（有测试）；Tab 关闭圆与 hover 命中（有测试）；拖拽改宽落到 Model 且重绘；按下/焦点环/Tab 环/方向键/Esc/tip 计时/toast 生命周期/重命名/快捷键表/重置布局/两种拖拽各有 reducer 测试，共 24/24；`shots/interact/` 有 focus、tip、toast、confirm、rename、shortcuts 六帧。

### 阶段 3 · 会话核心
- [ ] 消息模型：用户/助手/工具/审批/计划五类块 + 流式增量
- [ ] 消息流：分组、折叠、复制、重试、编辑重发、滚动锚定
- [ ] Composer：多行、@ 引用、/ 命令、模型/模式选择、附件、草稿、发送队列
- [ ] Deck：审批、提问、计划评审、表单；决议写回会话
- [ ] 右面板：Plan Review / 浏览器 / Explorer 真数据驱动
- **验收**：能新建会话 → 发消息 → 出现流式回复 → 触发一次审批 → 决议后继续 → 消息落盘。

### 阶段 4 · 工作区与持久化
- [ ] 项目/工作区模型、文件树读真实目录、打开/切换项目
- [ ] 会话历史存储（JSON）、搜索、归档/恢复/删除、导入导出
- [ ] 设置与布局记忆落盘（主题、密度、宽度、路由）
- **验收**：重启应用后路由、主题、会话列表、窗口布局还在；文件树能展开真实目录。

### 阶段 5 · 终端 + Git + 文件
- [ ] PTY 终端（多标签、主题、复制、清屏、滚动回放）
- [ ] Git 状态/diff/暂存/提交/分支/worktree
- [ ] 文件查看器（文本/图片/PDF）与结构化编辑
- **验收**：终端能跑 `ls`/`git status`；提交一个真实 commit；打开真实文件看到内容。

### 阶段 6 · 宿主与运行时
- [ ] `store.mbt` + `studio-protocol` 对齐的对象模型
- [ ] 真宿主进程（或本地 JSON 假宿主）跑通：会话、工具调用、账本、回放
- [ ] 审批账本与事件日志、运行时健康/诊断真数据
- **验收**：会话运行由宿主驱动，重启可恢复，审批有账本记录。

### 阶段 7 · Agent 与扩展
- [ ] 子 Agent / 编队 / 委派模型；后台任务队列
- [ ] 技能与插件运行时，MCP 服务器接入，命令清单
- [ ] 上下文查看器、标注、判定、侧问（btw）
- **验收**：一个任务能派给子 Agent 并回收结果；插件能注册命令并出现在 ⌘K。

### 阶段 8 · 媒体 / 预览 / 周边
- [ ] Markdown/Mermaid/代码高亮、图片/录音/视频、图形预览
- [ ] 托管浏览器面板、网页嵌入、录屏
- [ ] 引导 tour、光效档位、i18n 完整词表
- **验收**：Markdown 与 Mermaid 能真渲染；媒体页能预览真实文件。

### 阶段 9 · 打磨与验收
- [ ] 动效对齐（tokens.md §motion）、淡入/滑动、减少动效档
- [ ] 性能：滚动 60fps、消息流不卡、内存曲线
- [ ] 可访问性：焦点可见、aria 语义（自绘版以键盘环替代）
- **验收**：一份逐项对照表，参考的每个功能目录都能在我们的代码里指到实现。

## 4. 进度记录

- 2026-11-22：侧栏逐区视觉收口完成（行高/左缘/状态徽章/Explorer 46:54）。
- 2026-11-22：建立本路线图；阶段 1 开工。
- 2026-11-22：阶段 1 收口，10 页全部有内容，逐页截图对照通过。
- 2026-11-23：阶段 2 第一批——⌘K 命令面板（`palette.mbt`）、hover 态铺到壳与页面控件、会话窗滚轮（修好 `chat_height` 取错符号表的编译错误）、Tab 关闭圆可点。新增 5 条 reducer 测试（hover 命中、Tab 关闭、⌘K 过滤执行、页面滚轮、会话滚轮 + 回到最新），共 12/12。QA 入口加了 `OMP_PALETTE` / `OMP_HOVER_X` / `OMP_HOVER_Y`，面板与 hover 状态可直接截图。
- 2026-11-23：⌘K 面板按参考重写——壳 680×680 居中、conic 光环＋三层发光＋投影、遮罩分主题、输入行 53、列表 8/8/12、组标 24＋组间 6、行 34；目录扩到 42 条命令／5 组（含最近会话 ⌘1..⌘9 与配置直达页签），键盘补 Home/End/⌘数字/⌫，hover 移位高亮，空态与过滤态都有帧。QA 加 `OMP_PALETTE_QUERY`（`模型` / `zzz` 直出过滤与空态）。测试 13/13（新增面板壳 680/组间 6 的布局断言），`scripts/check.sh` 退出 0。
- 2026-11-23：阶段 2 第二批——交互层落地（`interact.mbt` 927 行 / `paint_interact.mbt` 360 行）：按下 tint（80ms 衰减）与 2px+2px 焦点环、Tab/Shift-Tab 与方向键环走、Esc 逐层、tip（500ms dwell + 120ms 淡入）与 toast（3s + 250ms 淡出上移）、三张 sheet（重置布局 / F2 重命名 / ⌘/ 快捷键表，含 0.6/0.5 遮罩、180/120ms 进出、重命名输入框聚焦、栏内 Tab 环、点遮罩关闭）、侧栏 200..400 与 Explorer 0.15..0.85 拖拽。新增 11 条 reducer 测试，共 24/24；QA 加 `OMP_MODAL` / `OMP_FOCUS` / `OMP_TOAST` / `OMP_TIP`，六种状态帧在 `shots/interact/`（focus、tip、toast、confirm、rename、shortcuts）；`scripts/check.sh` 退出 0。
- 2026-11-23：Tab 条右簇视觉收口——四个 `.icon-btn` 改回各自 26×26 方块、4px 节奏（此前「密度」和「右侧面板」被画成一块连着的紫色胶囊）；密度方块按参考用 `accent-soft` 无边框 + `tool-list` 双环双杠字形，四个方块共用同一个 glyph 函数。回归测试「tab strip keeps four 26px squares with one hit target each」钉住尺寸、间距、右内边距、各自命中与 4px 缝隙不响应，并补上「首页」方块的路由（`CClusterHome` → `go_route(Home)`，之前只画不响应也不进焦点环）。测试 25/25，`scripts/check.sh` 退出 0。
