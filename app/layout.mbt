// Geometry for the workbench shell and for each window body. Both the paint
// code and the pointer hit-test read these numbers, so a control can never be
// drawn somewhere it cannot be clicked.

///|
pub const TITLEBAR_H : Double = 36.0

///|
/// Left inset of the custom titlebar that the macOS traffic lights float over
/// (`env(titlebar-area-x)` in the reference shell).
pub const TITLEBAR_LEAD : Double = 78.0

///|
pub const TABS_H : Double = 44.0

///|
pub const RAIL_W : Double = 56.0

///|
pub const SIDEBAR_W : Double = 272.0

///|
/// `SIDEBAR_LIMITS` from the reference layout module: 200..400 with 272 as the
/// initial width and the double-click restore point. The live ceiling also
/// keeps 560px for the conversation (see `sidebar_ceiling`).
pub const SIDEBAR_MIN : Double = 200.0

///|
pub const SIDEBAR_MAX : Double = 400.0

///|
/// Conversation width the sidebar may never eat into, from
/// `CONVERSATION_MIN_WIDTH` in the reference workbench layout.
pub const CONVO_MIN_W : Double = 560.0

///|
/// Project/Explorer split clamp, shared by the drag and the keyboard path.
pub const SPLIT_MIN : Double = 0.15

///|
pub const SPLIT_MAX : Double = 0.85

///|
pub const DOCK_W : Double = 40.0

///|
/// Panels on the right dock rail: 面板 / 终端 / Git / 诊断 / Agent.
pub const DOCK_PANELS : Int = 5

///|
pub const DOCK_MARGIN : Double = 12.0

///|
pub const WIN_TITLEBAR_H : Double = 34.0

///|
/// Least width the window title menu keeps for itself before the source capsule
/// gives way: enough for roughly eight CJK characters plus the chevron.
pub const WIN_TITLE_MIN_W : Double = 110.0

///|
pub const CANVAS_PAD : Double = 12.0

///|
/// Live ceiling for the sidebar: 400px, but never so wide that the
/// conversation would fall under 560. A very narrow window therefore cannot
/// widen the sidebar at all, exactly like the reference clamp.
pub fn sidebar_ceiling(w : Double) -> Double {
  let by_convo = w - CONVO_MIN_W
  let ceiling = if by_convo < SIDEBAR_MAX { by_convo } else { SIDEBAR_MAX }
  if ceiling < 0.0 {
    0.0
  } else {
    ceiling
  }
}

///|
/// Clamp a dragged width into the live range. The floor drops below 200 only
/// when the window itself cannot afford it, which is the reference behaviour
/// (`Math.max(Math.min(200, maxWidth), …)`).
pub fn clamp_sidebar(w : Double, value : Double) -> Double {
  let ceiling = sidebar_ceiling(w)
  let floor = if SIDEBAR_MIN < ceiling { SIDEBAR_MIN } else { ceiling }
  clamp_f(value, floor, ceiling)
}

///|
/// The 6px drag band on the sidebar's right edge. It straddles the border so a
/// pointer on either side of the hairline grabs it, like `.sidebar-resizer`
/// sitting at `right: -3px`.
pub fn sidebar_resizer(shell : Shell) -> RectD {
  RectD::new(x=shell.sidebar.right() - 3.0, y=shell.sidebar.y, w=6.0, h=shell.sidebar.h)
}

///|
pub(all) struct Shell {
  w : Double
  h : Double
  titlebar : RectD
  tabs : RectD
  rail : RectD
  sidebar : RectD
  canvas : RectD
  dock : RectD
  body_y : Double
}

