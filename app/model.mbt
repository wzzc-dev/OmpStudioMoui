// Core data model for the OMP Studio replica: windowed workbench records,
// session/thread data and the chat timeline that the views render.

///|
pub(all) struct RectD {
  x : Double
  y : Double
  w : Double
  h : Double
}

///|
pub fn RectD::new(
  x~ : Double,
  y~ : Double,
  w~ : Double,
  h~ : Double,
) -> RectD {
  { x, y, w, h }
}

///|
pub fn RectD::right(self : RectD) -> Double {
  self.x + self.w
}

///|
pub fn RectD::bottom(self : RectD) -> Double {
  self.y + self.h
}

///|
pub fn RectD::area(self : RectD) -> Double {
  self.w * self.h
}

///|
#derive(Eq)
pub(all) enum WindowKind {
  Conversation
  PlanReview
  Browser
  Terminal
}

///|
pub fn WindowKind::label(self : WindowKind) -> String {
  match self {
    Conversation => "对话"
    PlanReview => "Plan Review"
    Browser => "托管浏览器"
    Terminal => "终端"
  }
}

///|
pub(all) struct WindowRec {
  id : Int
  kind : WindowKind
  title : String
  badge : String
  thread : Int
  rect : RectD
  pre_rect : RectD
  maximized : Bool
  minimized : Bool
}

///|
#derive(Eq)
pub(all) enum SnapZone {
  NoZone
  LeftHalf
  RightHalf
  FullTop
  TopLeft
  TopRight
  BottomLeft
  BottomRight
}

///|
pub fn SnapZone::rect(self : SnapZone) -> RectD {
  match self {
    NoZone => RectD::new(x=0.0, y=0.0, w=1.0, h=1.0)
    LeftHalf => RectD::new(x=0.0, y=0.0, w=0.5, h=1.0)
    RightHalf => RectD::new(x=0.5, y=0.0, w=0.5, h=1.0)
    FullTop => RectD::new(x=0.0, y=0.0, w=1.0, h=1.0)
    TopLeft => RectD::new(x=0.0, y=0.0, w=0.5, h=0.5)
    TopRight => RectD::new(x=0.5, y=0.0, w=0.5, h=0.5)
    BottomLeft => RectD::new(x=0.0, y=0.5, w=0.5, h=0.5)
    BottomRight => RectD::new(x=0.5, y=0.5, w=0.5, h=0.5)
  }
}

///|
/// The six split presets exposed by the maximize-button snap picker.
#derive(Eq)
pub(all) enum LayoutPreset {
  SplitEven
  SplitTwoOne
  ThreeColumns
  LeftStacked
  RightStacked
  Quadrants
}

///|
pub fn LayoutPreset::slots(self : LayoutPreset) -> Array[RectD] {
  match self {
    SplitEven => [
      RectD::new(x=0.0, y=0.0, w=0.5, h=1.0),
      RectD::new(x=0.5, y=0.0, w=0.5, h=1.0),
    ]
    SplitTwoOne => [
      RectD::new(x=0.0, y=0.0, w=0.666667, h=1.0),
      RectD::new(x=0.666667, y=0.0, w=0.333333, h=1.0),
    ]
    ThreeColumns => [
      RectD::new(x=0.0, y=0.0, w=0.333333, h=1.0),
      RectD::new(x=0.333333, y=0.0, w=0.333333, h=1.0),
      RectD::new(x=0.666667, y=0.0, w=0.333333, h=1.0),
    ]
    LeftStacked => [
      RectD::new(x=0.0, y=0.0, w=0.5, h=0.5),
      RectD::new(x=0.0, y=0.5, w=0.5, h=0.5),
      RectD::new(x=0.5, y=0.0, w=0.5, h=1.0),
    ]
    RightStacked => [
      RectD::new(x=0.0, y=0.0, w=0.5, h=1.0),
      RectD::new(x=0.5, y=0.0, w=0.5, h=0.5),
      RectD::new(x=0.5, y=0.5, w=0.5, h=0.5),
    ]
    Quadrants => [
      RectD::new(x=0.0, y=0.0, w=0.5, h=0.5),
      RectD::new(x=0.5, y=0.0, w=0.5, h=0.5),
      RectD::new(x=0.0, y=0.5, w=0.5, h=0.5),
      RectD::new(x=0.5, y=0.5, w=0.5, h=0.5),
    ]
  }
}

