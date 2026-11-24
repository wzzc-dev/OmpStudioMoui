// Secondary pages: the page frame (head + scrolling body) plus the home and
// history pages. Layout helpers here are shared with page_input.mbt so every
// control is hit-tested exactly where it is painted.

///|
pub fn paint_page(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  model : Model,
  w : Double,
  h : Double,
  p : Palette,
) -> Unit {
  let ps = page_shell(w, h)
  // Fill the whole shell first: the rail is painted over its own column.
  fill(ctx, rect(0.0, 0.0, w, h), p.bg)
  fill(ctx, rect_of(ps.head), p.bg)
  hair(ctx, ps.head.x, ps.head.bottom(), ps.head.right(), ps.head.bottom(), p.border)
  paint_page_head(ctx, ts, model, ps, p)
  let scroll = model.page_scroll
  let body_r = rect_of(ps.body)
  clip_rect(ctx, body_r)
  let content = RectD::new(
    x=ps.content.x,
    y=ps.content.y - scroll,
    w=ps.content.w,
    h=(page_content_height(model, ps) - scroll).max(1.0),
  )
  match model.route {
    Home => paint_home(ctx, ts, model, content, ps, p)
    History => paint_history(ctx, ts, model, content, ps, p)
    Capabilities => paint_capabilities(ctx, ts, model, content, ps, p)
    ModelConfig => paint_model_config(ctx, ts, model, content, ps, p)
    Settings => paint_settings(ctx, ts, model, content, ps, p)
    Statistics => paint_statistics(ctx, ts, model, content, ps, p)
    Diagnostics => paint_diagnostics(ctx, ts, model, content, ps, p)
    Evaluation => paint_evaluation(ctx, ts, model, content, ps, p)
    Media => paint_media(ctx, ts, model, content, ps, p)
    AgentHub => paint_agent_hub(ctx, ts, model, content, ps, p)
    Workbench => ()
  }
  unclip_rect(ctx)
  paint_page_scrollbar(ctx, model, ps, p)
  page_note_pill(ctx, ts, ps, model.page_note, p)
}

///|
fn paint_page_head(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  model : Model,
  ps : PageShell,
  p : Palette,
) -> Unit {
  let back = page_back_btn(ps)
  if hovering(model, back) {
    round_fill(ctx, rect_of(back), 6.0, p.surface_hover)
  }
  icon(ctx, "arrow-left", rect_of(back), 15.0, if hovering(model, back) { p.text } else { p.text_2 }, 1.7)
  let title = page_title_rect(ps)
  let cy = title.y + title.h / 2.0
  icon(ctx, model.route.icon(), rect(title.x, cy - 8.0, 16.0, 16.0), 15.0, p.text_2, 1.6)
  tline(ctx, ts, model.route.label(), font_ui(14.0, 600), p.text, title.x + 24.0, cy, title.w - 24.0)
  let slots = page_nav_slots(ps)
  let mut i = 0
  for route in page_nav_routes() {
    let slot = slots[i]
    if slot.right() <= page_theme_btn(ps).x - 8.0 {
      let active = route == model.route
      let hot = !active && hovering(model, slot)
      if active {
        round_fill(ctx, rect_of(slot), 6.0, p.accent_soft)
      } else if hot {
        round_fill(ctx, rect_of(slot), 6.0, p.surface_hover)
      }
      let fg = if active { p.accent } else if hot { p.text } else { p.text_3 }
      icon(ctx, route.icon(), rect(slot.x + 10.0, slot.y + 8.0, 14.0, 14.0), 13.0, fg, 1.6)
      // The pill is sized from the label's 12px advance, so give the line the
      // last 4px of the right padding as slack: a metric that rounds a hair
      // wider must not turn the label into an ellipsis (the reference never
      // truncates `.page-nav a` labels).
      tline(ctx, ts, route.label(), font_ui(12.0, 500), fg, slot.x + 30.0, slot.y + slot.h / 2.0, slot.w - 34.0)
    }
    i = i + 1
  }
  let theme = page_theme_btn(ps)
  if hovering(model, theme) {
    round_fill(ctx, rect_of(theme), 6.0, p.surface_hover)
  }
  icon(ctx, if model.dark { "moon" } else { "sun" }, rect_of(theme), 16.0, p.text_2, 1.6)
}

