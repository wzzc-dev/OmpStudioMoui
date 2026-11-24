# OMP Studio · Design Tokens

> 目标：给 MoonBit / moui 复刻版提供一份可直接抄进代码的数值表。
> 来源：`/tmp/omp-studio`（v0.2.8，main）。所有数值都从源码读出，括号里注明出处文件与行号。
> 核心文件：`apps/renderer/src/styles/tokens.css`（颜色、圆角、间距、动效、布局度量）、`typography.css`、`base.css`、`motion.css`、`light.css`、`workbench.css`、`sidebar.css`、`apps/renderer/src/dock/dock.css`、`conversationWorkspace/workspace.css`、`App.css`。

## 0. 命名约定与主题机制

| 机制 | 说明 | 出处 |
|---|---|---|
| 主题切换 | `html[data-theme="light"\|"dark"]`，默认（无属性）即 light | tokens.css:199-200, 374-375 |
| 光效档位 | `html[data-light="off\|soft\|std\|vivid"]`，只「加光」不改颜色 | tokens.css:6-13, light.css:1-33 |
| 信息密度 | `html[data-density="compact\|cozy"]` → `--density-scale` 0.85 / 1.15，只缩放间距阶梯，不动字号与布局 | tokens.css:62-78, 193-196 |
| 字号缩放 | `--ui-font-scale`（UI）/ `--output-font-scale`（对话正文、代码） | tokens.css:27-29, typography.css:2-29 |
| 文件类型调色板 | `html[data-palette="tri"]` 回落中性色（无障碍三通道模式） | tokens.css:530-552 |

一个关键设计原则（复刻时要保留）：**默认是「平」的**——`--shadow-menu` 与 `--shadow-modal` 都是 `none`（tokens.css:323-324, 475-476），层次靠边框 + 表面步进（`--bg` → `--surface` → `--surface-2` → `--surface-3`）。阴影只在「光效」档位 ≥ standard 时由 light.css 补上（light.css:73-94）。

---

## 1. 颜色 · 暗色表

`:root[data-theme="dark"]`，tokens.css:375-502。

### 1.1 背景与表面

| token | 值 | 用途 |
|---|---|---|
| `--bg` | `#121519` | 应用底 / 对话画布 / topbar 底 |
| `--bg-inset` | `#0e1013` | 侧栏、抽屉、dock 面板、浮窗内容底（比 `--bg` 更沉） |
| `--surface` | `#1a1b1f` | 卡片、composer、菜单、chip 浮起面 |
| `--surface-2` | `#222329` | 次级面：tab strip、代码块外的浅层、分区条 |
| `--surface-3` | `#2b2c33` | 三级面：进度条轨道、分区块 |
| `--surface-hover` | `rgba(235,235,245,0.05)` | 行/按钮 hover |
| `--surface-active` | `rgba(235,235,245,0.09)` | 按下 / 选中填充 / rail 高亮块 |
| `--selection` | `rgba(158,140,252,0.3)` | 文本选区 |

### 1.2 文本

| token | 值 | 对比度（对 `--surface`） | 用途 |
|---|---|---|---|
| `--text` | `#e7e8eb` | — | 正文、标题 |
| `--text-2` | `#a7abb4` | 8.1:1 | 次级正文、参数 |
| `--text-3` | `#8b909a` | 5.37:1 | 注释性文字、工具卡行文字 |
| `--text-faint` | `#7c828c` | 4.55:1 | 时间戳、耗时、行号（可读文本下限） |
| `--glyph-faint` | `#676b74` | — | 纯非文本灰：图标细线、rail 点、禁用字形 |
| `--text-on-accent` | `#121316` | 6.73:1 on accent | 强调色上的字（暗色下反相为深色） |

### 1.3 边框

| token | 值 | 用途 |
|---|---|---|
| `--border` | `rgba(255,255,255,0.07)` | 常规分隔线、卡片描边 |
| `--border-strong` | `rgba(255,255,255,0.12)` | composer 外框、tab / chip 描边、resizer |
| `--border-float` | `#46505f` | 脱离表面的窗框（modal、plan dialog），自己就能和页面分开 |
| `--accent-border` | `rgba(158,140,252,0.4)` | 强调描边、拖拽高亮、焦点态描边 |

