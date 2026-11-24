// ⌘K command palette. The catalog mirrors the reference's
// `commandPaletteCatalog.ts`: recent sessions first, then recommended actions,
// page navigation, panel toggles and the config shortcuts that land directly on
// a settings / model / capability tab. Groups are filtered as a whole (empty
// groups disappear) and flattened into one list so ↑ ↓ / ⏎ only ever deal with
// a plain index.

///|
pub(all) enum PaletteAction {
  PRoute(Route)
  PWindow(Int)
  PTheme
  PSidebar
  PExplorer
  PDensity
  PSnap
  PLatest
  PSettings(Int)
  PModel(Int)
  PCaps(Int)
  /// The three shell dialogs, reachable from the same catalog as everything
  /// else so no command is pointer-only.
  PRename
  PShortcuts
  PResetLayout
}

///|
pub(all) struct CmdItem {
  id : String
  label : String
  meta : String
  keys : String
  icon : String
  keywords : String
  action : PaletteAction
}

///|
pub(all) struct CmdGroup {
  id : String
  label : String
  items : Array[CmdItem]
}

///|
fn cmd(
  id : String,
  label : String,
  meta : String,
  keys : String,
  icon : String,
  keywords : String,
  action : PaletteAction,
) -> CmdItem {
  { id, label, meta, keys, icon, keywords, action }
}

///|
/// Recently opened sessions, mirroring the reference's `recents`: the first
/// nine windows get ⌘1..⌘9 so a switch is one keystroke away. A minimised
/// window still shows up here — choosing it restores it.
pub fn palette_recents(model : Model) -> Array[CmdItem] {
  let out : Array[CmdItem] = []
  let mut i = 0
  for win in model.windows {
    if i < 9 {
      let meta = if win.thread >= 0 && win.thread < model.threads.length() {
        let project = model.threads[win.thread].project
        if win.minimized {
          project + " · 已最小化"
        } else {
          project
        }
      } else if win.minimized {
        "已最小化"
      } else {
        ""
      }
      out.push(
        cmd(
          "win:\{win.id}",
          win.title,
          meta,
          "⌘\{(i + 1)}",
          "message",
          win.title,
          PWindow(win.id),
        ),
      )
      i = i + 1
    }
  }
  out
}

///|
fn palette_settings_group() -> Array[CmdItem] {
  let labels = settings_tab_labels()
  let out : Array[CmdItem] = []
  let mut i = 0
  for label in labels {
    out.push(
      cmd(
        "settings:\{i}",
        "设置 · " + label,
        "配置",
        "",
        "settings",
        "settings " + label,
        PSettings(i),
      ),
    )
    i = i + 1
  }
  out
}

///|
fn palette_models_group() -> Array[CmdItem] {
  let labels = model_tab_labels()
  let out : Array[CmdItem] = []
  let mut i = 0
  for label in labels {
    out.push(
      cmd(
        "models:\{i}",
        "模型配置 · " + label,
        "配置",
        "",
        "server",
        "model " + label,
        PModel(i),
      ),
    )
    i = i + 1
  }
  out
}

///|
fn palette_caps_group() -> Array[CmdItem] {
  let labels = caps_tab_labels()
  let out : Array[CmdItem] = []
  let mut i = 0
  for label in labels {
    out.push(
      cmd(
        "caps:\{i}",
        "能力中心 · " + label,
        "配置",
        "",
        "package",
        "capabilities " + label,
        PCaps(i),
      ),
    )
    i = i + 1
  }
  out
}