///|
fn paint_page_scrollbar(
  ctx : @common.PaintContext,
  model : Model,
  ps : PageShell,
  p : Palette,
) -> Unit {
  let limit = page_max_scroll(model, ps)
  if limit <= 1.0 {
    return
  }
  let track_y = ps.scroll_track.y
  let track_h = ps.scroll_track.h
  let visible = ps.body.h
  let total = visible + limit
  let thumb_h = (track_h * visible / total).max(28.0)
  let thumb_y = track_y + (track_h - thumb_h) * (model.page_scroll / limit)
  round_fill(ctx, rect(ps.scroll_track.x, thumb_y, ps.scroll_track.w, thumb_h), 2.0, p.surface_3)
}

///|
/// Total scrollable height of the current page's content, measured without a
/// text system from the same fixed row pitches the painters use.
pub fn page_content_height(model : Model, ps : PageShell) -> Double {
  let w = ps.content.w
  match model.route {
    Home => home_content_height(model, w)
    History => history_content_height(model, w)
    Capabilities => caps_content_height(model, w)
    ModelConfig => model_content_height(model, w)
    Settings => settings_content_height(model, w)
    Statistics => stats_content_height(model, w)
    Diagnostics => diag_content_height(model, w)
    Evaluation => eval_content_height(model, w)
    Media => media_content_height(model, w)
    AgentHub => hub_content_height(model, w)
    Workbench => 0.0
  }
}

///|
fn home_quick_labels() -> Array[String] {
  ["打开本地文件夹", "安装运行时", "克隆 Git 仓库", "恢复最近会话", "临时工作区"]
}

///|
fn home_quick_widths() -> Array[Double] {
  [130.0, 110.0, 128.0, 122.0, 110.0]
}

///|
pub fn home_quick_slots(model : Model, ps : PageShell) -> Array[RectD] {
  let _ = model
  let out : Array[RectD] = []
  let widths = home_quick_widths()
  let y = ps.content.y + 84.0 - model.page_scroll
  let mut x = ps.content.x
  let mut i = 0
  while i < widths.length() {
    out.push(RectD::new(x~, y~, w=widths[i], h=32.0))
    x = x + widths[i] + 8.0
    i = i + 1
  }
  out
}

///|
pub fn home_project_slots(model : Model, ps : PageShell) -> Array[RectD] {
  let out : Array[RectD] = []
  let gap = 12.0
  let cols = (ps.content.w / 300.0).floor().to_int().max(1).min(model.project_cards.length())
  let cw = (ps.content.w - gap * (cols - 1).to_double()) / cols.to_double()
  let y = ps.content.y + 158.0 - model.page_scroll
  let mut i = 0
  while i < cols {
    out.push(RectD::new(x=ps.content.x + (cw + gap) * i.to_double(), y~, w=cw, h=104.0))
    i = i + 1
  }
  out
}

///|
pub fn home_token_card(ps : PageShell, scroll : Double) -> RectD {
  RectD::new(x=ps.content.x, y=ps.content.y + 298.0 - scroll, w=ps.content.w, h=176.0)
}

///|
fn home_content_height(model : Model, _w : Double) -> Double {
  let activity = if model.history_rows.length() > 0 {
    526.0 + 12.0 + home_activity_count().to_double() * 36.0
  } else {
    526.0 + 56.0
  }
  activity + 24.0
}