### 1.4 强调色

| token | 值 | 用途 |
|---|---|---|
| `--accent` | `#9e8cfc` | 主强调（浅丁香）；链接、焦点环、进度填充、选中会话标题 |
| `--accent-hover` | `#b0a2ff` | 强调 hover |
| `--accent-soft` | `rgba(158,140,252,0.14)` | 选中行底、accent chip、rail 激活底 |
| `--accent-softer` | `rgba(158,140,252,0.08)` | 更淡的强调底、composer 焦点外环 |
| `--code-chip-bg` / `--code-chip-text` | `rgba(158,140,252,0.14)` / `#b3a5fd` | 行内代码 chip |

### 1.5 语义状态

| token | 值 | 用途 |
|---|---|---|
| `--green` / `-soft` | `#46b983` / `rgba(70,185,131,0.15)` | 运行中、通过、已提交、untracked |
| `--amber` / `-soft` | `#e0a23c` / `rgba(224,162,60,0.15)` | 等待 / 待确认 / 警告 |
| `--red` / `-soft` | `#f06568` / `rgba(240,101,104,0.14)` | 失败、错误、删除 |
| `--blue` / `-soft` | `#5da9e0` / `rgba(93,169,224,0.15)` | 运行 composer 边框、待回答、native windows 条 |
| `--danger-orange` | `#ff7a45` | Full Access 权限模式专用警示（对暗底约 6.7:1） |
| `--danger-orange-soft` | `color-mix(in srgb, var(--danger-orange) 14%, transparent)` | 同上填充 |
| `--danger-glow` | `#ffd9a8` | Full Access 呼吸外发光（氛围，不承载文字） |
| `--purple` | `var(--accent)` | 别名（待审核徽章走 accent） |

### 1.6 tint 调色板（角色 / 窗口身份）

主色 + `-soft`（填充，0.16）+ `-border`（0.4）。暗色取 400 级高饱和：

| 名称 | 主色 | 名称 | 主色 |
|---|---|---|---|
| green | `#4ade80` | cyan | `#22d3ee` |
| blue | `#38bdf8` | lime | `#a3e635` |
| teal | `#2dd4bf` | indigo | `#818cf8` |
| violet | `#a78bfa` | rose | `#fb7185` |
| pink | `#f472b6` | orange | `#fb923c` |

用途：`data-window-tint` 决定浮窗标题栏底色（`color-mix(tint 7%, --surface)`）、描边（25%）、焦点环（55%）、窗口标记底（14%）——dock.css:395-428。

### 1.7 Git / diff

| token | 值 | 用途 |
|---|---|---|
| `--git-modified` | `#e3a008` | 已修改 |
| `--git-added` | `#3fb950` | 新增 |
| `--git-deleted` | `#f0616d` | 删除 |
| `--git-renamed` | `#4a9eff` | 重命名 |
| `--git-untracked` | `#7ee787` | 未跟踪 |
| `--git-conflict` | `#f0616d` | 冲突 |
| `--diff-add-bg` / `-gutter` | `rgba(70,185,131,0.16)` / `0.28` | diff 新增行 / 行号槽 |
| `--diff-del-bg` / `-gutter` | `rgba(240,101,104,0.14)` / `0.26` | diff 删除行 / 行号槽 |

⚠️ 硬约束（tokens.css:349-355）：git 状态色只表达「现在怎么样」，文件类型色只表达「这个文件是什么」，两套不许混用。

### 1.8 文件类型色（Explorer，8 通道 + 3 别名 + 1 dim）

| token | 值 | | token | 值 |
|---|---|---|---|---|
| `--ftype-code` | `#93b4dc` | | `--ftype-script` | `#9ac387` |
| `--ftype-markup` | `#d3a271` | | `--ftype-test` | `#c4bb6f` |
| `--ftype-style` | `#e0a6c2` | | `--ftype-image` | `#6fc0d2` |
| `--ftype-data` | `#79bfa2` | | `--ftype-secret` | `#d1838b` |
| `--ftype-dim` | `#72767f` | | 别名 doc/config/lock | `var(--text-3)` |

