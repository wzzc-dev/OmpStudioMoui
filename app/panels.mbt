// Painted sections below the shell: the session sidebar, the floating windows
// (conversation / plan review / managed browser) and the canvas overlays
// (minimised capsules, snap picker, snap preview).

// ---------------------------------------------------------------------------
// Small text helpers used by every panel below.

///|
fn label(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  s : String,
  x : Double,
  y : Double,
  h : Double,
  size : Double,
  weight : Int32,
  color : @graphics.Color,
) -> Unit {
  let f = font_ui(size, weight)
  put_at(ctx, ts, s, f, color, x, y, h, 0.0)
}

///|
fn label_in(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  s : String,
  x : Double,
  y : Double,
  h : Double,
  max_w : Double,
  size : Double,
  weight : Int32,
  color : @graphics.Color,
) -> Unit {
  put_at(ctx, ts, s, font_ui(size, weight), color, x, y, h, max_w)
}

///|
fn label_right(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  s : String,
  right : Double,
  y : Double,
  h : Double,
  size : Double,
  weight : Int32,
  color : @graphics.Color,
) -> Unit {
  let f = font_ui(size, weight)
  let w = text_width(ts, s, f)
  put_r(ctx, rect(right - w, y, w, h), s, f, color)
}

///|
fn pill(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  r : RectD,
  s : String,
  fg : @graphics.Color,
  bg : @graphics.Color,
  size : Double,
) -> Unit {
  chip(ctx, ts, r, s, fg, bg, bg, size)
}

///|
fn status_chip(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  r : RectD,
  status : ThreadStatus,
  p : Palette,
) -> Unit {
  let c = status.color(p)
  chip(ctx, ts, r, status.label(), c, c.with_alpha(0.16), c.with_alpha(0.0), 9.5)
}

///|
fn bubble_fg(p : Palette) -> @graphics.Color {
  if p.dark {
    @graphics.Color::rgba(r=1.0, g=1.0, b=1.0)
  } else {
    solid(0x2a, 0x20, 0x4a)
  }
}

// ---------------------------------------------------------------------------
// Sidebar

///|
pub fn paint_sidebar(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  model : Model,
  shell : Shell,
  p : Palette,
) -> Unit {
  let r = shell.sidebar
  if r.w <= 1.0 {
    return
  }
  fill(ctx, rect_of(r), p.bg_inset)
  hair(ctx, r.right(), r.y, r.right(), r.bottom(), p.border)
  paint_sb_footer(ctx, ts, model, shell, p)
  clip_rect(ctx, rect_of(r))
  for slot in sidebar_slots(model, shell) {
    let s = slot.rect
    let hoverable = match slot.kind {
      SbNewThread => true
      SbSkills => true
      SbProject(_) => true
      SbThread(_) => true
      SbExpandMore => true
      SbFile(_) => true
      _ => false
    }
    if hoverable && hovering(model, s) {
      round_fill(ctx, rect_of(s), 8.0, p.surface_2.with_alpha(0.7))
    }
    match slot.kind {
      SbBrand => paint_sb_brand(ctx, ts, model, s, p)
      SbNewThread => paint_sb_nav(ctx, ts, s, "plus", "新建对话", "Ctrl ↑ O", p, false)
      SbSkills => paint_sb_nav(ctx, ts, s, "sparkles", "技能&插件", "5", p, true)
      SbSectionProjects => section_head(ctx, ts, s.x + 6.0, s.y + 8.0, s.w, "项目与对话", p)
      SbProject(i) => paint_sb_project(ctx, ts, model, s, i, p)
      SbThread(i) => paint_sb_thread(ctx, ts, model, s, i, p)
      SbExpandMore => paint_sb_more(ctx, ts, s, 7, p)
      SbSectionExplorer => {
        // Hairline on the 46/54 split between the project list and Explorer.
        hair(ctx, s.x, s.y - 6.5, s.x + s.w, s.y - 6.5, p.border)
        icon(ctx, "chevron-down", rect(s.x + 4.0, s.y + 8.0, 14.0, 14.0), 11.0, p.text_3, 1.6)
        section_head(ctx, ts, s.x + 22.0, s.y + 8.0, s.w, "Explorer", p)
        icon(ctx, "ellipsis", rect(s.right() - 24.0, s.y + 8.0, 16.0, 14.0), 12.0, p.text_3, 1.6)
      }
      SbFile(i) => paint_sb_file(ctx, ts, model, s, i, p)
      SbFooter => ()
    }
  }
  unclip_rect(ctx)
}

///|
fn paint_sb_brand(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  model : Model,
  r : RectD,
  p : Palette,
) -> Unit {
  ignore(model)
  // Collapse control, then the white brand disc, then the title: the same three
  // pieces the reference sidebar header shows at this width.
  icon(ctx, "menu", rect(r.x + 8.0, r.y + 3.5, 16.0, 16.0), 14.0, p.text_2, 1.7)
  let mark = RectD::new(x=r.x + 39.0, y=r.y + 1.5, w=20.0, h=20.0)
  brand_mark(
    ctx,
    mark,
    p.accent,
    if p.dark { solid(0xf2, 0xf1, 0xf6) } else { p.on_accent },
  )
  label(ctx, ts, "OMP Studio", r.x + 66.0, r.y + 0.2, 22.0, 14.0, 600, p.text)
  let search = RectD::new(x=r.right() - 31.0, y=r.y + 3.5, w=16.0, h=16.0)
  icon(ctx, "search", rect_of(search), 14.0, p.text_3, 1.6)
}

///|
fn paint_sb_nav(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  r : RectD,
  glyph : String,
  title : String,
  tail : String,
  p : Palette,
  badge : Bool,
) -> Unit {
  icon(ctx, glyph, rect(r.x + 14.0, r.y + 7.0, 16.0, 16.0), 14.0, p.text_3, 1.6)
  label(ctx, ts, title, r.x + 38.0, r.y + 5.0, 20.0, 12.0, 500, p.text)
  if badge {
    // Skills row: count badge, then the drill-in chevron that the reference
    // keeps at the very right edge of the row.
    let bw = (text_width(ts, tail, font_ui(11.0, 600)) + 12.0).max(18.0)
    let br = RectD::new(x=r.right() - 26.0 - bw, y=r.y + 6.0, w=bw, h=18.0)
    round_fill(ctx, rect_of(br), 9.0, p.accent.with_alpha(0.22))
    put_c(ctx, rect_of(br), tail, font_ui(11.0, 600), p.accent)
    icon(ctx, "chevron-right", rect(r.right() - 20.0, r.y + 9.0, 20.0, 12.0), 11.0, p.text_faint, 1.6)
  } else {
    label_right(ctx, ts, tail, r.right() - 10.0, r.y + 6.0, 16.0, 10.5, 500, p.text_faint)
  }
}

///|
fn paint_sb_project(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  model : Model,
  r : RectD,
  index : Int,
  p : Palette,
) -> Unit {
  ignore(model)
  if index < 0 || index >= model.projects.length() {
    return
  }
  let project = model.projects[index]
  // The reference project row is one line: folder icon, name, then the live
  // count as a green dot plus a number. The collapse chevron only replaces the
  // folder on hover, and the branch/diff badges live in the Explorer header,
  // not here — so neither is painted in the resting state. Projects that are
  // not the current one carry their branch in parentheses after the name.
  icon(ctx, "folder", rect(r.x + 8.0, r.y + 7.0, 14.0, 14.0), 12.0, p.text_3, 1.7)
  let name = if project.branch != "" && !project.current {
    "\{project.name} (\{project.branch})"
  } else {
    project.name
  }
  label(
    ctx,
    ts,
    name,
    r.x + 28.0,
    r.y + 4.0,
    20.0,
    12.0,
    600,
    if project.current { p.text } else { p.text_2 },
  )
  if project.count > 0 {
    let count = "\{project.count}"
    let cw = text_width(ts, count, font_ui(10.5, 500))
    label_right(ctx, ts, count, r.right() - 8.0, r.y + 6.0, 16.0, 10.5, 500, p.text_3)
    dot(ctx, r.right() - 8.0 - cw - 9.0, r.y + r.h / 2.0, 6.0, p.green)
  }
}

