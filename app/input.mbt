// Interaction layer: one reducer from Msg to Model, plus the pointer hit test
// that drives it. Every rectangle used here comes from geometry.mbt / layout.mbt
// — the same helpers the paint pass draws from — so a click always lands on what
// the user sees.

///|
fn clamp_d(v : Double, lo : Double, hi : Double) -> Double {
  if hi < lo {
    lo
  } else {
    v.max(lo).min(hi)
  }
}

///|
fn preset_at(i : Int) -> LayoutPreset {
  match i {
    0 => SplitEven
    1 => SplitTwoOne
    2 => ThreeColumns
    3 => LeftStacked
    4 => RightStacked
    _ => Quadrants
  }
}

///|
fn browser_query_at(i : Int) -> String {
  match i {
    0 => "localhost:5173/studio/preview"
    1 => "localhost:5173/studio/plan"
    2 => "github.com/the-snowpear/omp-studio"
    _ => ""
  }
}

///|
fn toggle_file(model : Model, i : Int) -> Model {
  let files : Array[FileRow] = []
  let mut j = 0
  for f in model.files {
    if j == i {
      files.push({ ..f, expanded: !f.expanded })
    } else {
      files.push(f)
    }
    j = j + 1
  }
  { ..model, files, }
}

///|
fn drop_plan_windows(model : Model) -> Model {
  let out = close_kind_windows(model, PlanReview)
  { ..out, plan_approved: false, }
}

///|
fn close_kind_windows(model : Model, kind : WindowKind) -> Model {
  let ws : Array[WindowRec] = []
  for win in model.windows {
    if win.kind != kind {
      ws.push(win)
    }
  }
  if ws.length() == 0 {
    return { ..model, windows: ws, active: -1, }
  }
  let active = if window_by_id({ ..model, windows: ws, }, model.active) is Some(_) {
    model.active
  } else {
    ws[ws.length() - 1].id
  }
  { ..model, windows: ws, active, }
}

///|
fn snap_window(model : Model, id : Int, zone : SnapZone) -> Model {
  let i = window_index(model, id)
  if i < 0 {
    return model
  }
  let ws = copy_windows(model)
  let win = ws[i]
  let spec = zone.rect()
  let pad = 0.002
  ws[i] = {
    ..win,
    maximized: false,
    pre_rect: win.rect,
    rect: RectD::new(
      x=spec.x + pad,
      y=spec.y + pad,
      w=(spec.w - pad * 2.0).max(0.05),
      h=(spec.h - pad * 2.0).max(0.05),
    ),
  }
  { ..model, windows: ws, }
}

///|
/// The six snap templates omp-studio offers while a window is dragged: the four
/// canvas corners, the two halves and the full top.
fn snap_zone_at(shell : Shell, x : Double, y : Double) -> SnapZone {
  let c = shell.canvas
  if c.w <= 0.0 || c.h <= 0.0 {
    return NoZone
  }
  let rx = (x - c.x) / c.w
  let ry = (y - c.y) / c.h
  if ry < 0.05 {
    if rx < 0.25 {
      TopLeft
    } else if rx > 0.75 {
      TopRight
    } else {
      FullTop
    }
  } else if ry > 0.95 {
    if rx < 0.5 {
      BottomLeft
    } else {
      BottomRight
    }
  } else if rx < 0.08 {
    LeftHalf
  } else if rx > 0.92 {
    RightHalf
  } else {
    NoZone
  }
}