### 1.9 代码

| token | 值 |
|---|---|
| `--code-bg` | `#141519` |
| `--code-chip-bg` / `--code-chip-text` | `rgba(158,140,252,0.14)` / `#b3a5fd` |

### 1.10 滚动条 / 缩略图

| token | 值 |
|---|---|
| `--scrollbar` | `rgba(235,235,245,0.16)` |
| `--scrollbar-hover` | `rgba(235,235,245,0.3)` |
| `--minimap-viewport` | `rgba(235,235,245,0.07)` |

### 1.11 上下文构成色（Topbar「Context」弹层）

`--context-messages #3887dc`、`--context-tools #b35e14`、`--context-instructions #28a580`、`--context-system #9380c8`（tokens.css:422-426）。它们是身份色，不是状态色。

### 1.12 光效亮度参数

`--lux-k`：off `0` / soft `0.6` / std `1` / vivid `1.25`（light.css:36-39）。暗色光色：`--lux-rim: rgb(255 255 255 / 0.065)`、`--lux-shade: rgb(0 0 0 / 0.28)`、`--lux-shade-deep: rgb(0 0 0 / 0.5)`（light.css:57-64）。

---

## 2. 颜色 · 亮色表

`:root` / `:root[data-theme="light"]`，tokens.css:199-372。

### 2.1 背景与表面

| token | 值 | 用途 |
|---|---|---|
| `--bg` | `#fbfbfc` | 应用底 / 对话画布（对话区背景） |
| `--bg-inset` | `#ffffff` | 侧栏、抽屉、dock 面（亮色下侧栏比对话区更白） |
| `--surface` | `#ffffff` | 卡片、composer、菜单 |
| `--surface-2` | `#f2f2f5` | 次级面（tab strip、进度轨道外的浅层） |
| `--surface-3` | `#e8e8ec` | 三级面（进度条轨道） |
| `--surface-hover` | `rgba(20,20,30,0.045)` | hover |
| `--surface-active` | `rgba(20,20,30,0.08)` | 按下 / 选中填充 |
| `--selection` | `rgba(110,86,207,0.2)` | 选区 |

### 2.2 文本

| token | 值 | 对比度（对白） | 用途 |
|---|---|---|---|
| `--text` | `#1d2129` | — | 正文标题 |
| `--text-2` | `#4e5560` | 7.34:1 | 次级正文 |
| `--text-3` | `#5c636e` | 5.95:1 | 辅助文字 |
| `--text-faint` | `#6d7480` | 4.72:1 | 时间戳、行号 |
| `--glyph-faint` | `#8b929d` | — | 非文本灰（3:1 档） |
| `--text-on-accent` | `#ffffff` | — | 强调色上的字 |

### 2.3 边框

| token | 值 |
|---|---|
| `--border` | `rgba(15,18,25,0.09)` |
| `--border-strong` | `rgba(15,18,25,0.16)` |
| `--border-float` | `#9b958c` |
| `--accent-border` | `rgba(110,86,207,0.35)` |

### 2.4 强调色

| token | 值 | 用途 |
|---|---|---|
| `--accent` | `#6e56cf` | 主强调（紫） |
| `--accent-hover` | `#5f48c0` | hover |
| `--accent-soft` | `rgba(110,86,207,0.1)` | 选中行底 |
| `--accent-softer` | `rgba(110,86,207,0.06)` | 极淡底 / composer 焦点外环 |
| `--code-chip-bg` / `--code-chip-text` | `rgba(110,86,207,0.09)` / `#5a45b8` | 代码 chip |

### 2.5 语义状态

| token | 值 | 备注 |
|---|---|---|
| `--green` / `-soft` | `#137a52` / `rgba(19,122,82,0.12)` | 已压深到 4.5:1 以上 |
| `--amber` / `-soft` | `#8f5a05` / `rgba(143,90,5,0.12)` | 同上 |
| `--red` / `-soft` | `#c0272c` / `rgba(192,39,44,0.1)` | 同上 |
| `--blue` / `-soft` | `#1f6ba3` / `rgba(31,107,163,0.12)` | 同上 |
| `--danger-orange` | `#c2410c` | Full Access（对白约 5.2:1） |
| `--danger-glow` | `#ffc46b` | Full Access 光晕 |