///|
fn paint_sb_thread(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  model : Model,
  r : RectD,
  index : Int,
  p : Palette,
) -> Unit {
  if index < 0 || index >= model.threads.length() {
    return
  }
  let thread = model.threads[index]
  let selected = thread.id == model.current_thread
  if selected {
    round_fill(ctx, rect(r.x + 4.0, r.y + 1.0, r.w - 8.0, r.h - 2.0), 6.0, p.accent_soft)
  }
  // The 14px gutter before the title is the folder slot the project row uses;
  // it only carries a marker while the thread is running, so titles stay
  // left-aligned with the project name whether or not the thread is busy.
  let running = thread.status == Running
  let idle = thread.status == Idle
  if running {
    round_stroke(
      ctx,
      rect(r.x + 10.0, r.y + r.h / 2.0 - 5.0, 10.0, 10.0),
      5.0,
      if selected { p.accent } else { p.text_3 },
      1.5,
    )
  }
  // Right cluster: a wait capsule replaces the timestamp (reference never shows
  // both), and only unselected rows carry an unread count.
  let has_chip = !running && !idle
  let chip_label = if has_chip { thread.status.label() } else { "" }
  let chip_w = if has_chip {
    text_width(ts, chip_label, font_ui(10.5, 500)) + 12.0
  } else {
    0.0
  }
  let chip_x = r.right() - 8.0 - chip_w
  let has_unread = thread.unread > 0 && !selected && !has_chip
  let dot_w = if has_unread { 16.0 } else { 0.0 }
  let title_x = r.x + 28.0
  let title_right = if has_chip {
    chip_x - 6.0
  } else if has_unread {
    chip_x - 10.0 - dot_w
  } else {
    r.right() - 8.0
  }
  let title_w = (title_right - title_x).max(24.0)
  let title_color = if selected { p.accent } else { p.text }
  let title = ellipsize(ts, thread.title, font_ui(12.0, 500), title_w)
  label(ctx, ts, title, title_x, r.y + 3.5, 20.0, 12.0, 500, title_color)
  if has_chip {
    status_chip(ctx, ts, RectD::new(x=chip_x, y=r.y + 6.0, w=chip_w, h=16.0), thread.status, p)
  } else if has_unread {
    badge_dot(
      ctx,
      ts,
      RectD::new(x=r.right() - 8.0 - 16.0, y=r.y + 6.0, w=16.0, h=15.0),
      "\{thread.unread}",
      p.accent,
    )
  } else if !running {
    label_right(ctx, ts, thread.when, r.right() - 8.0, r.y + 5.0, 16.0, 10.5, 500, p.text_faint)
  }
  ignore(thread.pinned)
  ignore(thread.sub)
}

///|
fn paint_sb_more(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  r : RectD,
  n : Int,
  p : Palette,
) -> Unit {
  // 「展开更多」sits on the same title column as the thread rows it reveals.
  icon(ctx, "chevron-down", rect(r.x + 8.0, r.y + 5.0, 14.0, 14.0), 11.0, p.text_faint, 1.6)
  label(ctx, ts, "展开 +\{n}", r.x + 28.0, r.y + 3.0, 18.0, 10.5, 500, p.text_faint)
}

///|
fn file_color(name : String, p : Palette) -> @graphics.Color {
  if name.ends_with(".tsx") || name.ends_with(".jsx") {
    p.blue
  } else if name.ends_with(".ts") || name.ends_with(".js") {
    p.accent
  } else if name.ends_with(".json") {
    p.amber
  } else if name.ends_with(".md") {
    p.green
  } else {
    p.text_3
  }
}

///|
fn paint_sb_file(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  model : Model,
  r : RectD,
  index : Int,
  p : Palette,
) -> Unit {
  if index < 0 || index >= model.files.length() {
    return
  }
  let file = model.files[index]
  let x = r.x + 8.0 + file.depth.to_double() * 12.0
  if file.folder {
    icon(
      ctx,
      if file.expanded { "chevron-down" } else { "chevron-right" },
      rect(x, r.y + 6.0, 12.0, 12.0),
      9.5,
      p.text_faint,
      1.7,
    )
    icon(ctx, "folder", rect(x + 12.0, r.y + 5.0, 14.0, 14.0), 11.5, p.text_3, 1.6)
    label(ctx, ts, file.name, x + 30.0, r.y + 3.0, 18.0, 11.0, 500, p.text_2)
  } else {
    let c = file_color(file.name, p)
    icon(ctx, "file", rect(x + 12.0, r.y + 5.0, 14.0, 14.0), 11.0, c, 1.5)
    let name_color = if file.added { p.green } else if file.modified { p.amber } else { p.text_2 }
    let nw = text_width(ts, file.name, font_ui(11.0, 500))
    label(ctx, ts, file.name, x + 30.0, r.y + 3.0, 18.0, 11.0, 500, name_color)
    if file.added {
      label(ctx, ts, "A", x + 32.0 + nw, r.y + 3.0, 18.0, 8.5, 600, p.green)
    } else if file.modified {
      label(ctx, ts, "M", x + 32.0 + nw, r.y + 3.0, 18.0, 8.5, 600, p.amber)
    }
  }
}

///|
fn paint_sb_footer(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  model : Model,
  shell : Shell,
  p : Palette,
) -> Unit {
  ignore(model)
  let r = RectD::new(
    x=shell.sidebar.x,
    y=shell.sidebar.bottom() - 44.0,
    w=shell.sidebar.w,
    h=44.0,
  )
  fill(ctx, rect_of(r), p.bg_inset)
  hair(ctx, r.x, r.y, r.right(), r.y, p.border)
  let av = RectD::new(x=r.x + 12.0, y=r.y + 8.0, w=26.0, h=26.0)
  avatar(ctx, av.x + av.w / 2.0, av.y + av.h / 2.0, 26.0, p.accent, "Z", ts, p)
  label(ctx, ts, "Zc", r.x + 46.0, r.y + 6.0, 18.0, 11.5, 600, p.text)
  label(ctx, ts, "OMP Pro · 在线", r.x + 46.0, r.y + 22.0, 16.0, 9.5, 500, p.text_3)
  dot(ctx, r.right() - 30.0, r.y + 22.0, 6.0, p.green)
  icon(ctx, "settings", rect(r.right() - 26.0, r.y + 8.0, 16.0, 16.0), 13.0, p.text_3, 1.6)
}

// ---------------------------------------------------------------------------
// Canvas windows