///|
/// Live drag bookkeeping. Rects are stored normalised to the workbench canvas so
/// the update stays independent of the viewport it happens to be rendered at.
pub struct DragInfo {
  active : Bool
  id : Int
  mode : Int
  edges : Int
  origin : RectD
  sx : Double
  sy : Double
  snap : SnapZone
}

///|
pub fn DragInfo::idle() -> DragInfo {
  {
    active: false,
    id: -1,
    mode: 0,
    edges: 0,
    origin: RectD::new(x=0.0, y=0.0, w=0.0, h=0.0),
    sx: 0.0,
    sy: 0.0,
    snap: NoZone,
  }
}

///|
#derive(Eq)
pub(all) enum ThreadStatus {
  Running
  /// Settled thread with nothing pending and no active run: the row shows a
  /// timestamp and no spinner, which is what the reference calls "idle".
  Idle
  AwaitingReview
  AwaitingAnswer
  AwaitingConfirm
}

///|
pub fn ThreadStatus::label(self : ThreadStatus) -> String {
  match self {
    Running => "运行中"
    Idle => ""
    AwaitingReview => "待审核"
    AwaitingAnswer => "待回答"
    AwaitingConfirm => "待确认"
  }
}

///|
pub fn ThreadStatus::color(self : ThreadStatus, p : Palette) -> @graphics.Color {
  match self {
    Running => p.green
    Idle => p.text_3
    AwaitingReview => p.accent
    AwaitingAnswer => p.blue
    AwaitingConfirm => p.amber
  }
}

///|
pub(all) struct Thread {
  id : Int
  title : String
  status : ThreadStatus
  pinned : Bool
  project : String
  path : String
  when : String
  unread : Int
  sub : Int
}

///|
pub(all) struct Project {
  id : Int
  name : String
  branch : String
  count : Int
  expanded : Bool
  dirty : Int
  adds : Int
  dels : Int
  running : Bool
  current : Bool
}

///|
pub(all) struct FileRow {
  depth : Int
  name : String
  folder : Bool
  added : Bool
  modified : Bool
  expanded : Bool
}

///|
pub(all) enum ChatItem {
  Checklist(Array[String])
  Diff(String, Int, Array[String])
  UserSay(String, String, String)
  AssistantSay(String, String, String)
  Tool(ToolCard)
  Commit(Bool, String, String, String)
  Approval(ApprovalBody)
}

///|
/// One task progress record, shown by the floating strip above the composer.
/// Keeping it on the model instead of in the transcript is what stops the
/// same summary from being painted twice.
pub(all) struct TaskProgress {
  done : Int
  total : Int
  files : Int
  adds : Int
  dels : Int
}

///|
pub(all) struct ToolCard {
  title : String
  cwd : String
  lines : Array[String]
  error : String
  status : String
}

///|
pub(all) struct ApprovalBody {
  title : String
  goal : String
  steps : Array[String]
  actions : Array[String]
}

///|
pub(all) struct PointerMsg {
  phase : Int
  x : Double
  y : Double
  w : Double
  h : Double
  wheel : Double
}

///|
/// One reachable control of the workbench shell. A canvas has no DOM, so this
/// id is the single handle that the press state, the keyboard focus ring, the
/// tooltip anchor and the activation path all share: `controls()` builds the
/// list once per frame, the painter draws from it and the hit test resolves
/// against it, so nothing can be focusable somewhere it is not drawn.
#derive(Eq)
pub(all) enum Ctl {
  CNone
  CNav(Int)
  /// The context cluster on the tab strip: panel toggle, theme, density, home
  /// and the Compact pill. They are separate ids so each one can carry its own
  /// tip and focus ring.
  CClusterPanel
  CClusterMoon
  CClusterSliders
  CClusterHome
  CClusterCompact
  CPlusTab
  CTab(Int)
  CTabClose(Int)
  CRail(Int)
  CRailHandle
  CSb(Int)
  CSbWidth
  CSbSplit
  CDock(Int)
  CWinMin(Int)
  CWinMax(Int)
  CWinClose(Int)
  CPageBack
  CPageTheme
  CPageNav(Int)
}