///|
/// The full catalog for this model, unfiltered. Reference order: recents,
/// recommended, pages, panels, config.
pub fn palette_catalog(model : Model) -> Array[CmdGroup] {
  let groups : Array[CmdGroup] = []
  let recents = palette_recents(model)
  if !recents.is_empty() {
    groups.push({ id: "chat", label: "最近会话", items: recents })
  }
  groups.push({
    id: "recommended",
    label: "推荐操作",
    items: [
      cmd("new-chat", "新建会话窗", "会话", "⇧⌘O", "plus", "new chat window 新建", PWindow(-1)),
      cmd("history", "打开会话历史", "页面", "", "history", "history 会话历史 time travel", PRoute(History)),
      cmd("skills", "打开技能与插件", "页面", "", "package", "skills plugins 技能 插件", PCaps(0)),
      cmd("settings", "打开设置", "页面", "", "settings", "settings 设置", PSettings(0)),
      cmd("rename", "重命名当前会话", "会话", "F2", "pencil", "rename 重命名 会话 标题", PRename),
    ],
  })
  let pages : Array[CmdItem] = []
  for route in all_routes() {
    pages.push(
      cmd(
        "route:\{route_slug(route)}",
        route.label(),
        "导航",
        "",
        route.icon(),
        route.label() + " " + route_slug(route),
        PRoute(route),
      ),
    )
  }
  groups.push({ id: "pages", label: "页面导航", items: pages })
  groups.push({
    id: "panels",
    label: "面板与视图",
    items: [
      cmd("sidebar", "切换侧栏", "布局", "⌘B", "panel-left", "sidebar 侧栏 切换", PSidebar),
      cmd("explorer", "切换 Explorer", "布局", "", "folder-open", "explorer files 文件树", PExplorer),
      cmd("density", "切换密度", "外观", "", "columns-3", "density 密度 紧凑", PDensity),
      cmd("snap", "吸附布局模板", "布局", "", "columns-3", "snap layout 吸附 布局", PSnap),
      cmd("latest", "回到最新消息", "会话", "", "chevron-down", "latest scroll 最新 回到", PLatest),
      cmd("theme", "切换主题", "外观", "", "sun", "theme dark light 主题 亮 暗", PTheme),
      cmd("shortcuts", "快捷键表", "帮助", "⌘/", "keyboard", "shortcuts 快捷键 帮助 keyboard", PShortcuts),
      cmd("reset-layout", "重置布局…", "布局", "", "rotate-ccw", "reset layout 重置 恢复 默认 布局", PResetLayout),
    ],
  })
  let config : Array[CmdItem] = []
  for item in palette_settings_group() {
    config.push(item)
  }
  for item in palette_models_group() {
    config.push(item)
  }
  for item in palette_caps_group() {
    config.push(item)
  }
  groups.push({ id: "config", label: "配置与设置", items: config })
  groups
}

///|
/// Groups that survive `query`. An empty query keeps everything; matching is
/// case-folded over label, meta, shortcut spelling and keywords, which is what
/// the reference does for its Chinese and English labels alike.
pub fn palette_groups(model : Model) -> Array[CmdGroup] {
  let q = model.palette_query.trim().to_lower()
  let out : Array[CmdGroup] = []
  for group in palette_catalog(model) {
    if q == "" {
      out.push(group)
    } else {
      let items : Array[CmdItem] = []
      for item in group.items {
        let hay = (item.label + " " + item.meta + " " + item.keys + " " + item.keywords).to_lower()
        if hay.contains(q) {
          items.push(item)
        }
      }
      if !items.is_empty() {
        out.push({ ..group, items, })
      }
    }
  }
  out
}

///|
/// One flat list for index maths. `palette_groups` keeps the grouping for paint.
pub fn palette_items(model : Model) -> Array[CmdItem] {
  let out : Array[CmdItem] = []
  for group in palette_groups(model) {
    for item in group.items {
      out.push(item)
    }
  }
  out
}

///|
/// Flat index of the recent row that wears ⌘<digit>, or -1. The digits are the
/// reference's quick-switch: ⌘1 is the first recent, ⌘9 the ninth.
pub fn palette_shortcut_row(model : Model, digit : String) -> Int {
  let items = palette_items(model)
  let want = "⌘" + digit
  let mut i = 0
  for item in items {
    if item.keys == want {
      return i
    }
    i = i + 1
  }
  -1
}