### 2.6 tint 调色板（600 级）

green `#16a34a`、blue `#0284c7`、teal `#0d9488`、violet `#7c3aed`、pink `#db2777`、orange `#ea580c`、cyan `#0891b2`、lime `#65a30d`、indigo `#4f46e5`、rose `#e11d48`；`-soft` 统一 0.13，`-border` 0.35。

### 2.7 Git / diff

`--git-modified #96570a`、`--git-added #177e33`、`--git-deleted #c7283a`、`--git-renamed #0a66c2`、`--git-untracked #1a7f37`、`--git-conflict #c7283a`；
`--diff-add-bg rgba(19,122,82,0.11)` / gutter `0.2`，`--diff-del-bg rgba(192,39,44,0.09)` / gutter `0.18`。

### 2.8 文件类型色

code `#3b5f8f`、markup `#7d5527`、style `#8a4a70`、data `#1f6b55`、script `#4a6b32`、test `#6d6118`、image `#23697d`、secret `#96434b`、dim `#787d86`。

### 2.9 代码 / 滚动条

`--code-bg #f4f4f7`；`--scrollbar rgba(20,20,30,0.18)`、`--scrollbar-hover rgba(20,20,30,0.32)`、`--minimap-viewport rgba(20,20,30,0.08)`。

### 2.10 光效光色（亮色）

`--lux-rim: rgb(255 255 255 / 0.9)`（上缘白边）、`--lux-shade: rgb(52 40 120 / 0.07)`、`--lux-shade-deep: rgb(52 40 120 / 0.14)`——亮色不能发光，改用「偏强调色的软阴影」（light.css:50-56）。

---

## 3. 圆角（两主题共用）

阶梯刻意比常规调大，让 UI 读起来是「圆」的；外层永远大于内层，保证嵌套不打架（tokens.css:53-60）。

| token | 值 | 用途 |
|---|---|---|
| `--r-4` | **6px** | 行内 chip、树行、小控件、工具卡行、dock tab close |
| `--r-6` | **9px** | 按钮、菜单项、工具卡、侧栏会话行、dock tab |
| `--r-8` | **12px** | 卡片、面板、popover、浮窗框、dock drag preview |
| `--r-10` | **16px** | modal、composer、命令面板、审批卡、dock rail 卡片、plan dialog |
| `--r-full` | **999px** | chip / 胶囊 / 圆形图标钮 / 进度条 |

源码里还有几个字面值，复刻时照抄：
- 侧栏右上角 `15px`（sidebar.css:17）
- 导航栏高亮块与按钮 `10px`（App.css:325-353）
- 浮窗最大化时 `border-radius: 0`（dock.css:419）
- dock rail 折叠动画里 `--r-12`（6px 的旧别名）→ `18px`（dock.css:350）

---

## 4. 间距刻度

以 `--density-scale` 等比缩放（tokens.css:67-78）；紧凑 = 0.85，宽松 = 1.15。

| token | 基准值 | | token | 基准值 |
|---|---|---|---|---|
| `--sp-2` | 2px | | `--sp-14` | 14px |
| `--sp-4` | 4px | | `--sp-16` | 16px |
| `--sp-6` | 6px | | `--sp-20` | 20px |
| `--sp-8` | 8px | | `--sp-24` | 24px |
| `--sp-10` | 10px | | `--sp-32` | 32px |
| `--sp-12` | 12px | | | |

补充度量：`--tap-min: 24px`（WCAG 2.2 最小点击区，图标可以比它小，命中区补齐）。

---

## 5. 字号 / 字重 / 行高

### 5.1 字号阶梯（约 1.17 倍，刻意去掉 13px 档）

| token | 值 | 用途（源码注释原文语义） |
|---|---|---|
| `--fs-11` | `11px` | 最小 UI 字：时间戳、元信息、帮助文字 |
| `--fs-12` | `12px` | 标准 UI 字：按钮、标签、树行 |
| `--fs-14` | `14px` | 次级标题、强调文字、分区标签 |
| `--fs-16` | `16px` | 正文、输入框、对话内容 |
| `--fs-18` | `18px` | 页面标题、面板标题 |
| `--fs-22` | `22px` | 大标题、欢迎语 |