///|
/// Dialog currently owning the app. `MConfirm` is the reset-layout
/// confirmation, `MRename` the thread rename field and `MShortcuts` the
/// read-only shortcut table; all three share the reference `.modal` shell.
#derive(Eq)
pub(all) enum ModalKind {
  MNone
  MConfirm
  MRename
  MShortcuts
}

///|
pub struct Model {
  dark : Bool
  windows : Array[WindowRec]
  active : Int
  next_id : Int
  drag : DragInfo
  snap_preview : SnapZone
  picker : Int
  layout : LayoutPreset
  sidebar_open : Bool
  explorer_open : Bool
  composer : String
  threads : Array[Thread]
  projects : Array[Project]
  files : Array[FileRow]
  current_thread : Int
  chat : Array[ChatItem]
  task : TaskProgress
  plan : ApprovalBody
  browser_tab : Int
  browser_nav : Int
  browser_query : String
  approval : Int
  plan_approved : Bool
  composer_focus : Bool
  browser_control : Int
  dock_tab : Int
  density : Int
  // Shell routing and secondary pages. The rail swaps the region right of it
  // between the workbench and a page; `back_route` is where the page-head back
  // button goes (statistics returns to home, the rest to the workbench).
  route : Route
  back_route : Route
  page_scroll : Double
  /// Last frame size seen by the pointer path. Page scroll clamping needs the
  /// shell it will be drawn in, and keyboard scrolling has no pointer event of
  /// its own to ask.
  frame_w : Double
  frame_h : Double
  language_zh : Bool
  motion : Int
  light : Int
  doc_width : Int
  settings_tab : Int
  caps_tab : Int
  model_tab : Int
  /// Background scope on the settings page: 0 = workbench only, 1 = whole app.
  bg_scope : Int
  /// Backing store for the settings switches: four per tab, tab-major.
  toggles : Array[Bool]
  /// A short status line under a page intro, used as the local action echo.
  page_note : String
  history_query : String
  history_filter : Int
  history_focus : Bool
  providers : Array[ProviderRow]
  active_provider : Int
  active_model : Int
  skills : Array[SkillRow]
  usage_days : Array[UsageDay]
  eval_runs : Array[EvalRun]
  usage_models : Array[UsageModelRow]
  media_items : Array[MediaItem]
  agents : Array[AgentRow]
  checks : Array[CheckRow]
  project_cards : Array[ProjectCard]
  history_rows : Array[HistoryRow]
  eval_filter : Int
  media_filter : Int
  role_routes : Array[RoleRoute]
  // Page-local selections that survive a route change, so reopening 统计 or 媒体
  // lands on the same range or item instead of resetting. stats_range 0..2 is
  // the 7/14/30 day window; -1 means nothing selected yet.
  stats_range : Int
  media_sel : Int
  hub_sel : Int
  diag_note : String
  update_note : String
  /// Pointer position for hover painting. `hover_on` is false until the pointer
  /// enters the window; a canvas has no per-control hover callback, so every
  /// painter asks whether its own rect contains this point.
  hover_x : Double
  hover_y : Double
  hover_on : Bool
  /// Workbench scroll offsets. `convo_scroll` counts pixels scrolled up from
  /// the bottom-anchored latest turn; `sidebar_scroll` slides the project and
  /// thread list. Both clamp against their measured content.
  convo_scroll : Double
  sidebar_scroll : Double
  /// ⌘K command palette: open flag, filter query, the highlighted row and the
  /// list's pixel offset (its group captions make rows a variable height, so
  /// the viewport moves by pixels rather than by row count).
  palette_open : Bool
  palette_query : String
  palette_index : Int
  palette_scroll : Double
  /// Sidebar width in pixels, dragged by its 6px resizer. Reference limits are
  /// 200..400 with 272 as the restore point (`SIDEBAR_LIMITS`).
  sidebar_w : Double
  /// Project/Explorer split measured from the end of the action rows to the
  /// footer, dragged by the hairline divider. 0.46 is the reference default;
  /// 0.15..0.85 is its clamp.
  sidebar_split : Double
  /// Active width drag: 0 none, 1 sidebar width, 2 sidebar split. `resize_base`
  /// is the value at pointer-down and `resize_anchor` the pointer coordinate
  /// the drag started from, so a drag is relative and never jumps.
  resize_mode : Int
  resize_base : Double
  resize_anchor : Double
  /// Pressed control: which one, its rect for painting, and the two paint-clock
  /// stamps that drive the tactile feedback (down, up). The 1px push is held
  /// while the pointer is down and decays over 80ms after release
  /// (`--dur-tactile`), so a click still reads on the frame that follows it.
  press_ctl : Ctl
  press_rect : RectD
  press_down : Bool
  press_at : Double
  press_up : Double
  /// Keyboard focus ring: the control, its rect, and `focus_kb` which keeps it
  /// keyboard-only like `:focus-visible` — a pointer press never leaves a ring.
  focus_ctl : Ctl
  focus_rect : RectD
  focus_kb : Bool
  /// Tooltip dwell: the hover target and when it became the target. The bubble
  /// paints once 500ms (`--tip-delay`) pass on the same control.
  tip_ctl : Ctl
  tip_rect : RectD
  tip_start : Double
  /// The text the tip shows, latched when the pointer settled on the control so
  /// the bubble still reads while the control is repainted without its label.
  tip_text : String
  /// Toast: text, and the paint-clock window it lives in. `toast_end` is when
  /// the leave animation starts; the host paints nothing once it is over.
  toast_text : String
  toast_start : Double
  toast_end : Double
  /// Modal dialog: which one owns the app, the same kind kept while it leaves
  /// (the leave animation needs the shell and it is no longer the owner), the
  /// two stamps, the rename buffer and which footer button the keyboard holds.
  modal : ModalKind
  modal_leaving : ModalKind
  modal_open : Double
  modal_close : Double
  modal_input : String
  modal_focus : Int
}

