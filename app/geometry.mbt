// Shared hit/geometry for the custom chrome. Every rect the paint code draws is
// produced here, so the pointer handler and the renderer can never disagree.

///|
pub struct WinChrome {
  bar : RectD
  icon : RectD
  title : RectD
  source : RectD
  status_dot : RectD
  tt : RectD
  dock : RectD
  more : RectD
  min : RectD
  max : RectD
  close : RectD
}

///|
/// `source_w` is the width the source capsule wants, measured from its text by
/// the paint code (content width, capped at 180 like the reference). The left
/// group is laid out menu → capsule → status dot; the menu absorbs the slack
/// and is the only part that ellipsizes, while the capsule and then the dot are
/// dropped whole as the window narrows. The reference hides the capsule at a
/// coarse ≤620px breakpoint; here it goes exactly when keeping it would squeeze
/// the title past `WIN_TITLE_MIN_W`, so a wide window keeps it and a narrow one
/// never crops the title in its favour. The pointer path leaves `source_w` at the
/// default 0.0: no clickable control depends on it, so its hit rects stay right.
pub fn win_chrome(frame : RectD, source_w? : Double = 0.0) -> WinChrome {
  let bar = RectD::new(x=frame.x, y=frame.y, w=frame.w, h=WIN_TITLEBAR_H)
  let btn_y = bar.y + 4.0
  let bw = 26.0
  // `.cw-window-actions-slot` keeps a 3px rhythm inside the actions cluster
  // (the bar itself keeps 2px between the title slot and that cluster).
  let gap = 3.0
  let close = RectD::new(x=bar.x + bar.w - 5.0 - bw, y=btn_y, w=bw, h=bw)
  let max = RectD::new(x=close.x - (bw + gap), y=btn_y, w=bw, h=bw)
  let min = RectD::new(x=max.x - (bw + gap), y=btn_y, w=bw, h=bw)
  let more = RectD::new(x=min.x - (bw + gap), y=btn_y, w=bw, h=bw)
  let dock = RectD::new(x=more.x - (bw + gap), y=btn_y, w=bw, h=bw)
  let tt = RectD::new(x=(dock.x - 3.0 - 66.0).max(bar.x + 88.0), y=bar.y + 5.0, w=66.0, h=24.0)
  let icon = RectD::new(x=bar.x + 10.0, y=bar.y + 7.0, w=20.0, h=20.0)
  let left_limit = (tt.x - 8.0).max(bar.x + 60.0)
  // Left group: title menu → source capsule → status dot. The menu takes what
  // is left after the other two, so the trio stays packed against the Time
  // Travel pill instead of leaving a hole in the middle of the bar.
  let title_x = icon.x + icon.w + 6.0
  let available = (left_limit - title_x).max(0.0)
  let want_source = source_w.min(180.0)
  let mut cap = 0.0
  let mut dot_w = 0.0
  // `WIN_TITLE_MIN_W` keeps the menu readable (about eight CJK characters plus
  // the chevron). A capsule that would squeeze the title below it is dropped
  // instead of cropping the very thing the bar is for; the dot goes last.
  let needs_cap = 6.0 + want_source + 6.0 + 16.0 + WIN_TITLE_MIN_W
  if want_source >= 24.0 && needs_cap <= available {
    cap = want_source
    dot_w = 16.0
  } else if 6.0 + 16.0 + WIN_TITLE_MIN_W <= available {
    dot_w = 16.0
  }
  let tail = (if cap > 0.0 { cap + 6.0 } else { 0.0 }) + (if dot_w > 0.0 { dot_w + 6.0 } else { 0.0 })
  let title = RectD::new(x=title_x, y=bar.y + 4.0, w=(available - tail).max(60.0), h=26.0)
  let source = RectD::new(
    x=title.right() + (if cap > 0.0 { 6.0 } else { 0.0 }),
    y=bar.y + 8.0,
    w=cap,
    h=18.0,
  )
  let status_dot = if dot_w > 0.0 {
    RectD::new(x=source.right() + 6.0, y=bar.y + 9.0, w=dot_w, h=16.0)
  } else {
    RectD::new(x=0.0, y=0.0, w=0.0, h=0.0)
  }
  { bar, icon, title, source, status_dot, tt, dock, more, min, max, close }
}