///|
/// `sidebar_w` is the user-dragged width, so a shell built from the model and
/// the same shell rebuilt by a hit test always agree on where the sidebar ends.
pub fn shell_layout(
  w : Double,
  h : Double,
  sidebar_open : Bool,
  sidebar_w~ : Double = SIDEBAR_W,
) -> Shell {
  let body_y = TITLEBAR_H + TABS_H
  let body_h = (h - body_y).max(1.0)
  let dock_x = w - DOCK_MARGIN - DOCK_W
  let sb_w = if sidebar_open { sidebar_w } else { 0.0 }
  let canvas_x = RAIL_W + sb_w + CANVAS_PAD
  // The window tab strip sits beside the sidebar header, not above it: the
  // reference shell puts the sidebar brand row and the tabs on the same band,
  // so the rail and sidebar start right under the 36px titlebar.
  let tabs_x = RAIL_W + sb_w
  let under_titlebar = (h - TITLEBAR_H).max(1.0)
  {
    w,
    h,
    titlebar: RectD::new(x=0.0, y=0.0, w~, h=TITLEBAR_H),
    tabs: RectD::new(x=tabs_x, y=TITLEBAR_H, w=(w - tabs_x).max(1.0), h=TABS_H),
    rail: RectD::new(x=0.0, y=TITLEBAR_H, w=RAIL_W, h=under_titlebar),
    sidebar: RectD::new(x=RAIL_W, y=TITLEBAR_H, w=sb_w, h=under_titlebar),
    canvas: RectD::new(
      x=canvas_x,
      y=body_y + CANVAS_PAD,
      w=(dock_x - CANVAS_PAD - canvas_x).max(200.0),
      h=(body_h - CANVAS_PAD * 2.0).max(120.0),
    ),
    dock: RectD::new(x=dock_x, y=body_y + CANVAS_PAD, w=DOCK_W, h=(body_h - CANVAS_PAD * 2.0).max(120.0)),
    body_y,
  }
}

///|
pub fn RectD::contains(self : RectD, x : Double, y : Double) -> Bool {
  x >= self.x && x <= self.x + self.w && y >= self.y && y <= self.y + self.h
}

///|
pub fn RectD::inside(self : RectD, r : RectD) -> Bool {
  r.x >= self.x && r.y >= self.y && r.x + r.w <= self.x + self.w && r.y + r.h <= self.y + self.h
}

///|
pub fn RectD::def(self : RectD, d : Double) -> RectD {
  RectD::new(x=self.x + d, y=self.y + d, w=(self.w - d * 2.0).max(0.0), h=(self.h - d * 2.0).max(0.0))
}

///|
pub fn RectD::at(self : RectD, x : Double, y : Double) -> RectD {
  RectD::new(x=x, y=y, w=self.w, h=self.h)
}

///|
pub fn RectD::sized(self : RectD, w : Double, h : Double) -> RectD {
  RectD::new(x=self.x, y=self.y, w=w, h=h)
}

///|
pub fn clamp_f(v : Double, lo : Double, hi : Double) -> Double {
  if v < lo {
    lo
  } else if v > hi {
    hi
  } else {
    v
  }
}

///|
pub fn win_px(win : WindowRec, shell : Shell) -> RectD {
  let c = shell.canvas
  RectD::new(
    x=c.x + win.rect.x * c.w,
    y=c.y + win.rect.y * c.h,
    w=(win.rect.w * c.w).max(320.0),
    h=(win.rect.h * c.h).max(200.0),
  )
}

///|
/// Conversation window: the message column, the minimap rail and the composer
/// dock at the bottom. The deck (approval / task progress) is anchored just
/// above the composer, matching workbench.css.
pub(all) struct ConvoBox {
  frame : RectD
  body : RectD
  scroll : RectD
  doc_x : Double
  doc_w : Double
  minimap : RectD
  deck : RectD
  progress : RectD
  composer : RectD
  composer_row : RectD
  send : RectD
  approve : RectD
  approve_session : RectD
  deny : RectD
}

///|
/// The "回到最新" pill shown while a conversation is scrolled up, shared by the
/// painter and the click handler so it is clickable exactly where drawn.
pub fn convo_latest_pill(cb : ConvoBox) -> RectD {
  RectD::new(x=cb.scroll.right() - 96.0, y=cb.scroll.bottom() - 30.0, w=82.0, h=22.0)
}