///|
/// Toast lifetime, from `ToastHost` in the reference: arrive on `--dur-slower`
/// (320ms), hold `SHOW_MS` (2800ms), then leave on `--dur-slow` (250ms). The
/// hold is a reading window rather than a layout constant, so it is one value
/// shared by the timer and the painter.
pub const TOAST_IN_MS : Double = 320.0

///|
pub const TOAST_HOLD_MS : Double = 2800.0

///|
pub const TOAST_OUT_MS : Double = 250.0

///|
/// `--tip-delay` from the reference tokens: how long the pointer rests on a
/// control before its tip shows.
pub const TIP_DELAY_MS : Double = 500.0

///|
/// `--motion-fade` (`--dur-fast`): the tip bubble fades in once its dwell is up.
pub const TIP_FADE_MS : Double = 120.0

///|
/// `--dur-tactile`: a press being acknowledged, and how long the push decays
/// after the pointer comes up.
pub const TACTILE_MS : Double = 80.0

///|
/// `--dur` and `--dur-fast` for the sheet: the dialog arrives over 180ms and
/// leaves over 120ms, the backdrop fades on the fast step.
pub const SHEET_IN_MS : Double = 180.0

///|
pub const SHEET_OUT_MS : Double = 120.0


///|
pub(all) enum Msg {
  ToggleTheme
  ToggleSidebar
  ToggleExplorer
  NewThread
  SelectThread(Int)
  ComposerInput(String)
  ComposerSend
  FocusWindow(Int)
  CloseWindow(Int)
  MinimizeWindow(Int)
  ToggleMaximize(Int)
  OpenPicker(Int)
  ClosePicker
  ApplyPreset(LayoutPreset)
  ApprovePlan
  RefinePlan
  SelectBrowserTab(Int)
  SelectBrowserNav(Int)
  SelectBrowserQuery(Int)
  Pointer(PointerMsg)
  KeyTyped(String)
  KeyDown(String, Int)
  CapsuleClick(Int)
  DockSelect(Int)
  AllowOnce
  AllowSession
  DenyApproval
  DenyPlan
  BrowserControl(Int)
  NewWindow
  ToggleDensity
  GoRoute(Route)
  GoBack
  PageScroll(Double)
  CapsTab(Int)
  ToggleSkill(Int)
  HistoryFilter(Int)
  HistoryRow(Int)
  SelectProvider(Int)
  SelectModel(Int)
  SettingsTab(Int)
  SetLanguage(Bool)
  CycleMotion
  CycleLight
  CycleDocWidth
  ToggleAgent(Int)
  EvalFilter(Int)
  MediaFilter(Int)
  ToggleProvider(Int)
  StatsRange(Int)
  MediaSelect(Int)
  HubSelect(Int)
  DiagAction(Int)
  CheckUpdate
  ModelTab(Int)
  ToggleSwitch(Int)
  BgScope(Int)
  CapsRun(Int)
  TestProvider(Int)
  RefreshModels(Int)
  CycleRoleModel(Int)
  HistoryFocus
  TogglePalette
  ClosePalette
  PaletteType(String)
  PaletteMove(Int)
  PaletteRun(Int)
  /// Tab / Shift-Tab: +1 walks forward, -1 back.
  FocusStep(Int)
  /// Arrow keys move the ring along the same list, ±1.
  FocusArrow(Int)
  FocusActivate
  FocusClear
  ModalOpen(ModalKind)
  ModalClose
  ModalType(String)
  ModalBackspace
  ModalConfirm
  Toast(String)
}