///|
pub fn paint_windows(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  model : Model,
  shell : Shell,
  p : Palette,
) -> Unit {
  let vis = visible_windows(model)
  for window in vis {
    if window.id != model.active {
      paint_window(ctx, ts, model, shell, p, window)
    }
  }
  for window in vis {
    if window.id == model.active {
      paint_window(ctx, ts, model, shell, p, window)
    }
  }
  if model.snap_preview != NoZone {
    let zone = model.snap_preview
    let c = shell.canvas
    let nr = zone.rect()
    let r = RectD::new(
      x=c.x + nr.x * c.w + 6.0,
      y=c.y + nr.y * c.h + 6.0,
      w=(nr.w * c.w - 12.0).max(20.0),
      h=(nr.h * c.h - 12.0).max(20.0),
    )
    round_fill(ctx, rect_of(r), 12.0, p.accent.with_alpha(0.12))
    round_stroke(ctx, rect_of(r), 12.0, p.accent.with_alpha(0.6), 1.5)
  }
}

///|
fn paint_window(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  model : Model,
  shell : Shell,
  p : Palette,
  win : WindowRec,
) -> Unit {
  let frame = win_px(win, shell)
  // The reference `.dock-float` stacks two shadows — a wide ambient one and a
  // tight contact one — so a window reads as floating on the flat dark theme
  // without the single heavy halo the tokens rule out.
  shadow(ctx, rect_of(frame), 12.0, rgba8(0, 0, 0, 0.18), 48.0, 16.0)
  shadow(ctx, rect_of(frame), 12.0, rgba8(0, 0, 0, 0.08), 8.0, 2.0)
  round_fill(ctx, rect_of(frame), 12.0, p.window_bg)
  round_stroke(ctx, rect_of(frame), 12.0, p.border_strong, 1.0)
  // Everything the window paints stays inside its frame: narrow layouts shrink
  // their rows instead of letting a footer button bleed onto the canvas.
  clip_round(ctx, rect_of(frame), 12.0)
  match win.kind {
    Conversation => paint_convo(ctx, ts, model, p, win, frame)
    PlanReview => paint_plan(ctx, ts, model, p, win, frame)
    Browser => paint_browser(ctx, ts, model, p, win, frame)
    Terminal => paint_terminal(ctx, ts, model, p, win, frame)
  }
  paint_win_titlebar(ctx, ts, model, p, win, frame)
  unclip(ctx)
}

///|
fn paint_win_titlebar(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  model : Model,
  p : Palette,
  win : WindowRec,
  frame : RectD,
) -> Unit {
  // The source capsule is content-sized, so its text is measured before the bar
  // is laid out: the chrome then gives the capsule exactly that width and puts
  // the status dot right after it.
  let source_label = win_source_label(model, win)
  let source_font = font_ui(10.0, 500)
  let source_w = if source_label == "" {
    0.0
  } else {
    // 5px of padding on each side, matching the reference capsule's `0 5px`.
    text_width(ts, source_label, source_font) + 10.0
  }
  let chrome = win_chrome(frame, source_w~)
  let bar = chrome.bar
  fill(ctx, rect_of(bar), p.window_bg_alt)
  hair(ctx, bar.x, bar.bottom(), bar.right(), bar.bottom(), p.border)
  // Kind tile + title menu.
  round_fill(ctx, rect_of(chrome.icon), 6.0, p.surface_2)
  icon(
    ctx,
    match win.kind {
      Conversation => "message-square"
      PlanReview => "file-check"
      Browser => "globe"
      Terminal => "terminal"
    },
    rect_of(chrome.icon),
    13.0,
    p.accent,
    1.7,
  )
  // Title menu: the label is cut to the room left in the bar and the chevron
  // then trails the drawn text, the way the reference menu auto-sizes instead
  // of pinning the caret to the far edge of a fixed slot.
  let title_font = font_ui(12.0, 500)
  let title_room = (chrome.title.w - 20.0).max(0.0)
  let title_text = ellipsize(ts, win.title, title_font, title_room)
  label_in(
    ctx,
    ts,
    title_text,
    chrome.title.x,
    chrome.title.y + 3.0,
    chrome.title.h - 6.0,
    title_room,
    12.0,
    500,
    p.text,
  )
  icon(
    ctx,
    "chevron-down",
    rect(chrome.title.x + text_width(ts, title_text, title_font) + 5.0, chrome.title.y + 8.0, 11.0, 11.0),
    10.0,
    p.text_3,
    1.8,
  )
  // Source capsule: project · branch, a small surface-2 chip (6px corners, the
  // reference `--r-4`); `win_chrome` already dropped it when the window cannot
  // hold it, so here it only needs to be drawn.
  if source_label != "" && chrome.source.w >= 24.0 {
    round_fill(ctx, rect_of(chrome.source), 6.0, p.surface_2)
    put_c(
      ctx,
      rect_of(chrome.source),
      ellipsize(ts, source_label, source_font, chrome.source.w - 10.0),
      source_font,
      p.text_3,
    )
  }
  // Status dot of the window's thread.
  let mut status = Running
  for thread in model.threads {
    if thread.id == win.thread {
      status = thread.status
    }
  }
  if chrome.status_dot.w > 0.0 {
    dot(ctx, chrome.status_dot.x + 8.0, chrome.status_dot.y + 8.0, 7.0, status.color(p))
  }
  // Time Travel pill.
  chip(
    ctx,
    ts,
    chrome.tt,
    "Time Travel",
    p.text_2,
    p.surface_2,
    p.border_strong,
    8.5,
  )
  // Right control cluster. Every button answers the pointer with the same
  // translucent plate the reference's `.icon-btn:hover` paints, and the close
  // button turns red the way its `is-danger` twin does.
  // The conversation-tools rail is on by default, so its toggle is the
  // accent-soft square the reference paints (`.dock-icon-button.is-active`) —
  // the very same control as the one in the tab strip, not a second panel
  // glyph. Everything to its right stays an icon button.
  round_fill(ctx, rect_of(chrome.dock), 6.0, p.accent_soft)
  tool_list_glyph(
    ctx,
    chrome.dock.x + chrome.dock.w / 2.0,
    chrome.dock.y + chrome.dock.h / 2.0,
    p.accent,
  )
  chrome_button(ctx, model, chrome.more, "ellipsis", 15.0, p)
  chrome_button(ctx, model, chrome.min, "minus", 14.0, p)
  chrome_button(ctx, model, chrome.max, if win.maximized { "copy" } else { "square" }, 12.0, p)
  chrome_button(ctx, model, chrome.close, "x", 13.0, p)
}

///|
/// One window-chrome icon button: the hover plate, then the glyph. `close` is
/// the destructive one, so its plate is red-soft and its glyph goes full red.
fn chrome_button(
  ctx : @common.PaintContext,
  model : Model,
  r : RectD,
  name : String,
  size : Double,
  p : Palette,
) -> Unit {
  let hot = hovering(model, r)
  let danger = name == "x"
  if hot {
    round_fill(
      ctx,
      rect_of(r),
      6.0,
      if danger { p.red.with_alpha(0.16) } else { p.surface_hover },
    )
  }
  let fg = if hot {
    if danger {
      p.red
    } else {
      p.text
    }
  } else {
    p.text_3
  }
  icon(ctx, name, rect_of(r), size, fg, 1.6)
}

///|
/// Text of the window source capsule: `项目 · 分支` (the reference header puts
/// the project first and its branch after the dot; the connection half only
/// appears for remote workspaces, which this build does not model). A window
/// whose thread or project is gone yields "", and the caller skips the capsule.
fn win_source_label(model : Model, win : WindowRec) -> String {
  let mut project = ""
  for thread in model.threads {
    if thread.id == win.thread {
      project = thread.project
    }
  }
  if project == "" {
    return ""
  }
  let mut branch = ""
  for proj in model.projects {
    if proj.name == project && branch == "" {
      branch = proj.branch
    }
  }
  // A project can own several worktrees; the window names the current one.
  for proj in model.projects {
    if proj.name == project && proj.current {
      branch = proj.branch
    }
  }
  if branch == "" {
    return project
  }
  project + " · " + branch
}

