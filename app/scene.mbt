// Top-level scene: the four-column workbench shell (titlebar, window tabs,
// nav rail, session sidebar, canvas, dock rail) plus the canvas contents.

///|
pub fn paint_scene(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  model : Model,
  area : @geometry.Rect,
  now : Double,
) -> Unit {
  // Stamp the paint clock and the painted frame size first: every timed layer
  // below (press, tip, toast, sheet) reads them, and so does the next keystroke.
  paint_now.val = now
  let p = Palette::new(model.dark)
  let w = area.size.width
  let h = area.size.height
  paint_frame_w.val = w
  paint_frame_h.val = h
  let shell = shell_layout(w, h, model.sidebar_open, sidebar_w=model.sidebar_w)
  fill(ctx, rect(0.0, 0.0, w, h), p.bg)
  if model.route == Workbench {
    paint_titlebar(ctx, ts, model, shell, p)
    paint_tabs(ctx, ts, model, shell, p)
    paint_rail(ctx, ts, model, shell, p)
    paint_sidebar(ctx, ts, model, shell, p)
    paint_canvas(ctx, ts, model, shell, p)
    paint_dock(ctx, ts, model, shell, p)
    paint_overlays(ctx, ts, model, shell, p)
  } else {
    // A secondary page keeps the titlebar and the rail and swaps everything
    // right of them for the page shell (44px head + padded scrolling body).
    paint_page(ctx, ts, model, w, h, p)
    paint_titlebar(ctx, ts, model, shell, p)
    paint_rail(ctx, ts, model, shell, p)
  }
  if model.palette_open {
    paint_palette(ctx, ts, model, shell, p)
  }
  // Interaction layer, in reference z order: press/focus feedback on the
  // controls, then the dialog (z 80), the tooltip (z 90) and the toast (z 100).
  paint_interaction(ctx, ts, model, shell, p, w, h)
}

///|
fn paint_titlebar(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  model : Model,
  shell : Shell,
  p : Palette,
) -> Unit {
  let r = shell.titlebar
  fill(ctx, rect_of(r), p.bg)
  hair(ctx, 0.0, r.bottom(), shell.w, r.bottom(), p.border)
  let btn_y = r.y + 4.0
  let pitch = 32.0
  let nav = titlebar_nav_slots(shell)
  let mut i = 0
  let icons = ["panel-left", "arrow-left", "arrow-right"]
  while i < 3 {
    let br = nav[i]
    let active = i == 0 && model.sidebar_open
    if active {
      round_fill(ctx, rect_of(br), 8.0, p.surface_2)
    } else if hovering(model, br) {
      round_fill(ctx, rect_of(br), 8.0, p.surface_2)
    }
    icon(ctx, icons[i], rect_of(br), 15.0, if active { p.text } else { p.text_2 }, 1.6)
    i = i + 1
  }
  // Menu row: left-aligned right after the nav buttons, as in the reference.
  let labels = ["文件", "编辑", "视图", "帮助"]
  let f = font_ui(12.0, 500)
  let mut mx = r.x + TITLEBAR_LEAD + 2.0 * pitch + 28.0 + 17.0
  for label in labels {
    let tw = text_width(ts, label, f)
    // The menu label is a hit target wider than its glyphs, as in the reference
    // where the row is a padded button and the text sits inside it.
    let mr = RectD::new(x=mx - 8.0, y=r.y + 6.0, w=tw + 18.0, h=24.0)
    let hot = hovering(model, mr)
    if hot {
      round_fill(ctx, rect_of(mr), 6.0, p.surface_hover)
    }
    put(ctx, rect(mx, r.y + 9.0, tw + 2.0, 18.0), label, f, if hot { p.text } else { p.text_2 })
    mx = mx + tw + 25.5
  }
}

