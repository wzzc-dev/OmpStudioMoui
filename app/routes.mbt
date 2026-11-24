// Routing and page chrome. The reference shell keeps one persistent rail and
// swaps the area to its right between the workbench and a secondary page; the
// page itself is a 44px head (back, fixed-width title slot, nav bubbles, theme
// toggle) over a padded scrolling body. Both the paint pass and the pointer
// hit-test read these rects, so a page control can never be drawn where it
// cannot be clicked.

///|
#derive(Eq)
pub(all) enum Route {
  Workbench
  Home
  History
  Capabilities
  ModelConfig
  Settings
  Diagnostics
  Evaluation
  Media
  Statistics
  AgentHub
}

///|
pub fn Route::label(self : Route) -> String {
  match self {
    Workbench => "工作台"
    Home => "首页"
    History => "会话历史"
    Capabilities => "能力中心"
    ModelConfig => "模型配置"
    Settings => "设置"
    Diagnostics => "诊断中心"
    Evaluation => "评测"
    Media => "媒体"
    Statistics => "统计"
    AgentHub => "Agent Hub"
  }
}

///|
pub fn Route::icon(self : Route) -> String {
  match self {
    Workbench => "app-window"
    Home => "house"
    History => "history"
    Capabilities => "package"
    ModelConfig => "server"
    Settings => "settings"
    Diagnostics => "pulse"
    Evaluation => "pulse"
    Media => "image"
    Statistics => "pulse"
    AgentHub => "bot"
  }
}

///|
/// Every route, workbench first. The ⌘K catalog lists pages from here so a new
/// route shows up in the palette the moment it is added to the enum's table.
pub fn all_routes() -> Array[Route] {
  [
    Workbench,
    Home,
    History,
    Capabilities,
    ModelConfig,
    Settings,
    Diagnostics,
    Evaluation,
    Media,
    Statistics,
    AgentHub,
  ]
}

///|
/// Rail destinations in reference order: only the six top-level ones live on
/// the collapsible rail; every page is reachable from the page-head row.
pub fn rail_routes() -> Array[Route] {
  [Workbench, Home, History, Capabilities, ModelConfig, Settings]
}

///|
pub fn rail_route_index(route : Route) -> Int {
  let items = rail_routes()
  let mut i = 0
  let mut found = -1
  for item in items {
    if item == route && found < 0 {
      found = i
    }
    i = i + 1
  }
  found
}

///|
/// Page-head navigation order (`PAGE_NAV_DEFS` in the reference). Statistics
/// and Agent Hub are opened from other pages, so they stay out of the row.
pub fn page_nav_routes() -> Array[Route] {
  [Workbench, Home, History, Capabilities, ModelConfig, Evaluation, Media, Settings, Diagnostics]
}

///|
fn route_char_count(s : String) -> Int {
  let mut n = 0
  for _c in s.iter() {
    n = n + 1
  }
  n
}

///|
/// Bubble width on the reference's `.page-nav a` box: 10px padding, a 14px
/// icon, the 6px gap and the label at 12px, then 10px padding again. CJK
/// labels are one em wide, so the label run is simply 12px per character.
pub fn nav_pill_width(route : Route) -> Double {
  40.0 + route_char_count(route.label()).to_double() * 12.0
}

///|
pub(all) struct PageShell {
  rail : RectD
  head : RectD
  body : RectD
  /// Body minus the uniform 24/32 padding, clamped to a 1080px reading column
  /// and centred, matching `.page-body` + `.page-wide`.
  content : RectD
  scroll_track : RectD
}

///|
pub fn page_shell(w : Double, h : Double) -> PageShell {
  let rail = RectD::new(x=0.0, y=TITLEBAR_H, w=RAIL_W, h=(h - TITLEBAR_H).max(1.0))
  let head = RectD::new(x=RAIL_W, y=TITLEBAR_H, w=(w - RAIL_W).max(1.0), h=44.0)
  let body = RectD::new(
    x=RAIL_W,
    y=head.bottom(),
    w=(w - RAIL_W).max(1.0),
    h=(h - head.bottom()).max(1.0),
  )
  let inner_w = (body.w - 64.0).max(120.0).min(1080.0)
  let content = RectD::new(
    x=body.x + (body.w - inner_w) / 2.0,
    y=body.y + 24.0,
    w=inner_w,
    h=body.h,
  )
  {
    rail,
    head,
    body,
    content,
    scroll_track: RectD::new(x=body.right() - 8.0, y=body.y + 6.0, w=4.0, h=(body.h - 12.0).max(1.0)),
  }
}

///|
pub fn page_back_btn(ps : PageShell) -> RectD {
  RectD::new(x=ps.head.x + 8.0, y=ps.head.y + 8.0, w=28.0, h=28.0)
}

///|
pub fn page_title_rect(ps : PageShell) -> RectD {
  RectD::new(x=ps.head.x + 46.0, y=ps.head.y, w=186.0, h=ps.head.h)
}

///|
pub fn page_nav_start(ps : PageShell) -> Double {
  page_title_rect(ps).right() + 16.0
}

///|
pub fn page_nav_slots(ps : PageShell) -> Array[RectD] {
  let out : Array[RectD] = []
  let mut x = page_nav_start(ps)
  for route in page_nav_routes() {
    let w = nav_pill_width(route)
    out.push(RectD::new(x~, y=ps.head.y + 7.0, w~, h=30.0))
    x = x + w + 5.0
  }
  out
}

///|
pub fn page_theme_btn(ps : PageShell) -> RectD {
  RectD::new(x=ps.head.right() - 40.0, y=ps.head.y + 8.0, w=28.0, h=28.0)
}

///|
/// How far the page body can scroll is a property of the page content, which
/// each painter reports once it has laid out. Stored per frame so the scroll
/// thumb and the wheel clamp agree.
pub fn page_nav_route_at(ps : PageShell, x : Double, y : Double) -> Int {
  let slots = page_nav_slots(ps)
  let mut i = 0
  while i < slots.length() {
    if slots[i].contains(x, y) && slots[i].right() <= ps.head.right() - 44.0 {
      return i
    }
    i = i + 1
  }
  -1
}

///|
/// Route by slug, for the QA harness (`OMP_ROUTE=statistics shot.sh`): the page
/// is captured straight after launch instead of by driving the rail first.
pub fn route_by_slug(slug : String) -> Route {
  match slug {
    "home" => Home
    "history" => History
    "capabilities" => Capabilities
    "model-config" => ModelConfig
    "settings" => Settings
    "diagnostics" => Diagnostics
    "evaluation" => Evaluation
    "media" => Media
    "statistics" => Statistics
    "agent-hub" => AgentHub
    _ => Workbench
  }
}

///|
/// Slug for a route: the inverse of `route_by_slug`, used for the palette ids
/// and for keying QA captures.
pub fn route_slug(route : Route) -> String {
  match route {
    Workbench => "workbench"
    Home => "home"
    History => "history"
    Capabilities => "capabilities"
    ModelConfig => "model-config"
    Settings => "settings"
    Diagnostics => "diagnostics"
    Evaluation => "evaluation"
    Media => "media"
    Statistics => "statistics"
    AgentHub => "agent-hub"
  }
}
