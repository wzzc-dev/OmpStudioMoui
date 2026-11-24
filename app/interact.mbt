// Interaction layer: the reachable control list, its hit test, and the three
// timed feedbacks the reference runs beside the layout — press/tactile, tip
// dwell and toast lifetime — plus the modal sheet. Everything here reads the
// same geometry helpers the painters draw from, so a control can never be
// focusable, hoverable or pressable somewhere it is not painted.

///|
/// One reachable control of the shell: the id, the rect it occupies this frame,
/// and the label its tip shows (empty means the control has no tip).
pub struct CtlRec {
  ctl : Ctl
  rect : RectD
  tip : String
}

///|
/// Character count, not byte count: CJK labels are one advance per character,
/// which is what the button widths below assume.
fn ctl_chars(s : String) -> Int {
  let mut n = 0
  for _c in s.iter() {
    n = n + 1
  }
  n
}

///|
/// Control list in paint order. The hit test walks it backwards, so whatever is
/// painted last — a tab's close circle, the sidebar resizer, the top window's
/// chrome — wins the click. Page headers replace the workbench tab strip, so the
/// list switches with the route instead of carrying both.
pub fn controls(model : Model, shell : Shell) -> Array[CtlRec] {
  let out : Array[CtlRec] = []
  // Titlebar: sidebar toggle, back, forward.
  let nav = titlebar_nav_slots(shell)
  let nav_tips = ["切换侧栏", "后退", "前进"]
  let mut i = 0
  while i < nav.length() {
    out.push({ ctl: CNav(i), rect: nav[i], tip: nav_tips[i] })
    i = i + 1
  }
  if model.route == Workbench {
    for tab in tab_slots(model, shell) {
      out.push({ ctl: CTab(tab.id), rect: tab.rect, tip: "" })
      if tab.active {
        out.push({ ctl: CTabClose(tab.id), rect: tab_close_rect(tab), tip: "关闭窗口" })
      }
    }
    out.push({ ctl: CPlusTab, rect: plus_tab(model, shell), tip: "新对话" })
    let cluster = tab_cluster(shell)
    if cluster.tier >= 0 {
      out.push({ ctl: CClusterPanel, rect: cluster.panel, tip: "右侧面板" })
      out.push({ ctl: CClusterMoon, rect: cluster.moon, tip: "主题" })
      out.push({ ctl: CClusterSliders, rect: cluster.sliders, tip: "密度" })
      out.push({ ctl: CClusterHome, rect: cluster.home, tip: "首页" })
      out.push({ ctl: CClusterCompact, rect: cluster.compact, tip: "紧凑显示" })
    }
  } else {
    // Page head: back, the 186px title slot, the nav bubbles and the theme
    // toggle. A bubble that would run into the theme button is not painted as
    // reachable, matching the reference's hidden-overflow rule.
    let ps = page_shell(shell.w, shell.h)
    out.push({ ctl: CPageBack, rect: page_back_btn(ps), tip: "返回" })
    let slots = page_nav_slots(ps)
    let routes = page_nav_routes()
    let theme = page_theme_btn(ps)
    let mut n = 0
    while n < slots.length() && n < routes.length() {
      if slots[n].right() <= theme.x - 8.0 {
        out.push({ ctl: CPageNav(n), rect: slots[n], tip: routes[n].label() })
      }
      n = n + 1
    }
    out.push({ ctl: CPageTheme, rect: theme, tip: "主题" })
  }
  // Rail: six destinations, then the collapse handle.
  let rails = rail_slots(shell)
  let routes = rail_routes()
  let mut r = 0
  while r < rails.length() {
    let tip = if r < routes.length() { routes[r].label() } else { "" }
    out.push({ ctl: CRail(r), rect: rails[r], tip })
    r = r + 1
  }
  out.push({ ctl: CRailHandle, rect: rail_handle(shell), tip: "折叠侧栏" })
  if model.route == Workbench {
    // Sidebar rows, then the width resizer and the project/Explorer split on
    // top of them: the resizer straddles the border, so it must win the hit.
    let slots = sidebar_slots(model, shell)
    let mut s = 0
    while s < slots.length() {
      let slot = slots[s]
      let tip = match slot.kind {
        SbNewThread => "新对话"
        SbSkills => "技能"
        SbProject(id) =>
          if id >= 0 && id < model.projects.length() {
            model.projects[id].name
          } else {
            ""
          }
        SbThread(id) =>
          if id >= 0 && id < model.threads.length() {
            model.threads[id].title
          } else {
            ""
          }
        SbFile(id) =>
          if id >= 0 && id < model.files.length() {
            model.files[id].name
          } else {
            ""
          }
        _ => ""
      }
      out.push({ ctl: CSb(s), rect: slot.rect, tip })
      s = s + 1
    }
    out.push({ ctl: CSbSplit, rect: sidebar_split_handle(model, shell), tip: "" })
    out.push({ ctl: CSbWidth, rect: sidebar_resizer(shell), tip: "调整宽度" })
  }
  // Window chrome: min/max/close of every visible window, in paint order so the
  // raised window's controls are found first.
  for win in visible_windows(model) {
    let frame = win_px(win, shell)
    let chrome = win_chrome(frame)
    out.push({ ctl: CWinMin(win.id), rect: chrome.min, tip: "最小化" })
    out.push({ ctl: CWinMax(win.id), rect: chrome.max, tip: "最大化" })
    out.push({ ctl: CWinClose(win.id), rect: chrome.close, tip: "关闭" })
  }
  // Dock rail: five panels.
  let docks = dock_slots(shell)
  let dock_tips = ["面板", "终端", "Git", "诊断", "Agent"]
  let mut d = 0
  while d < docks.length() {
    out.push({ ctl: CDock(d), rect: docks[d], tip: dock_tips[d] })
    d = d + 1
  }
  out
}