///|
fn drag_apply(model : Model, shell : Shell, pm : PointerMsg) -> Model {
  let d = model.drag
  let cw = shell.canvas.w
  let ch = shell.canvas.h
  if cw <= 1.0 || ch <= 1.0 {
    return model
  }
  let idx = window_index(model, d.id)
  if idx < 0 {
    return { ..model, drag: DragInfo::idle(), }
  }
  let ws = copy_windows(model)
  let win = ws[idx]
  let o = d.origin
  let dx = (pm.x - d.sx) / cw
  let dy = (pm.y - d.sy) / ch
  let min_w = (320.0 / cw).min(0.9)
  let min_h = (200.0 / ch).min(0.9)
  let next = if d.mode == 0 {
    RectD::new(
      x=clamp_d(o.x + dx, 0.0, (1.0 - o.w).max(0.0)),
      y=clamp_d(o.y + dy, 0.0, (1.0 - o.h).max(0.0)),
      w=o.w,
      h=o.h,
    )
  } else {
    let mut x = o.x
    let mut y = o.y
    let mut w = o.w
    let mut h = o.h
    if d.edges / 1 % 2 == 1 {
      let nx = clamp_d(o.x + dx, 0.0, o.x + o.w - min_w)
      w = o.x + o.w - nx
      x = nx
    }
    if d.edges / 2 % 2 == 1 {
      w = clamp_d(o.w + dx, min_w, 1.0 - o.x)
    }
    if d.edges / 4 % 2 == 1 {
      let ny = clamp_d(o.y + dy, 0.0, o.y + o.h - min_h)
      h = o.y + o.h - ny
      y = ny
    }
    if d.edges / 8 % 2 == 1 {
      h = clamp_d(o.h + dy, min_h, 1.0 - o.y)
    }
    RectD::new(x~, y~, w~, h~)
  }
  ws[idx] = { ..win, rect: next, }
  let preview = if d.mode == 0 {
    snap_zone_at(shell, pm.x, pm.y)
  } else {
    NoZone
  }
  { ..model, windows: ws, snap_preview: preview, }
}

///|
/// Start a shell-width drag. The drag is relative to the pointer-down value and
/// coordinate, so the edge never jumps when the grab lands a few pixels off.
fn begin_resize(model : Model, mode : Int, base : Double, anchor : Double) -> Model {
  {
    ..model,
    resize_mode: mode,
    resize_base: base,
    resize_anchor: anchor,
    drag: DragInfo::idle(),
    snap_preview: NoZone,
  }
}

///|
/// Sidebar width (1) or project/Explorer split (2), clamped by the same helpers
/// the painter uses (`clamp_sidebar`, `SPLIT_MIN..SPLIT_MAX`).
fn resize_apply(model : Model, shell : Shell, pm : PointerMsg) -> Model {
  if model.resize_mode == 1 {
    let next = clamp_sidebar(shell.w, model.resize_base + (pm.x - model.resize_anchor))
    { ..model, sidebar_w: next, }
  } else if model.resize_mode == 2 {
    let region = sidebar_region_h(model, shell)
    let next = clamp_f(
      model.resize_base + (pm.y - model.resize_anchor) / region,
      SPLIT_MIN,
      SPLIT_MAX,
    )
    { ..model, sidebar_split: next, }
  } else {
    model
  }
}

///|
/// Window body click: buttons first, then the title bar (drag), then the eight
/// resize bands, then focus.
fn window_down(model : Model, win : WindowRec, frame : RectD, x : Double, y : Double) -> Model {
  let chrome = win_chrome(frame)
  if chrome.close.contains(x, y) {
    return close_window(model, win.id)
  }
  if chrome.min.contains(x, y) {
    return minimize_window(model, win.id)
  }
  if chrome.max.contains(x, y) {
    return toggle_maximize(model, win.id)
  }
  if chrome.more.contains(x, y) {
    return { ..model, picker: win.id, }
  }
  if chrome.dock.contains(x, y) {
    return { ..model, dock_tab: (model.dock_tab + 1) % DOCK_PANELS, }
  }
  let hit = frame_hit(frame, x, y)
  if hit != 0 {
    return {
      ..model,
      drag: {
        active: true,
        id: win.id,
        mode: if hit == 16 { 0 } else { 1 },
        edges: if hit == 16 { 0 } else { hit },
        origin: win.rect,
        sx: x,
        sy: y,
        snap: NoZone,
      },
    }
  }
  ignore(chrome)
  model
}