///|
pub fn convo_box(frame : RectD) -> ConvoBox {
  let body = RectD::new(
    x=frame.x,
    y=frame.y + WIN_TITLEBAR_H,
    w=frame.w,
    h=(frame.h - WIN_TITLEBAR_H).max(80.0),
  )
  let pad = 12.0
  let minimap_w = 22.0
  let composer_h = 88.0
  let composer_bottom = body.y + body.h - 8.0
  let composer = RectD::new(
    x=body.x + pad,
    y=composer_bottom - composer_h,
    w=(body.w - pad * 2.0 - minimap_w - 8.0).max(120.0),
    h=composer_h,
  )
  let progress = RectD::new(x=composer.x, y=composer.y - 30.0, w=composer.w, h=24.0)
  let doc_w = composer.w.min(768.0)
  let deck_h = 150.0
  let deck = RectD::new(x=composer.x, y=progress.y - 8.0 - deck_h, w=doc_w, h=deck_h)
  let minimap = RectD::new(
    x=body.x + body.w - pad - minimap_w,
    y=body.y + 6.0,
    w=minimap_w,
    h=(progress.y - body.y - 18.0).max(40.0),
  )
  let scroll = RectD::new(
    x=body.x + pad,
    y=body.y + 4.0,
    w=(body.w - pad * 2.0 - minimap_w - 4.0).max(80.0),
    h=(deck.y - body.y - 12.0).max(40.0),
  )
  let composer_row = RectD::new(
    x=composer.x + 10.0,
    y=composer.y + 44.0,
    w=composer.w - 20.0,
    h=26.0,
  )
  let send = RectD::new(x=composer.x + composer.w - 40.0, y=composer.y + composer.h - 38.0, w=30.0, h=30.0)
  let footer_y = deck.y + deck.h - 42.0
  let approve = RectD::new(x=deck.x + deck.w - 110.0, y=footer_y, w=98.0, h=30.0)
  let approve_session = RectD::new(x=approve.x - 110.0, y=footer_y, w=102.0, h=30.0)
  let deny = RectD::new(x=approve_session.x - 62.0, y=footer_y, w=54.0, h=30.0)
  {
    frame,
    body,
    scroll,
    doc_x: scroll.x,
    doc_w: scroll.w.min(768.0),
    minimap,
    deck,
    progress,
    composer,
    composer_row,
    send,
    approve,
    approve_session,
    deny,
  }
}

///|
pub(all) struct PlanBox {
  frame : RectD
  body : RectD
  content : RectD
  chip : RectD
  approve : RectD
  keep : RectD
  compact : RectD
  refine : RectD
  dismiss : RectD
}

///|
pub fn plan_box(frame : RectD) -> PlanBox {
  let body = RectD::new(
    x=frame.x,
    y=frame.y + WIN_TITLEBAR_H,
    w=frame.w,
    h=(frame.h - WIN_TITLEBAR_H).max(60.0),
  )
  let pad = 16.0
  let gap = 8.0
  let content_w = (body.w - pad * 2.0).max(80.0)
  // The five footer actions wrap to a second row when the window is too narrow
  // to hold them side by side — the same flex-wrap the reference footer uses.
  let row_total = 110.0 + gap + 132.0 + gap + 118.0 + gap + 86.0 + gap + 78.0
  let rows = if row_total > content_w { 2 } else { 1 }
  let footer_h = 30.0 * rows.to_double() + gap * (rows - 1).to_double()
  let content = RectD::new(
    x=body.x + pad,
    y=body.y + 12.0,
    w=content_w,
    h=(body.h - 12.0 - footer_h - 26.0).max(40.0),
  )
  let bottom = body.y + body.h - 14.0 - 30.0
  let (approve, keep, compact, refine, dismiss) = if rows == 1 {
    (
      RectD::new(x=content.x, y=bottom, w=110.0, h=30.0),
      RectD::new(x=content.x + 118.0, y=bottom, w=132.0, h=30.0),
      RectD::new(x=content.x + 258.0, y=bottom, w=118.0, h=30.0),
      RectD::new(x=content.x + 384.0, y=bottom, w=86.0, h=30.0),
      RectD::new(x=content.x + 478.0, y=bottom, w=78.0, h=30.0),
    )
  } else {
    let row1 = bottom - 38.0
    (
      RectD::new(x=content.x, y=row1, w=110.0, h=30.0),
      RectD::new(x=content.x + 118.0, y=row1, w=132.0, h=30.0),
      RectD::new(x=content.x + 258.0, y=row1, w=118.0, h=30.0),
      RectD::new(x=content.x, y=bottom, w=86.0, h=30.0),
      RectD::new(x=content.x + 94.0, y=bottom, w=78.0, h=30.0),
    )
  }
  {
    frame,
    body,
    content,
    chip: RectD::new(x=content.x, y=content.y, w=64.0, h=20.0),
    approve,
    keep,
    compact,
    refine,
    dismiss,
  }
}