///|
/// Topmost control under the point. Zero-sized rects (a tier hidden by a narrow
/// window) never hit, matching "paint nothing, click nothing".
pub fn ctl_hit(list : Array[CtlRec], x : Double, y : Double) -> Ctl {
  let mut i = list.length() - 1
  while i >= 0 {
    let rec = list[i]
    if rec.rect.w > 0.0 && rec.rect.h > 0.0 && rec.rect.contains(x, y) {
      return rec.ctl
    }
    i = i - 1
  }
  CNone
}

///|
pub fn ctl_rect(list : Array[CtlRec], want : Ctl) -> RectD? {
  let mut found : RectD? = None
  for rec in list {
    if rec.ctl == want && found is None {
      found = Some(rec.rect)
    }
  }
  found
}

///|
pub fn ctl_tip(list : Array[CtlRec], want : Ctl) -> String {
  let mut text = ""
  for rec in list {
    if rec.ctl == want && text == "" {
      text = rec.tip
    }
  }
  text
}

///|
/// Controls the keyboard ring visits. Sidebar rows and the two resize bands are
/// pointer-only, like a list whose rows are not tab stops; every actual button
/// of the chrome is reachable.
fn focusable(ctl : Ctl) -> Bool {
  match ctl {
    CNone => false
    CSb(_) => false
    CSbWidth => false
    CSbSplit => false
    _ => true
  }
}

///|
/// The same list, filtered to keyboard stops, in paint order.
pub fn focus_list(model : Model, shell : Shell) -> Array[CtlRec] {
  let out : Array[CtlRec] = []
  for rec in controls(model, shell) {
    if focusable(rec.ctl) && rec.rect.w > 0.0 && rec.rect.h > 0.0 {
      out.push(rec)
    }
  }
  out
}

///|
fn shell_of(model : Model) -> Shell {
  let (w, h) = frame_size(model)
  shell_layout(w, h, model.sidebar_open, sidebar_w=model.sidebar_w)
}