///|
fn paint_home(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  model : Model,
  c : RectD,
  ps : PageShell,
  p : Palette,
) -> Unit {
  let _ = ps
  let mut y = c.y
  // Identity block: 60px avatar, h1 22/600, status line 14 under it.
  let av = 60.0
  dot(ctx, c.x + av / 2.0, y + av / 2.0, av, rgba8(158, 140, 252, 0.22))
  round_stroke(ctx, rect(c.x, y, av, av), av / 2.0, p.accent_border, 1.0)
  tline_c(ctx, ts, "Z", font_ui(24.0, 600), p.accent, c.x, y + av / 2.0, av)
  tline(ctx, ts, "你好，Zoe", font_ui(22.0, 600), p.text, c.x + av + 12.0, y + 16.0, c.w - av - 40.0)
  tline(ctx, ts, "Runtime 就绪 · 3 个模型可用 · 工作区已同步", font_ui(14.0, 400), p.text_3, c.x + av + 12.0, y + 42.0, c.w - av - 40.0)
  icon(ctx, "pencil", rect(c.right() - 26.0, y + 6.0, 20.0, 20.0), 14.0, p.text_3, 1.6)
  y = y + av + 24.0
  // Quick actions.
  let labels = home_quick_labels()
  let slots = home_quick_slots(model, ps)
  let mut i = 0
  while i < slots.length() {
    let disabled = i == 2 || i == 3
    if disabled {
      round_fill(ctx, rect_of(slots[i]), 8.0, p.surface_2)
      tline_c(ctx, ts, labels[i], font_ui(12.5, 500), p.text_faint, slots[i].x, slots[i].y + 16.0, slots[i].w)
    } else {
      page_btn(ctx, ts, slots[i], labels[i], i == 0, p, hovered=hovering(model, slots[i]))
    }
    i = i + 1
  }
  // Recent projects.
  let sec_y = c.y + 128.0
  page_section(ctx, ts, c.x, sec_y, c.w, "最近项目", p)
  let cards = home_project_slots(model, ps)
  let mut ci = 0
  while ci < cards.length() && ci < model.project_cards.length() {
    let card = cards[ci]
    let proj = model.project_cards[ci]
    page_card(ctx, card, p)
    icon(ctx, "folder-open", rect(card.x + 14.0, card.y + 14.0, 18.0, 18.0), 16.0, p.text_2, 1.6)
    tline(ctx, ts, proj.name, font_ui(14.0, 600), p.text, card.x + 40.0, card.y + 23.0, card.w - 56.0)
    tline(ctx, ts, proj.path, font_mono(11.0), p.text_3, card.x + 14.0, card.y + 46.0, card.w - 28.0)
    if proj.dirty > 0 {
      let tag = RectD::new(x=card.x + 14.0, y=card.y + 60.0, w=54.0, h=20.0)
      page_tag(ctx, ts, tag, "dirty \{proj.dirty}", p.amber, p)
    }
    hair(ctx, card.x + 14.0, card.bottom() - 32.0, card.right() - 14.0, card.bottom() - 32.0, p.border)
    tline(ctx, ts, proj.branch + " · " + proj.thread, font_ui(11.0, 400), p.text_3, card.x + 14.0, card.bottom() - 16.0, card.w - 62.0)
    tline_r(ctx, ts, proj.when, font_ui(11.0, 400), p.text_3, card.right() - 14.0, card.bottom() - 16.0, 44.0)
    ci = ci + 1
  }
  // Token usage card.
  let token = home_token_card(ps, model.page_scroll)
  page_card(ctx, token, p)
  page_section(ctx, ts, token.x + 16.0, token.y + 14.0, token.w - 32.0, "Token 使用 · 最近 14 天", p)
  tline_r(ctx, ts, "打开统计页 ›", font_ui(11.0, 500), p.accent, token.right() - 16.0, token.y + 22.0, 80.0)
  let mut total_in = 0
  let mut total_out = 0
  for day in model.usage_days {
    total_in = total_in + day.input
    total_out = total_out + day.output
  }
  tline(ctx, ts, "输入 \{fmt_tokens(total_in)}", font_ui(20.0, 600), p.text, token.x + 16.0, token.y + 64.0, 160.0)
  tline(ctx, ts, "输出 \{fmt_tokens(total_out)}", font_ui(12.0, 400), p.text_3, token.x + 16.0, token.y + 88.0, 160.0)
  let chart = RectD::new(x=token.x + 190.0, y=token.y + 34.0, w=token.w - 214.0, h=token.h - 56.0)
  page_bar_chart(ctx, ts, chart, model.usage_days, p)
  // Recent activity: the newest five history entries, as the reference lists
  // them under the token card.
  let act_y = c.y + 498.0
  page_section(ctx, ts, c.x, act_y, c.w, "最近活动", p)
  let rows = home_activity_slots(model, ps)
  if rows.length() > 0 {
    let box = home_activity_card(ps, model.page_scroll)
    page_card(ctx, box, p)
    let mut i = 0
    while i < rows.length() && i < model.history_rows.length() {
      let row = rows[i]
      let entry = model.history_rows[i]
      let tile = RectD::new(x=row.x + 10.0, y=row.y + (row.h - 22.0) / 2.0, w=22.0, h=22.0)
      round_fill(ctx, rect_of(tile), 6.0, p.accent_soft)
      icon(ctx, "message-circle", rect_of(tile), 12.0, p.accent, 1.5)
      tline(ctx, ts, "会话：\{entry.title}", font_ui(12.0, 400), p.text_2, row.x + 42.0, row.y + row.h / 2.0, row.w - 100.0)
      tline_r(ctx, ts, entry.when, font_ui(11.0, 400), p.text_3, row.right() - 12.0, row.y + row.h / 2.0, 60.0)
      i = i + 1
    }
  } else {
    let box = RectD::new(x=c.x, y=act_y + 18.0, w=c.w, h=56.0)
    page_card(ctx, box, p)
    tline(ctx, ts, "暂无最近活动", font_ui(12.0, 400), p.text_3, box.x + 16.0, box.y + box.h / 2.0, box.w - 32.0)
  }
}

