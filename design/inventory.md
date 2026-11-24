# OMP Studio · 界面结构清单

> 目的：把复刻版要画/要实现的界面拆成区域，每区给出**真实尺寸**与**交互行为**，数值全部从 `/tmp/omp-studio`（v0.2.8，main）源码读出并注明出处。
> 配套：颜色/字号/动效见 [tokens.md](tokens.md)，中文文案见 [copy.md](copy.md)。

## 0. 全局壳层

界面是「**一条顶栏 + 左栏 + 侧栏 + 画布 + 右缘工具坞**」的四列结构，浮窗浮在画布之上。窗口模式下画布上方多一条 44px 的窗口 Tab 条。

### 0.1 尺寸总表

| 区域 | 尺寸 | 出处 |
|---|---|---|
| 应用标题栏 `.app-titlebar` | 高 **36px**，`padding: 0 10px`，gap 8，图标钮 **28×28** | `App.css:22-53` |
| 工作台顶栏 `.topbar` | 高 **44px**（`--topbar-h`），右 padding 12 / 左 8，gap 8，下边框 1px | `workbench.css:6-14`、`tokens.css:86` |
| 左图标栏 `.app-rail` | 宽 **56px**（`--nav-rail-w`），折叠 **0**；按钮 38×38、步进 42、把手 18×46、头像 34 | `App.css:203-219, 325-353`、`tokens.css:87` |
| 会话侧栏 `.sidebar` | 宽 **272px**（`--sidebar-w`），拖拽范围 **200–400px**，resizer **6px**（右缘 -3px） | `sidebar.css:6-7, 40-42`、`tokens.css:88` |
| 工作台画布 | 撑满剩余宽度；浮窗坐标以画布为原点 | `App.tsx` layout |
| 右侧面板 `--panel-w` | 默认 **480px** | `tokens.css` |
| 右缘工具坞（展开） | 宽 **320px**，`right: 12px`；紧凑态 **40px** | `dock.css:264, 358` |
| 右缘工具坞（宽度调整） | resizer **6px**，`left: -3px` | `dock.css:355-358` |
| 对话正文 / composer | `max-width: **768px**`（`--doc-max-w`） | `--doc-max-w`、`workbench.css:295-303` |
| minimap | 宽 **36px**，贴在对话右缘；composer 左侧让出 `16+36+8` | `--minimap-w`、`workbench.css:2465-2472` |
| 底部面板 | 默认高 **240px** | `--bottom-panel-h` |

### 0.2 视觉分层原则

层次**不靠阴影**，靠「边框 + 表面步进」：`--bg` → `--surface` → `--surface-2` → `--surface-3`。`--shadow-menu` / `--shadow-modal` 默认都是 `none`，只有光效档位 ≥ `standard` 时才由 `light.css` 补光（见 tokens.md §6）。
→ 复刻时**不要**给卡片加阴影，先靠 1px 边框和底色差；否则暗色下会糊成一团。

**唯一的例外是交互 Deck（审批/提问/计划卡）**：它故意带一圈 accent 辉光来抢注意力 —— 亮色 `0 0 22px 4px accent@16%` + 两层淡黑影，暗色把辉光提到 22% 并把黑影加深（`workbench.css:2926-2947`）。复刻时这层辉光要保留，它是「现在需要你操作」的唯一视觉信号。

### 0.3 z-index

`--z-topbar 20` < `--z-panel 30` < `--z-menu 60` < `--z-float 70` < `--z-modal 80` < `--z-tip 90` < `--z-toast 100`。
浮窗用独立序列 **`31 + order*2`**（`WindowFrame.tsx:51`），不参与上面的阶梯。

---

## 1. 左图标栏（NavRail）

**组成**：顶部 6 个目的地图标（工作台/首页/会话历史/能力中心/模型配置/设置）→ 中间弹性空白 → 底部「有更新」按钮 + 账户头像 34px → 骑在右缘的折叠把手 18×46。