// ---------------------------------------------------------------------------
// Conversation window

///|
fn paint_convo(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  model : Model,
  p : Palette,
  win : WindowRec,
  frame : RectD,
) -> Unit {
  ignore(win)
  let cb = convo_box(frame)
  fill(ctx, rect_of(cb.body), p.window_bg)
  // Message stream, bottom-anchored so the latest turn is always visible.
  let total = chat_height(ts, model, cb.doc_w)
  let maxoff = (total - cb.scroll.h + 10.0).max(0.0)
  let offset = (maxoff - model.convo_scroll).max(0.0)
  clip_rect(ctx, rect_of(cb.scroll))
  let mut y = cb.scroll.y - offset
  for item in model.chat {
    let h = chat_item_h(ts, item, cb.doc_w)
    paint_chat_item(ctx, ts, model, p, item, cb.doc_x, y, cb.doc_w)
    y = y + h
  }
  unclip_rect(ctx)
  if offset > 0.0 {
    let pill = convo_latest_pill(cb)
    panel(ctx, pill, 11.0, p.surface_2, p.border)
    icon(ctx, "arrow-down", rect(pill.x + 6.0, pill.y + 5.0, 12.0, 12.0), 10.0, p.text_3, 1.7)
    label(ctx, ts, "回到最新", pill.x + 20.0, pill.y + 3.0, 16.0, 9.5, 500, p.text_3)
  }
  paint_minimap(ctx, ts, model, cb, p)
  paint_progress_strip(ctx, ts, model, cb, p)
  paint_deck(ctx, ts, model, cb, p)
  paint_composer(ctx, ts, model, cb, p)
}

///|
fn chat_item_h(ts : @core.TextSystem, item : ChatItem, w : Double) -> Double {
  match item {
    Checklist(items) => 26.0 + items.length().to_double() * 21.0 + 10.0
    Diff(_label, _n, _chips) => 34.0
    UserSay(_initial, _meta, text) => {
      let lines = wrap_text(ts, text, font_ui(13.0, 400), w * 0.78 - 28.0)
      20.0 + 16.0 + lines.length().to_double() * 20.0 + 20.0
    }
    AssistantSay(_initial, _meta, text) => {
      let lines = wrap_text(ts, text, font_ui(13.0, 400), w)
      20.0 + lines.length().to_double() * 20.0 + 16.0
    }
    Tool(card) => 30.0 + card.lines.length().to_double() * 16.0 + 18.0
    Commit(_q, _badge, _note, text) => {
      let lines = wrap_text(ts, text, font_ui(11.5, 400), w - 28.0)
      14.0 + 16.0 + lines.length().to_double() * 18.0 + 12.0
    }
    Approval(_body) => 0.0
  }
}

///|
fn chat_height(ts : @core.TextSystem, model : Model, w : Double) -> Double {
  let mut total = 16.0
  for item in model.chat {
    total = total + chat_item_h(ts, item, w) + 6.0
  }
  total
}

///|
fn paint_chat_item(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  model : Model,
  p : Palette,
  item : ChatItem,
  x : Double,
  y : Double,
  w : Double,
) -> Unit {
  match item {
    Checklist(items) => {
      label(ctx, ts, "任务清单 · \{items.length()} 项", x, y + 2.0, 18.0, 11.0, 600, p.text_2)
      let mut i = 0
      for row in items {
        let ry = y + 24.0 + i.to_double() * 21.0
        let box = RectD::new(x=x + 2.0, y=ry + 4.0, w=13.0, h=13.0)
        round_stroke(ctx, rect_of(box), 4.0, p.border_strong, 1.0)
        if i == 0 {
          icon(ctx, "check", rect_of(box), 10.0, p.green, 2.0)
        }
        label(ctx, ts, row, x + 24.0, ry + 1.0, 18.0, 11.5, 400, p.text_2)
        i = i + 1
      }
    }
    Diff(summary, adds, chips) => {
      let r = RectD::new(x~, y=y + 2.0, w~, h=26.0)
      panel(ctx, r, 8.0, p.surface, p.border)
      icon(ctx, "file-diff", rect(r.x + 8.0, r.y + 6.0, 14.0, 14.0), 11.0, p.text_3, 1.6)
      let sw = text_width(ts, summary, font_ui(11.0, 500))
      label(ctx, ts, summary, r.x + 26.0, r.y + 4.0, 18.0, 11.0, 500, p.text_2)
      label(ctx, ts, "+\{adds}", r.x + 26.0 + sw + 8.0, r.y + 4.0, 18.0, 11.0, 600, p.green)
      label(ctx, ts, "−12", r.x + 26.0 + sw + 8.0 + text_width(ts, "+\{adds}", font_ui(11.0, 600)) + 6.0, r.y + 4.0, 18.0, 11.0, 600, p.red)
      let mut bx = r.right() - 8.0
      let mut ci = chips.length() - 1
      while ci >= 0 {
        let name = chips[ci]
        let bw = text_width(ts, name, font_ui(10.0, 500)) + 16.0
        let br = RectD::new(x=bx - bw, y=r.y + 3.0, w=bw, h=20.0)
        chip(ctx, ts, br, name, p.text_3, p.surface_2, p.surface_2.with_alpha(0.0), 10.0)
        bx = bx - bw - 6.0
        ci = ci - 1
      }
    }
    UserSay(initial, meta, text) => {
      let bubble_w = (w * 0.78).min(560.0)
      let bx = x + w - bubble_w
      let by = y + 2.0
      let font = font_ui(13.0, 400)
      let lines = wrap_text(ts, text, font, bubble_w - 28.0)
      let bh = 12.0 + 12.0 + lines.length().to_double() * 20.0 + 14.0
      let bg = if p.dark { p.accent } else { solid(0xee, 0xe9, 0xff) }
      round_fill(ctx, rect(bx, by, bubble_w, bh), 16.0, bg)
      // Square the bottom-right corner: the sender side of the bubble.
      fill(ctx, rect(bx + bubble_w - 12.0, by + bh - 12.0, 12.0, 12.0), bg)
      let fg = bubble_fg(p)
      label_right(
        ctx,
        ts,
        meta,
        bx + bubble_w - 14.0,
        by + 6.0,
        14.0,
        9.5,
        500,
        fg.with_alpha(0.66),
      )
      let av = RectD::new(x=bx + 10.0, y=by + 6.0, w=16.0, h=16.0)
      round_fill(ctx, rect_of(av), 8.0, fg.with_alpha(0.18))
      put_c(ctx, rect_of(av), initial, font_ui(9.0, 600), fg)
      let mut ly = by + 26.0
      for line in lines {
        put(ctx, rect(bx + 14.0, ly, bubble_w - 28.0, 20.0), line, font, fg)
        ly = ly + 20.0
      }
    }
    AssistantSay(initial, meta, text) => {
      let av = RectD::new(x=x, y=y + 4.0, w=20.0, h=20.0)
      round_fill(ctx, rect_of(av), 10.0, p.accent.with_alpha(0.18))
      put_c(ctx, rect_of(av), initial, font_ui(10.0, 600), p.accent)
      label(ctx, ts, "OMP", x + 28.0, y + 4.0, 20.0, 11.5, 600, p.text)
      label(ctx, ts, meta, x + 28.0 + text_width(ts, "OMP", font_ui(11.5, 600)) + 8.0, y + 4.0, 20.0, 9.5, 400, p.text_faint)
      let font = font_ui(13.0, 400)
      let lines = wrap_text(ts, text, font, w - 28.0)
      let mut ly = y + 28.0
      for line in lines {
        put(ctx, rect(x + 28.0, ly, w - 28.0, 20.0), line, font, p.text)
        ly = ly + 20.0
      }
    }
    Tool(card) => {
      let h = 30.0 + card.lines.length().to_double() * 16.0 + 12.0
      let r = RectD::new(x~, y=y + 2.0, w~, h~)
      panel(ctx, r, 9.0, p.surface, p.border)
      icon(ctx, "chevron-down", rect(r.x + 8.0, r.y + 8.0, 12.0, 12.0), 10.0, p.text_3, 1.8)
      label_in(ctx, ts, card.title, r.x + 24.0, r.y + 4.0, 18.0, r.w - 140.0, 11.0, 600, p.text_2)
      let status = card.status
      let sw = text_width(ts, status, font_ui(9.5, 500)) + 14.0
      let sr = RectD::new(x=r.right() - sw - 8.0, y=r.y + 5.0, w=sw, h=18.0)
      chip(
        ctx,
        ts,
        sr,
        status,
        if status == "运行中" { p.blue } else { p.text_3 },
        if status == "运行中" { p.blue.with_alpha(0.16) } else { p.surface_2 },
        p.surface_2.with_alpha(0.0),
        9.5,
      )
      let block = RectD::new(x=r.x + 8.0, y=r.y + 30.0, w=r.w - 16.0, h=h - 38.0)
      round_fill(ctx, rect_of(block), 7.0, p.bg_inset)
      let mono = font_mono(10.0)
      let mut ly = block.y + 6.0
      for line in card.lines {
        let failed = line.contains("error") || line.contains("Error")
        put(ctx, rect(block.x + 8.0, ly, block.w - 12.0, 16.0), line, mono, if failed { p.red } else { p.text_2 })
        ly = ly + 16.0
      }
      ignore(card.cwd)
      ignore(card.error)
    }
    Commit(_queued, badge, note, text) => {
      let lines = wrap_text(ts, text, font_ui(11.5, 400), w - 28.0)
      let h = 14.0 + 16.0 + lines.length().to_double() * 18.0 + 12.0
      let r = RectD::new(x~, y=y + 2.0, w~, h~)
      panel(ctx, r, 10.0, p.surface, p.border)
      let bw = text_width(ts, badge, font_ui(9.5, 600)) + 16.0
      let br = RectD::new(x=r.x + 12.0, y=r.y + 8.0, w=bw, h=18.0)
      let accent = if note.contains("排队") { p.green } else { p.amber }
      chip(ctx, ts, br, badge, accent, accent.with_alpha(0.16), accent.with_alpha(0.0), 9.5)
      label(ctx, ts, note, br.right() + 8.0, r.y + 7.0, 18.0, 9.5, 400, p.text_faint)
      let mut ly = r.y + 30.0
      for line in lines {
        put(ctx, rect(r.x + 14.0, ly, w - 28.0, 18.0), line, font_ui(11.5, 400), p.text_2)
        ly = ly + 18.0
      }
    }
    Approval(_body) => ignore(model)
  }
}