///|
/// Controls inside a window body, keyed by window kind. `None` means the click
/// landed on plain body and should fall through to focus / drag handling.
fn window_control(
  model : Model,
  win : WindowRec,
  frame : RectD,
  x : Double,
  y : Double,
) -> Model? {
  match win.kind {
    Conversation => {
      let cb = convo_box(frame)
      if cb.approve.contains(x, y) || cb.approve_session.contains(x, y) {
        Some({ ..model, approval: 1, })
      } else if cb.deny.contains(x, y) {
        Some({ ..model, approval: 2, })
      } else if cb.send.contains(x, y) {
        Some(send_composer(model))
      } else if cb.composer.contains(x, y) {
        Some({ ..model, composer_focus: true, })
      } else if convo_latest_pill(cb).contains(x, y) {
        Some({ ..model, convo_scroll: 0.0, })
      } else {
        None
      }
    }
    PlanReview => {
      let pb = plan_box(frame)
      if pb.approve.contains(x, y) || pb.keep.contains(x, y) || pb.compact.contains(x, y) {
        Some({ ..model, plan_approved: true, })
      } else if pb.refine.contains(x, y) {
        Some(model)
      } else if pb.dismiss.contains(x, y) {
        Some(drop_plan_windows(model))
      } else {
        None
      }
    }
    Browser => {
      let bb = browser_box(frame)
      if bb.back.contains(x, y) {
        Some({ ..model, browser_nav: 0, })
      } else if bb.forward.contains(x, y) {
        Some({ ..model, browser_nav: 1, })
      } else if bb.reload.contains(x, y) {
        Some({ ..model, browser_nav: 2, })
      } else if bb.seg_agent.contains(x, y) {
        Some({ ..model, browser_control: 0, })
      } else if bb.seg_me.contains(x, y) {
        Some({ ..model, browser_control: 1, })
      } else if bb.omnibox.contains(x, y) {
        Some({ ..model, browser_query: "localhost:5173/studio/preview", })
      } else {
        None
      }
    }
    Terminal => None
  }
}

///|
fn sidebar_down(model : Model, slot : SbSlot) -> Model {
  match slot.kind {
    SbNewThread => new_thread(model)
    SbThread(id) => select_thread(model, id)
    SbSectionExplorer => { ..model, explorer_open: !model.explorer_open, }
    SbFile(i) => toggle_file(model, i)
    _ => model
  }
}