**尺寸**：宽 56；按钮 38×38、圆角 10、间距步进 42；激活态是一块会滑动的 `app-rail-window` 高亮块（`--rail-active-index` 驱动位移）。

**交互**：
- 点图标切路由；激活项高亮块滑过去（`background` 过渡，`--dur-fast`）。
- 折叠：宽 56 → 0，用 `width var(--dur-slow) var(--ease-nav)`；折叠时 `app-rail-clip` 设 `inert`，把手贴在移动的边框线上。
- 账户按钮打开账户菜单（rail 折叠后由侧栏 footer 接管，两者只有一个 owner）。
- `data-dock-entry="rail"`：可被拖拽/停靠系统接管。

---

## 2. 窗口 Tab 条（仅窗口模式，44px）

**组成**：左「新建对话 +」→ 每个浮窗一个 tab → 右端是焦点窗口的 dock 填充位。tab 内容为 `窗口图标 + 标题 + 状态`；最小化/桌面窗口也占一格。

**尺寸**：条高 44（`--topbar-h`），`padding: 0 4px 0 8px`；tab 高 **32**，`min-width: 80 / max-width: 220`，激活时 `min-width: 112`，gap 3；关闭钮 **24×26**（平时 `opacity: 0`，hover/激活才现形）。

**交互**：
- 点 tab = 聚焦该窗口（不移动窗口位置）；`×` = 关闭该窗口（等同窗口自己的 ×）。
- tab 标签含状态与位置：`[title, status.label, 已最小化/独立窗口]` 用 ` · ` 连接。
- 焦点窗口胜出；所有窗口最小化时，选中「持有共享 chrome 的会话」。
- 键盘：`←/→` 移动焦点，`Delete` 关闭。

---

## 3. 会话侧栏（272px）

自上而下 5 段：**品牌行**（logo 22×22 圆角 9 + `OMP Studio` + 搜索/菜单钮）→ **主导航行**（`新建对话` 带 `Ctrl ⌘ O`、`技能与插件` 带数字角标）→ **项目与对话** 分区 → **Explorer** 分区 → 底部账户/状态区。

### 3.1 尺寸

| 元素 | 数值 | 出处 |
|---|---|---|
| 侧栏上内边距 | `10px 10px 0`；右上角圆角 15 | `sidebar.css:58-95` |
| 品牌行 | 高约 30，logo 22×22 / 圆角 9，名字 14px/600 | 同上 |
| 分区头 `.sb-section-head` | `padding: 6px 12px 4px`，11px / 600 / uppercase，`--text-3` | `sidebar.css:104-113` |
| 项目行 `.project-head-row` | `padding: 6px 8px`，圆角 9；右侧 flags（dirty 数、running 点、attention 点） | `sidebar.css:242-252` |
| 会话行 `.thread` | `padding: 6px 8px`，gap 6，圆角 **9**（`--r-6`），对齐项目名（左 8 + 14 文件夹槽 + 6 gap） | `sidebar.css:242-252` |
| 状态胶囊 `.t-wait` | `chip xs`：高 **16px**，字号 10.5px | `ThreadWaitChip.tsx`、`components.css:151-179` |
| 文件树行 `.tree-row` | 高 **24px**，gap 5，圆角 **4**，缩进 `--depth-pad`（默认 6） | `sidebar.css:547-565` |
| 文件树容器 | `padding: 0 6px`，12px | 同上 |
| resizer | 宽 6，`right: -3`，hover `--accent-border` | `sidebar.css:40-42` |

### 3.2 会话树结构

```
项目(omp-web)  · branch · dirty 3 · +214 −58 · ●running
 ├ 新建对话（空白）                             now
 ├ 内容图鉴：全部工具卡与正文格式   📌           now
 ├ 跟踪上游 pi-web 更新到 omp-web  📌  ⤷ 3     32m
 ├ Audit and fix OSS repository issues         2h   [待回答]
 ├ Mermaid 全屏缩放计划与交互确认               4d   [待审核]
 ├ 修复 Git Bash 路径未找到问题                 4d   [待确认]
 ├ 重构 session 存储层 (session)               6d   （归档）
 └ 展开 +7
pi-web (upstream) · v0.8.1
omp-web (feat/mermaid) · +1263 −341
```