///|
/// Activity card and its row slots. Five rows of 36 plus a 12px frame, the same
/// pitch the painter uses, so the hit-test can address each row.
pub fn home_activity_card(ps : PageShell, scroll : Double) -> RectD {
  let n = home_activity_count()
  RectD::new(x=ps.content.x, y=ps.content.y + 526.0 - scroll, w=ps.content.w, h=(12.0 + n.to_double() * 36.0))
}

///|
fn home_activity_count() -> Int {
  5
}

///|
pub fn home_activity_slots(model : Model, ps : PageShell) -> Array[RectD] {
  let out : Array[RectD] = []
  let n = model.history_rows.length().min(home_activity_count())
  let base = home_activity_card(ps, model.page_scroll)
  let mut i = 0
  while i < n {
    out.push(RectD::new(x=base.x + 4.0, y=base.y + 6.0 + i.to_double() * 36.0, w=base.w - 8.0, h=36.0))
    i = i + 1
  }
  out
}

///|
pub fn fmt_tokens(n : Int) -> String {
  if n >= 1000000 {
    "\{(n / 100000).to_double() / 10.0}M"
  } else if n >= 1000 {
    "\{(n / 100).to_double() / 10.0}k"
  } else {
    "\{n}"
  }
}

///|
fn history_filtered(model : Model) -> Array[HistoryRow] {
  let out : Array[HistoryRow] = []
  for i in history_filtered_ids(model) {
    out.push(model.history_rows[i])
  }
  out
}

///|
pub fn history_rows_len(model : Model) -> Int {
  history_filtered(model).length()
}

///|
/// Absolute indexes of the rows the toolbar filter keeps, so a click on the
/// filtered list still opens the row the model stores.
pub fn history_filtered_ids(model : Model) -> Array[Int] {
  let q = model.history_query
  let out : Array[Int] = []
  let mut i = 0
  for row in model.history_rows {
    let archived = row.state == 5
    let keep_state = if model.history_filter == 0 {
      true
    } else if model.history_filter == 1 {
      !archived
    } else {
      archived
    }
    let keep_query = if q == "" {
      true
    } else {
      row.title.contains(q) || row.project.contains(q)
    }
    if keep_state && keep_query {
      out.push(i)
    }
    i = i + 1
  }
  out
}

///|
pub fn history_toolbar_slots(model : Model, ps : PageShell) -> (RectD, RectD) {
  let _ = model
  let y = ps.content.y - model.page_scroll
  let tabs_w = 3.0 * 64.0
  let search = RectD::new(x=ps.content.x, y~, w=(ps.content.w - tabs_w - 16.0).max(120.0), h=36.0)
  let tabs = RectD::new(x=search.right() + 16.0, y~, w=tabs_w, h=36.0)
  (search, tabs)
}