///|
/// Pointer down: overlays own the pointer while open, then windows (topmost
/// first), then the tab strip, the left rail, the sidebar rows and the dock.
fn pointer_down(model : Model, shell : Shell, pm : PointerMsg) -> Model {
  let x = pm.x
  let y = pm.y
  let nav = titlebar_nav_slots(shell)
  let mut ni = 0
  while ni < nav.length() {
    if nav[ni].contains(x, y) {
      return if ni == 0 {
        { ..model, sidebar_open: !model.sidebar_open }
      } else if ni == 1 {
        go_route(model, model.back_route)
      } else {
        model
      }
    }
    ni = ni + 1
  }
  // The two shell bands are grabbed before anything they overlap: the width
  // resizer straddles the sidebar border and the split handle sits on top of
  // the project/Explorer row list.
  if model.sidebar_open {
    if sidebar_resizer(shell).contains(x, y) {
      return begin_resize(model, 1, model.sidebar_w, x)
    }
    if sidebar_split_handle(model, shell).contains(x, y) {
      return begin_resize(model, 2, model.sidebar_split, y)
    }
  }
  if model.picker >= 0 {
    let cells = picker_cells(shell)
    let mut i = 0
    while i < cells.length() {
      if cells[i].contains(x, y) {
        return apply_preset({ ..model, picker: -1, }, preset_at(i))
      }
      i = i + 1
    }
    return { ..model, picker: -1, }
  }
  for cap in capsule_rects(model, shell) {
    if cap.rect.contains(x, y) {
      return restore_window(model, cap.id)
    }
  }
  let vis = visible_windows(model)
  let mut i = vis.length() - 1
  while i >= 0 {
    let win = vis[i]
    let frame = win_px(win, shell)
    if frame.contains(x, y) {
      let raised = raise_window(model, win.id)
      match window_control(raised, win, frame, x, y) {
        Some(m) => return m
        None => return window_down(raised, win, frame, x, y)
      }
    }
    i = i - 1
  }
  let cluster = tab_cluster(shell)
  if cluster.tier >= 0 {
    if cluster.panel.contains(x, y) {
      return { ..model, sidebar_open: !model.sidebar_open, }
    }
    if cluster.moon.contains(x, y) {
      let dark = !model.dark
      return toast_show({ ..model, dark }, if dark { "已切换到深色主题" } else { "已切换到浅色主题" })
    }
    if cluster.sliders.contains(x, y) || cluster.compact.contains(x, y) {
      let next = if model.density >= 2 { 0 } else { model.density + 1 }
      return toast_show({ ..model, density: next }, "已切换信息密度")
    }
    if cluster.home.contains(x, y) {
      return go_route(model, Home)
    }
  }
  if plus_tab(model, shell).contains(x, y) {
    return new_conversation_window(model, model.current_thread, "新对话")
  }
  for tab in tab_slots(model, shell) {
    // The close circle of the open tab sits inside its own rect, so it is
    // tested first: clicking it closes the window instead of re-raising it.
    if tab.active && tab_close_rect(tab).contains(x, y) {
      return close_window(model, tab.id)
    }
    if tab.rect.contains(x, y) {
      return raise_window(model, tab.id)
    }
  }
  if rail_handle(shell).contains(x, y) {
    return { ..model, sidebar_open: !model.sidebar_open, }
  }
  if rail_avatar(shell).contains(x, y) {
    return model
  }
  let rails = rail_slots(shell)
  let rail_routes_list = rail_routes()
  let mut i = 0
  while i < rails.length() {
    if rails[i].contains(x, y) {
      return if i < rail_routes_list.length() { go_route(model, rail_routes_list[i]) } else { model }
    }
    i = i + 1
  }
  for slot in sidebar_slots(model, shell) {
    if slot.rect.contains(x, y) {
      return sidebar_down(model, slot)
    }
  }
  let docks = dock_slots(shell)
  let mut i = 0
  while i < docks.length() {
    if docks[i].contains(x, y) {
      return { ..model, dock_tab: i, }
    }
    i = i + 1
  }
  model
}

///|
/// Wheel over the conversation: `convo_scroll` counts pixels scrolled up from
/// the bottom-anchored latest turn, so a wheel-down gesture lowers it. The
/// content height is measured with the host text system the layout pass handed
/// over, which is what keeps the clamp identical to the painter's offset.
fn convo_wheel(model : Model, shell : Shell, pm : PointerMsg) -> Model? {
  let vis = visible_windows(model)
  let mut i = vis.length() - 1
  while i >= 0 {
    let win = vis[i]
    let frame = win_px(win, shell)
    if frame.contains(pm.x, pm.y) {
      match win.kind {
        Conversation => {
          let cb = convo_box(frame)
          if !cb.scroll.contains(pm.x, pm.y) {
            return Some(model)
          }
          let total = chat_height(app_text.val, model, cb.doc_w)
          let maxoff = (total - cb.scroll.h + 10.0).max(0.0)
          let next = (model.convo_scroll - pm.wheel).max(0.0).min(maxoff)
          return Some({ ..model, convo_scroll: next })
        }
        _ => return Some(model)
      }
    }
    i = i - 1
  }
  None
}

