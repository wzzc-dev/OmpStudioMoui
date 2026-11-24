// Page data. Everything here mirrors the reference fixtures (preview mode) so
// the pages read like the original console. Stage 4 of docs/roadmap.md replaces
// these constants with a persisted store; the pages only read fields, so the
// swap stays local.

///|
pub(all) struct SkillRow {
  name : String
  desc : String
  on : Bool
  /// 0 = skill package, 1 = plugin bundle, 2 = MCP server, 3 = command.
  kind : Int
}

///|
pub(all) struct ProviderRow {
  name : String
  base : String
  models : Array[String]
  key_ok : Bool
  key_hint : String
  on : Bool
}

///|
pub(all) struct UsageDay {
  label : String
  input : Int
  output : Int
}

///|
pub(all) struct EvalRun {
  name : String
  /// 0 = running, 1 = passed, 2 = failed.
  status : Int
  score : Double
  when : String
}

///|
pub(all) struct MediaItem {
  name : String
  /// 0 = image, 1 = audio, 2 = video.
  kind : Int
  size : String
  when : String
  /// Hue in degrees, used for the generated thumbnail tint.
  hue : Double
}

///|
pub(all) struct AgentRow {
  name : String
  model : String
  desc : String
  on : Bool
  scope : String
}

///|
pub(all) struct CheckRow {
  name : String
  detail : String
  ok : Bool
}

///|
pub(all) struct ProjectCard {
  name : String
  path : String
  /// Branch checked out in the project and the thread the card previews, shown
  /// on the card foot as `branch · thread` on the left and the age on the right.
  branch : String
  thread : String
  dirty : Int
  when : String
}

///|
pub(all) struct HistoryRow {
  title : String
  project : String
  branch : String
  when : String
  /// 0 = idle, 1 = running, 2 = awaiting review, 3 = awaiting answer,
  /// 4 = awaiting confirm, 5 = archived.
  state : Int
  tokens : Int
}

///|
pub fn demo_skills() -> Array[SkillRow] {
  [
    { name: "moonbit-guide", desc: "MoonBit 语言、工具链与项目结构规范", on: true, kind: 0 },
    { name: "office", desc: "读写 Word / Excel / PPT / PDF", on: true, kind: 0 },
    { name: "screenshot-qa", desc: "原生 macOS 应用的构建/截图验收", on: true, kind: 0 },
    { name: "moonbit-refactor", desc: "把 MoonBit 代码改成惯用写法并保测试", on: false, kind: 0 },
    { name: "chrome-devtools", desc: "浏览器调试与页面取证", on: false, kind: 0 },
    { name: "@omp-studio/renderer", desc: "渲染层插件包 · 面板注册表", on: true, kind: 1 },
    { name: "@omp-studio/terminal", desc: "PTY 终端面板插件", on: true, kind: 1 },
    { name: "@omp-studio/git", desc: "Git 工作流面板插件", on: false, kind: 1 },
    { name: "filesystem", desc: "读写工作区文件 · 18 个工具", on: true, kind: 2 },
    { name: "github", desc: "仓库、Issue、PR、代码搜索 · 24 个工具", on: true, kind: 2 },
    { name: "playwright", desc: "浏览器自动化 · 12 个工具", on: false, kind: 2 },
    { name: "builtin.rename", desc: "重命名当前会话", on: true, kind: 3 },
    { name: "builtin.compact", desc: "压缩当前上下文", on: true, kind: 3 },
    { name: "runtime.install", desc: "安装/升级 OMP Runtime", on: true, kind: 3 },
    { name: "session.fork", desc: "Fork 当前会话", on: true, kind: 3 },
    { name: "workspace.open", desc: "打开本地工作区", on: true, kind: 3 },
  ]
}

///|
pub fn demo_providers() -> Array[ProviderRow] {
  [
    {
      name: "Anthropic",
      base: "https://api.anthropic.com",
      models: ["claude-sonnet-4.5", "claude-opus-4.1", "claude-haiku-4"],
      key_ok: true,
      key_hint: "sk-ant-••••7f2c",
      on: true,
    },
    {
      name: "OpenAI",
      base: "https://api.openai.com/v1",
      models: ["gpt-5.2", "gpt-5-mini", "o4-mini"],
      key_ok: true,
      key_hint: "sk-••••9d41",
      on: true,
    },
    {
      name: "DeepSeek",
      base: "https://api.deepseek.com",
      models: ["deepseek-v4", "deepseek-v4-flash"],
      key_ok: false,
      key_hint: "未配置",
      on: false,
    },
    {
      name: "Local · llama.cpp",
      base: "http://127.0.0.1:8080/v1",
      models: ["qwen3-coder-30b", "devstral-small"],
      key_ok: true,
      key_hint: "无需密钥",
      on: true,
    },
  ]
}