///|
fn paint_tabs(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  model : Model,
  shell : Shell,
  p : Palette,
) -> Unit {
  let r = shell.tabs
  fill(ctx, rect_of(r), p.surface_2)
  hair(ctx, 0.0, r.bottom(), shell.w, r.bottom(), p.border)
  let plus = plus_tab(model, shell)
  round_fill(ctx, rect_of(plus), 8.0, if hovering(model, plus) { p.surface_2 } else { p.surface })
  round_stroke(ctx, rect_of(plus), 8.0, p.border_strong, 1.0)
  icon(ctx, "plus", rect_of(plus), 14.0, p.text_2, 1.7)
  for slot in tab_slots(model, shell) {
    match window_by_id(model, slot.id) {
      Some(win) => {
        let tr = slot.rect
        let active = slot.active && !win.minimized
        if active {
          panel(ctx, tr, 9.0, p.surface, p.border_strong)
        } else if hovering(model, tr) {
          round_fill(ctx, rect_of(tr), 9.0, p.surface_3)
        } else {
          round_fill(ctx, rect_of(tr), 9.0, p.surface_2)
        }
        let kind_icon = match win.kind {
          Conversation => "message-square"
          PlanReview => "file-check"
          Browser => "globe"
          Terminal => "terminal"
        }
        let icon_color = if active { p.accent } else { p.text_3 }
        icon(ctx, kind_icon, rect(tr.x + 8.0, tr.y + 8.0, 16.0, 16.0), 13.0, icon_color, 1.6)
        let title_color = if active { p.text } else { p.text_3 }
        let tf = font_ui(12.0, if active { 600 } else { 500 })
        let tag = "已最小化"
        let gf = font_ui(9.5, 500)
        let badge_w = if win.minimized { text_width(ts, tag, gf) + 12.0 } else { 0.0 }
        // Whatever the tab carries on its right — the close button or the
        // minimised badge — is subtracted from the label first, so neither
        // ever lands on top of the text.
        let close_w = if active { 24.0 } else { 0.0 }
        let trail = close_w + (if badge_w > 0.0 { badge_w + 6.0 } else { 0.0 })
        let title_x = tr.x + 28.0
        let title_w = (tr.right() - 6.0 - trail - title_x).max(10.0)
        put(
          ctx,
          rect(title_x, tr.y + 2.0, title_w, 28.0),
          ellipsize(ts, win.title, tf, title_w),
          tf,
          title_color,
        )
        if active {
          // The close affordance is a round hit target, so its hover plate is a
          // circle around the glyph rather than a square in the tab corner.
          let xr = tab_close_rect(slot)
          let hot = hovering(model, xr)
          if hot {
            round_fill(ctx, rect_of(xr), 10.0, p.surface_hover)
          }
          icon(ctx, "x", rect_of(xr), 12.0, if hot { p.text } else { p.text_3 }, 1.6)
        }
        if win.minimized {
          let gr = RectD::new(x=tr.right() - 6.0 - badge_w, y=tr.y + 8.0, w=badge_w, h=16.0)
          round_fill(ctx, rect_of(gr), 8.0, p.surface_3)
          put_c(ctx, rect_of(gr), tag, gf, p.text_3)
        }
      }
      None => ()
    }
  }
  let cluster = tab_cluster(shell)
  if cluster.tier < 0 {
    let hint = "⌘K 命令面板"
    let hf = font_ui(10.5, 500)
    let hw = text_width(ts, hint, hf)
    put_r(
      ctx,
      rect(shell.w - 14.0 - hw, shell.tabs.y + 14.0, hw, 18.0),
      hint,
      hf,
      p.text_faint,
    )
  } else {
    paint_tab_cluster(ctx, ts, cluster, p)
  }
}