///|
fn paint_minimap(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  model : Model,
  cb : ConvoBox,
  p : Palette,
) -> Unit {
  ignore(ts)
  let m = cb.minimap
  round_fill(ctx, rect_of(m), 4.0, p.bg_inset)
  let n = model.chat.length()
  let mut i = 0
  for item in model.chat {
    let y = m.y + 6.0 + (m.h - 20.0) * (i.to_double() / n.to_double())
    let h = match item {
      Tool(_c) => 8.0
      UserSay(_a, _b, _c) => 6.0
      Commit(_q, _b, _c, _d) => 7.0
      _ => 3.0
    }
    let color = match item {
      Tool(_c) => p.accent.with_alpha(0.5)
      UserSay(_a, _b, _c) => p.accent.with_alpha(0.9)
      Commit(_q, _b, _c, _d) => p.green.with_alpha(0.7)
      _ => p.text_3.with_alpha(0.35)
    }
    round_fill(ctx, rect(m.x + 4.0, y, m.w - 8.0, h), 1.5, color)
    i = i + 1
  }
  let thumb = RectD::new(x=m.x + 2.0, y=m.y + m.h * 0.55, w=m.w - 4.0, h=m.h * 0.22)
  round_stroke(ctx, rect_of(thumb), 3.0, p.text_3.with_alpha(0.4), 1.0)
}

///|
fn paint_progress_strip(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  model : Model,
  cb : ConvoBox,
  p : Palette,
) -> Unit {
  // The transcript no longer carries a progress item, so this strip is the one
  // and only place the run summary is painted. Read it from the model.
  let t = model.task
  let r = cb.progress
  panel(ctx, r, 8.0, p.surface, p.border)
  let text = "第 \{t.done} / \{t.total} 步 · \{t.files} 个文件已更改"
  label(ctx, ts, text, r.x + 10.0, r.y + 2.0, 16.0, 9.5, 500, p.text_3)
  let stats = "+\{t.adds} −\{t.dels}"
  let sw = text_width(ts, stats, font_ui(9.5, 500))
  label_right(ctx, ts, stats, r.right() - 10.0, r.y + 2.0, 16.0, 9.5, 500, p.text_faint)
  let track = RectD::new(x=r.x + 10.0, y=r.y + r.h - 7.0, w=(r.w - 30.0 - sw).max(24.0), h=3.0)
  round_fill(ctx, rect_of(track), 1.5, p.surface_2)
  let frac = if t.total == 0 { 0.0 } else { t.done.to_double() / t.total.to_double() }
  round_fill(ctx, rect(track.x, track.y, (track.w * frac).max(8.0), 3.0), 1.5, p.accent)
}