///|
pub fn demo_usage_days() -> Array[UsageDay] {
  [
    { label: "11-09", input: 42000, output: 8100 },
    { label: "11-10", input: 61000, output: 12500 },
    { label: "11-11", input: 38000, output: 7400 },
    { label: "11-12", input: 88000, output: 19200 },
    { label: "11-13", input: 52000, output: 10800 },
    { label: "11-14", input: 30000, output: 6100 },
    { label: "11-15", input: 96000, output: 21400 },
    { label: "11-16", input: 71000, output: 15200 },
    { label: "11-17", input: 44000, output: 9100 },
    { label: "11-18", input: 120000, output: 26800 },
    { label: "11-19", input: 98000, output: 22100 },
    { label: "11-20", input: 64000, output: 13300 },
    { label: "11-21", input: 86000, output: 18700 },
    { label: "11-22", input: 41000, output: 8800 },
  ]
}

///|
pub fn demo_eval_runs() -> Array[EvalRun] {
  [
    { name: "swe-bench-lite · claude-sonnet-4.5", status: 1, score: 0.72, when: "2h" },
    { name: "terminal-bench · gpt-5.2", status: 1, score: 0.64, when: "5h" },
    { name: "moonbit-refactor · local/qwen3", status: 0, score: 0.0, when: "运行中" },
    { name: "ui-snapshot · claude-haiku-4", status: 2, score: 0.38, when: "1d" },
    { name: "tool-call-loop · claude-opus-4.1", status: 1, score: 0.91, when: "2d" },
    { name: "long-context-recall · gpt-5-mini", status: 1, score: 0.55, when: "3d" },
  ]
}

///|
pub fn demo_media() -> Array[MediaItem] {
  [
    { name: "sidebar-before.png", kind: 0, size: "184 KB", when: "now", hue: 268.0 },
    { name: "sidebar-after.png", kind: 0, size: "191 KB", when: "now", hue: 282.0 },
    { name: "workbench-light.png", kind: 0, size: "312 KB", when: "12m", hue: 32.0 },
    { name: "plan-review.mov", kind: 2, size: "18.4 MB", when: "1h", hue: 198.0 },
    { name: "voice-note-0042.wav", kind: 1, size: "2.1 MB", when: "2h", hue: 142.0 },
    { name: "token-chart.svg", kind: 0, size: "24 KB", when: "4h", hue: 12.0 },
    { name: "explorer-tree.png", kind: 0, size: "96 KB", when: "1d", hue: 88.0 },
    { name: "terminal-cast.mov", kind: 2, size: "42.8 MB", when: "2d", hue: 236.0 },
  ]
}

///|
pub fn demo_agents() -> Array[AgentRow] {
  [
    { name: "Chief", model: "claude-opus-4.1", desc: "统筹任务、拆解与回收结果", on: true, scope: "全局" },
    { name: "Pix", model: "claude-sonnet-4.5", desc: "设计拆解与视觉规范，只产出文档", on: true, scope: "omp-studio" },
    { name: "Shot", model: "claude-sonnet-4.5", desc: "验收工具链与截图回归", on: true, scope: "omp-studio" },
    { name: "Reviewer", model: "gpt-5.2", desc: "代码评审、风险与测试覆盖", on: false, scope: "omp-web" },
    { name: "Scout", model: "local/qwen3-coder-30b", desc: "大范围检索与线索汇总", on: false, scope: "全局" },
  ]
}

///|
pub fn demo_checks() -> Array[CheckRow] {
  [
    { name: "Runtime 连接", detail: "stdio · 12ms 往返 · 已握手", ok: true },
    { name: "Session 存储", detail: "~/.omp/sessions · 1.2 GB / 20 GB", ok: true },
    { name: "模型凭据", detail: "Anthropic、OpenAI、Local 可用；DeepSeek 未配置", ok: false },
    { name: "工作区索引", detail: "4 个项目 · 12,884 个文件 · 已同步", ok: true },
    { name: "PTY 后端", detail: "forkpty · 64 列 × 40 行 · shell /bin/zsh", ok: true },
    { name: "宿主版本", detail: "omp-host 0.2.8 · protocol v3", ok: true },
    { name: "更新检查", detail: "上次检查 18m 前 · 无新版本", ok: true },
  ]
}

///|
pub fn demo_project_cards() -> Array[ProjectCard] {
  [
    { name: "omp-web", path: "D:/Project/omp-web", branch: "feat/mermaid", thread: "跟踪上游 pi-web 更新到 omp-web", dirty: 3, when: "32m" },
    { name: "pi-web", path: "D:/Project/pi-web", branch: "main", thread: "模型委派：子 Agent 回收策略", dirty: 0, when: "2h" },
    { name: "omp-studio", path: "D:/Project/omp-studio", branch: "main", thread: "Render workbench at 1440 vs 1600", dirty: 1, when: "1d" },
  ]
}