///|
pub struct TabSlot {
  id : Int
  rect : RectD
  active : Bool
}

///|
/// The close affordance of an active tab, shared by the painter and the click
/// handler so the circle the pointer lights is exactly the circle that closes
/// the window.
pub fn tab_close_rect(slot : TabSlot) -> RectD {
  let tr = slot.rect
  RectD::new(x=tr.right() - 28.0, y=tr.y + 6.0, w=20.0, h=20.0)
}

///|
/// The context cluster on the right of the tab strip: width of the full set
/// (quick actions, token meters, cache meter, Compact pill, layout and theme
/// toggles) measured off the reference at 1600 CSS px, plus the gap the strip
/// keeps before it. Everything here is right-anchored, so the cluster keeps its
/// internal rhythm at any window width and only drops items as it narrows.
pub const TAB_CLUSTER_W : Double = 640.0

///|
pub const TAB_CLUSTER_GAP : Double = 8.0

///|
pub const TAB_BADGE_RESERVE : Double = 68.0

///|
/// Three densities for the cluster, chosen from the room the strip has:
/// 2 keeps everything, 1 drops the three quick-action buttons, 0 keeps only the
/// layout and theme toggles, and -1 (a very narrow window) keeps none. The tab
/// geometry reserves exactly the room the painted cluster needs, so tabs can
/// never run underneath it.
pub fn tab_cluster_tier(shell : Shell) -> Int {
  let strip = shell.w - shell.tabs.x
  if strip >= TAB_CLUSTER_W + 604.0 + TAB_CLUSTER_GAP {
    2
  } else if strip >= 1024.0 {
    1
  } else if strip >= 700.0 {
    0
  } else {
    -1
  }
}

///|
pub fn tab_cluster_reserve(shell : Shell) -> Double {
  match tab_cluster_tier(shell) {
    2 => TAB_CLUSTER_W + TAB_CLUSTER_GAP
    1 => 508.0
    0 => 148.0
    _ => 0.0
  }
}

///|
fn empty_rect() -> RectD {
  RectD::new(x=0.0, y=0.0, w=0.0, h=0.0)
}

///|
pub struct TabCluster {
  tier : Int
  robot : RectD
  clock : RectD
  pencil : RectD
  tok_up : RectD
  tok_down : RectD
  cache_num : RectD
  cache_word : RectD
  ring : RectD
  pct : RectD
  compact : RectD
  sliders : RectD
  panel : RectD
  moon : RectD
  home : RectD
  div_a : RectD
  div_b : RectD
  div_c : RectD
}