对话正文走 `--output-font-scale` 独立缩放（typography.css:2-13）；工具卡行文字是 `13px`（workbench.css:1403，字面值），侧栏时间戳 `10.5px`（sidebar.css:405），chip xs `10.5px`（components.css:178），窗口小字 `fs-10`（workspace.css:43）。

### 5.2 字重

`--fw-regular 400`、`--fw-medium 500`、`--fw-semibold 600`、`--fw-bold 700`（tokens.css:48-51）。

用途约定：正文 400；可点击的强调标签 500；分区标题（侧栏 uppercase 小标）600；卡片标题/审批抬头 600。

### 5.3 行高

| 位置 | 值 | 出处 |
|---|---|---|
| body 默认 | `1.55` | base.css:27 |
| 对话正文单行高度 | `calc(12px * output-scale * 1.65)` ≈ 19.8px | typography.css:17 |
| 浏览器状态条 | `1.45` | managedBrowser.css:60 |

### 5.4 字体族

```
--font-ui-default: -apple-system, BlinkMacSystemFont, "Segoe UI", "PingFang SC",
  "Hiragino Sans GB", "Microsoft YaHei", "Noto Sans SC", sans-serif;
--font-mono-default: "JetBrains Mono", "Cascadia Code", ui-monospace, "SF Mono",
  Menlo, Monaco, Consolas, "Courier New", monospace;
```
（tokens.css:17-26；`--font-terminal` = mono，`--font-output` = ui，`--terminal-font-size: 12px`）

### 5.5 字距

侧栏分区标题 `letter-spacing: 0.04em` + `text-transform: uppercase`（sidebar.css:110-113）；Explorer 标题加强到 `0.1em`（sidebar.css:122-124）。

### 5.6 图标

`.icon` 16×16、stroke-width 1.6、`vertical-align: -3px`；`.sm` 13×13、`.lg` 18×18（base.css:155-168）。导航栏图标 18px（App.css:352），工具卡图标 12px（workbench.css:1421），窗口按钮图标 13px（dock.css:68-78 的 26px 按钮内 3px padding）。

---

## 6. 阴影

默认全平（`none`）。只有三处自带阴影，与主题无关：

| 位置 | 值 | 出处 |
|---|---|---|
| Deck（composer 上方交互卡）亮色 | `0 0 22px 4px accent@16%, 0 8px 28px rgba(15,17,26,.10), 0 2px 8px rgba(15,17,26,.06)` | workbench.css:2940-2946 |
| Deck 暗色 | `0 0 26px 4px accent@22%, 0 8px 28px rgba(0,0,0,.45), 0 2px 8px rgba(0,0,0,.30)` | workbench.css:2948-2954 |
| 浮窗 frame | `0 16px 48px rgba(0,0,0,.18), 0 2px 8px rgba(0,0,0,.08)` | dock.css:405-407 |
| 焦点浮窗 | `0 0 0 1px tint@55%, 0 0 18px tint@16%` 叠加在 frame 阴影上 | dock.css:414-416 |
| 胶囊 | `0 2px 8px rgba(0,0,0,.08)` | dock.css:443 |
| dock rail overlay | `0 12px 40px rgb(0 0 0 / 16%)` | dock.css:389 |
| 侧栏右缘光 | `0 0 8px color-mix(text 16%, transparent)`（`::after`，z-index:-1） | sidebar.css:28-35 |
| composer 焦点 | `0 0 0 3px accent-softer, 0 0 18px 2px accent@25%`（不是阴影层，是发光） | workbench.css:3571-3576 |

光效档位 ≥ standard 时追加（light.css:73-94）：