///|
pub fn demo_history_rows() -> Array[HistoryRow] {
  [
    { title: "跟踪上游 pi-web 更新到 omp-web", project: "omp-web", branch: "feat/mermaid", when: "32m", state: 1, tokens: 21400 },
    { title: "内容图鉴：全部工具卡与正文格式", project: "omp-web", branch: "feat/mermaid", when: "now", state: 0, tokens: 8600 },
    { title: "Audit and fix OSS repository issues", project: "omp-web", branch: "feat/mermaid", when: "2h", state: 3, tokens: 41200 },
    { title: "Mermaid 全屏缩放计划与交互确认", project: "omp-web", branch: "feat/mermaid", when: "4d", state: 2, tokens: 9800 },
    { title: "修复 Git Bash 路径未找到问题", project: "omp-web", branch: "fix/git-bash-path", when: "4d", state: 4, tokens: 5400 },
    { title: "重构 session 存储层 (session)", project: "omp-web", branch: "feat/mermaid", when: "6d", state: 5, tokens: 33100 },
    { title: "Render workbench at 1440 vs 1600", project: "omp-studio", branch: "main", when: "1d", state: 0, tokens: 12800 },
    { title: "Terminal pane 主题与滚动回放", project: "omp-studio", branch: "main", when: "2d", state: 0, tokens: 7600 },
    { title: "模型委派：子 Agent 回收策略", project: "pi-web", branch: "upstream", when: "3d", state: 0, tokens: 21400 },
    { title: "Plan Review 卡片密度", project: "pi-web", branch: "upstream", when: "5d", state: 5, tokens: 4600 },
    { title: "审批账本导出与回放", project: "omp-web", branch: "feat/ledger", when: "1w", state: 5, tokens: 18700 },
    { title: "Explorer 46:54 分栏落地", project: "omp-studio", branch: "main", when: "1w", state: 0, tokens: 6200 },
  ]
}

///|
pub fn history_state_label(state : Int) -> String {
  match state {
    0 => ""
    1 => "运行中"
    2 => "待审核"
    3 => "待回答"
    4 => "待确认"
    _ => "已归档"
  }
}

///|
pub fn kind_label(kind : Int) -> String {
  match kind {
    0 => "技能"
    1 => "插件"
    _ => "MCP"
  }
}

///|
pub fn eval_status_label(status : Int) -> String {
  match status {
    0 => "运行中"
    1 => "通过"
    _ => "失败"
  }
}

///|
/// Per-model usage on the statistics page. `share` is the percentage of the
/// window's total tokens, `cost` the billed amount in USD as a display string,
/// mirroring the reference `usage` panel's provider breakdown.
pub(all) struct UsageModelRow {
  name : String
  input : Int
  output : Int
  cost : String
}

///|
/// Role → model routing shown on the model-config page. The reference keeps a
/// separate routing table (main / sub-agent / summary / vision) so a single
/// provider list can drive several roles at once.
pub(all) struct RoleRoute {
  role : String
  model : String
  note : String
}

///|
pub(all) struct ShortcutRow {
  keys : String
  label : String
}

///|
pub fn demo_usage_models() -> Array[UsageModelRow] {
  [
    { name: "claude-sonnet-4.5", input: 512000, output: 108000, cost: "$18.42" },
    { name: "gpt-5.2", input: 286000, output: 61000, cost: "$11.08" },
    { name: "deepseek-v4-flash", input: 174000, output: 39000, cost: "$0.86" },
    { name: "claude-haiku-4", input: 96000, output: 18000, cost: "$1.24" },
    { name: "local/qwen3-coder-30b", input: 62000, output: 12000, cost: "$0.00" },
  ]
}

///|
pub fn demo_role_routes() -> Array[RoleRoute] {
  [
    { role: "主对话", model: "claude-sonnet-4.5", note: "默认模型 · 支持工具调用" },
    { role: "子 Agent", model: "gpt-5.2", note: "并行分派 · 最长 20 分钟" },
    { role: "摘要 / Compact", model: "claude-haiku-4", note: "低成本 · 32k 窗口" },
    { role: "视觉 / 截图", model: "gpt-5.2", note: "图像输入 · 2 张上限" },
  ]
}

///|
pub fn demo_shortcuts() -> Array[ShortcutRow] {
  [
    { keys: "⌘ K", label: "命令面板" },
    { keys: "⌘ O", label: "新建对话" },
    { keys: "⌘ ⇧ P", label: "打开计划评审" },
    { keys: "⌘ ⇧ B", label: "切换侧栏" },
    { keys: "⌘ ,", label: "打开设置" },
    { keys: "Esc", label: "关闭最上层浮层" },
  ]
}

///|
pub fn media_kind_label(kind : Int) -> String {
  match kind {
    0 => "图片"
    1 => "音频"
    _ => "视频"
  }
}