///|
fn paint_deck(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  model : Model,
  cb : ConvoBox,
  p : Palette,
) -> Unit {
  let r = cb.deck
  let pending = model.approval == 0
  if pending {
    shadow(ctx, rect_of(r), 16.0, p.accent.with_alpha(0.16), 22.0, 0.0)
  }
  let border = if pending {
    p.amber.with_alpha(0.38)
  } else {
    p.border
  }
  panel(ctx, r, 16.0, p.surface, border)
  let head_h = 30.0
  let head = RectD::new(x=r.x + 1.0, y=r.y + 1.0, w=r.w - 2.0, h=head_h)
  clip_round(ctx, rect_of(r), 16.0)
  fill(ctx, rect_of(head), if pending { p.amber.with_alpha(0.16) } else { p.surface_2 })
  unclip(ctx)
  let title = if pending { "审批请求" } else { "审批已处理" }
  label(ctx, ts, title, head.x + 14.0, head.y + 6.0, 18.0, 11.5, 600, if pending { p.amber } else { p.text_3 })
  if pending {
    let risk = "中风险"
    let rw = text_width(ts, risk, font_ui(9.5, 500)) + 14.0
    let rr = RectD::new(x=head.right() - rw - 10.0, y=head.y + 6.0, w=rw, h=18.0)
    chip(ctx, ts, rr, risk, p.amber, p.amber.with_alpha(0.18), p.amber.with_alpha(0.0), 9.5)
  } else {
    label_right(
      ctx,
      ts,
      if model.approval == 1 { "已允许一次" } else { "已拒绝" },
      head.right() - 10.0,
      head.y + 6.0,
      18.0,
      9.5,
      500,
      if model.approval == 1 { p.green } else { p.red },
    )
  }
  let body = model.plan
  let by = r.y + head_h + 8.0
  label(
    ctx,
    ts,
    "OMP 请求执行以下受保护的工具操作：",
    r.x + 14.0,
    by,
    16.0,
    10.5,
    400,
    p.text_2,
  )
  let block = RectD::new(x=r.x + 14.0, y=by + 20.0, w=r.w - 28.0, h=30.0)
  round_fill(ctx, rect_of(block), 8.0, p.bg_inset)
  put(ctx, rect(block.x + 9.0, block.y + 6.0, block.w - 16.0, 16.0), "$ npm run check", font_mono(10.0), p.text_2)
  label(
    ctx,
    ts,
    "受影响路径：D:/Project/omp-web/package.json · \{body.title}",
    r.x + 14.0,
    block.bottom() + 3.0,
    14.0,
    9.0,
    400,
    p.text_faint,
  )
  let foot = RectD::new(x=r.x + 12.0, y=r.bottom() - 40.0, w=r.w - 24.0, h=30.0)
  let den = cb.deny
  let once = cb.approve
  let session = cb.approve_session
  outline_button(
    ctx,
    ts,
    den,
    "拒绝",
    p.red,
    if hovering(model, den) { p.red.with_alpha(0.14) } else { p.surface },
    p.red.with_alpha(0.4),
  )
  primary_button(
    ctx,
    ts,
    once,
    "允许一次",
    if hovering(model, once) { p.accent_hover } else { p.accent },
    p.on_accent,
  )
  outline_button(
    ctx,
    ts,
    session,
    "本会话允许",
    p.text_2,
    if hovering(model, session) { p.surface_hover } else { p.surface },
    p.border_strong,
  )
  let remember = RectD::new(x=foot.x, y=foot.y, w=64.0, h=30.0)
  outline_button(
    ctx,
    ts,
    remember,
    "记住…",
    p.text_3,
    if hovering(model, remember) { p.surface_hover } else { p.surface },
    p.border_strong,
  )
}

///|
fn paint_composer(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  model : Model,
  cb : ConvoBox,
  p : Palette,
) -> Unit {
  let r = cb.composer
  panel(ctx, r, 16.0, p.surface, p.border_strong)
  let pending = model.approval == 0
  // Top row: pending hint or the @-reference chips.
  let top = RectD::new(x=r.x + 10.0, y=r.y + 8.0, w=r.w - 20.0, h=20.0)
  if pending {
    icon(ctx, "circle-alert", rect(top.x + 1.0, top.y + 3.0, 12.0, 12.0), 11.0, p.amber, 1.8)
    label(
      ctx,
      ts,
      "请先处理上方的询问或审批，再发送新消息",
      top.x + 18.0,
      top.y + 1.0,
      16.0,
      9.5,
      500,
      p.amber,
    )
  } else {
    let refs = ["@App.tsx", "@package.json", "+2", "12.4k tokens"]
    let mut cx = top.x
    for ref in refs {
      let cw = text_width(ts, ref, font_ui(9.5, 500)) + 16.0
      let cr = RectD::new(x=cx, y=top.y, w=cw, h=20.0)
      if ref == "12.4k tokens" {
        chip(ctx, ts, cr, ref, p.text_faint, p.surface_2, p.surface_2.with_alpha(0.0), 9.5)
      } else {
        chip(ctx, ts, cr, ref, p.accent, p.accent_soft, p.accent_border, 9.5)
      }
      cx = cx + cw + 6.0
    }
  }
  // Input line.
  let input = RectD::new(x=r.x + 10.0, y=r.y + 32.0, w=r.w - 20.0, h=26.0)
  if model.composer == "" {
    label(ctx, ts, "输入消息，Enter 发送，Shift+Enter 换行…", input.x, input.y, 22.0, 12.5, 400, p.text_faint)
  } else {
    put(
      ctx,
      rect(input.x, input.y, input.w, 22.0),
      model.composer,
      font_ui(12.5, 400),
      p.text,
    )
  }
  // Bottom bar: permission / mode / model / think pills, then attach, mic, send.
  let bar_y = r.y + r.h - 32.0
  let perm = RectD::new(x=r.x + 10.0, y=bar_y, w=86.0, h=24.0)
  chip(ctx, ts, perm, "Full Access", p.orange, p.orange.with_alpha(0.12), p.orange.with_alpha(0.3), 9.5)
  let mode = RectD::new(x=perm.right() + 6.0, y=bar_y, w=70.0, h=24.0)
  chip(
    ctx,
    ts,
    mode,
    "默认模式",
    p.text_2,
    if hovering(model, mode) { p.surface_3 } else { p.surface_2 },
    p.surface_2.with_alpha(0.0),
    9.5,
  )
  let model_pill = RectD::new(x=mode.right() + 6.0, y=bar_y, w=128.0, h=24.0)
  chip(
    ctx,
    ts,
    model_pill,
    "sonnet-4.5",
    p.text_2,
    if hovering(model, model_pill) { p.surface_3 } else { p.surface_2 },
    p.surface_2.with_alpha(0.0),
    9.5,
  )
  let think = RectD::new(x=model_pill.right() + 6.0, y=bar_y, w=64.0, h=24.0)
  chip(ctx, ts, think, "思考 · 中", p.accent, p.accent_soft, p.accent_border, 9.0)
  // The two icon affordances get the same round hover plate as the tab close.
  let clip_r = RectD::new(x=r.right() - 96.0, y=bar_y + 2.0, w=20.0, h=20.0)
  let mic_r = RectD::new(x=r.right() - 70.0, y=bar_y + 2.0, w=20.0, h=20.0)
  for pair in [(clip_r, "paperclip"), (mic_r, "mic")] {
    let (br, name) = pair
    let hot = hovering(model, br)
    if hot {
      round_fill(ctx, rect_of(br), 6.0, p.surface_hover)
    }
    icon(ctx, name, rect(br.x + 2.0, br.y + 2.0, 16.0, 16.0), 13.0, if hot { p.text } else { p.text_3 }, 1.6)
  }
  let send = cb.send
  if pending {
    round_fill(ctx, rect_of(send), 15.0, p.surface_2)
    icon(ctx, "lock", rect_of(send), 13.0, p.text_faint, 1.8)
  } else if model.composer == "" {
    round_fill(ctx, rect_of(send), 15.0, p.surface_2)
    icon(ctx, "arrow-up", rect_of(send), 14.0, p.text_faint, 2.0)
  } else {
    round_fill(
      ctx,
      rect_of(send),
      15.0,
      if hovering(model, send) { p.accent_hover } else { p.accent },
    )
    icon(ctx, "arrow-up", rect_of(send), 14.0, p.on_accent, 2.0)
  }
}

// ---------------------------------------------------------------------------
// Plan Review window