///|
/// Every rect the cluster paints, right-anchored to the strip's right edge.
/// The offsets come from the reference CSS: `.topbar` keeps 12px to the right
/// edge, every `.icon-btn` is a 26px square on the `.tb-right` 4px rhythm, and
/// `.tb-compact` is a 24px-tall pill with 10px side padding. Hidden items are
/// zero-sized rects, which paint as nothing and cannot be clicked.
pub fn tab_cluster(shell : Shell) -> TabCluster {
  let tier = tab_cluster_tier(shell)
  let right = shell.w - 12.0
  let cy = shell.tabs.y + shell.tabs.h / 2.0
  let btn = fn(c : Double) -> RectD {
    RectD::new(x=right - c - 26.0, y=cy - 13.0, w=26.0, h=26.0)
  }
  let keep_actions = tier >= 2
  let keep_meters = tier >= 1
  let keep_toggles = tier >= 0
  let zero = empty_rect()
  {
    tier,
    robot: if keep_actions { btn(566.0) } else { zero },
    clock: if keep_actions { btn(530.0) } else { zero },
    pencil: if keep_actions { btn(491.0) } else { zero },
    tok_up: if keep_meters { RectD::new(x=right - 470.0, y=cy - 9.0, w=40.0, h=18.0) } else { zero },
    tok_down: if keep_meters { RectD::new(x=right - 420.0, y=cy - 9.0, w=34.0, h=18.0) } else { zero },
    cache_num: if keep_meters { RectD::new(x=right - 364.0, y=cy - 9.0, w=32.0, h=18.0) } else { zero },
    cache_word: if keep_meters { RectD::new(x=right - 330.0, y=cy - 9.0, w=34.0, h=18.0) } else { zero },
    ring: if keep_meters { RectD::new(x=right - 275.0, y=cy - 8.0, w=16.0, h=16.0) } else { zero },
    pct: if keep_meters { RectD::new(x=right - 254.0, y=cy - 9.0, w=24.0, h=18.0) } else { zero },
    compact: if keep_meters { RectD::new(x=right - 207.0, y=cy - 12.0, w=83.0, h=24.0) } else { zero },
    // The dock-rail toggle is the same 26px square as the panel / theme / home
    // buttons, one 4px rhythm apart: two separate squares, never one merged
    // pill and never overlapping the Compact pill to its left.
    sliders: if keep_toggles { btn(90.0) } else { zero },
    panel: if keep_toggles { btn(60.0) } else { zero },
    moon: if keep_toggles { btn(30.0) } else { zero },
    home: if keep_toggles { btn(0.0) } else { zero },
    div_a: if keep_meters { RectD::new(x=right - 376.0, y=cy - 6.0, w=1.0, h=12.0) } else { zero },
    div_b: if keep_meters { RectD::new(x=right - 286.0, y=cy - 6.0, w=1.0, h=12.0) } else { zero },
    div_c: if keep_meters { RectD::new(x=right - 220.0, y=cy - 6.0, w=1.0, h=12.0) } else { zero },
  }
}

///|
pub fn tab_slots(model : Model, shell : Shell) -> Array[TabSlot] {
  let out : Array[TabSlot] = []
  let start = shell.tabs.x + 8.0
  let right = (shell.w - 12.0 - tab_cluster_reserve(shell)).max(start + 60.0)
  let avail = (right - start).max(60.0)
  // One pass to learn how much each tab would like, a second to shrink them
  // proportionally when four windows sit in a strip that only fits three.
  let wants : Array[Double] = []
  let mut total = 0.0
  for window in model.windows {
    let extra = if window.minimized { TAB_BADGE_RESERVE } else { 0.0 }
    let approx = window.title.length().to_double() * 6.6 + 58.0 + extra
    let want = (if window.id == model.active { 104.0 } else { 74.0 }) + extra
    let w = approx.max(want).min(196.0 + extra)
    wants.push(w)
    total = total + w
  }
  let gaps = if model.windows.length() > 1 { (model.windows.length() - 1).to_double() * 3.0 } else { 0.0 }
  let scale = if total + gaps > avail { (avail - gaps).max(60.0) / total.max(1.0) } else { 1.0 }
  let mut x = start
  let mut i = 0
  for window in model.windows {
    let w = (wants[i] * scale).max(64.0)
    if x + w > right + 1.0 {
      break
    }
    out.push({ id: window.id, rect: RectD::new(x=x, y=shell.tabs.y + 6.0, w=w, h=32.0), active: window.id == model.active })
    x = x + w + 3.0
    i = i + 1
  }
  out
}

///|
/// The `+` sits right after the last tab, as in the reference strip; it falls
/// back to the strip's left edge when no window is open.
pub fn plus_tab(model : Model, shell : Shell) -> RectD {
  let slots = tab_slots(model, shell)
  let x = if slots.is_empty() {
    shell.tabs.x + 8.0
  } else {
    slots[slots.length() - 1].rect.right() + 6.0
  }
  RectD::new(x=x, y=shell.tabs.y + 10.0, w=24.0, h=24.0)
}