///|
fn pointer_update(model : Model, pm : PointerMsg) -> Model {
  // Remember the frame size: page scroll clamping needs the shell, and a page
  // keystroke has no pointer event of its own to ask.
  let model = { ..model, frame_w: pm.w, frame_h: pm.h, hover_x: pm.x, hover_y: pm.y, hover_on: true }
  // A dialog owns the pointer too: backdrop dismiss, footer buttons, nothing
  // behind it. A dialog that is already leaving ignores the pointer, like the
  // reference's `pointer-events: none` on `.is-leaving`.
  if model.modal != MNone {
    return modal_pointer(model, pm)
  }
  if model.modal_leaving != MNone {
    return model
  }
  // The palette is modal: while it is open the pointer only reaches the panel.
  // Clicking a row runs it, hovering a row selects it (the reference moves the
  // highlight on pointer-enter) and the wheel scrolls the list itself.
  if model.palette_open {
    let panel_r = palette_panel_rect(pm.w, pm.h)
    if pm.phase == 0 {
      let row = palette_row_at(model, pm.x, pm.y)
      if row >= 0 {
        return palette_run(model, row)
      }
      if !panel_r.contains(pm.x, pm.y) {
        return { ..model, palette_open: false, palette_query: "", palette_index: 0, palette_scroll: 0.0 }
      }
    } else if pm.phase == 2 {
      let row = palette_row_at(model, pm.x, pm.y)
      if row >= 0 && row != model.palette_index {
        return palette_reveal({ ..model, palette_index: row })
      }
    } else if pm.phase == 3 {
      let max_off = palette_scroll_max(model)
      return { ..model, palette_scroll: (model.palette_scroll + pm.wheel).max(0.0).min(max_off) }
    }
    return model
  }
  if pm.phase == 4 {
    // Pointer left the window: no hover, no tip.
    return tip_clear({ ..model, hover_on: false })
  }
  let shell = shell_layout(pm.w, pm.h, model.sidebar_open, sidebar_w=model.sidebar_w)
  // The reachable-control list is built once per event and shared by the press
  // feedback, the hit test and the tip dwell, so feedback can never land on a
  // control that is not painted.
  let list = controls(model, shell)
  if model.route != Workbench {
    if pm.phase == 0 {
      let pressed = press_begin(model, list, pm.x, pm.y)
      return press_prune(page_pointer(pressed, pm), shell)
    }
    if pm.phase == 1 {
      return press_release({ ..page_pointer(model, pm), resize_mode: 0, })
    }
    // The shell bands belong to the workbench: a secondary page paints no
    // sidebar, so there is nothing there to widen.
    let out = page_pointer(model, pm)
    if pm.phase == 2 {
      return hover_tip(out, list, pm.x, pm.y)
    }
    return out
  }
  if pm.phase == 3 {
    let scrolled = match convo_wheel(model, shell, pm) {
      Some(m) => m
      None => model
    }
    return scrolled
  }
  match pm.phase {
    0 => press_prune(pointer_down(press_begin(model, list, pm.x, pm.y), shell, pm), shell)
    1 => {
      let out = if model.drag.active && model.drag.snap != NoZone {
        snap_window(model, model.drag.id, model.drag.snap)
      } else {
        model
      }
      press_release({ ..out, drag: DragInfo::idle(), snap_preview: NoZone, resize_mode: 0, })
    }
    2 => {
      let resized = if model.resize_mode != 0 {
        resize_apply(model, shell, pm)
      } else {
        model
      }
      let moved = if resized.drag.active {
        drag_apply(resized, shell, pm)
      } else {
        resized
      }
      hover_tip(moved, list, pm.x, pm.y)
    }
    _ => model
  }
}

///|
/// Typing goes to the composer, except on the history page while its search
/// field holds focus: then the same keystrokes drive the query.
fn type_text(model : Model, s : String) -> Model {
  if s == "" {
    return model
  }
  // The rename dialog's field is the only text surface that can hold focus
  // while a sheet owns the app; the other two take no typing.
  if model.modal == MRename {
    return update(model, ModalType(s))
  }
  if model.modal != MNone {
    return model
  }
  if model.palette_open {
    return { ..model, palette_query: model.palette_query + s, palette_index: 0, palette_scroll: 0.0 }
  }
  if model.route == History && model.history_focus {
    return { ..model, history_query: model.history_query + s }
  }
  push_composer(model, s)
}

///|
fn drop_last(s : String) -> String {
  let chars : Array[Char] = []
  for c in s.iter() {
    chars.push(c)
  }
  let keep : Array[Char] = []
  let mut i = 0
  while i + 1 < chars.length() {
    keep.push(chars[i])
    i = i + 1
  }
  let mut out = ""
  for c in keep {
    out = out + c.to_string()
  }
  out
}