///|
/// The frame the shell is drawn in. `update` keeps `frame_w`/`frame_h` from the
/// last pointer event, but keyboard input arrives without one; the paint pass
/// stashes the size it actually painted at, so both paths agree even after the
/// window is resized.
pub fn frame_size(model : Model) -> (Double, Double) {
  let w = paint_frame_w.val
  let h = paint_frame_h.val
  if w > 0.0 && h > 0.0 {
    (w, h)
  } else {
    (model.frame_w, model.frame_h)
  }
}

///|
/// Move the focus ring along the control list. Tab wraps; Shift-Tab walks back.
/// The ring is keyboard-only (`focus_kb`), so a pointer press never leaves one.
pub fn focus_step(model : Model, d : Int) -> Model {
  let list = focus_list(model, shell_of(model))
  let n = list.length()
  if n == 0 {
    return model
  }
  let mut idx = -1
  let mut i = 0
  for rec in list {
    if rec.ctl == model.focus_ctl && idx < 0 {
      idx = i
    }
    i = i + 1
  }
  let next = if idx < 0 {
    if d < 0 { n - 1 } else { 0 }
  } else {
    let raw = (idx + d) % n
    if raw < 0 {
      raw + n
    } else {
      raw
    }
  }
  {
    ..model,
    focus_ctl: list[next].ctl,
    focus_rect: list[next].rect,
    focus_kb: true,
  }
}

///|
/// Enter/Space on the ring: the same activation path a click takes.
pub fn focus_activate(model : Model) -> Model {
  if model.focus_ctl == CNone {
    return model
  }
  let shell = shell_of(model)
  let hit = model.focus_ctl
  let next = activate_ctl(model, shell, hit)
  // Keep the ring only where the control still exists after the action, so
  // closing a window does not leave a ring floating over the canvas.
  match ctl_rect(controls(next, shell), hit) {
    Some(r) => { ..next, focus_rect: r, }
    None => focus_clear(next)
  }
}

///|
pub fn focus_clear(model : Model) -> Model {
  { ..model, focus_ctl: CNone, focus_kb: false, }
}

///|
/// The keyboard activation table. Pointer clicks keep their existing per-region
/// handlers; this maps the ids those regions expose so Tab ⏎ and a click do the
/// same thing.
pub fn activate_ctl(model : Model, shell : Shell, ctl : Ctl) -> Model {
  match ctl {
    CNav(0) => { ..model, sidebar_open: !model.sidebar_open, }
    CNav(1) => go_route(model, model.back_route)
    CNav(2) => model
    CNav(_) => model
    CClusterPanel => { ..model, sidebar_open: !model.sidebar_open, }
    CClusterMoon => { ..model, dark: !model.dark, }
    CClusterSliders | CClusterCompact => {
      let next = if model.density >= 2 { 0 } else { model.density + 1 }
      { ..model, density: next, }
    }
    CClusterHome => go_route(model, Home)
    CPlusTab => new_conversation_window(model, model.current_thread, "新对话")
    CTab(id) => raise_window(model, id)
    CTabClose(id) => close_window(model, id)
    CRail(i) => {
      let routes = rail_routes()
      if i >= 0 && i < routes.length() {
        go_route(model, routes[i])
      } else {
        model
      }
    }
    CRailHandle => { ..model, sidebar_open: !model.sidebar_open, }
    CSb(i) => {
      let slots = sidebar_slots(model, shell)
      if i >= 0 && i < slots.length() {
        sidebar_down(model, slots[i])
      } else {
        model
      }
    }
    CSbWidth | CSbSplit => model
    CDock(i) => { ..model, dock_tab: i, }
    CWinMin(id) => minimize_window(model, id)
    CWinMax(id) => toggle_maximize(model, id)
    CWinClose(id) => close_window(model, id)
    CPageBack => go_route(model, model.back_route)
    CPageTheme => { ..model, dark: !model.dark, }
    CPageNav(i) => {
      let routes = page_nav_routes()
      if i >= 0 && i < routes.length() {
        go_route(model, routes[i])
      } else {
        model
      }
    }
    CNone => model
  }
}