///|
fn demo_windows() -> Array[WindowRec] {
  [
    {
      id: 0,
      kind: Conversation,
      title: "SYNC · 跟踪上游 pi-web 更新到 omp-web",
      badge: "3",
      thread: 0,
      rect: RectD::new(x=0.004, y=0.006, w=0.556, h=0.988),
      pre_rect: RectD::new(x=0.004, y=0.006, w=0.556, h=0.988),
      maximized: false,
      minimized: false,
    },
    {
      id: 1,
      kind: PlanReview,
      title: "Plan Review",
      badge: "",
      thread: 0,
      rect: RectD::new(x=0.566, y=0.006, w=0.43, h=0.6),
      pre_rect: RectD::new(x=0.566, y=0.006, w=0.43, h=0.6),
      maximized: false,
      minimized: false,
    },
    {
      id: 2,
      kind: Browser,
      title: "Studio 组件预览 · localhost:5173",
      badge: "",
      thread: 0,
      rect: RectD::new(x=0.566, y=0.61, w=0.43, h=0.384),
      pre_rect: RectD::new(x=0.566, y=0.61, w=0.43, h=0.384),
      maximized: false,
      minimized: false,
    },
    {
      id: 3,
      kind: Conversation,
      title: "Mermaid 全屏缩放计划与交互评审",
      badge: "1",
      thread: 3,
      rect: RectD::new(x=0.06, y=0.1, w=0.5, h=0.7),
      pre_rect: RectD::new(x=0.06, y=0.1, w=0.5, h=0.7),
      maximized: false,
      minimized: true,
    },
  ]
}

///|
fn demo_threads() -> Array[Thread] {
  [
    {
      id: 0,
      title: "跟踪上游 pi-web 更新到 omp-web",
      status: Running,
      pinned: true,
      project: "omp-web",
      path: "D:/Project/omp-web",
      when: "32m",
      unread: 3,
      sub: 3,
    },
    {
      id: 1,
      title: "内容图鉴：全部工具卡与正文格式",
      status: Idle,
      pinned: true,
      project: "omp-web",
      path: "D:/Project/omp-web",
      when: "now",
      unread: 0,
      sub: 0,
    },
    {
      id: 2,
      title: "Audit and fix OSS repository issues",
      status: AwaitingAnswer,
      pinned: false,
      project: "omp-web",
      path: "D:/Project/omp-web",
      when: "2h",
      unread: 0,
      sub: 0,
    },
    {
      id: 3,
      title: "Mermaid 全屏缩放计划与交互确认",
      status: AwaitingReview,
      pinned: false,
      project: "omp-web",
      path: "D:/Project/omp-web",
      when: "4d",
      unread: 0,
      sub: 0,
    },
    {
      id: 4,
      title: "修复 Git Bash 路径未找到问题",
      status: AwaitingConfirm,
      pinned: false,
      project: "omp-web",
      path: "D:/Project/omp-web",
      when: "4d",
      unread: 0,
      sub: 0,
    },
    {
      id: 5,
      title: "重构 session 存储层 (session)",
      status: Running,
      pinned: false,
      project: "omp-web",
      path: "D:/Project/omp-web",
      when: "6d",
      unread: 0,
      sub: 0,
    },
  ]
}