// ---------------------------------------------------------------------------
// Layout. The reference paints `.cmdk-shell` at min(680px, 100vw - 40px) by
// min(680px, 100vh - 48px), centred, over a 45%-black backdrop; the input row is
// 14/18 padding over a 16px field, then an 8px-padded scrolling list.

///|
pub const PALETTE_MAX : Double = 680.0

///|
pub const PALETTE_RADIUS : Double = 28.0

///|
pub const PALETTE_INPUT_H : Double = 53.0

///|
pub const PALETTE_ITEM_H : Double = 34.0

///|
pub const PALETTE_GROUP_H : Double = 24.0

/// `.cmdk-group + .cmdk-group { margin-top: var(--sp-6) }`.
///
///|
pub const PALETTE_GROUP_GAP : Double = 6.0

///|
pub const PALETTE_LIST_PAD : Double = 8.0

///|
pub fn palette_panel_rect(w : Double, h : Double) -> RectD {
  let pw = (w - 40.0).min(PALETTE_MAX)
  let ph = (h - 48.0).min(PALETTE_MAX)
  RectD::new(x=(w - pw) / 2.0, y=(h - ph) / 2.0, w=pw, h=ph)
}

///|
pub fn palette_list_rect(panel : RectD) -> RectD {
  RectD::new(
    x=panel.x + PALETTE_LIST_PAD,
    y=panel.y + PALETTE_INPUT_H,
    w=panel.w - PALETTE_LIST_PAD * 2.0,
    h=(panel.h - PALETTE_INPUT_H - PALETTE_LIST_PAD - 12.0).max(1.0),
  )
}

///|
/// A painted line: a group caption or one flat-list row. The caption carries a
/// flag for every group but the first, which sits 6px lower (the reference's
/// `.cmdk-group + .cmdk-group` margin).
pub(all) enum PaletteLine {
  PaletteGroupLabel(String, Bool)
  PaletteItemRow(Int)
}

///|
pub fn palette_line_height(line : PaletteLine) -> Double {
  match line {
    PaletteGroupLabel(_, spaced) => PALETTE_GROUP_H + (if spaced {
      PALETTE_GROUP_GAP
    } else {
      0.0
    })
    PaletteItemRow(_) => PALETTE_ITEM_H
  }
}

///|
pub fn palette_lines(model : Model) -> Array[PaletteLine] {
  let out : Array[PaletteLine] = []
  let mut index = 0
  let mut first = true
  for group in palette_groups(model) {
    out.push(PaletteGroupLabel(group.label, !first))
    first = false
    for _item in group.items {
      out.push(PaletteItemRow(index))
      index = index + 1
    }
  }
  out
}

///|
pub fn palette_content_h(lines : Array[PaletteLine]) -> Double {
  let mut total = 0.0
  for line in lines {
    total = total + palette_line_height(line)
  }
  total
}

///|
pub fn palette_scroll_max(model : Model) -> Double {
  let panel = palette_panel_rect(model.frame_w, model.frame_h)
  let list = palette_list_rect(panel)
  (palette_content_h(palette_lines(model)) - list.h).max(0.0)
}

///|
fn palette_item_top(lines : Array[PaletteLine], index : Int) -> Double {
  let mut y = 0.0
  for line in lines {
    match line {
      PaletteItemRow(i) => if i == index {
        return y
      }
      _ => ()
    }
    y = y + palette_line_height(line)
  }
  y
}

///|
/// Clamps the list offset and keeps the selected row inside the viewport, the
/// same contract as the reference's `scrollIntoView({ block: "nearest" })`.
pub fn palette_reveal(model : Model) -> Model {
  let panel = palette_panel_rect(model.frame_w, model.frame_h)
  let list = palette_list_rect(panel)
  let lines = palette_lines(model)
  let max_off = (palette_content_h(lines) - list.h).max(0.0)
  let top = palette_item_top(lines, model.palette_index)
  let mut off = model.palette_scroll.max(0.0).min(max_off)
  if top < off {
    off = top
  } else if top + PALETTE_ITEM_H > off + list.h {
    off = top + PALETTE_ITEM_H - list.h
  }
  { ..model, palette_scroll: off.max(0.0).min(max_off) }
}

