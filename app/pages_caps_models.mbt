// Capabilities and model configuration pages. Both follow the same body
// grammar: a 62px intro (title + subtitle + right actions), a 32px tab strip
// and a list of rows. Every row rect comes from the `*_rows` helpers here, so
// the paint pass and the hit-test in page_input.mbt always agree.

///|
/// Intro block height: title baseline, subtitle and the 18px gap under it.
pub const PAGE_INTRO_H : Double = 62.0

///|
pub const PAGE_TABS_H : Double = 32.0

///|
pub fn page_body_top(ps : PageShell, scroll : Double) -> Double {
  ps.content.y - scroll + PAGE_INTRO_H + PAGE_TABS_H + 18.0
}

///|
/// Title, subtitle and the optional right-hand action row of a page body.
pub fn page_intro(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  r : RectD,
  title : String,
  subtitle : String,
  p : Palette,
) -> Unit {
  tline(ctx, ts, title, font_ui(20.0, 600), p.text, r.x, r.y + 16.0, r.w - 200.0)
  tline(ctx, ts, subtitle, font_ui(12.0, 400), p.text_3, r.x, r.y + 42.0, r.w - 200.0)
}

///|
/// Bottom-right status pill, painted over the body as the local action echo of
/// pages that do not have a toast surface yet (stage 2 replaces it).
pub fn page_note_pill(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  ps : PageShell,
  note : String,
  p : Palette,
) -> Unit {
  if note == "" {
    return
  }
  let f = font_ui(11.5, 500)
  let w = text_width(ts, note, f) + 26.0
  let r = RectD::new(
    x=(ps.body.right() - 24.0 - w).max(ps.body.x + 8.0),
    y=ps.body.bottom() - 44.0,
    w~,
    h=28.0,
  )
  panel(ctx, r, 8.0, p.surface_2, p.border_strong)
  dot(ctx, r.x + 12.0, r.y + r.h / 2.0, 6.0, p.green)
  tline(ctx, ts, note, f, p.text_2, r.x + 22.0, r.y + r.h / 2.0, r.w - 32.0)
}

// ---------------------------------------------------------------------------
// Capabilities

///|
pub fn caps_tab_labels() -> Array[String] {
  ["Skills", "Plugins", "MCP", "Slash Commands", "扩展体系"]
}

///|
/// Tab index → the SkillRow.kind it lists; 4 is the overview tab.
pub fn caps_tab_kind(tab : Int) -> Int {
  match tab {
    0 => 0
    1 => 1
    2 => 2
    3 => 3
    _ => -1
  }
}

///|
pub fn caps_tabs_rect(ps : PageShell, scroll : Double) -> RectD {
  RectD::new(
    x=ps.content.x,
    y=ps.content.y - scroll + PAGE_INTRO_H,
    w=ps.content.w,
    h=PAGE_TABS_H,
  )
}

///|
/// Global indices of the rows this tab lists, so a toggle addresses the same
/// record the model keeps rather than a copy.
pub fn caps_rows(model : Model) -> Array[Int] {
  let out : Array[Int] = []
  let kind = caps_tab_kind(model.caps_tab)
  let mut i = 0
  for row in model.skills {
    if kind < 0 || row.kind == kind {
      out.push(i)
    }
    i = i + 1
  }
  out
}

///|
pub fn caps_row_slots(model : Model, ps : PageShell) -> Array[RectD] {
  let out : Array[RectD] = []
  let y0 = page_body_top(ps, model.page_scroll)
  for i in caps_rows(model) {
    let _ = i
    out.push(RectD::new(x=ps.content.x, y=y0 + out.length().to_double() * 76.0, w=ps.content.w, h=68.0))
  }
  out
}

///|
pub fn caps_row_action(r : RectD) -> RectD {
  RectD::new(x=r.right() - 88.0, y=r.y + (r.h - 26.0) / 2.0, w=74.0, h=26.0)
}

///|
fn caps_content_height(model : Model, _w : Double) -> Double {
  if caps_tab_kind(model.caps_tab) < 0 {
    112.0 + 168.0 + 24.0
  } else {
    112.0 + caps_rows(model).length().to_double() * 76.0 + 12.0
  }
}