| token | 亮色 | 暗色 |
|---|---|---|
| `--shadow-menu` | `inset 0 1px 0 --lux-rim, 0 2px 6px -2px shade, 0 12px 32px -10px shade-deep` | 同上 + `0 0 calc(40px*k) -16px glow@40%` |
| `--shadow-modal` | `inset 0 1px 0 --lux-rim, 0 4px 14px -4px shade, 0 28px 72px -18px shade-deep` | 同上 + `0 0 calc(80px*k) -24px glow@34%` |
| 卡片（`.card` 等） | `inset 0 1px 0 rim, 0 1px 2px shade, 0 8px 20px -14px shade-deep` | 同 |

---

## 7. 动效

数值只在 tokens.css（tokens.css:96-171），规则只在 motion.css；`src/motion.ts` 镜像同一张表（复刻时只抄这张表即可）。

### 7.1 时长阶梯（约 ×1.4，按「动的是什么」选，不按「哪个好看」）

| token | 值 | 语义 |
|---|---|---|
| `--dur-tactile` | **80ms** | 按下被确认 |
| `--dur-fast` | **120ms** | 颜色、hover、位置不变的东西；popover |
| `--dur` | **180ms** | 单个元素换状态：chevron、开关、展开 |
| `--dur-slow` | **250ms** | 区域变尺寸/变位置：面板、抽屉、卡片 |
| `--dur-slower` | **320ms** | 整个表面到达：页面、tab pane、toast |
| `--dur-hero` | **480ms** | 承载意义的形变：ask genie、plan sheet |
| `--dur-flash` | 900ms | 留一眼再淡出的高亮 |
| `--dur-marquee` | 3000ms | 长标签按阅读速度滚动 |
| `--tip-delay` | 500ms | 悬停提示的等待（是等待，不是动画） |
| `--stagger` | 40ms | 级联条目之间的间隔 |

规则：**离开比到达快一档**（320ms 到达的面，250ms 离开），所以关闭从不像在等。

### 7.2 曲线

| token | 值 | 语义 |
|---|---|---|
| `--ease` | `cubic-bezier(0.25,0.1,0.25,1)` | 状态色/透明度 |
| `--ease-out` | `cubic-bezier(0.16,0.84,0.44,1)` | 到达（减速落位） |
| `--ease-in` | `cubic-bezier(0.5,0,0.75,0)` | 离开（加速走开） |
| `--ease-nav` | `cubic-bezier(0.32,0.72,0,1)` | 表面横穿屏幕：起步利落、长软着陆、不过冲 |
| `--ease-ios` | `cubic-bezier(0.25,0.46,0.45,0.94)` | 跟随手势 |
| `--ease-emphasis` | `cubic-bezier(0.38,0,0.08,1)` | 大形状起止都在静止的形变 |
| `--ease-loop` | `cubic-bezier(0.42,0,0.58,1)` | 往复循环（呼吸） |
| `--ease-spring` | `linear(...)` 阻尼弹簧 ζ0.62，约 8% 过冲 | 小标记落位（**唯一会过冲的曲线**，只用于标记与滑块） |

### 7.3 位移

| token | 值 | 用途 |
|---|---|---|
| `--shift-xs` | 4px | 单个元素：popover、行内展开 |
| `--shift-sm` | 8px | 一个组件；任何面离开时的漂移距离 |
| `--shift-md` | 12px | 纵深方向到达的面：页面、toast |
| `--shift-lg` | 16px | 横向到达的面：tab pane、deck cell |

规律：面离开只漂到达距离的一半；纵深走垂直，兄弟走水平。

### 7.4 循环（是状态，不是过渡；只许「静」不许「删」）

| token | 值 | 用途 |
|---|---|---|
| `--loop-spin` | 800ms | spinner |
| `--loop-pulse` | 1400ms | 呼吸点、skeleton 扫光、进度条扫光、等待光晕 |
| `--loop-drift` | 2400ms | 活着的微漂移 |
| `--loop-orbit` | 3200ms | 边缘跑一圈的光 |
| `--loop-ambient` | 18000ms | 环境场极慢漂移 |

### 7.5 动画配方（可直接复用，motion.css:63-118）