///|
pub fn history_row_slots(model : Model, ps : PageShell) -> Array[RectD] {
  let out : Array[RectD] = []
  let y0 = ps.content.y + 50.0 - model.page_scroll
  let rows = history_filtered(model)
  let has_side = ps.content.w > 820.0
  let main_w = if has_side { ps.content.w - 336.0 } else { ps.content.w }
  let mut i = 0
  while i < rows.length() {
    out.push(RectD::new(x=ps.content.x, y=y0 + i.to_double() * 70.0, w=main_w, h=62.0))
    i = i + 1
  }
  out
}

///|
pub fn history_side_card(ps : PageShell, scroll : Double) -> RectD {
  RectD::new(x=ps.content.x + ps.content.w - 320.0, y=ps.content.y + 50.0 - scroll, w=320.0, h=272.0)
}

///|
fn history_content_height(model : Model, _w : Double) -> Double {
  50.0 + history_filtered(model).length().to_double() * 70.0 + 24.0
}

///|
fn paint_history(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  model : Model,
  c : RectD,
  ps : PageShell,
  p : Palette,
) -> Unit {
  let (search, tabs) = history_toolbar_slots(model, ps)
  let _ = c
  page_input(ctx, ts, search, model.history_query, "搜索会话、项目或分支…", model.history_focus, p)
  page_segmented(ctx, ts, tabs, ["全部", "进行中", "已归档"], model.history_filter, p)
  let rows = history_row_slots(model, ps)
  let data = history_filtered(model)
  let mut i = 0
  while i < rows.length() && i < data.length() {
    let r = rows[i]
    let row = data[i]
    page_card(ctx, r, p)
    tline(ctx, ts, row.title, font_ui(14.0, 500), p.text, r.x + 14.0, r.y + 22.0, r.w - 200.0)
    let sub = "\{row.project} · \{row.branch} · \{fmt_tokens(row.tokens)} tokens"
    tline(ctx, ts, sub, font_mono(11.0), p.text_3, r.x + 14.0, r.y + 44.0, r.w - 200.0)
    let label = history_state_label(row.state)
    if label != "" {
      let color = match row.state {
        1 => p.green
        2 => p.accent
        3 => p.blue
        4 => p.amber
        _ => p.text_3
      }
      let tw = text_width(ts, label, font_ui(11.0, 500)) + 16.0
      let tag = RectD::new(x=r.right() - 14.0 - tw - 60.0, y=r.y + 21.0, w=tw, h=20.0)
      page_tag(ctx, ts, tag, label, color, p)
    }
    tline_r(ctx, ts, row.when, font_ui(11.0, 400), p.text_3, r.right() - 14.0, r.y + 31.0, 56.0)
    i = i + 1
  }
  if rows.length() == 0 {
    tline_c(ctx, ts, "没有匹配的会话", font_ui(12.0, 400), p.text_3, c.x, c.y + 90.0, c.w)
  }
  if ps.content.w > 820.0 {
    let side = history_side_card(ps, model.page_scroll)
    page_card(ctx, side, p)
    page_section(ctx, ts, side.x + 16.0, side.y + 12.0, side.w - 32.0, "Time Travel", p)
    tline(ctx, ts, "从任意一次消息快照恢复会话状态。", font_ui(12.0, 400), p.text_3, side.x + 16.0, side.y + 44.0, side.w - 32.0)
    let mut k = 0
    while k < 4 {
      let y = side.y + 72.0 + k.to_double() * 44.0
      hair(ctx, side.x + 16.0, y + 22.0, side.right() - 16.0, y + 22.0, p.border)
      dot(ctx, side.x + 22.0, y + 8.0, 6.0, if k == 0 { p.accent } else { p.text_faint })
      tline(ctx, ts, "快照 #\{4 - k} · \{k * 2 + 1} 条消息", font_ui(12.0, 500), p.text_2, side.x + 34.0, y + 2.0, side.w - 60.0)
      tline(ctx, ts, "\{k * 3 + 2}h 前", font_ui(11.0, 400), p.text_3, side.x + 34.0, y + 18.0, side.w - 60.0)
      k = k + 1
    }
    let btn = RectD::new(x=side.x + 16.0, y=side.bottom() - 44.0, w=side.w - 32.0, h=32.0)
    page_btn(ctx, ts, btn, "恢复到最新快照", false, p, hovered=hovering(model, btn))
  }
}