- 项目按「项目 → 分支分组」两级；同项目多 worktree 时并列（截图里 `pi-web (upstream)` 与 `omp-web (feat/mermaid)`）。
- 子会话（sub-agent）用 `⤷ {count}` 挂在父会话行尾。
- 固定（📌）、未读（数字）、归档、运行中（pulse 点）各自有独立标记。

### 3.3 状态徽章（关键交互）

| 语义 | 文案 | 色 | 位置 |
|---|---|---|---|
| 审批等待 | 待确认 | amber | 会话行右端 |
| 计划评审 | 待审核 | purple | 会话行右端 |
| 提问等待 | 待回答 | blue | 会话行右端 |

行为：`role="status"` + `aria-label`；不阻断点击；对应 `THREAD_WAIT_TONE`（`sidebar/threadWait.ts:24-28`）。

### 3.4 交互

- 点会话行：激活并在画布打开/聚焦对应会话窗口；激活行 `--accent-soft` + 标题变 `--accent` + 500 字重。
- hover 整行高亮（高亮挂在 `.thread-row` 上，指针移到右侧操作钮时行背景不熄灭）。
- 行尾 `…` / 右键：重命名、根据对话自动命名、归档、Fork、交接摘要。
- 项目头右键/hover：切换项目、新建会话、在终端打开、在外部编辑器打开、Git 操作。
- Explorer：单击选中、双击/回车打开文件、`⌥` 新建文件/文件夹、刷新、拖拽到对话当引用。
- 侧栏可整体折叠（`margin-left: -272px`），顶栏布局钮 `data-dock-entry="left"` 与它同步。

---

## 4. 工作台画布（Workbench Canvas）

**定位**：占据 `rail + sidebar` 之后的所有剩余空间；浮窗、吸附布局、最小化胶囊都在这层。

**组成**：
1. 空态（没打开任何会话时）；
2. 浮窗层（`dock-float`，绝对定位）；
3. 吸附布局层（`snapLayer`，浮窗吸附时以它为坐标系）；
4. 最小化胶囊行（画布顶部，`left/right: 56px`，高 32，圆角 9，max-width 178）。

**尺寸/规则**：
- 浮窗默认最小 **320×200**（`WindowFrame.tsx:13`）；吸附布局最小 **360×280**（`snap.ts:3`）。
- 吸附模板 6 种：`halves / wide-left / columns / stack-left / stack-right / quarters`（`snap.ts:5`），分栏比例 `2/3` 或 `1/3+2/3`。
- 浮窗 z 序 `31 + order*2`，指针按下或 focus 时 `raise()`。

**交互**：
- **拖动**：拖标题栏（`cursor: grab`）移动；`-webkit-app-region: drag` 只给原生浮窗。
- **缩放**：8 个手柄（四边 6px、四角 12px），带 `minWidth/minHeight` 夹取与边界夹取。
- **双击标题栏** = 最大化/还原（按钮区域除外，`WindowFrame.tsx:60`）。
- **最大化**：铺满画布；**最小化**：收到胶囊行。
- **吸附**：拖到画布边缘触发吸附预览（`snap-picker` 截图），吸附后 `resizable={false}`。
- **点击任意浮窗** = 提到最前（`stacking.raise()`）；`预览模式`下不参与 z 序。

---

## 5. 会话窗口（画布内最大的一类浮窗）

### 5.1 窗口标题栏（34px）

> 这就是需求里说的「含 Time Travel / 布局钮 / 最小化 / 关闭」的那条。