///|
fn paint_plan(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  model : Model,
  p : Palette,
  win : WindowRec,
  frame : RectD,
) -> Unit {
  ignore(win)
  let pb = plan_box(frame)
  fill(ctx, rect_of(pb.body), p.window_bg)
  let plan = model.plan
  // Header.
  label(ctx, ts, "Plan Review", pb.content.x, pb.content.y, 16.0, 10.0, 600, p.text_faint)
  let approved = model.plan_approved
  if approved {
    let cw = text_width(ts, "已批准", font_ui(9.5, 600)) + 16.0
    let cr = RectD::new(x=pb.content.right() - cw, y=pb.content.y, w=cw, h=18.0)
    chip(ctx, ts, cr, "已批准", p.green, p.green.with_alpha(0.16), p.green.with_alpha(0.0), 9.5)
  } else {
    let cw = text_width(ts, "阅读 / 编辑", font_ui(9.0, 500)) + 16.0
    let cr = RectD::new(x=pb.content.right() - cw, y=pb.content.y, w=cw, h=18.0)
    chip(ctx, ts, cr, "阅读 / 编辑", p.text_3, p.surface_2, p.surface_2.with_alpha(0.0), 9.0)
  }
  label_in(ctx, ts, plan.title, pb.content.x, pb.content.y + 20.0, 24.0, pb.content.w - 90.0, 15.0, 600, p.text)
  clip_rect(ctx, rect_of(pb.content))
  let mut y = pb.content.y + 54.0
  y = y + plan_section(ctx, ts, "## 目标", plan.goal, pb.content.x, y, pb.content.w, p)
  y = y + 10.0
  y = y + plan_section_steps(ctx, ts, "## 实施步骤", plan.steps, pb.content.x, y, pb.content.w, p)
  y = y + 10.0
  y = y + plan_section(
    ctx,
    ts,
    "## 执行档位",
    "标准 · 逐条执行，每步完成后报告；遇到需要审批的动作会先停下等待确认。",
    pb.content.x,
    y,
    pb.content.w,
    p,
  )
  unclip_rect(ctx)
  // Footer buttons.
  let approve = pb.approve
  primary_button(
    ctx,
    ts,
    approve,
    if approved { "已批准并执行" } else { "批准并执行" },
    if approved { p.green } else { p.accent },
    p.on_accent,
  )
  outline_button(ctx, ts, pb.keep, "保留上下文执行", p.text_2, p.surface, p.border_strong)
  outline_button(ctx, ts, pb.compact, "压缩后执行", p.text_2, p.surface, p.border_strong)
  outline_button(ctx, ts, pb.refine, "修改意见", p.text_2, p.surface, p.border_strong)
  outline_button(ctx, ts, pb.dismiss, "放弃计划", p.red, p.surface, p.red.with_alpha(0.35))
}

///|
fn plan_section(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  heading : String,
  body : String,
  x : Double,
  y : Double,
  w : Double,
  p : Palette,
) -> Double {
  label(ctx, ts, heading, x, y, 20.0, 11.5, 700, p.accent)
  let font = font_ui(11.5, 400)
  let lines = wrap_text(ts, body, font, w - 8.0)
  let mut ly = y + 24.0
  for line in lines {
    put(ctx, rect(x, ly, w - 8.0, 18.0), line, font, p.text_2)
    ly = ly + 18.0
  }
  ly - y + 6.0
}

///|
fn plan_section_steps(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  heading : String,
  steps : Array[String],
  x : Double,
  y : Double,
  w : Double,
  p : Palette,
) -> Double {
  label(ctx, ts, heading, x, y, 20.0, 11.5, 700, p.accent)
  let mut ly = y + 24.0
  let mut i = 0
  for step in steps {
    let badge = RectD::new(x=x, y=ly + 1.0, w=16.0, h=16.0)
    round_fill(ctx, rect_of(badge), 8.0, p.accent_soft)
    put_c(ctx, rect_of(badge), "\{i + 1}", font_ui(9.0, 600), p.accent)
    let font = font_ui(11.5, 400)
    let lines = wrap_text(ts, step, font, w - 26.0)
    let mut sy = ly
    for line in lines {
      put(ctx, rect(x + 24.0, sy, w - 26.0, 18.0), line, font, p.text_2)
      sy = sy + 18.0
    }
    ly = ly + lines.length().to_double() * 18.0 + 4.0
    i = i + 1
  }
  ly - y + 4.0
}

// ---------------------------------------------------------------------------
// Managed browser window

///|
fn paint_browser(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  model : Model,
  p : Palette,
  win : WindowRec,
  frame : RectD,
) -> Unit {
  ignore(win)
  let bb = browser_box(frame)
  fill(ctx, rect_of(bb.body), p.window_bg)
  fill(ctx, rect_of(bb.toolbar), p.surface)
  hair(ctx, bb.toolbar.x, bb.toolbar.bottom(), bb.toolbar.right(), bb.toolbar.bottom(), p.border)
  let manual = model.browser_control == 1
  icon(ctx, "arrow-left", rect_of(bb.back), 13.0, if manual { p.text_2 } else { p.text_faint }, 1.7)
  icon(ctx, "arrow-right", rect_of(bb.forward), 13.0, if manual { p.text_2 } else { p.text_faint }, 1.7)
  icon(ctx, "rotate-cw", rect_of(bb.reload), 13.0, if manual { p.text_2 } else { p.text_faint }, 1.7)
  // Omnibox.
  round_fill(ctx, rect_of(bb.omnibox), 6.0, p.surface_2)
  round_stroke(ctx, rect_of(bb.omnibox), 6.0, p.border, 1.0)
  let lock_x = bb.omnibox.x + 9.0
  icon(ctx, if manual { "lock-open" } else { "lock" }, rect(lock_x, bb.omnibox.y + 5.0, 12.0, 12.0), 10.5, p.green, 1.7)
  let url = if model.browser_query == "" { "localhost:5173/studio/preview" } else { model.browser_query }
  label_in(ctx, ts, url, lock_x + 18.0, bb.omnibox.y + 4.0, 16.0, bb.omnibox.w - 92.0, 10.5, 500, p.text_2)
  let zoom = "100%"
  let zw = text_width(ts, zoom, font_ui(8.5, 500)) + 10.0
  let zr = RectD::new(x=bb.omnibox.right() - 26.0 - zw, y=bb.omnibox.y + 4.0, w=zw, h=14.0)
  chip(ctx, ts, zr, zoom, p.text_faint, p.surface, p.border, 8.5)
  let space = if manual { "人工" } else { "Agent" }
  let sw = text_width(ts, space, font_ui(8.5, 600)) + 10.0
  let sr = RectD::new(x=bb.omnibox.right() - 6.0 - sw, y=bb.omnibox.y + 4.0, w=sw, h=14.0)
  chip(
    ctx,
    ts,
    sr,
    space,
    if manual { p.accent } else { p.green },
    if manual { p.accent_soft } else { p.green.with_alpha(0.14) },
    p.surface.with_alpha(0.0),
    8.5,
  )
  // Agent | 我 segmented control: manual control is the only accent-filled block.
  panel(ctx, bb.seg_agent, 7.0, if manual { p.surface_2 } else { p.accent }, p.border_strong)
  put_c(ctx, rect_of(bb.seg_agent), "Agent", font_ui(9.0, 600), if manual { p.text_3 } else { p.on_accent })
  panel(ctx, bb.seg_me, 7.0, if manual { p.accent } else { p.surface_2 }, p.border_strong)
  put_c(ctx, rect_of(bb.seg_me), "我", font_ui(9.0, 600), if manual { p.on_accent } else { p.text_3 })
  icon(ctx, "ellipsis", rect(bb.seg_me.right() + 8.0, bb.seg_me.y + 4.0, 14.0, 14.0), 12.0, p.text_3, 1.7)
  // Page: the managed page is a native layer in the real app; here it is a mock.
  fill(ctx, rect_of(bb.page), solid(0xf7, 0xf7, 0xf9))
  paint_mock_page(ctx, ts, model, bb.page, p)
  // Status bar.
  fill(ctx, rect_of(bb.status), p.surface)
  hair(ctx, bb.status.x, bb.status.y, bb.status.right(), bb.status.y, p.border)
  dot(ctx, bb.status.x + 12.0, bb.status.y + 8.0, 6.0, if manual { p.accent } else { p.green })
  label(
    ctx,
    ts,
    if manual { "我已接管 · 地址框可编辑" } else { "Agent 控制中 · 页面只读" },
    bb.status.x + 22.0,
    bb.status.y + 1.0,
    14.0,
    9.0,
    500,
    p.text_3,
  )
  label_right(ctx, ts, "1 个标签 · 0 个下载", bb.status.right() - 10.0, bb.status.y + 1.0, 14.0, 9.0, 400, p.text_faint)
}