///|
/// The three titlebar nav buttons (sidebar toggle, back, forward). Fixed-size
/// slots, so the painter and the hit test never disagree about where they are.
pub fn titlebar_nav_slots(shell : Shell) -> Array[RectD] {
  let out : Array[RectD] = []
  let btn_y = shell.titlebar.y + 4.0
  let mut i = 0
  while i < 3 {
    out.push(RectD::new(x=shell.titlebar.x + TITLEBAR_LEAD + i.to_double() * 32.0, y=btn_y, w=28.0, h=28.0))
    i = i + 1
  }
  out
}

///|
pub fn rail_slots(shell : Shell) -> Array[RectD] {
  let out : Array[RectD] = []
  let mut i = 0
  while i < 6 {
    out.push(RectD::new(x=shell.rail.x + 9.0, y=shell.rail.y + 10.0 + i.to_double() * 42.0, w=38.0, h=38.0))
    i = i + 1
  }
  out
}

///|
pub fn rail_handle(shell : Shell) -> RectD {
  RectD::new(x=shell.rail.x + RAIL_W - 9.0, y=shell.rail.y + shell.rail.h / 2.0 - 23.0, w=18.0, h=46.0)
}

///|
pub fn rail_avatar(shell : Shell) -> RectD {
  RectD::new(x=shell.rail.x + 11.0, y=shell.rail.y + shell.rail.h - 12.0 - 34.0, w=34.0, h=34.0)
}

///|
pub fn rail_update(shell : Shell) -> RectD {
  let a = rail_avatar(shell)
  RectD::new(x=shell.rail.x + 9.0, y=a.y - 8.0 - 38.0, w=38.0, h=38.0)
}

///|
pub fn dock_slots(shell : Shell) -> Array[RectD] {
  let out : Array[RectD] = []
  let mut i = 0
  while i < DOCK_PANELS {
    out.push(RectD::new(x=shell.dock.x + 2.0, y=shell.dock.y + i.to_double() * 44.0, w=36.0, h=36.0))
    i = i + 1
  }
  out
}

///|
pub enum SbKind {
  SbBrand
  SbNewThread
  SbSkills
  SbSectionProjects
  SbProject(Int)
  SbThread(Int)
  SbExpandMore
  SbSectionExplorer
  SbFile(Int)
  SbFooter
}

///|
pub struct SbSlot {
  kind : SbKind
  rect : RectD
}

///|
pub fn density_scale(density : Int) -> Double {
  match density {
    0 => 1.0
    1 => 0.85
    _ => 1.15
  }
}

///|
/// Top of the project/Explorer region inside the sidebar: the same point the
/// row list starts laying projects out from, so the split handle and the
/// hairline can never drift apart. The row heights scale with density, and so
/// does this sum (brand + two action rows + their gaps).
fn sidebar_region_top(model : Model, shell : Shell) -> Double {
  let s = density_scale(model.density)
  shell.sidebar.y + 10.0 + (32.0 + 2.0 + 30.0 + 2.0 + 30.0 + 6.0) * s
}

///|
/// The split, in pixels, as the row list measures it: `sidebar_split` is a
/// fraction of the region between the action rows and the footer.
pub fn sidebar_divider_y(model : Model, shell : Shell) -> Double {
  let top = sidebar_region_top(model, shell)
  top + sidebar_region_h(model, shell) * clamp_f(model.sidebar_split, SPLIT_MIN, SPLIT_MAX)
}

///|
/// Height of the draggable project/Explorer region. The split is a fraction of
/// this, so a drag maps pixels to the same 0.15..0.85 range the painter clamps
/// against — at any density step.
pub fn sidebar_region_h(model : Model, shell : Shell) -> Double {
  let footer_y = shell.sidebar.y + shell.sidebar.h - 44.0
  let rows_bottom = footer_y - 2.0
  let top = sidebar_region_top(model, shell)
  (rows_bottom - top).max(1.0)
}