///|
/// Pointer-down bookkeeping: which control went down, where it is, and the
/// paint clock. Activation still happens on the down event, exactly like the
/// existing per-region handlers, so the feedback never delays the click.
pub fn press_begin(model : Model, list : Array[CtlRec], x : Double, y : Double) -> Model {
  let ctl = ctl_hit(list, x, y)
  match ctl_rect(list, ctl) {
    Some(r) => {
      {
        ..model,
        press_ctl: ctl,
        press_rect: r,
        press_down: true,
        press_at: paint_now.val,
        press_up: 0.0,
        focus_kb: false,
      }
    }
    None => { ..model, press_ctl: CNone, press_down: false, focus_kb: false }
  }
}

///|
/// Keep the press feedback only while its control still exists. Closing a tab
/// removes the control in the same event, and a ring must not outlive it; a rect
/// that moved (a layout preset, a window raise) is refreshed to the new one.
pub fn press_prune(model : Model, shell : Shell) -> Model {
  if model.press_ctl == CNone {
    return model
  }
  match ctl_rect(controls(model, shell), model.press_ctl) {
    Some(r) => {
      if r.x == model.press_rect.x && r.y == model.press_rect.y && r.w == model.press_rect.w && r.h == model.press_rect.h {
        model
      } else {
        { ..model, press_rect: r }
      }
    }
    None => { ..model, press_ctl: CNone, press_down: false }
  }
}

///|
/// Pointer-up: hold the last rect for `TACTILE_MS` while the push decays. The
/// painter reads `press_up` for the fade, so the frame after the click still
/// shows it.
pub fn press_release(model : Model) -> Model {
  if !model.press_down {
    return model
  }
  { ..model, press_down: false, press_up: paint_now.val }
}

///|
/// How strongly the press still reads: full while the pointer is down, then a
/// linear decay over `--dur-tactile` (80ms) after release so the frame that
/// follows a click still shows it.
pub fn press_alpha(model : Model) -> Double {
  let now = paint_now.val
  if model.press_down {
    return 1.0
  }
  let age = now - model.press_up
  if age >= TACTILE_MS {
    0.0
  } else {
    1.0 - (age / TACTILE_MS).max(0.0)
  }
}

///|
/// Dwell bookkeeping. A new target restarts the 500ms timer; staying on the
/// same control keeps it running, so a sweep across buttons never flashes a
/// tip. `tip_text` is latched here so the bubble still reads if the control is
/// repainted without its label.
pub fn hover_tip(model : Model, list : Array[CtlRec], x : Double, y : Double) -> Model {
  let ctl = ctl_hit(list, x, y)
  if ctl == CNone {
    return tip_clear(model)
  }
  let text = ctl_tip(list, ctl)
  if text == "" {
    return tip_clear(model)
  }
  if ctl == model.tip_ctl {
    return model
  }
  match ctl_rect(list, ctl) {
    Some(r) => {
      { ..model, tip_ctl: ctl, tip_rect: r, tip_start: paint_now.val, tip_text: text }
    }
    None => tip_clear(model)
  }
}

///|
pub fn tip_clear(model : Model) -> Model {
  if model.tip_ctl == CNone && model.tip_text == "" {
    return model
  }
  { ..model, tip_ctl: CNone, tip_text: "" }
}

///|
/// 0 before the delay, then a 120ms `--motion-fade` in.
pub fn tip_alpha(model : Model) -> Double {
  if model.tip_ctl == CNone || model.tip_text == "" {
    return 0.0
  }
  let age = paint_now.val - model.tip_start - TIP_DELAY_MS
  if age <= 0.0 {
    0.0
  } else {
    ease_out((age / TIP_FADE_MS).min(1.0))
  }
}