///|
fn paint_mock_page(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  model : Model,
  page : RectD,
  p : Palette,
) -> Unit {
  ignore(model)
  let ink = solid(0x1d, 0x21, 0x29)
  let muted = solid(0x6d, 0x74, 0x80)
  let card = solid(0xff, 0xff, 0xff)
  let line = solid(0xe6, 0xe7, 0xeb)
  let accent = solid(0x6e, 0x56, 0xcf)
  let x = page.x + 20.0
  let w = page.w - 40.0
  round_fill(ctx, rect(page.x, page.y, page.w, 42.0), 0.0, card)
  fill(ctx, rect(page.x, page.y + 42.0, page.w, 1.0), line)
  let mark = RectD::new(x=x, y=page.y + 10.0, w=22.0, h=22.0)
  round_fill(ctx, rect_of(mark), 7.0, accent)
  label(ctx, ts, "Studio", x + 30.0, page.y + 10.0, 22.0, 12.5, 700, ink)
  label(ctx, ts, "组件预览", x + 30.0 + text_width(ts, "Studio", font_ui(12.5, 700)) + 8.0, page.y + 12.0, 18.0, 10.0, 500, muted)
  label_right(ctx, ts, "localhost:5173", page.right() - 20.0, page.y + 12.0, 18.0, 9.5, 500, muted)
  label(ctx, ts, "Preview · 交互组件示例", x, page.y + 68.0, 26.0, 18.0, 700, ink)
  label(ctx, ts, "所有卡片共享同一套 tokens，暗色主题下不加大面积阴影。", x, page.y + 96.0, 20.0, 10.5, 400, muted)
  let mut i = 0
  while i < 3 {
    let cy = page.y + 132.0 + i.to_double() * 84.0
    if cy + 72.0 < page.bottom() - 8.0 {
      let cr = RectD::new(x~, y=cy, w~, h=72.0)
      round_fill(ctx, rect_of(cr), 12.0, card)
      round_stroke(ctx, rect_of(cr), 12.0, line, 1.0)
      let names = ["Button · 主要 / 次要 / 危险", "Approval Card · 待处理 / 已处理", "Tool Card · 折叠 / 展开"]
      label(ctx, ts, names[i], cr.x + 14.0, cr.y + 12.0, 20.0, 11.5, 600, ink)
      label(ctx, ts, "tokens · radius 16 · border 1px", cr.x + 14.0, cr.y + 34.0, 18.0, 9.5, 400, muted)
      let chip_r = RectD::new(x=cr.right() - 52.0, y=cr.y + 12.0, w=40.0, h=18.0)
      chip(ctx, ts, chip_r, "示例", accent, solid(0xf1, 0xee, 0xfc), solid(0xf1, 0xee, 0xfc), 9.0)
    }
    i = i + 1
  }
  ignore(p)
}

// ---------------------------------------------------------------------------
// Terminal window (only reachable through the mock data for now)

///|
fn paint_terminal(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  model : Model,
  p : Palette,
  win : WindowRec,
  frame : RectD,
) -> Unit {
  ignore(model)
  let body = RectD::new(
    x=frame.x,
    y=frame.y + WIN_TITLEBAR_H,
    w=frame.w,
    h=frame.h - WIN_TITLEBAR_H,
  )
  fill(ctx, rect_of(body), p.bg_inset)
  let mono = font_mono(10.5)
  let lines = [
    "omp-studio  main  ✓",
    "Last login: Thu Nov 20 09:12:04 on ttys002",
    "~/Project/omp-web $ npm run check",
    "> tsc --noEmit && vite build",
    "✓ built in 3.42s",
    "~/Project/omp-web $ ",
  ]
  let mut y = body.y + 8.0
  for line in lines {
    put(ctx, rect(body.x + 12.0, y, body.w - 20.0, 18.0), line, mono, p.text_2)
    y = y + 17.0
  }
  ignore(win)
  ignore(ts)
}

// ---------------------------------------------------------------------------
// Overlays

///|
pub fn paint_overlays(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  model : Model,
  shell : Shell,
  p : Palette,
) -> Unit {
  // No capsule row here: this build always shows the window tab strip, which
  // already carries every minimised window (with its 已最小化 tag). Painting
  // capsules too put a second title right on top of the focused window's title
  // bar, since both start at the canvas top edge. The tab is the one owner:
  // clicking it restores the window (see `pointer_down`).
  ignore((ts, model, shell, p))
  if model.picker >= 0 {
    paint_snap_picker(ctx, ts, model, shell, p)
  }
}

///|
fn paint_snap_picker(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  model : Model,
  shell : Shell,
  p : Palette,
) -> Unit {
  let c = shell.canvas
  fill(ctx, rect_of(c), @graphics.Color::rgba(r=0.0, g=0.0, b=0.0, a=0.28))
  let panel_r = picker_panel(shell)
  shadow(ctx, rect_of(panel_r), 14.0, p.shadow, 30.0, 10.0)
  panel(ctx, panel_r, 14.0, p.surface, p.border_strong)
  label(ctx, ts, "吸附布局", panel_r.x + 16.0, panel_r.y + 14.0, 20.0, 12.0, 600, p.text)
  label_right(ctx, ts, "选择模板后窗口铺满对应区域", panel_r.right() - 16.0, panel_r.y + 16.0, 18.0, 9.0, 400, p.text_faint)
  let presets = [
    SplitEven,
    SplitTwoOne,
    ThreeColumns,
    LeftStacked,
    RightStacked,
    Quadrants,
  ]
  let names = ["左右等分", "2/3 + 1/3", "三栏", "左侧堆叠", "右侧堆叠", "四宫格"]
  let cells = picker_cells(shell)
  let mut i = 0
  for cell in cells {
    if i >= presets.length() {
      break
    }
    let preset = presets[i]
    let active = model.layout == preset
    round_fill(ctx, rect_of(cell), 10.0, if active { p.accent_soft } else { p.surface_2 })
    round_stroke(ctx, rect_of(cell), 10.0, if active { p.accent_border } else { p.border }, 1.0)
    let cell_rect = rect_of(cell)
    let preview = trim(cell_rect, 10.0, 8.0, 10.0, 26.0)
    fill(ctx, preview, if p.dark { p.bg_inset } else { solid(0xf4, 0xf4, 0xf7) })
    for slot in preset.slots() {
      let sr = rect(
        preview.origin.x + slot.x * preview.size.width + 2.0,
        preview.origin.y + slot.y * preview.size.height + 2.0,
        slot.w * preview.size.width - 4.0,
        slot.h * preview.size.height - 4.0,
      )
      round_fill(ctx, sr, 3.0, if active { p.accent.with_alpha(0.5) } else { p.text_3.with_alpha(0.28) })
    }
    put_c(
      ctx,
      rect(cell.x, cell.bottom() - 22.0, cell.w, 18.0),
      names[i],
      font_ui(9.5, 500),
      if active { p.accent } else { p.text_3 },
    )
    i = i + 1
  }
}