///|
fn paint_capabilities(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  model : Model,
  c : RectD,
  ps : PageShell,
  p : Palette,
) -> Unit {
  let _ = c
  let intro = RectD::new(
    x=ps.content.x,
    y=ps.content.y - model.page_scroll,
    w=ps.content.w,
    h=PAGE_INTRO_H,
  )
  page_intro(ctx, ts, intro, "能力中心", "Slash 命令、技能、插件与 MCP 工具服务", p)
  let tabs = caps_tabs_rect(ps, model.page_scroll)
  page_segmented(ctx, ts, tabs, caps_tab_labels(), model.caps_tab, p)
  if caps_tab_kind(model.caps_tab) < 0 {
    paint_caps_overview(ctx, ts, model, ps, p)
    return
  }
  let rows = caps_row_slots(model, ps)
  let ids = caps_rows(model)
  let mut i = 0
  while i < rows.length() && i < ids.length() {
    let r = rows[i]
    let item = model.skills[ids[i]]
    page_card(ctx, r, p)
    // Row shape follows the reference `.cap-item-summary`: a small icon tile,
    // then a name line (name + kind chip), then the one-line summary.
    let tile = RectD::new(x=r.x + 14.0, y=r.y + 16.0, w=36.0, h=36.0)
    round_fill(ctx, rect_of(tile), 8.0, p.surface_2)
    icon(ctx, "package", rect_of(tile), 16.0, p.text_2, 1.6)
    tline(ctx, ts, item.name, font_mono(13.0), p.text, r.x + 62.0, r.y + 24.0, r.w - 260.0)
    let kind = kind_label(item.kind)
    let kw = text_width(ts, kind, font_ui(10.5, 500)) + 16.0
    let nx = r.x + 62.0 + text_width(ts, item.name, font_mono(13.0)) + 8.0
    page_tag(ctx, ts, RectD::new(x=nx, y=r.y + 16.0, w=kw, h=18.0), kind, p.text_3, p)
    tline(ctx, ts, item.desc, font_ui(11.5, 400), p.text_3, r.x + 62.0, r.y + 44.0, r.w - 260.0)
    let act = caps_row_action(r)
    if item.kind == 3 {
      page_btn(ctx, ts, act, "执行", false, p, hovered=hovering(model, act))
    } else {
      page_toggle(
        ctx,
        RectD::new(x=act.x + 19.0, y=act.y + 3.0, w=36.0, h=20.0),
        item.on,
        p,
      )
      tline_r(ctx, ts, if item.on { "已启用" } else { "已禁用" }, font_ui(10.5, 400), p.text_3, act.x - 8.0, act.y + act.h / 2.0, 60.0)
    }
    i = i + 1
  }
}

///|
fn paint_caps_overview(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  model : Model,
  ps : PageShell,
  p : Palette,
) -> Unit {
  let y0 = page_body_top(ps, model.page_scroll)
  let counts = capabilities_counts(model)
  let labels = ["技能", "插件", "MCP 服务器", "Slash 命令"]
  let gap = 12.0
  let w = (ps.content.w - gap * 3.0) / 4.0
  let mut i = 0
  while i < 4 {
    let r = RectD::new(x=ps.content.x + (w + gap) * i.to_double(), y=y0, w~, h=96.0)
    page_card(ctx, r, p)
    tline(ctx, ts, labels[i], font_ui(12.0, 400), p.text_3, r.x + 14.0, r.y + 22.0, w - 28.0)
    tline(ctx, ts, "\{counts[i]}", font_ui(26.0, 600), p.text, r.x + 14.0, r.y + 54.0, w - 28.0)
    tline(ctx, ts, if counts[i] > 0 { "已安装" } else { "未安装" }, font_ui(10.5, 400), p.text_3, r.x + 14.0, r.y + 78.0, w - 28.0)
    i = i + 1
  }
  let note = RectD::new(x=ps.content.x, y=y0 + 116.0, w=ps.content.w, h=48.0)
  page_card(ctx, note, p)
  tline(ctx, ts, "扩展体系：技能包提供工作流，插件包注册面板，MCP 服务器暴露工具，Slash 命令在 composer 里调用。", font_ui(12.0, 400), p.text_2, note.x + 16.0, note.y + 18.0, note.w - 32.0)
  tline(ctx, ts, "启用状态按能力逐项保存；同一会话内切换对下一次调用生效。", font_ui(11.0, 400), p.text_3, note.x + 16.0, note.y + 38.0, note.w - 32.0)
}

///|
pub fn capabilities_counts(model : Model) -> Array[Int] {
  let out = [0, 0, 0, 0]
  for row in model.skills {
    out[row.kind] = out[row.kind] + 1
  }
  out
}

// ---------------------------------------------------------------------------
// Model configuration

///|
pub fn model_tab_labels() -> Array[String] {
  ["供应商", "模型定义", "角色", "Fallback 链"]
}

///|
pub fn model_tabs_rect(ps : PageShell, scroll : Double) -> RectD {
  RectD::new(
    x=ps.content.x,
    y=ps.content.y - scroll + PAGE_INTRO_H,
    w=ps.content.w,
    h=PAGE_TABS_H,
  )
}