///|
/// The toast half of `ToastHost`: arrive on `--dur-slower`, leave on
/// `--dur-slow`, hold `SHOW_MS` from mount. Leave starts at `toast_end`.
pub fn toast_show(model : Model, text : String) -> Model {
  if text == "" {
    return model
  }
  let now = paint_now.val
  {
    ..model,
    toast_text: text,
    toast_start: now,
    toast_end: now + TOAST_HOLD_MS,
  }
}

///|
pub fn toast_live(model : Model) -> Bool {
  toast_live_at(model, paint_now.val)
}

///|
/// Same window, read at a given clock: `needs_frames_at` samples the clock the
/// runtime is about to paint with, not the one the last frame left behind.
pub fn toast_live_at(model : Model, now : Double) -> Bool {
  model.toast_text != "" && now < model.toast_end + TOAST_OUT_MS
}

///|
/// Opacity over arrive → hold → leave.
pub fn toast_alpha(model : Model) -> Double {
  let now = paint_now.val
  if model.toast_text == "" {
    return 0.0
  }
  if now < model.toast_end {
    let age = now - model.toast_start
    if age < TOAST_IN_MS {
      ease_out((age / TOAST_IN_MS).max(0.0))
    } else {
      1.0
    }
  } else if now < model.toast_end + TOAST_OUT_MS {
    1.0 - ease_in(((now - model.toast_end) / TOAST_OUT_MS).min(1.0))
  } else {
    0.0
  }
}

///|
/// Vertical travel: a notice rises 12px in from the bottom edge and drifts 8px
/// back out on leave (`--shift-md`, `--shift-sm`).
pub fn toast_lift(model : Model) -> Double {
  let now = paint_now.val
  if model.toast_text == "" {
    return 0.0
  }
  if now < model.toast_end {
    let age = now - model.toast_start
    if age < TOAST_IN_MS {
      12.0 * (1.0 - ease_out((age / TOAST_IN_MS).max(0.0)))
    } else {
      0.0
    }
  } else if now < model.toast_end + TOAST_OUT_MS {
    8.0 * ease_in(((now - model.toast_end) / TOAST_OUT_MS).min(1.0))
  } else {
    0.0
  }
}

///|
/// Whether the paint pass must ask the host for another frame. Timestamps come
/// from the paint clock, so this is a pure read of the same values the painters
/// use — an idle shell with the pointer off every control stops ticking instead
/// of painting forever.
pub fn needs_frames(model : Model) -> Bool {
  needs_frames_at(model, paint_now.val)
}

///|
/// The same read at an explicit clock. The canvas calls this from inside its
/// paint with the runtime's own `now_ms`, so the answer is re-evaluated on every
/// frame: a press decay ends by itself instead of leaving the redraw loop alive
/// until some unrelated event rebuilds the view.
pub fn needs_frames_at(model : Model, now : Double) -> Bool {
  if model.press_down {
    return true
  }
  // A press that is decaying still owns its rect; an idle model (no control)
  // never asks for frames even at clock zero.
  if model.press_ctl != CNone && now - model.press_up < TACTILE_MS {
    return true
  }
  if model.tip_ctl != CNone && model.tip_text != "" {
    let age = now - model.tip_start
    if age < TIP_DELAY_MS + TIP_FADE_MS {
      return true
    }
  }
  if toast_live_at(model, now) {
    return true
  }
  if model.modal != MNone && now - model.modal_open < SHEET_IN_MS {
    return true
  }
  if model.modal_leaving != MNone && now - model.modal_close < SHEET_OUT_MS {
    return true
  }
  false
}

// ---------------------------------------------------------------------------
// Modal sheet. 480 wide, 12vh from the top, `.modal` shell: 10px radius,
// 16/20 head, 12/20 body, 12/20/16 foot with 28px buttons.