**尺寸**：高 **34**（`flex: 0 0 34px`），`padding: 3px 5px 3px 10px`，圆角 12，gap 2，下边框 1px（tint 12% 混 border）；标题背景是 `--window-title-bg`（tint 7% 混 surface）。`dock.css:421`。

**左组**：标题菜单（窗口图标 20×20 圆角 6 + 标题 + chevron，高 26）→ 来源胶囊（项目 · 连接，max-width 180，10px 字）→ 状态点 16px（running 绿+ pulse / waiting 琥珀 / error 红）。
**窗口模式下**左侧改成面包屑：`项目 › 分支 › 会话`，`›` 分隔符用 `--text-faint`，窄容器（≤620/520/460）逐级隐藏来源胶囊、Fork/Handoff、标题里的 code。

**右组**：Time Travel → 布局钮（对话工具区）→ `…` → 最小化 → 最大化/还原 → 关闭。按钮都是 `dock-icon-button`。

**交互**：
- 标题菜单：会话菜单（重命名/Fork/交接/压缩/导出/归档）。
- 状态点 tooltip 显示 `status.label`（运行中/待确认…）。
- Time Travel 是胶囊：未开启显示「开启」，点击弹「开启前，了解代价与风险」；已开启显示时间线入口。
- `…` 菜单见 copy.md §4.1（标注 / Token 用量 / Context 构成 / 离线 Token 计数 / 收回对话区）。
- 双击标题栏 = 最大化；整条可拖动；`cursor: grab`。

### 5.2 消息流

**尺寸**：正文 `max-width 768`；每条 `.ev` 下边距 **20**；用户气泡 `padding: 10px 14px`、圆角 **16 16 4 16**、`max-width: 78%`、14px/1.7；暗色底 `--accent` 实底 + `--text-on-accent` 文字，亮色底 `#eee9ff`（`workbench.css:541-600`）。

**组成**：`head`（角色徽标 + 时间 + 耗时 + 操作）→ `body`（Markdown / 代码 / 表格 / 图片）→ `refs`（引用 chip，gap 6）。

**角色风格**（关键复刻点）：
- **用户**：右对齐实底气泡，右下小角指向发送者。
- **助手**：文档式正文，无气泡，左对齐，可全宽。

**交互**：
- 复制代码块（hover 出现「复制代码」）。
- 工具卡默认折叠，展开看命令/输出。
- 正文内的错误/失败用 `--red` 行内块，不整条染色。
- 滚动到底出现「回到最新」胶囊；右缘 minimap 36px 可点击跳转、滚轮过滤。
- 消息级操作（Fork `branchSession` / 重试上一轮 `retryTurn`）由消息头与会话尾承担；具体露出时机以实现为准，不在本文档臆断。

### 5.3 工具卡（Tool card）

**尺寸**：行最小高 **24**（`--tap-min`），`padding: 2px 4px`，gap 6，字号 **13**，圆角 6；展开体左缩进 `4+14+6=24`，右缩进 `4+13+6=23`（`workbench.css:1392-1480`）。

**组成**：`▸ 工具名 · 参数摘要` → 右侧状态/耗时 → 展开体（命令块 `$ …` + 输出 + diff）。

**交互**：单击标题切换展开；展开态 chevron 转 **180°**（`.tl-item.open .tl-chev`，注意不是 90°）；命令块左侧 `$` 不可选中；输出超长时横向滚动（行 `width: max-content`），失败行标红；`运行中` 用蓝 chip，`执行完成` 用灰字。

### 5.4 审批卡（Approval）

**尺寸**（`workbench.css:1947-1984, 2926-2968`）：
- 外壳：边框 `amber` 38% 混透明，圆角 **16**（`--r-10`），底 `--surface`；
- 头 `.approval-head`：`padding: 10px 14px`，背景 `--amber-soft`、文字 `--amber`、12px / 600 —— **整条头是琥珀色**，这是它和提问卡（accent 边框）在远处就能分开的原因；
- 体 `.approval-body`：`12px 14px`，12px，`--text-2`；里面的命令块是 mono + `--code-bg` + 圆角 9 + `8px 10px`；
- 脚 `.approval-foot`：`10px 14px` + 上边框，`flex-wrap: wrap`；
- 定位：贴底 **8px**，`max-width 768`，高度上限 `min(420px, 72vh)`；
- 已处理态 `.resolved`：边框变 `--border`，头变 `--surface-2` + `--text-3`（琥珀色「要注意」语气撤掉）。