///|
///|
fn demo_projects() -> Array[Project] {
  [
    {
      id: 0,
      name: "omp-web",
      branch: "main",
      count: 3,
      expanded: true,
      dirty: 3,
      adds: 214,
      dels: 58,
      running: true,
      current: true,
    },
    {
      id: 1,
      name: "pi-web",
      branch: "upstream",
      count: 0,
      expanded: false,
      dirty: 0,
      adds: 0,
      dels: 0,
      running: false,
      current: false,
    },
    {
      id: 2,
      name: "omp-web",
      branch: "feat/mermaid",
      count: 7,
      expanded: false,
      dirty: 7,
      adds: 1263,
      dels: 341,
      running: false,
      current: false,
    },
  ]
}

///|
///|
fn demo_files() -> Array[FileRow] {
  [
    { depth: 0, name: ".claude", folder: true, added: false, modified: false, expanded: false },
    { depth: 0, name: ".code-review-graph", folder: true, added: false, modified: false, expanded: false },
    { depth: 0, name: ".github", folder: true, added: false, modified: false, expanded: false },
    { depth: 0, name: "app", folder: true, added: false, modified: false, expanded: true },
    { depth: 1, name: "App.tsx", folder: false, added: false, modified: true, expanded: false },
    { depth: 1, name: "main.tsx", folder: false, added: false, modified: false, expanded: false },
    { depth: 1, name: "routes", folder: true, added: false, modified: false, expanded: false },
    { depth: 0, name: "bin", folder: true, added: false, modified: false, expanded: false },
    { depth: 0, name: "components", folder: true, added: false, modified: false, expanded: true },
    { depth: 1, name: "DirectoryPicker.tsx", folder: false, added: false, modified: false, expanded: false },
    { depth: 1, name: "MermaidBlock.tsx", folder: false, added: true, modified: false, expanded: false },
    { depth: 1, name: "ChatTimeline.tsx", folder: false, added: false, modified: false, expanded: false },
    { depth: 1, name: "CodeBlock.tsx", folder: false, added: false, modified: true, expanded: false },
    { depth: 1, name: "TelemetryBar.tsx", folder: false, added: false, modified: false, expanded: false },
    { depth: 0, name: "docs", folder: true, added: false, modified: false, expanded: false },
    { depth: 0, name: "hooks", folder: true, added: false, modified: false, expanded: false },
    { depth: 0, name: "lib", folder: true, added: false, modified: false, expanded: false },
    { depth: 0, name: "tests", folder: true, added: false, modified: false, expanded: false },
  ]
}

///|
fn demo_chat() -> Array[ChatItem] {
  [
    Checklist(["核对本地路径", "复查类型错误", "确认缩放交互"]),
    Diff("2 个文件已更改", 87, ["审核", "标注"]),
    UserSay("S", "你 · 06:02", "文档写完了。再跑一遍 typecheck，输出盯着，TS2322 一并修掉。"),
    Tool({
      title: "Bash · npm run typecheck",
      cwd: "D:/Project/omp-web",
      lines: [
        "$ npm run typecheck",
        "> tsc --noEmit",
        "src/index.ts(12,5): error TS2322: Type 'string' is not assignable to type 'number'.",
      ],
      error: "1 error",
      status: "运行中",
    }),
    Commit(true, "已提交 4", "由 Runtime 排队和执行", "完成依赖 bump、类型修复与三处布局收尾，按顺序并入主线。"),
    Commit(false, "本地草稿 2", "本轮结束后自动按序提交", "对比完 v0.8.1 的变更后，把 package.json 里 pi-web 的依赖版本同步 bump 到 0.8.1，再跑一遍 npm run check。"),
  ]
}