| 变量 | 组合 | 用于 |
|---|---|---|
| `--motion-pop` | `omp-pop-in 120ms ease-out backwards`（opacity 0→, translate 4px×pop-from, scale .97） | 从锚点长出来：菜单、下拉、hover 卡 |
| `--motion-reveal` | `omp-rise-in 180ms ease-out backwards`（translate 4px） | 流里出现的内容 |
| `--motion-unfold` | `omp-drop-in 180ms ease-out backwards`（translate -4px） | 标题下展开的 body |
| `--motion-swap` | `omp-swap-in 120ms ease-out backwards`（opacity .4 起步） | 原地换内容（详情面板跟随列表） |
| `--motion-sheet` / `-out` | `omp-sheet-in 180ms ease-out`（translate 8px, scale .98）/ `120ms ease-in` | 无锚点浮层：modal、dialog、palette |
| `--motion-fade` / `-out` | `120ms` fade | 遮罩、纯淡出 |
| `--motion-toast` / `-out` | `320ms ease-out` / `250ms ease-in` | 从窗口边缘来的提示 |

reduced-motion 只有一处策略（motion.css 末尾），组件不许自己写 `@media (prefers-reduced-motion)`。

---

## 8. 布局度量

`tokens.css:85-94` + 组件实测值。

| token | 值 | 说明 |
|---|---|---|
| `--topbar-h` | **44px** | 顶栏；窗口模式 tab strip 同高（workspace.css:16） |
| `--nav-rail-w` | **56px** | 左侧图标栏；折叠为 0（App.css:203-219） |
| `--sidebar-w` | **272px** | 会话侧栏默认宽 |
| `--sidebar-min` / `--sidebar-max` | **200 / 400px** | 拖拽范围 |
| `--minimap-w` | **36px** | 对话右缘缩略导航；composer 左 padding 要让它（`+36+8`） |
| `--panel-w` | **480px** | 右侧面板默认宽 |
| `--doc-max-w` | **768px** | 对话正文/composer 最大宽（`--conversation-width` 也是 768） |
| `--bottom-panel-h` | **240px** | 底部面板默认高 |

组件级实测：

| 元素 | 数值 | 出处 |
|---|---|---|
| 导航栏按钮 | 38×38，步进 42，圆角 10，头像 34，折叠把手 18×46 | App.css:204-207, 325-353, 387-396 |
| 侧栏 | 上内边距 10/10/0；品牌 logo 22×22 圆角 9；右上角圆角 15 | sidebar.css:58-95 |
| 侧栏分区头 | `padding: 6px 12px 4px`，11px/600/uppercase | sidebar.css:104-113 |
| 侧栏会话行 | `padding: 6px 8px`，gap 6，圆角 9 | sidebar.css:242-252 |
| 侧栏 resizer | 6px 宽，右缘 -3px | sidebar.css:40-42 |
| 对话正文 | max-width 768，阅读栏 `768 + 2×32 + rail` | workbench.css:295-303 |
| Composer | max-width 768，圆角 16，边框 `--border-strong`；bar `padding: 4px 8px 8px`；pill 高 24 圆角全 | workbench.css:3558-3588, 4172-4187 |
| Composer 外层 | `padding: 10px 16px 8px`，左额外 `+36+8` | workbench.css:2465-2472 |
| 上下文 chip | 高 22，圆角 9，11px mono | workbench.css:3579-3587 |
| Deck 交互卡 | 贴底 8px，max-width 768，圆角 16；高度上限 `min(420px, 72vh)` | workbench.css:2926-2968 |
| 审批卡 | 圆角 16；头 `10/14`；体 `12/14`；脚 `10/14` | workbench.css:1948-1984 |
| 提问卡 | 圆角 16，边框 accent@28% | workbench.css:2003-2007 |
| Plan Review 浮层 | overlay `padding: 24px 40px`；dialog `min(1080px,100%)` × 100%，圆角 16 | workbench.css:3336-3380 |
| 进度条 | 轨道高 4，圆角全，填充 accent，最小宽 8% | components.css:356-368 |
| 工具卡行 | 最小高 24（`--tap-min`），`padding: 2px 4px`，gap 6，13px，圆角 6 | workbench.css:1392-1409 |
| 工具卡展开体缩进 | 左 `4+14+6=24px`，右 `4+13+6=23px` | workbench.css:1471-1480 |
| chip | 20 高；`.sm` 18；`.xs` 16（10.5px 字） | components.css:151-179 |
| dock rail 展开 | `right: 12px`，宽 `--dock-rail-w` 默认 **320px**；卡片间距 10 | dock.css:264-271 |
| dock rail 紧凑 | `right: 12px`，宽 **40px**；图标 36×36 圆形 | dock.css:358-362 |
| dock rail 工具条 | 最小高 28，hover 才显形 | dock.css:274-276 |
| dock 图标列 | gap 8，padding 2，图标 36 圆形（border-strong） | dock.css:361-364 |
| dock overlay | `right: 48px; top: 32px`，圆角 16，标题行 44 | dock.css:389-392 |
| dock tab strip | 高 36；tab 高 32，min 80 / max 210，激活 min 112；关闭钮 24×26 | dock.css:205-229 |
| 浮窗 frame | 标题栏 **34px**，`padding: 3px 5px 3px 10px`，圆角 12；resizer 边 6 / 角 12 | dock.css:405-443 |
| 浮窗最小尺寸 | 默认 minWidth 320 × minHeight 200；吸附布局最小 **360×280** | WindowFrame.tsx:13, snap.ts:3 |
| 浮窗 z 序 | `31 + order*2` | WindowFrame.tsx:51 |
| 胶囊 | 高 32，max-width 178，圆角 9；整行 `left: 56px; right: 56px` | dock.css:442-452 |
| 对话窗口 tab | 高 32，min 80 / max 220，激活 min 112；标题按钮高 26 | workspace.css:16-42 |
| 托管浏览器工具条 | 高 38；omni 框高 28 圆角 9；状态条最小高 32 | managedBrowser.css:12, 22, 60 |