///|
pub fn provider_row_slots(model : Model, ps : PageShell) -> Array[RectD] {
  let out : Array[RectD] = []
  let y0 = page_body_top(ps, model.page_scroll)
  let mut i = 0
  while i < model.providers.length() {
    out.push(RectD::new(x=ps.content.x, y=y0 + i.to_double() * 94.0, w=ps.content.w, h=84.0))
    i = i + 1
  }
  out
}

///|
pub fn provider_toggle_rect(r : RectD) -> RectD {
  RectD::new(x=r.right() - 62.0, y=r.y + 14.0, w=36.0, h=20.0)
}

///|
pub fn provider_test_rect(r : RectD) -> RectD {
  RectD::new(x=r.right() - 62.0, y=r.y + 48.0, w=48.0, h=24.0)
}

///|
/// Flattened model catalogue: every provider's models in provider order.
pub fn model_rows(model : Model) -> Array[(Int, Int)] {
  let out : Array[(Int, Int)] = []
  let mut pi = 0
  for prov in model.providers {
    let mut mi = 0
    for _m in prov.models {
      out.push((pi, mi))
      mi = mi + 1
    }
    pi = pi + 1
  }
  out
}

///|
pub fn model_row_slots(model : Model, ps : PageShell) -> Array[RectD] {
  let out : Array[RectD] = []
  let y0 = page_body_top(ps, model.page_scroll)
  for _row in model_rows(model) {
    out.push(RectD::new(x=ps.content.x, y=y0 + out.length().to_double() * 56.0, w=ps.content.w, h=48.0))
  }
  out
}

///|
pub fn role_row_slots(model : Model, ps : PageShell) -> Array[RectD] {
  let out : Array[RectD] = []
  let y0 = page_body_top(ps, model.page_scroll)
  let mut i = 0
  while i < model.role_routes.length() {
    out.push(RectD::new(x=ps.content.x, y=y0 + i.to_double() * 68.0, w=ps.content.w, h=60.0))
    i = i + 1
  }
  out
}

///|
pub fn fallback_row_slots(model : Model, ps : PageShell) -> Array[RectD] {
  let out : Array[RectD] = []
  let y0 = page_body_top(ps, model.page_scroll)
  let mut i = 0
  while i < 3 {
    out.push(RectD::new(x=ps.content.x, y=y0 + i.to_double() * 60.0, w=ps.content.w, h=52.0))
    i = i + 1
  }
  out
}

///|
fn model_content_height(model : Model, _w : Double) -> Double {
  match model.model_tab {
    0 => 112.0 + model.providers.length().to_double() * 94.0 + 12.0
    1 => 112.0 + model_rows(model).length().to_double() * 56.0 + 12.0
    2 => 112.0 + model.role_routes.length().to_double() * 68.0 + 12.0
    _ => 112.0 + 3.0 * 60.0 + 12.0
  }
}

///|
fn paint_model_config(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  model : Model,
  c : RectD,
  ps : PageShell,
  p : Palette,
) -> Unit {
  let _ = c
  let intro = RectD::new(
    x=ps.content.x,
    y=ps.content.y - model.page_scroll,
    w=ps.content.w,
    h=PAGE_INTRO_H,
  )
  page_intro(ctx, ts, intro, "模型配置", "Provider 预设、API 凭证、模型路由与角色定义", p)
  page_segmented(ctx, ts, model_tabs_rect(ps, model.page_scroll), model_tab_labels(), model.model_tab, p)
  match model.model_tab {
    0 => paint_providers(ctx, ts, model, ps, p)
    1 => paint_models(ctx, ts, model, ps, p)
    2 => paint_roles(ctx, ts, model, ps, p)
    _ => paint_fallbacks(ctx, ts, model, ps, p)
  }
}