///|
/// Flat index of the row under the pointer, or -1 when the pointer is on a
/// group caption / empty list space. Paint and hit-testing share this walk.
pub fn palette_row_at(model : Model, x : Double, y : Double) -> Int {
  let panel = palette_panel_rect(model.frame_w, model.frame_h)
  let list = palette_list_rect(panel)
  if !list.contains(x, y) {
    return -1
  }
  let lines = palette_lines(model)
  let mut top = list.y - model.palette_scroll
  for line in lines {
    let h = palette_line_height(line)
    if y >= top && y < top + h {
      match line {
        PaletteItemRow(i) => return i
        PaletteGroupLabel(_, _) => return -1
      }
    }
    top = top + h
  }
  -1
}

// ---------------------------------------------------------------------------
// Drawing

///|
/// The reference rings the panel with a conic gradient (blue → accent →
/// accent/red mix, three times) and blurs it into a 22px glow. A canvas cannot
/// blur a shape, so the halo is a stack of outward strokes at falling alpha,
/// which reads the same at screenshot distance.
fn palette_ring(model : Model, p : Palette, alpha : Double) -> @graphics.Brush {
  let panel = palette_panel_rect(model.frame_w, model.frame_h)
  let blue = p.blue.with_alpha(alpha)
  let accent = p.accent.with_alpha(alpha)
  let hot = p.accent.mix(p.red, 0.55).with_alpha(alpha)
  let stops : Array[@core.GradientStop] = [
    @core.GradientStop::new(color=blue, at=0.0),
    @core.GradientStop::new(color=accent, at=0.111),
    @core.GradientStop::new(color=hot, at=0.222),
    @core.GradientStop::new(color=blue, at=0.333),
    @core.GradientStop::new(color=accent, at=0.444),
    @core.GradientStop::new(color=hot, at=0.555),
    @core.GradientStop::new(color=blue, at=0.666),
    @core.GradientStop::new(color=accent, at=0.777),
    @core.GradientStop::new(color=hot, at=0.888),
    @core.GradientStop::new(color=blue, at=1.0),
  ]
  @graphics.Brush::conic(center=@geometry.Point::new(x=panel.x + 150.0, y=panel.y + 90.0), stops~, angle_degrees=125.0)
}

///|
/// The halo behind the shell: the reference blurs a conic ring, which a canvas
/// cannot do directly, so four offset shadows (blue, accent, the accent/red mix
/// and blue again) paint the hue sweep around the panel. The panel fill covers
/// everything inside, leaving only the outer bloom.
fn palette_glow(
  ctx : @common.PaintContext,
  model : Model,
  p : Palette,
) -> Unit {
  let panel = palette_panel_rect(model.frame_w, model.frame_h)
  let rr = @graphics.RoundedRect::new(rect=rect_of(panel), radius=PALETTE_RADIUS)
  let hot = p.accent.mix(p.red, 0.55)
  // Three concentric blooms instead of the reference's blurred conic ring: the
  // canvas has no blur filter, and offset shadows smeared to one side. Outer
  // blue, inner accent, a faint warm edge — the same halo, still symmetric.
  let layers : Array[(@graphics.Color, Double, Double, Double)] = [
    (p.blue, 34.0, 0.0, 0.13),
    (hot, 24.0, 1.0, 0.10),
    (p.accent, 16.0, 0.0, 0.16),
  ]
  for layer in layers {
    @views.draw_shadow(
      ctx,
      @graphics.ShadowSpec::new(
        rect=rr,
        color=layer.0.with_alpha(layer.3),
        offset=@geometry.Point::new(x=0.0, y=0.0),
        blur_radius=layer.1,
        spread=layer.2,
      ),
    )
  }
}