---

## 9. z-index 阶梯（`tokens.css:173-191`，用名字，不用裸值）

| token | 值 | 层 |
|---|---|---|
| `--z-base` | 1 | 基础 |
| `--z-resizer` | 5 | 拖拽分隔条 |
| `--z-scroll-aid` | 9 | 滚动辅助 |
| `--z-rail` | 10 | 左栏 / deck |
| `--z-rail-tools` | 11 | 左栏工具 |
| `--z-topbar` | 20 | 顶栏 |
| `--z-panel` | 30 | 侧栏、面板 |
| `--z-fab` | 40 | 悬浮按钮 |
| `--z-menu` | 60 | 菜单 / popover |
| `--z-float` | 70 | BTW 浮窗（压住菜单，让位给 modal） |
| `--z-modal` | 80 | 独占 modal（Plan Review 用这层） |
| `--z-tip` | 90 | hover 提示（在 modal 之上、toast 之下） |
| `--z-toast` | 100 | toast |

组件里的额外层（别和阶梯混用）：dock overlay 29、紧凑 rail 29、胶囊 28、drag preview 57、浮窗 31+2n、plan overlay `--z-modal`。

---

## 10. 复刻速查（最小可用集）

如果只想先做「像」的一版，抄这 24 个值就够：

```
bg            #121519 / #fbfbfc
bg-inset      #0e1013 / #ffffff
surface       #1a1b1f / #ffffff
surface-2     #222329 / #f2f2f5
border        rgba(255,255,255,.07) / rgba(15,18,25,.09)
border-strong rgba(255,255,255,.12) / rgba(15,18,25,.16)
text          #e7e8eb / #1d2129
text-2        #a7abb4 / #4e5560
text-3        #8b909a / #5c636e
accent        #9e8cfc / #6e56cf
accent-soft   rgba(158,140,252,.14) / rgba(110,86,207,.1)
green         #46b983 / #137a52
amber         #e0a23c / #8f5a05
red           #f06568 / #c0272c
blue          #5da9e0 / #1f6ba3

r-chip 6  r-btn 9  r-card 12  r-modal 16  r-pill 999
fs 11 / 12 / 14 / 16 / 18 / 22   fw 400 / 500 / 600 / 700
topbar 44  rail 56  sidebar 272  minimap 36  doc 768  panel 480
dur 80 / 120 / 180 / 250 / 320 / 480
ease-out cubic-bezier(.16,.84,.44,1)
```