///|
pub(all) struct BrowserBox {
  frame : RectD
  body : RectD
  toolbar : RectD
  back : RectD
  forward : RectD
  reload : RectD
  omnibox : RectD
  seg_agent : RectD
  seg_me : RectD
  status : RectD
  page : RectD
}

///|
pub fn browser_box(frame : RectD) -> BrowserBox {
  let body = RectD::new(
    x=frame.x,
    y=frame.y + WIN_TITLEBAR_H,
    w=frame.w,
    h=(frame.h - WIN_TITLEBAR_H).max(60.0),
  )
  let toolbar = RectD::new(x=body.x, y=body.y, w=body.w, h=38.0)
  let cy = toolbar.y + (toolbar.h - 22.0) / 2.0
  let back = RectD::new(x=toolbar.x + 8.0, y=cy, w=22.0, h=22.0)
  let forward = RectD::new(x=back.x + 24.0, y=cy, w=22.0, h=22.0)
  let reload = RectD::new(x=forward.x + 24.0, y=cy, w=22.0, h=22.0)
  let seg_w = 26.0
  let seg_agent = RectD::new(x=toolbar.x + toolbar.w - 8.0 - seg_w * 2.0 - 30.0, y=cy, w=seg_w, h=22.0)
  let seg_me = RectD::new(x=seg_agent.x + seg_w, y=cy, w=seg_w, h=22.0)
  let omnibox = RectD::new(x=reload.x + 30.0, y=cy, w=(seg_agent.x - 8.0 - reload.x - 30.0).max(60.0), h=22.0)
  let status = RectD::new(x=body.x, y=body.y + body.h - 26.0, w=body.w, h=26.0)
  let page = RectD::new(
    x=body.x,
    y=toolbar.y + toolbar.h,
    w=body.w,
    h=(status.y - toolbar.y - toolbar.h).max(40.0),
  )
  { frame, body, toolbar, back, forward, reload, omnibox, seg_agent, seg_me, status, page }
}

///|
/// Window frame hit zones: `edges` bits W=1, E=2, N=4, S=8 for the 6px resize
/// band, and 1 when the point falls on the title bar.
pub fn frame_hit(frame : RectD, x : Double, y : Double) -> Int {
  let band = 6.0
  if !frame.contains(x, y) {
    return 0
  }
  let west = x <= frame.x + band
  let east = x >= frame.x + frame.w - band
  let north = y <= frame.y + band
  let south = y >= frame.y + frame.h - band
  let mut edges = 0
  if west {
    edges = edges + 1
  }
  if east {
    edges = edges + 2
  }
  if north {
    edges = edges + 4
  }
  if south {
    edges = edges + 8
  }
  if edges != 0 {
    return edges
  }
  if y <= frame.y + WIN_TITLEBAR_H {
    return 16
  }
  edges
}

///|
pub fn norm_rect(r : RectD, canvas : RectD) -> RectD {
  RectD::new(x=(r.x - canvas.x) / canvas.w, y=(r.y - canvas.y) / canvas.h, w=r.w / canvas.w, h=r.h / canvas.h)
}