///|
pub const MODAL_W : Double = 480.0

///|
pub const MODAL_CONFIRM_H : Double = 144.0

///|
pub const MODAL_RENAME_H : Double = 162.0

///|
pub const MODAL_SHORTCUTS_H : Double = 260.0

///|
/// The dialog that owns the app, or the one still leaving (its shell has to be
/// painted for the leave animation).
pub fn modal_kind(model : Model) -> ModalKind {
  if model.modal != MNone {
    model.modal
  } else {
    model.modal_leaving
  }
}

///|
pub fn modal_height(kind : ModalKind) -> Double {
  match kind {
    MConfirm => MODAL_CONFIRM_H
    MRename => MODAL_RENAME_H
    MShortcuts => MODAL_SHORTCUTS_H
    MNone => 0.0
  }
}

///|
/// Untransformed sheet rect: what the pointer hits while the dialog is open.
pub fn modal_box(model : Model, w : Double, h : Double) -> RectD {
  let kind = modal_kind(model)
  let mw = MODAL_W.min((w - 48.0).max(200.0))
  let mh = modal_height(kind)
  let top = (h * 0.12).min((h - mh - 24.0).max(0.0))
  RectD::new(x=(w - mw) / 2.0, y=top, w=mw, h=mh)
}

///|
pub struct ModalBtns {
  cancel : RectD
  confirm : RectD
  has_cancel : Bool
}

///|
fn btn_width(label : String) -> Double {
  (ctl_chars(label).to_double() * 12.0 + 20.0).max(44.0)
}

///|
/// Footer buttons, right-aligned with an 8px gap. Shortcuts has a single
/// primary "关闭"; the other two a cancel + primary pair.
pub fn modal_buttons(model : Model, sheet : RectD) -> ModalBtns {
  let kind = modal_kind(model)
  let (cancel_label, confirm_label) = match kind {
    MConfirm => ("取消", "重置布局")
    MRename => ("取消", "重命名")
    MShortcuts => ("", "关闭")
    MNone => ("", "")
  }
  let bh = 28.0
  let by = sheet.bottom() - 16.0 - bh
  let cw = btn_width(confirm_label)
  let confirm = RectD::new(x=sheet.right() - 20.0 - cw, y=by, w=cw, h=bh)
  let has_cancel = cancel_label != ""
  let cancel = if has_cancel {
    let w = btn_width(cancel_label)
    RectD::new(x=confirm.x - 8.0 - w, y=by, w~, h=bh)
  } else {
    RectD::new(x=0.0, y=0.0, w=0.0, h=0.0)
  }
  { cancel, confirm, has_cancel }
}

///|
/// Keyboard focus inside a dialog: 0 is the primary button, 1 the cancel button
/// when the dialog has one. Tab walks them; Enter runs the focused one, which is
/// how a reader backs out with the keyboard alone.
pub fn modal_has_cancel(model : Model) -> Bool {
  let (w, h) = frame_size(model)
  modal_buttons(model, modal_box(model, w, h)).has_cancel
}

///|
pub fn modal_focus_step(model : Model, d : Int) -> Model {
  // The rename dialog has three stops in reading order: field, cancel, primary.
  // The other two start on their primary, so Tab only walks the footer.
  if model.modal == MRename {
    let idx = match model.modal_focus {
      2 => 0
      1 => 1
      _ => 2
    }
    let raw = (idx + d) % 3
    let next = if raw < 0 { raw + 3 } else { raw }
    {
      ..model,
      modal_focus: match next {
        0 => 2
        1 => 1
        _ => 0
      },
    }
  } else {
    let count = if modal_has_cancel(model) { 2 } else { 1 }
    let raw = (model.modal_focus + d) % count
    let next = if raw < 0 { raw + count } else { raw }
    { ..model, modal_focus: next }
  }
}