///|
/// The 10px band the split can be dragged by, centred on the hairline. The
/// reference drags `#sbProjects` against `.dock-left-cards` with a 6px handle;
/// 10px here keeps it grabbable at any density step.
pub fn sidebar_split_handle(model : Model, shell : Shell) -> RectD {
  let y = sidebar_divider_y(model, shell)
  RectD::new(x=shell.sidebar.x + 6.0, y=y - 5.0, w=(shell.sidebar.w - 12.0).max(1.0), h=10.0)
}

///|
/// One row list drives both the paint code and the hit test, so clicks land on
/// the row that is actually visible at that y.
pub fn sidebar_slots(model : Model, shell : Shell) -> Array[SbSlot] {
  let out : Array[SbSlot] = []
  let s = density_scale(model.density)
  // The reference sidebar insets its rows 6px and lets each painter add its own
  // 2px (project/thread) or 4px (action row) padding, so titles, folder names
  // and the section heads all share one left edge.
  let x = shell.sidebar.x + 6.0
  let w = (shell.sidebar.w - 12.0).max(1.0)
  let footer_h = 44.0
  let footer_y = shell.sidebar.y + shell.sidebar.h - footer_h
  // Rows stop above the footer instead of running under it. The list is the
  // single source for both painting and hit testing, so a dropped row cannot
  // be clicked either.
  let rows_bottom = footer_y - 2.0
  let mut y = shell.sidebar.y + 10.0
  let h_brand = 32.0 * s
  let h_nav = 30.0 * s
  let h_head = 26.0 * s
  let h_project = 28.0 * s
  let h_thread = 27.0 * s
  let h_more = 24.0 * s
  let h_file = 24.0 * s
  // Vertical rhythm from the reference sidebar: brand row, 2px, two 30px action
  // rows 2px apart, 6px, then the section head. Matching those gaps is what puts
  // the project row and every thread row on the reference's baselines.
  out.push({ kind: SbBrand, rect: RectD::new(x~, y~, w~, h=h_brand) })
  y = y + h_brand + 2.0 * s
  out.push({ kind: SbNewThread, rect: RectD::new(x~, y~, w~, h=h_nav) })
  y = y + h_nav + 2.0 * s
  out.push({ kind: SbSkills, rect: RectD::new(x~, y~, w~, h=h_nav) })
  y = y + h_nav + 6.0 * s
  // The reference splits the sidebar 46/54 between the project block and the
  // Explorer, with a hairline divider between them. The split is measured from
  // the end of the action rows down to the footer, so both blocks stay put as
  // the window resizes instead of the file list swallowing the project list.
  let divider_y = sidebar_divider_y(model, shell)
  let projects_bottom = divider_y - 6.0
  out.push({ kind: SbSectionProjects, rect: RectD::new(x~, y~, w~, h=h_head) })
  y = y + h_head
  let mut p = 0
  while p < model.projects.length() {
    let project = model.projects[p]
    if y + h_project > projects_bottom {
      break
    }
    out.push({ kind: SbProject(p), rect: RectD::new(x~, y~, w~, h=h_project) })
    y = y + h_project
    if project.expanded {
      if project.current {
        let mut t = 0
        while t < model.threads.length() {
          let thread = model.threads[t]
          if thread.project == project.name {
            if y + h_thread > projects_bottom {
              break
            }
            out.push({ kind: SbThread(t), rect: RectD::new(x~, y~, w~, h=h_thread) })
            y = y + h_thread
          }
          t = t + 1
        }
      }
      if y + h_more <= projects_bottom {
        out.push({ kind: SbExpandMore, rect: RectD::new(x~, y~, w~, h=h_more) })
        y = y + h_more
      }
    }
    p = p + 1
  }
  y = divider_y + 6.0
  if y + h_head <= rows_bottom {
    out.push({ kind: SbSectionExplorer, rect: RectD::new(x~, y~, w~, h=h_head) })
    y = y + h_head
  }
  let mut f = 0
  while f < model.files.length() {
    if y + h_file > rows_bottom {
      break
    }
    out.push({ kind: SbFile(f), rect: RectD::new(x~, y~, w~, h=h_file) })
    y = y + h_file
    f = f + 1
  }
  out.push({
    kind: SbFooter,
    rect: RectD::new(x=shell.sidebar.x, y=footer_y, w=shell.sidebar.w, h=footer_h),
  })
  out
}