///|
/// The context cluster on the right of the tab strip: quick actions, the token
/// and cache meters, the Compact pill and the layout/theme toggles. Every item
/// comes from `tab_cluster`, so a hidden item is simply not painted.
fn paint_tab_cluster(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  c : TabCluster,
  p : Palette,
) -> Unit {
  let f_num = font_ui(10.5, 600)
  let f_word = font_ui(10.5, 400)
  let f_compact = font_mono(10.5)
  // Quick actions: new window, agent, history, rename.
  if c.robot.w > 0.0 {
    icon(ctx, "users", rect_of(c.robot), 16.0, p.text_3, 1.5)
    icon(ctx, "clock", rect_of(c.clock), 16.0, p.text_3, 1.5)
    icon(ctx, "pencil", rect_of(c.pencil), 15.0, p.text_3, 1.5)
  }
  // Token meters: thin arrows, not chevrons, so they read as counts.
  if c.tok_up.w > 0.0 {
    arrow(ctx, c.tok_up.x + 3.0, c.tok_up.y + c.tok_up.h / 2.0, true, p.text_3)
    put(
      ctx,
      rect(c.tok_up.x + 15.0, c.tok_up.y, 24.0, 18.0),
      "3.5M",
      f_num,
      p.text_2,
    )
    arrow(ctx, c.tok_down.x + 3.0, c.tok_down.y + c.tok_down.h / 2.0, false, p.text_3)
    put(
      ctx,
      rect(c.tok_down.x + 15.0, c.tok_down.y, 22.0, 18.0),
      "73k",
      f_num,
      p.text_2,
    )
    hair(ctx, c.div_a.x + 0.5, c.div_a.y, c.div_a.x + 0.5, c.div_a.bottom(), p.border_strong)
    put(
      ctx,
      rect(c.cache_num.x, c.cache_num.y, 30.0, 18.0),
      "36.6M",
      f_num,
      p.text_2,
    )
    put_r(
      ctx,
      rect(c.cache_word.x, c.cache_word.y, c.cache_word.w, 18.0),
      "cache",
      f_word,
      p.text_faint,
    )
    hair(ctx, c.div_b.x + 0.5, c.div_b.y, c.div_b.x + 0.5, c.div_b.bottom(), p.border_strong)
    // The cache ring: a faint track plus a coloured arc for the 22%.
    let cx = c.ring.x + c.ring.w / 2.0
    let cy = c.ring.y + c.ring.h / 2.0
    round_stroke(ctx, inset_rect(rect_of(c.ring), 1.5), 6.5, p.border_strong, 3.0)
    ring_arc(ctx, cx, cy, 6.5, p.accent, -1.5708, 1.3815, 3.0)
    put_r(ctx, rect_of(c.pct), "22%", f_num, p.text_2)
    hair(ctx, c.div_c.x + 0.5, c.div_c.y, c.div_c.x + 0.5, c.div_c.bottom(), p.border_strong)
  }
  if c.compact.w > 0.0 {
    // `.tb-compact`: a 24px-tall 9px-radius pill, 10px side padding, a 13px
    // minimize glyph, 4px gap, then the mono label — its own button, 8px
    // clear of the rail toggle, never part of a merged pill.
    panel(ctx, c.compact, 9.0, p.surface, p.border_strong)
    let cy = c.compact.y + c.compact.h / 2.0
    line(ctx, c.compact.x + 12.44, cy, c.compact.x + 20.56, cy, p.text_2, 1.6)
    put(
      ctx,
      rect(c.compact.x + 27.0, c.compact.y + 3.0, c.compact.w - 37.0, 18.0),
      "Compact",
      f_compact,
      p.text_2,
    )
  }
  if c.sliders.w > 0.0 {
    // `.dock-icon-button.is-active`: an accent-soft square with the accent
    // glyph, no border — the border here used to bleed into the panel button
    // beside it and read as one pill.
    panel(ctx, c.sliders, 9.0, p.accent_soft, rgba8(0, 0, 0, 0.0))
    tool_list_glyph(
      ctx,
      c.sliders.x + c.sliders.w / 2.0,
      c.sliders.y + c.sliders.h / 2.0,
      p.accent,
    )
  }
  if c.panel.w > 0.0 {
    icon(ctx, "panel-left", rect_of(c.panel), 16.0, p.text_3, 1.5)
    icon(ctx, "moon", rect_of(c.moon), 15.0, p.text_3, 1.5)
    icon(ctx, "house", rect_of(c.home), 15.0, p.text_3, 1.5)
  }
}