///|
fn demo_plan() -> ApprovalBody {
  {
    title: "冻结 Preview 缩放协议",
    goal: "冻结 Preview 缩放协议，补上拖拽惯性开关，再用类型检查确认 Mermaid 全屏路径。",
    steps: [
      "核对现有 Preview 面板的 pan / zoom 事件，列出惯性开关要接的状态。",
      "默认关闭惯性；打开后松手继续滑行，用 velocity * 0.92 衰减。",
      "重新跑一遍 typecheck，确认没有新增错误。",
    ],
    actions: [
      "Approve and execute",
      "Approve and keep context",
      "Approve and compact context",
      "Refine plan",
    ],
  }
}

///|
pub fn Model::new() -> Model {
  {
    dark: true,
    windows: demo_windows(),
    active: 0,
    next_id: 4,
    drag: DragInfo::idle(),
    snap_preview: NoZone,
    picker: -1,
    layout: LeftStacked,
    sidebar_open: true,
    explorer_open: true,
    composer: "",
    threads: demo_threads(),
    projects: demo_projects(),
    files: demo_files(),
    current_thread: 0,
    chat: demo_chat(),
    task: { done: 5, total: 7, files: 3, adds: 223, dels: 4 },
    plan: demo_plan(),
    browser_tab: 1,
    browser_nav: 1,
    browser_query: "",
    approval: 0,
    plan_approved: false,
    composer_focus: false,
    browser_control: 0,
    dock_tab: 2,
    density: 0,
    route: Workbench,
    back_route: Workbench,
    page_scroll: 0.0,
    frame_w: 1440.0,
    frame_h: 900.0,
    language_zh: true,
    motion: 0,
    light: 2,
    doc_width: 1,
    settings_tab: 0,
    caps_tab: 0,
    model_tab: 0,
    bg_scope: 0,
    toggles: [true, true, true, false, false, false, true, false, true, true, false, true, true, false, true, false, true, true, false, false, true, false, true, false, true, true, true, false, false, true, false, false],
    page_note: "",
    history_query: "",
    history_filter: 0,
    history_focus: false,
    providers: demo_providers(),
    active_provider: 0,
    active_model: 0,
    skills: demo_skills(),
    usage_days: demo_usage_days(),
    eval_runs: demo_eval_runs(),
    usage_models: demo_usage_models(),
    media_items: demo_media(),
    agents: demo_agents(),
    checks: demo_checks(),
    project_cards: demo_project_cards(),
    history_rows: demo_history_rows(),
    eval_filter: 0,
    media_filter: 0,
    role_routes: demo_role_routes(),
    stats_range: 1,
    media_sel: 0,
    hub_sel: 0,
    diag_note: "",
    update_note: "",
    hover_x: 0.0,
    hover_y: 0.0,
    hover_on: false,
    convo_scroll: 0.0,
    sidebar_scroll: 0.0,
    palette_open: false,
    palette_query: "",
    palette_index: 0,
    palette_scroll: 0.0,
    sidebar_w: 272.0,
    sidebar_split: 0.46,
    resize_mode: 0,
    resize_base: 0.0,
    resize_anchor: 0.0,
    press_ctl: CNone,
    press_rect: RectD::new(x=0.0, y=0.0, w=0.0, h=0.0),
    press_down: false,
    press_at: 0.0,
    press_up: 0.0,
    focus_ctl: CNone,
    focus_rect: RectD::new(x=0.0, y=0.0, w=0.0, h=0.0),
    focus_kb: false,
    tip_ctl: CNone,
    tip_rect: RectD::new(x=0.0, y=0.0, w=0.0, h=0.0),
    tip_start: 0.0,
    tip_text: "",
    toast_text: "",
    toast_start: 0.0,
    toast_end: 0.0,
    modal: MNone,
    modal_leaving: MNone,
    modal_open: 0.0,
    modal_close: 0.0,
    modal_input: "",
    modal_focus: 0,
  }
}

///|
pub fn visible_windows(model : Model) -> Array[WindowRec] {
  let out : Array[WindowRec] = []
  for window in model.windows {
    if !window.minimized {
      out.push(window)
    }
  }
  out
}

///|
pub fn window_by_id(model : Model, id : Int) -> WindowRec? {
  let mut found : WindowRec? = None
  for window in model.windows {
    if window.id == id {
      found = Some(window)
    }
  }
  found
}