///|
pub struct ComposerPills {
  input : RectD
  chips : RectD
  perm : RectD
  mode : RectD
  model : RectD
  think : RectD
  attach : RectD
  mic : RectD
}

///|
pub fn composer_pills(composer : RectD) -> ComposerPills {
  let px = composer.x + 10.0
  let bar_y = composer.y + composer.h - 32.0
  let input = RectD::new(x=composer.x + 10.0, y=composer.y + 33.0, w=composer.w - 20.0, h=24.0)
  let chips = RectD::new(x=composer.x + 10.0, y=composer.y + 8.0, w=composer.w - 20.0, h=20.0)
  let perm = RectD::new(x=px, y=bar_y, w=112.0, h=24.0)
  let mode = RectD::new(x=perm.x + perm.w + 6.0, y=bar_y, w=78.0, h=24.0)
  let model = RectD::new(x=mode.x + mode.w + 6.0, y=bar_y, w=138.0, h=24.0)
  let think = RectD::new(x=model.x + model.w + 6.0, y=bar_y, w=58.0, h=24.0)
  let attach = RectD::new(x=composer.x + composer.w - 96.0, y=bar_y, w=24.0, h=24.0)
  let mic = RectD::new(x=composer.x + composer.w - 66.0, y=bar_y, w=24.0, h=24.0)
  { input, chips, perm, mode, model, think, attach, mic }
}

///|
pub struct Capsule {
  id : Int
  rect : RectD
}

///|
/// The minimised-window capsules along the top of the canvas.
pub fn capsule_rects(model : Model, shell : Shell) -> Array[Capsule] {
  let out : Array[Capsule] = []
  let mut x = shell.canvas.x + 8.0
  let right = shell.canvas.right() - 8.0
  for window in model.windows {
    if window.minimized {
      let w = (window.title.length().to_double() * 6.2 + 46.0).max(96.0).min(178.0)
      if x + w > right {
        break
      }
      out.push({
        id: window.id,
        rect: RectD::new(x~, y=shell.canvas.y + 4.0, w~, h=32.0),
      })
      x = x + w + 6.0
    }
  }
  out
}

///|
pub fn picker_panel(shell : Shell) -> RectD {
  let c = shell.canvas
  let w = 404.0.min(c.w - 32.0)
  let h = 258.0.min(c.h - 32.0)
  RectD::new(x=c.x + (c.w - w) / 2.0, y=c.y + (c.h - h) / 2.0, w~, h~)
}

///|
/// The six preset cells inside the max-button picker, in reading order.
pub fn picker_cells(shell : Shell) -> Array[RectD] {
  let out : Array[RectD] = []
  let panel = picker_panel(shell)
  let pad = 16.0
  let gap = 10.0
  let cw = (panel.w - pad * 2.0 - gap * 2.0) / 3.0
  let ch = 78.0
  let mut row = 0
  while row < 2 {
    let mut col = 0
    while col < 3 {
      out.push(
        RectD::new(
          x=panel.x + pad + col.to_double() * (cw + gap),
          y=panel.y + 44.0 + row.to_double() * (ch + gap),
          w=cw,
          h=ch,
        ),
      )
      col = col + 1
    }
    row = row + 1
  }
  out
}