///|
/// The reference `tool-list` glyph — a ring and a short bar on each of two
/// rows, drawn in a 16px box (circles r1.55 at x4.4, bars 7.6→12.8). Shared by
/// the dock-rail toggle in the tab strip and the one in every window header,
/// so the same control never paints two different icons.
fn tool_list_glyph(
  ctx : @common.PaintContext,
  cx : Double,
  cy : Double,
  color : @graphics.Color,
) -> Unit {
  let row = fn(cyy : Double) -> Unit {
    round_stroke(ctx, rect(cx - 3.6 - 1.55, cyy - 1.55, 3.1, 3.1), 1.55, color, 1.6)
    line(ctx, cx - 0.4, cyy, cx + 4.8, cyy, color, 1.6)
  }
  row(cy - 3.1)
  row(cy + 3.1)
}

///|
/// A thin count arrow (straight stem + head) used by the token meters.
fn arrow(
  ctx : @common.PaintContext,
  x : Double,
  y : Double,
  up : Bool,
  color : @graphics.Color,
) -> Unit {
  let dir = if up { -1.0 } else { 1.0 }
  line(ctx, x, y - 4.0 * dir, x, y + 4.0 * dir, color, 1.3)
  line(ctx, x - 3.0, y - 1.0 * dir, x, y - 4.0 * dir, color, 1.3)
  line(ctx, x + 3.0, y - 1.0 * dir, x, y - 4.0 * dir, color, 1.3)
}

///|
fn rail_route_icon(index : Int) -> String {
  let routes = rail_routes()
  if index >= 0 && index < routes.length() {
    routes[index].icon()
  } else {
    "house"
  }
}

///|
fn paint_rail(
  ctx : @common.PaintContext,
  _ts : @core.TextSystem,
  model : Model,
  shell : Shell,
  p : Palette,
) -> Unit {
  let r = shell.rail
  fill(ctx, rect_of(r), p.bg_inset)
  hair(ctx, r.right(), r.y, r.right(), r.bottom(), p.border)
  let slots = rail_slots(shell)
  // The rail follows the route: a page that also lives on the rail lights its
  // own slot, statistics / evaluation / media / diagnostics light none.
  let active = rail_route_index(model.route)
  let mut i = 0
  while i < slots.length() {
    let s = slots[i]
    let lit = i == active
    // The active destination is a neutral surface block, not an accent tint.
    if lit {
      round_fill(ctx, rect_of(s), 10.0, p.surface_2)
    } else if hovering(model, s) {
      round_fill(ctx, rect_of(s), 10.0, p.surface_2.with_alpha(0.55))
    }
    let color = if lit { p.text } else { p.text_3 }
    if i == 0 {
      workbench_glyph(ctx, s, color)
    } else {
      icon(ctx, rail_route_icon(i), rect_of(s), 18.0, color, 1.6)
    }
    i = i + 1
  }
  let upd = rail_update(shell)
  icon(ctx, "sparkles", rect_of(upd), 17.0, p.text_3, 1.6)
  dot(ctx, upd.x + upd.w - 11.0, upd.y + 11.0, 6.0, p.amber)
  let av = rail_avatar(shell)
  avatar(ctx, av.x + av.w / 2.0, av.y + av.h / 2.0, 34.0, p.accent, "Z", _ts, p)
  let handle = rail_handle(shell)
  panel(ctx, handle, 6.0, p.surface, p.border_strong)
  icon(ctx, if model.sidebar_open { "chevron-left" } else { "chevron-right" }, rect_of(handle), 11.0, p.text_3, 1.7)
}

///|
fn paint_dock(
  ctx : @common.PaintContext,
  _ts : @core.TextSystem,
  model : Model,
  shell : Shell,
  p : Palette,
) -> Unit {
  let slots = dock_slots(shell)
  let icons = ["layers", "terminal", "git-branch", "gauge", "bot"]
  let mut i = 0
  while i < slots.length() && i < icons.length() {
    let s = slots[i]
    let active = i == model.dock_tab
    round_fill(ctx, rect_of(s), 18.0, if active { p.accent_soft } else if hovering(model, s) { p.surface_2 } else { p.bg })
    round_stroke(ctx, rect_of(s), 18.0, if active { p.accent_border } else { p.border_strong }, 1.0)
    icon(ctx, icons[i], rect_of(s), 16.0, if active { p.accent } else { p.text_3 }, 1.6)
    i = i + 1
  }
}