///|
fn key_update(model : Model, key : String, mods : Int) -> Model {
  let shift = mods % 2 == 1
  let meta = mods / 8 % 2 == 1
  // A dialog owns the keyboard while it is open: Esc closes, Enter runs the
  // focused footer button, Tab walks the two buttons and Backspace edits the
  // rename field. Nothing behind the sheet hears a key.
  if model.modal != MNone {
    if key == "Escape" {
      return modal_close_now(model)
    }
    if key == "Tab" {
      return modal_focus_step(model, if shift { -1 } else { 1 })
    }
    if key == "Enter" {
      return modal_confirm(model)
    }
    if key == "Backspace" {
      return update(model, ModalBackspace)
    }
    return model
  }
  // ⌘K toggles the palette from anywhere; while it is open it owns the keys.
  if mods / 8 % 2 == 1 && (key == "k" || key == "K") {
    if model.palette_open {
      return { ..model, palette_open: false, palette_query: "", palette_index: 0, palette_scroll: 0.0 }
    }
    return { ..model, palette_open: true, palette_query: "", palette_index: 0, palette_scroll: 0.0 }
  }
  // ⌘B and ⇧⌘O are the two shell shortcuts the palette advertises; they work
  // from any route, like ⌘K.
  if meta && (key == "b" || key == "B") {
    return { ..model, sidebar_open: !model.sidebar_open, }
  }
  if meta && shift && (key == "o" || key == "O") {
    let closed = { ..model, palette_open: false, palette_query: "", palette_index: 0, palette_scroll: 0.0, }
    return new_conversation_window(closed, closed.current_thread, "新对话")
  }
  if model.palette_open {
    if key == "Escape" {
      return { ..model, palette_open: false, palette_query: "", palette_index: 0, palette_scroll: 0.0 }
    }
    if key == "Enter" {
      return update(model, PaletteRun(model.palette_index))
    }
    if key == "ArrowDown" || key == "Down" {
      return update(model, PaletteMove(1))
    }
    if key == "ArrowUp" || key == "Up" {
      return update(model, PaletteMove(-1))
    }
    if key == "Home" {
      return palette_reveal({ ..model, palette_index: 0 })
    }
    if key == "End" {
      let count = palette_items(model).length()
      return palette_reveal({ ..model, palette_index: (count - 1).max(0) })
    }
    // ⌘1..⌘9 jump straight to a recent session, as the reference does while
    // the palette owns the keyboard.
    if mods / 8 % 2 == 1 {
      let row = palette_shortcut_row(model, key)
      if row >= 0 {
        return palette_run(model, row)
      }
    }
    if key == "Backspace" {
      let q = model.palette_query
      let chars : Array[Char] = []
      for c in q.iter() {
        chars.push(c)
      }
      let keep : Array[Char] = []
      let mut i = 0
      while i + 1 < chars.length() {
        keep.push(chars[i])
        i = i + 1
      }
      return { ..model, palette_query: String::from_array(keep[:]), palette_index: 0, palette_scroll: 0.0 }
    }
    return model
  }
  // Pages own Esc (leave the page) and the history search field; the workbench
  // keeps its own key handling below.
  if model.route != Workbench {
    let (fw, fh) = frame_size(model)
    if key == "Escape" {
      if model.focus_kb && model.focus_ctl != CNone {
        return focus_clear(model)
      }
      if model.tip_ctl != CNone {
        return tip_clear(model)
      }
      if model.history_focus {
        return { ..model, history_focus: false }
      }
      return go_route(model, model.back_route)
    }
    if key == "Tab" {
      let next = focus_step(model, if shift { -1 } else { 1 })
      return { ..next, history_focus: false, }
    }
    if key == "Enter" && model.focus_kb && model.focus_ctl != CNone {
      return focus_activate(model)
    }
    if model.history_focus {
      match key {
        "Backspace" => return { ..model, history_query: drop_last(model.history_query) }
        "Enter" => return { ..model, history_focus: false }
        _ => return model
      }
    }
    if key == "PageDown" {
      return page_scroll_by(model, 320.0, page_shell(fw, fh))
    }
    if key == "PageUp" {
      return page_scroll_by(model, -320.0, page_shell(fw, fh))
    }
    return model
  }
  // Workbench keyboard: the focus ring is a keyboard-only layer, so Tab starts
  // it, Enter runs the ring's control, the arrows walk the same order and Esc
  // peels back one layer at a time (picker → ring → tip → composer).
  if key == "Tab" {
    return focus_step(model, if shift { -1 } else { 1 })
  }
  if key == "Enter" {
    if model.focus_kb && model.focus_ctl != CNone {
      return focus_activate(model)
    }
    if shift {
      return push_composer(model, "\n")
    }
    if model.approval == 0 {
      // A pending approval blocks sending — composer.pendingInteractionHint.
      return model
    }
    return send_composer(model)
  }
  if key == "Backspace" {
    return pop_composer(model)
  }
  if key == "Escape" {
    if model.picker >= 0 {
      return { ..model, picker: -1, }
    }
    if model.focus_kb && model.focus_ctl != CNone {
      return focus_clear(model)
    }
    if model.tip_ctl != CNone {
      return tip_clear(model)
    }
    return { ..model, composer_focus: false, }
  }
  if key == "ArrowDown" || key == "Down" || key == "ArrowRight" || key == "Right" {
    if model.focus_kb && model.focus_ctl != CNone {
      return focus_step(model, 1)
    }
    return model
  }
  if key == "ArrowUp" || key == "Up" || key == "ArrowLeft" || key == "Left" {
    if model.focus_kb && model.focus_ctl != CNone {
      return focus_step(model, -1)
    }
    return model
  }
  // Dialog entry points: F2 renames the raised window, ⌘/ or "?" opens the
  // shortcut table — the same two commands the ⌘K palette offers.
  if key == "F2" {
    return modal_open_now(model, MRename)
  }
  if (meta && key == "/") || (shift && key == "/") || key == "?" {
    return modal_open_now(model, MShortcuts)
  }
  model
}