///|
fn paint_providers(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  model : Model,
  ps : PageShell,
  p : Palette,
) -> Unit {
  let rows = provider_row_slots(model, ps)
  let mut i = 0
  while i < rows.length() {
    let r = rows[i]
    let prov = model.providers[i]
    let selected = i == model.active_provider
    page_card(ctx, r, p)
    if selected {
      round_stroke(ctx, rect_of(r), 10.0, p.accent_border, 1.5)
    }
    tline(ctx, ts, prov.name, font_ui(14.0, 600), p.text, r.x + 14.0, r.y + 22.0, r.w - 200.0)
    let badge = if i == 0 || i == 1 { "原生" } else if i == 3 { "本地" } else { "第三方" }
    page_tag(ctx, ts, RectD::new(x=r.x + 14.0, y=r.y + 36.0, w=text_width(ts, badge, font_ui(10.5, 500)) + 16.0, h=18.0), badge, p.text_3, p)
    tline(ctx, ts, prov.base, font_mono(11.0), p.text_3, r.x + 84.0, r.y + 45.0, r.w - 300.0)
    let models_label = "\{prov.models.length()} 个模型 · \{prov.key_hint}"
    tline(ctx, ts, models_label, font_ui(11.0, 400), if prov.key_ok { p.text_3 } else { p.amber }, r.x + 14.0, r.y + 66.0, r.w - 200.0)
    let toggle = provider_toggle_rect(r)
    page_toggle(ctx, toggle, prov.on, p)
    let tbtn = provider_test_rect(r)
    page_btn(ctx, ts, tbtn, "测试", false, p, hovered=hovering(model, tbtn))
    i = i + 1
  }
}

///|
fn paint_models(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  model : Model,
  ps : PageShell,
  p : Palette,
) -> Unit {
  let rows = model_row_slots(model, ps)
  let ids = model_rows(model)
  let mut i = 0
  while i < rows.length() && i < ids.length() {
    let r = rows[i]
    let (pi, mi) = ids[i]
    let prov = model.providers[pi]
    let name = prov.models[mi]
    page_card(ctx, r, p)
    let selected = i == model.active_model
    dot(ctx, r.x + 20.0, r.y + r.h / 2.0, 8.0, if selected { p.accent } else { p.border_strong })
    tline(ctx, ts, name, font_mono(12.5), p.text, r.x + 36.0, r.y + 16.0, r.w - 260.0)
    tline(ctx, ts, prov.name, font_ui(11.0, 400), p.text_3, r.x + 36.0, r.y + 33.0, r.w - 260.0)
    let caps = if pi == 0 { "思考 · 工具 · 图片" } else if pi == 1 { "思考 · 工具" } else if pi == 3 { "工具" } else { "工具" }
    tline_r(ctx, ts, caps, font_ui(10.5, 400), p.text_faint, r.right() - 14.0, r.y + r.h / 2.0, 150.0)
    i = i + 1
  }
}

///|
fn paint_roles(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  model : Model,
  ps : PageShell,
  p : Palette,
) -> Unit {
  let rows = role_row_slots(model, ps)
  let mut i = 0
  while i < rows.length() {
    let r = rows[i]
    let role = model.role_routes[i]
    page_card(ctx, r, p)
    tline(ctx, ts, role.role, font_ui(13.5, 600), p.text, r.x + 14.0, r.y + 20.0, r.w - 360.0)
    tline(ctx, ts, role.note, font_ui(11.5, 400), p.text_3, r.x + 14.0, r.y + 40.0, r.w - 360.0)
    let mw = text_width(ts, role.model, font_mono(11.5)) + 24.0
    page_tag(ctx, ts, RectD::new(x=r.right() - 14.0 - mw - 76.0, y=r.y + 19.0, w=mw, h=22.0), role.model, p.text_2, p)
    tline_r(ctx, ts, "⇄ 点击切换", font_ui(10.5, 400), p.text_faint, r.right() - 14.0, r.y + 30.0, 70.0)
    i = i + 1
  }
}

///|
fn paint_fallbacks(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  model : Model,
  ps : PageShell,
  p : Palette,
) -> Unit {
  let rows = fallback_row_slots(model, ps)
  let primaries = ["claude-sonnet-4.5", "gpt-5.2", "local/qwen3-coder-30b"]
  let chains = [
    ["gpt-5.2", "claude-haiku-4", "deepseek-v4-flash"],
    ["claude-sonnet-4.5", "deepseek-v4-flash"],
    ["deepseek-v4-flash"],
  ]
  let mut i = 0
  while i < rows.length() {
    let r = rows[i]
    page_card(ctx, r, p)
    tline(ctx, ts, primaries[i], font_mono(12.0), p.text, r.x + 14.0, r.y + 26.0, 260.0)
    let chain = chains[i]
    let mut x = r.x + 250.0
    for fallback in chain {
      let w = text_width(ts, fallback, font_mono(11.0)) + 20.0
      page_tag(ctx, ts, RectD::new(x~, y=r.y + 15.0, w~, h=22.0), fallback, p.text_3, p)
      x = x + w + 8.0
    }
    tline_r(ctx, ts, "恢复策略 retry.fallbackRevertPolicy", font_ui(10.5, 400), p.text_faint, r.right() - 14.0, r.y + 26.0, 240.0)
    i = i + 1
  }
}