///|
fn paint_canvas(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  model : Model,
  shell : Shell,
  p : Palette,
) -> Unit {
  fill(ctx, rect_of(shell.canvas), p.bg)
  // Faint dot grid makes the canvas read as a surface behind floating cards.
  let mut gx = shell.canvas.x
  while gx < shell.canvas.right() {
    let mut gy = shell.canvas.y
    while gy < shell.canvas.bottom() {
      dot(ctx, gx, gy, 1.0, rgba8(255, 255, 255, 0.035))
      gy = gy + 24.0
    }
    gx = gx + 24.0
  }
  if visible_windows(model).is_empty() {
    paint_empty_state(ctx, ts, model, shell, p)
    return
  }
  paint_windows(ctx, ts, model, shell, p)
}

///|
fn paint_empty_state(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  model : Model,
  shell : Shell,
  p : Palette,
) -> Unit {
  let c = shell.canvas
  let cx = c.x + c.w / 2.0
  let title = "准备好开始新的任务了吗？"
  let tf = font_ui(20.0, 600)
  let tw = text_width(ts, title, tf)
  put(ctx, rect(cx - tw / 2.0, c.y + c.h * 0.34, tw + 2.0, 30.0), title, tf, p.text)
  let desc = "在下方输入您的需求，或通过 / 调用命令、@ 引用上下文文件与技能。"
  let df = font_ui(12.0, 400)
  let dw = text_width(ts, desc, df)
  put(ctx, rect(cx - dw / 2.0, c.y + c.h * 0.34 + 34.0, dw + 2.0, 20.0), desc, df, p.text_3)
  let box = RectD::new(x=cx - 340.0, y=c.y + c.h * 0.34 + 84.0, w=680.0, h=96.0)
  panel(ctx, box, 16.0, p.surface, p.border_strong)
  put(ctx, rect(box.x + 14.0, box.y + 12.0, box.w - 28.0, 24.0), "输入消息开始对话…", font_ui(12.5, 400), p.text_faint)
  let pills = composer_pills(box)
  let pf = font_ui(10.5, 600)
  chip(ctx, ts, pills.perm, "Full Access", p.orange, p.surface_2, rgba8(0, 0, 0, 0.0), 10.5)
  chip(ctx, ts, pills.mode, "默认模式", p.text_2, p.surface_2, rgba8(0, 0, 0, 0.0), 10.5)
  chip(ctx, ts, pills.model, "claude-sonnet-4.5", p.text_2, p.surface_2, rgba8(0, 0, 0, 0.0), 10.5)
  let send = RectD::new(x=box.x + box.w - 44.0, y=box.y + box.h - 40.0, w=30.0, h=30.0)
  round_fill(ctx, rect_of(send), 15.0, p.accent)
  icon(ctx, "arrow-up", rect_of(send), 15.0, p.on_accent, 2.0)
  ignore(pf)
  ignore(model)
}

///|
/// The workbench destination mark: a wide panel with a slit beside two stacked
/// cells, matching the reference rail's first icon rather than a plain grid.
fn workbench_glyph(ctx : @common.PaintContext, s : RectD, color : @graphics.Color) -> Unit {
  let cx = s.x + s.w / 2.0
  let cy = s.y + s.h / 2.0
  let w = 15.0
  let h = 11.0
  let x0 = cx - w / 2.0
  let y0 = cy - h / 2.0
  // Left cell: a rounded plate with a vertical slit.
  round_stroke(ctx, rect(x0, y0, 6.0, h), 1.6, color, 1.7)
  line(ctx, x0 + 3.0, y0 + 2.4, x0 + 3.0, y0 + h - 2.4, color, 1.5)
  // Right side: two stacked cells.
  round_stroke(ctx, rect(x0 + 7.5, y0, 7.5, 4.4), 1.4, color, 1.7)
  round_stroke(ctx, rect(x0 + 7.5, y0 + 6.6, 7.5, 4.4), 1.4, color, 1.7)
}