**组成**：标题 `审批请求` + 风险 chip（高/中/低）→ 说明 `OMP 请求执行以下受保护的工具操作：` → 动作详情（工具名、参数、受影响路径）→ 脚：`拒绝`（danger）/`允许一次`（primary）/`本会话允许`/`记住…`（二级菜单：仅本会话 / 跨会话记住）。

**交互**：
- 记住：按文件夹或文件粒度，受限目录直接禁用（文案见 copy.md §8）。
- 审批未处理时 composer 被拦：`请先处理上方的询问或审批，再发送新消息`；此时在输入框发送会「拒绝这次调用并把消息转交给 OMP」。
- 提交中出现 loading；失败保留卡片 + `提交失败，卡片已保留。请重试。`
- 同一时刻只有一张 active card（`deck.active`），其余排队。

### 5.5 进度条 / 任务进度

**位置**：composer 上方浮条，展开时向上覆盖对话区（`workbench.css:2522`）。
**组成**：一行摘要 `第 5 / 7 步 · 3 个文件已更改 · 部分编辑` → 展开后两列：待办列表（checkbox + 阶段分组）+ 文件变更（+adds −dels）。
**尺寸**：内联进度条轨道高 **4**、圆角全、填充 accent、最小宽 **8%**（`components.css:356-368`）。
**交互**：点标题展开/收起；列表自动滚动，用户滚轮即暂停；文件行可点开 diff。

### 5.6 Composer 底栏

**尺寸**：区域 `padding: 10px 16px 8px`，左侧额外让出 `16 + 36 + 8`；输入面板 `max-width 768`、圆角 **16**、边框 `--border-strong`；bar `padding: 4px 8px 8px`；权限/模式 pill 高 **24**、圆角全；上下文 chip 高 **22**、圆角 9、11px mono。

**组成**（左→右）：
1. 上沿：上下文 chip 行（`@` 引用、已加载文件、token 计数）；
2. 输入区（多行，自动增高）；
3. 下沿：`权限 pill`（Full Access 等）→ `模式` → `模型` → 思考档 → `＋`更多 → 麦克风 → `发送/停止`；
4. 上方叠：排队条（已提交/本地草稿）、任务进度浮条、审批拦截提示。

**交互**：
- `Enter` 发送；`Shift+Enter` 换行；运行中 `Enter` 排队（`{shortcut}` 立刻交给 Runtime）。
- 排队消息可编辑：`Enter` 写回原位、`Escape` 取消并还原草稿。
- 权限/模式/模型切换只在**下一轮**生效，当前轮显示提示。
- 有 pending 交互时输入被禁用。
- 附件、`@` 引用、`/` 指令各自弹层；`/` 支持分组（会话/模式/模型/上下文/能力/工作区/协作/帮助）。
- 模型未加载显示「加载模型配置…」。

---

## 6. 审批窗 / Plan Review 浮窗

**两种承载**：
1. **会话内联**：计划卡贴在消息流底部（截图里的紫框 `Plan Review` 卡）；
2. **独立浮窗**：`WindowFrame` 承载，标题 `Plan Review · {计划标题}`，34px 标题栏 + 最小化/最大化/关闭。

**尺寸**：
- 内联卡：贴底 8px，max-width 768，圆角 16，高度上限 `min(420px, 72vh)`。
- 浮层 dialog：overlay `padding: 24px 40px`（`position: fixed; inset: 0`）；dialog `min(1080px, 100%)` × 100%，圆角 16，z = `--z-modal`（80）；遮罩单独一层，亮色 `rgba(15,15,25,0.5)`、暗色 `rgba(0,0,0,0.6)`；展开 `--dur-slower`，收起 `--dur-slow`（`workbench.css:3336-3392`）。