///|
fn kbd_chip(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  r : RectD,
  s : String,
  p : Palette,
) -> Unit {
  round_fill(ctx, rect_of(r), 4.0, p.surface)
  round_stroke(ctx, rect_of(r), 4.0, p.border_strong, 1.0)
  hair(ctx, r.x + 3.0, r.bottom() - 1.0, r.right() - 3.0, r.bottom() - 1.0, p.border_strong)
  let f = font_mono(10.5)
  put_c(ctx, rect_of(r), s, f, p.text_3)
  ignore(ts)
}

///|
pub fn paint_palette(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  model : Model,
  shell : Shell,
  p : Palette,
) -> Unit {
  let items = palette_items(model)
  let lines = palette_lines(model)
  let panel = palette_panel_rect(shell.w, shell.h)
  let list = palette_list_rect(panel)
  // Backdrop: `rgba(15,15,25,.28)` light, `rgba(0,0,0,.45)` dark.
  let backdrop = if p.dark {
    @graphics.Color::rgba(r=0.0, g=0.0, b=0.0, a=0.45)
  } else {
    rgba8(0x0f, 0x0f, 0x19, 0.28)
  }
  fill(ctx, rect(0.0, 0.0, shell.w, shell.h), backdrop)
  // `box-shadow: 0 18px 48px color-mix(in srgb, var(--text) 16%, transparent)`.
  @views.draw_shadow(
    ctx,
    @graphics.ShadowSpec::new(
      rect=@graphics.RoundedRect::new(rect=rect_of(panel), radius=PALETTE_RADIUS),
      color=p.text.with_alpha(0.16),
      offset=@geometry.Point::new(x=0.0, y=18.0),
      blur_radius=48.0,
      spread=0.0,
    ),
  )
  palette_glow(ctx, model, p)
  round_fill(ctx, rect_of(panel), PALETTE_RADIUS, p.surface)
  @views.stroke_rounded_rect(
    ctx,
    @graphics.RoundedRect::new(rect=rect_of(panel), radius=PALETTE_RADIUS),
    palette_ring(model, p, 0.95),
    1.5,
  )
  // Input row: 18px gutter, a 14px magnifier, a 16px field and the Esc chip.
  let iy = panel.y + 14.0
  icon(ctx, "search", rect(panel.x + 18.0, iy + 4.0, 14.0, 14.0), 14.0, p.text_3, 1.6)
  let f = font_ui(16.0, 400)
  let field_x = panel.x + 42.0
  let field_w = panel.w - 42.0 - 18.0 - 40.0
  if model.palette_query == "" {
    put(ctx, rect(field_x, iy, field_w, 22.0), "输入命令或搜索…", f, p.text_faint)
  } else {
    let shown = ellipsize(ts, model.palette_query, f, field_w)
    put(ctx, rect(field_x, iy, field_w, 22.0), shown, f, p.text)
    let cw = text_width(ts, shown, f)
    fill(ctx, rect(field_x + cw + 1.0, iy + 2.0, 1.5, 18.0), p.accent)
  }
  let esc_w = text_width(ts, "Esc", font_mono(10.5)) + 14.0
  kbd_chip(
    ctx,
    ts,
    RectD::new(x=panel.right() - 18.0 - esc_w, y=iy + 1.0, w=esc_w, h=20.0),
    "Esc",
    p,
  )
  hair(ctx, panel.x, panel.y + PALETTE_INPUT_H, panel.right(), panel.y + PALETTE_INPUT_H, p.border)
  clip_rect(ctx, rect_of(list))
  if items.is_empty() {
    let f13 = font_ui(13.0, 400)
    icon(ctx, "search", rect(list.x + list.w / 2.0 - 12.0, list.y + list.h / 2.0 - 34.0, 24.0, 24.0), 24.0, p.text_3, 1.7)
    put_c(ctx, rect(list.x, list.y + list.h / 2.0 - 4.0, list.w, 20.0), "未找到匹配的命令或项目", f13, p.text_3)
  } else {
    let mut top = list.y - model.palette_scroll
    for line in lines {
      let h = palette_line_height(line)
      if top + h >= list.y && top <= list.bottom() {
        match line {
          PaletteGroupLabel(text, spaced) =>
            put(
              ctx,
              rect(
                list.x + 10.0,
                top + (if spaced { PALETTE_GROUP_GAP } else { 0.0 }) + 4.0,
                list.w - 20.0,
                16.0,
              ),
              text,
              font_ui(11.0, 500),
              p.text_faint,
            )
          PaletteItemRow(idx) => {
            let item = items[idx]
            let r = RectD::new(x=list.x, y=top, w=list.w, h=34.0)
            if idx == model.palette_index || hovering(model, r) {
              round_fill(ctx, rect_of(r), 6.0, p.surface_hover)
            }
            icon(ctx, item.icon, rect(r.x + 10.0, r.y + 10.0, 14.0, 14.0), 14.0, p.text_3, 1.6)
            let lf = font_ui(14.0, 400)
            put(ctx, rect(r.x + 34.0, r.y + 7.0, r.w - 120.0, 20.0), ellipsize(ts, item.label, lf, r.w - 120.0), lf, p.text)
            if item.meta != "" {
              let mf = font_ui(12.0, 400)
              // `.cmdk-item-meta` sits 10px gap + 4px margin past the label.
              let mw = text_width(ts, item.label, lf) + 34.0 + 14.0
              put(ctx, rect(r.x + mw, r.y + 8.0, r.w - mw - 90.0, 18.0), ellipsize(ts, item.meta, mf, (r.w - mw - 90.0).max(0.0)), mf, p.text_faint)
            }
            if item.keys != "" {
              let kf = font_mono(10.5)
              let kw = text_width(ts, item.keys, kf) + 14.0
              kbd_chip(ctx, ts, RectD::new(x=r.right() - 10.0 - kw, y=r.y + 7.0, w=kw, h=20.0), item.keys, p)
            }
          }
        }
      }
      top = top + h
    }
  }
  unclip_rect(ctx)
}