///|
/// Title of the raised window, which the rename dialog starts from and writes
/// back to both the window and its thread.
fn active_title(model : Model) -> String {
  for win in model.windows {
    if win.id == model.active {
      return win.title
    }
  }
  ""
}

///|
/// Input field inside the rename dialog. It is the dialog's first Tab stop
/// (`modal_focus = 2`), and the caret lives in it while the sheet is open.
pub fn modal_input_rect(sheet : RectD) -> RectD {
  RectD::new(x=sheet.x + 20.0, y=sheet.y + 48.0, w=(sheet.w - 40.0).max(1.0), h=32.0)
}

///|
pub fn modal_open_now(model : Model, kind : ModalKind) -> Model {
  if kind == MNone {
    return model
  }
  {
    ..model,
    modal: kind,
    modal_leaving: MNone,
    modal_open: paint_now.val,
    modal_close: 0.0,
    // The rename field starts on the current title so it is edited, not
    // retyped; the two dialogs with a footer start on their primary button.
    modal_input: if kind == MRename { active_title(model) } else { "" },
    // The rename dialog opens in its text field, like the reference's
    // `autoFocus`; the other two open on their primary button.
    modal_focus: if kind == MRename { 2 } else { 0 },
    palette_open: false,
    palette_query: "",
    palette_index: 0,
    palette_scroll: 0.0,
    tip_ctl: CNone,
    tip_text: "",
    press_ctl: CNone,
    press_down: false,
  }
}

///|
/// Start the leave animation. The kind is kept in `modal_leaving`, so the sheet
/// still paints (fading) after `modal` no longer owns the app.
pub fn modal_close_now(model : Model) -> Model {
  if model.modal == MNone {
    return model
  }
  {
    ..model,
    modal_leaving: model.modal,
    modal: MNone,
    modal_close: paint_now.val,
  }
}

///|
/// Backdrop opacity factor: fade in over 120ms, fade out over 120ms.
pub fn modal_fade(model : Model) -> Double {
  let now = paint_now.val
  if model.modal != MNone {
    ease_out(((now - model.modal_open) / 120.0).min(1.0).max(0.0))
  } else if model.modal_leaving != MNone {
    1.0 - ease_in(((now - model.modal_close) / SHEET_OUT_MS).min(1.0).max(0.0))
  } else {
    0.0
  }
}

///|
/// Sheet scale and vertical drift: 0.98 → 1 rising 8px on open, reversing on
/// leave. Returns `(scale, dy)`.
pub fn modal_motion(model : Model) -> (Double, Double) {
  let now = paint_now.val
  if model.modal != MNone {
    let t = ease_out(((now - model.modal_open) / SHEET_IN_MS).min(1.0).max(0.0))
    (0.98 + 0.02 * t, 8.0 * (1.0 - t))
  } else if model.modal_leaving != MNone {
    let t = ease_in(((now - model.modal_close) / SHEET_OUT_MS).min(1.0).max(0.0))
    (1.0 - 0.02 * t, 4.0 * t)
  } else {
    (1.0, 0.0)
  }
}

///|
fn rename_current(model : Model, name : String) -> Model {
  let trimmed = name.trim().to_string()
  if trimmed == "" {
    return model
  }
  let ws = copy_windows(model)
  let threads : Array[Thread] = []
  let mut thread_idx = -1
  for win in ws {
    if win.id == model.active {
      thread_idx = win.thread
    }
  }
  let mut i = 0
  for thread in model.threads {
    if i == thread_idx {
      threads.push({ ..thread, title: trimmed })
    } else {
      threads.push(thread)
    }
    i = i + 1
  }
  let mut j = 0
  for win in ws {
    if win.id == model.active {
      ws[j] = { ..win, title: trimmed }
    }
    j = j + 1
  }
  { ..model, windows: ws, threads, }
}