**组成**：
- 头：`Plan Review` + 计划标题 + `已批准` chip（批准后）+ 折叠/放大/关闭；
- 主体：Markdown 按 H2 切 section（`目标 / 实施步骤 / 执行档位`），支持 `阅读 / 编辑` 双视图；
- 右/下：全文批注输入；
- 脚：`批准并执行`（primary）、`保留上下文执行`、`压缩后执行`、`修改意见`（展开输入）、`保存并退出`、`放弃计划`。

**交互**：
- 覆盖式 modal，背景对话不可操作；`Esc` 关闭（放弃）。
- 阅读↔编辑切换，编辑态显示 `未保存 / 已保存` 与「保存计划」。
- 批准后再执行会显示「已批准」；失败 toast `计划评审已变化，请稍后重试`。
- 计划正文来自会话里的 Markdown 文档，不是硬编码 —— **复刻时 mock 数据要自带 `## 目标` 这类标题**。
- 一个会话同时只有一张待审计划，队列里显示 `待审核的计划`。

---

## 7. 托管浏览器窗（Managed Browser）

**承载**：同样是 `WindowFrame`（34px 标题栏），标题是页面标题；下方是 38px 工具条 + 页面区。

**尺寸**（`browser/managedBrowser.css`）：
| 元素 | 数值 |
|---|---|
| 工具条 `.mb-toolbar` | 高 **38**，`padding: 0 6px 0 4px`（起始页 12），gap 6 |
| 地址框 `.mb-omnibox` | 高 **28**，`padding: 0 4px 0 9px`，圆角 **9**（`--r-6`），底 `--surface-2` |
| 地址框聚焦 | 边框 `--accent-border` + 3px `--accent-softer` 外环 |
| 控制段按钮 | 高 **22**，`padding: 0 8px`（紧凑 6） |
| 加载条 `.mb-loadbar` | 高 **2**，贴底 `bottom: -1` |
| 状态条 `.mb-bar` | 最小高 **32**，`padding: 3px 6px 3px 10px` |
| 页面字号 | 12px（工具条整体） |

**组成**（左→右）：后退 / 前进 / 刷新（仅人工接管可用）→ 地址框（锁图标 + host + path + 缩放 chip + 空间 chip）→ `Agent | 我` 控制段 → `…` 更多 → 标题。

**交互**：
- **Agent 是静态默认**；点 `我` 人工接管（accent 实底，唯一强调色块），接管后可输入网址、点前进后退、缩放；再点 `Agent` 归还。
- 接管是「同一页面」的租约，不新开 tab；已被其他窗口持有时按钮禁用并提示。
- 未接管时地址框 `readOnly`，tooltip `接管后可以输入网址`。
- 加载时 2px 条扫动，落定后淡出；错误 host 变红。
- `…`：新建标签页 `⌘T`、查找 `⌘F`、选元素、DevTools、缩放、原生窗口、复制网址、系统浏览器、关闭其他、释放网页、下载、设置、页面与能力。
- 页面本身是原生/native 层，**不能在页面区域上叠画任何东西**（`managedBrowser.css` 头注释明确要求）。

---

## 8. 右缘工具坞（Dock Rail）

**三种状态**：展开 **320px** / 紧凑 **40px** / 隐藏 **0**；`right: 12px`，切换用 View Transition（`--dock-rail-transition`）。

**组成**：
1. **工具条**（`min-height 28`，hover/focus-within 才 `opacity: 1`）：添加 / 模式 / 隐藏 三个钮；
2. **卡片列表**（展开态）：卡片间距 **10**，卡片圆角 16（`--r-10`），卡片头 `min-height: 44`、`padding: 3px 14px`，底部 1px 分隔线；
3. **图标列**（紧凑态）：竖向 gap 8、padding 2、图标 **36×36** 圆形（`--r-full`，边框 `--border-strong`），激活为 accent 描边 + `--accent-soft` 底；
4. **宽度 resizer**：6px，`left: -3px`，hover 变 `--accent-border`。