// ---------------------------------------------------------------------------
// Behaviour. Choosing a row closes the palette; the item's surface takes over.

///|
/// Executes the row at `index` in the filtered flat list. Runs always close the
/// palette, like the reference: the destination is what the user asked for.
pub fn palette_run(model : Model, index : Int) -> Model {
  let items = palette_items(model)
  if index < 0 || index >= items.length() {
    return model
  }
  let action = items[index].action
  let closed = { ..model, palette_open: false, palette_query: "", palette_index: 0, palette_scroll: 0.0 }
  match action {
    PRoute(route) => go_route(closed, route)
    PWindow(id) =>
      if id < 0 {
        update(closed, NewWindow)
      } else {
        let restored = restore_window(closed, id)
        if restored.route != Workbench {
          go_route(restored, Workbench)
        } else {
          restored
        }
      }
    PTheme => update(closed, ToggleTheme)
    PSidebar => update(closed, ToggleSidebar)
    PExplorer => update(closed, ToggleExplorer)
    PDensity => update(closed, ToggleDensity)
    PSnap => update(closed, OpenPicker(closed.active))
    PLatest => { ..closed, convo_scroll: 0.0 }
    PSettings(tab) => { ..go_route(closed, Settings), settings_tab: tab, }
    PModel(tab) => { ..go_route(closed, ModelConfig), model_tab: tab, }
    PCaps(tab) => { ..go_route(closed, Capabilities), caps_tab: tab, }
    PRename => modal_open_now(closed, MRename)
    PShortcuts => modal_open_now(closed, MShortcuts)
    PResetLayout => modal_open_now(closed, MConfirm)
  }
}