///|
pub fn update(model : Model, msg : Msg) -> Model {
  match msg {
    ToggleTheme => {
      let dark = !model.dark
      toast_show({ ..model, dark }, if dark { "已切换到深色主题" } else { "已切换到浅色主题" })
    }
    ToggleSidebar => { ..model, sidebar_open: !model.sidebar_open, }
    ToggleExplorer => { ..model, explorer_open: !model.explorer_open, }
    NewThread => new_thread(model)
    SelectThread(id) => select_thread(model, id)
    ComposerInput(s) => push_composer(model, s)
    ComposerSend => send_composer(model)
    FocusWindow(id) => raise_window(model, id)
    CloseWindow(id) => close_window(model, id)
    MinimizeWindow(id) => minimize_window(model, id)
    ToggleMaximize(id) => toggle_maximize(model, id)
    OpenPicker(id) => { ..model, picker: id, }
    ClosePicker => { ..model, picker: -1, }
    ApplyPreset(preset) => toast_show(apply_preset(model, preset), "已应用布局模板")
    ApprovePlan => { ..model, plan_approved: true, }
    RefinePlan => model
    SelectBrowserTab(i) => { ..model, browser_tab: i, }
    SelectBrowserNav(i) => { ..model, browser_nav: i, }
    SelectBrowserQuery(i) => { ..model, browser_query: browser_query_at(i), }
    Pointer(p) => pointer_update(model, p)
    KeyTyped(s) => type_text(model, s)
    KeyDown(key, mods) => key_update(model, key, mods)
    CapsuleClick(id) => restore_window(model, id)
    DockSelect(i) => { ..model, dock_tab: i, }
    AllowOnce => { ..model, approval: 1, }
    AllowSession => { ..model, approval: 1, }
    DenyApproval => { ..model, approval: 2, }
    DenyPlan => drop_plan_windows(model)
    BrowserControl(i) => { ..model, browser_control: i, }
    NewWindow => new_conversation_window(model, model.current_thread, "新对话")
    ToggleDensity => {
      let next = if model.density >= 2 { 0 } else { model.density + 1 }
      toast_show({ ..model, density: next }, "已切换信息密度")
    }
    GoRoute(route) => go_route(model, route)
    GoBack => go_route(model, model.back_route)
    PageScroll(delta) => page_scroll_by(model, delta, page_shell(model.frame_w, model.frame_h))
    CapsTab(i) => { ..model, caps_tab: i, page_scroll: 0.0, }
    ToggleSkill(i) => toggle_skill(model, i)
    HistoryFilter(i) => { ..model, history_filter: i, history_focus: false, page_scroll: 0.0, }
    HistoryRow(i) => open_history_row(model, i)
    HistoryFocus => { ..model, history_focus: !model.history_focus, }
    SelectProvider(i) => if i >= 0 && i < model.providers.length() {
      { ..model, active_provider: i, page_note: "已选择供应商 " + model.providers[i].name }
    } else {
      model
    }
    SelectModel(i) => select_model_note(model, i)
    SettingsTab(i) => { ..model, settings_tab: i, page_scroll: 0.0, }
    SetLanguage(zh) => { ..model, language_zh: zh, }
    CycleMotion => { ..model, motion: next_cycle(model.motion, 3), }
    CycleLight => { ..model, light: next_cycle(model.light, 3), }
    CycleDocWidth => { ..model, doc_width: next_cycle(model.doc_width, 3), }
    ToggleAgent(i) => toggle_agent(model, i)
    EvalFilter(i) => { ..model, eval_filter: i, page_scroll: 0.0, }
    MediaFilter(i) => { ..model, media_filter: i, page_scroll: 0.0, }
    ToggleProvider(i) => toggle_provider(model, i)
    StatsRange(i) => { ..model, stats_range: i, page_scroll: 0.0, }
    MediaSelect(i) => { ..model, media_sel: i, }
    HubSelect(i) => { ..model, hub_sel: i, }
    DiagAction(i) => diag_action(model, i)
    CheckUpdate => { ..model, update_note: "已检查 · 没有新版本", page_note: "已检查更新 · 没有新版本", }
    ModelTab(i) => { ..model, model_tab: i, page_scroll: 0.0, }
    ToggleSwitch(i) => toggle_switch(model, i)
    BgScope(i) => { ..model, bg_scope: i, }
    CapsRun(i) => caps_run(model, i)
    TestProvider(i) => test_provider(model, i)
    RefreshModels(i) => refresh_models(model, i)
    CycleRoleModel(i) => cycle_role_model(model, i)
    TogglePalette => if model.palette_open {
      { ..model, palette_open: false, palette_query: "", palette_index: 0, palette_scroll: 0.0 }
    } else {
      { ..model, palette_open: true, palette_query: "", palette_index: 0, palette_scroll: 0.0 }
    }
    ClosePalette => { ..model, palette_open: false, palette_query: "", palette_index: 0, palette_scroll: 0.0 }
    PaletteType(s) => { ..model, palette_query: model.palette_query + s, palette_index: 0, palette_scroll: 0.0 }
    PaletteMove(d) => {
      let count = palette_items(model).length()
      let next = if count == 0 {
        0
      } else {
        let raw = (model.palette_index + d) % count
        if raw < 0 {
          raw + count
        } else {
          raw
        }
      }
      palette_reveal({ ..model, palette_index: next })
    }
    PaletteRun(i) => palette_run(model, i)
    FocusStep(d) => focus_step(model, d)
    // Arrow keys walk the same ring; the reference keeps one tab order and
    // lets both axes step through it.
    FocusArrow(d) => focus_step(model, d)
    FocusActivate => focus_activate(model)
    FocusClear => focus_clear(model)
    ModalOpen(kind) => modal_open_now(model, kind)
    ModalClose => modal_close_now(model)
    ModalType(s) =>
      if model.modal == MRename && ctl_chars(model.modal_input) < 120 {
        { ..model, modal_input: model.modal_input + s }
      } else {
        model
      }
    ModalBackspace => { ..model, modal_input: drop_last(model.modal_input) }
    ModalConfirm => modal_confirm(model)
    Toast(text) => toast_show(model, text)
  }
}