///|
/// Enter / the primary button. Rename applies the buffer, confirm resets the
/// layout, shortcuts only closes; every path ends in the leave animation and a
/// toast reporting what happened.
pub fn modal_confirm(model : Model) -> Model {
  let kind = model.modal
  if kind == MNone {
    return model
  }
  // Tab moved the highlight to the cancel button: Enter is its click. The
  // rename field (2) and the primary (0) both commit.
  if model.modal_focus == 1 && modal_has_cancel(model) {
    return modal_close_now(model)
  }
  let (next, note) = match kind {
    MConfirm => (apply_preset(model, SplitEven), "布局已恢复默认排布")
    MRename => {
      let name = model.modal_input.trim().to_string()
      if name == "" {
        (model, "")
      } else {
        (rename_current(model, name), "已重命名为 " + name)
      }
    }
    MShortcuts => (model, "")
    MNone => (model, "")
  }
  let closed = modal_close_now(next)
  if note == "" {
    closed
  } else {
    toast_show(closed, note)
  }
}

///|
/// Pointer while a dialog owns the app: the sheet and its buttons are the only
/// targets; a click on the backdrop dismisses it, as in the reference.
pub fn modal_pointer(model : Model, pm : PointerMsg) -> Model {
  if model.modal == MNone {
    return model
  }
  let sheet = modal_box(model, pm.w, pm.h)
  let buttons = modal_buttons(model, sheet)
  if pm.phase == 2 {
    if buttons.confirm.contains(pm.x, pm.y) {
      if model.modal_focus != 0 {
        return { ..model, modal_focus: 0 }
      }
    } else if buttons.has_cancel && buttons.cancel.contains(pm.x, pm.y) {
      if model.modal_focus != 1 {
        return { ..model, modal_focus: 1 }
      }
    }
    return model
  }
  if pm.phase != 0 {
    return model
  }
  // A click on the backdrop dismisses the sheet; inside it only the footer
  // buttons act, exactly as in the reference.
  if !sheet.contains(pm.x, pm.y) {
    return modal_close_now(model)
  }
  if model.modal == MRename && modal_input_rect(sheet).contains(pm.x, pm.y) {
    return { ..model, modal_focus: 2 }
  }
  if buttons.confirm.contains(pm.x, pm.y) {
    return modal_confirm({ ..model, modal_focus: 0 })
  }
  if buttons.has_cancel && buttons.cancel.contains(pm.x, pm.y) {
    return modal_close_now(model)
  }
  model
}

// ---------------------------------------------------------------------------
// Motion. The reference's `--ease-out` and `--ease-in` are cubic Béziers; the
// canvas paints frames, so the curve is solved on the x axis by bisection (the
// x axis is monotonic) and the y is read at that parameter.

///|
fn bezier_axis(s : Double, p1 : Double, p2 : Double) -> Double {
  let u = 1.0 - s
  3.0 * u * u * s * p1 + 3.0 * u * s * s * p2 + s * s * s
}

///|
fn cubic_bezier(t : Double, x1 : Double, y1 : Double, x2 : Double, y2 : Double) -> Double {
  let x = t.min(1.0).max(0.0)
  let mut lo = 0.0
  let mut hi = 1.0
  let mut s = x
  let mut i = 0
  while i < 24 {
    if bezier_axis(s, x1, x2) < x {
      lo = s
    } else {
      hi = s
    }
    s = (lo + hi) / 2.0
    i = i + 1
  }
  bezier_axis(s, y1, y2)
}

///|
/// `--ease-out: cubic-bezier(0.16, 0.84, 0.44, 1)`.
pub fn ease_out(t : Double) -> Double {
  cubic_bezier(t, 0.16, 0.84, 0.44, 1.0)
}

///|
/// `--ease-in: cubic-bezier(0.5, 0, 0.75, 0)`.
pub fn ease_in(t : Double) -> Double {
  cubic_bezier(t, 0.5, 0.0, 0.75, 0.0)
}