**交互**：
- 布局钮（标题栏的「对话工具区」）在 展开/紧凑/隐藏 之间切换。
- 展开时对话区**主动让宽**：`.convo-scroll` 与 `.composer-region` 宽度改为 `calc(100% - rail-w - 12px)` —— 不是盖住对话。
- 紧凑态点图标 = 在该位置展开对应卡片；卡片可拖拽重排、拖到左右/底部成组。
- 每个卡片可折叠（`.dock-card.is-collapsed`）、可隐藏、可分离成独立浮窗、可吸附成面板。
- 卡片头右侧可以挂**仪表**（`dock-meter-summary`，告警色 `--amber`/`--red`），显示实时数值（如 token/上下文/进程）。
- 键盘：区域支持 `Shift+F10` 打开上下文菜单。

---

## 9. 交互与层级汇总（复刻时按这张表验）

| # | 行为 | 规则 | 出处 |
|---|---|---|---|
| 1 | 浮窗置顶 | 指针按下或 focus 即 `raise()`，z = `31+2n` | `WindowFrame.tsx:47-51` |
| 2 | 拖动 | 仅标题栏；按钮区 `data-window-drag` 不触发 | `WindowFrame.tsx:58-60` |
| 3 | 双击标题 | 最大化 / 还原 | `WindowFrame.tsx:60` |
| 4 | 缩放 | 8 向手柄，边 6 / 角 12 | `dock.css:405-443` |
| 5 | 吸附 | 6 模板；吸附后不可手改尺寸 | `snap.ts:5` |
| 6 | 最小化 | 收成胶囊（高 32，圆角 9），点胶囊恢复 | `dock.css:442-452` |
| 7 | 侧栏拖动 | 200–400px 夹取，resizer hover 高亮 | `sidebar.css:40-42` |
| 8 | 左栏折叠 | 宽 → 0，`inert` 内容，把手随边框走 | `App.css:203-219` |
| 9 | 工具坞切换 | 展开让宽、紧凑变圆图标列、隐藏归零 | `dock.css:264, 358-364` |
| 10 | composer 语义 | Enter 发 / Shift+Enter 换行 / 运行中 Enter 排队 | copy.md §11 |
| 11 | 审批拦截 | 有 pending 时禁止发送 | `composer.pendingInteractionHint` |
| 12 | 主题切换 | `html[data-theme]`，默认 light | tokens.md §0 |
| 13 | 密度切换 | `data-density` 只缩放间距（0.85/1.15） | `tokens.css:62-78` |
| 14 | 光效 | `data-light` 只加光，不改颜色 | `light.css:1-33` |

---

## 10. 复刻顺序建议（按「能跑起来」的最短路径）

1. **壳层**：36px 标题栏 + 56px 左栏 + 272px 侧栏 + 画布（先固定尺寸，不做拖拽）。
2. **侧栏**：项目树 + 会话行 + 三种状态胶囊（这是信息密度最高、最容易一眼像的部分）。
3. **会话窗口**：34px 标题栏（Time Travel/布局/最小化/关闭）+ 消息流 + 工具卡。
4. **composer**：输入 + 权限/模式/模型 pill + 发送/停止。
5. **审批卡 + Plan Review**：两张卡决定「产品感」，先做静态态。
6. **右缘工具坞**：先只做紧凑 40px 图标列，展开态后补。
7. **托管浏览器窗**：38px 工具条 + 28px 地址框 + `Agent|我` 段，页面区放占位。
8. 最后补：拖动/缩放/吸附、minimap、任务进度、Time Travel 引导。

> 每一步都能独立验收；尺寸与颜色都用 tokens.md 的数值，文案用 copy.md，不要在实现里现编。
