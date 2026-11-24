// Settings, statistics, diagnostics, evaluation, media and Agent Hub pages.
// Same body grammar as the capability pages: intro, tab strip, then rows. The
// row helpers are the single source of truth for both paint and hit-test.

// ---------------------------------------------------------------------------
// Settings

///|
pub fn settings_tab_labels() -> Array[String] {
  ["常规", "背景", "对话与交互", "权限与安全", "上下文与记忆", "文件与终端", "任务与执行", "高级"]
}

///|
/// One settings row: label, description, control kind and its argument.
/// kind 0 = toggle (arg is the switch slot), 1 = language, 2 = motion,
/// 3 = light, 4 = document width, 5 = density, 6 = background scope.
pub fn settings_rows(tab : Int) -> Array[(String, String, Int, Int)] {
  match tab {
    0 => [
      ("界面语言", "切换后立即生效，无需重启", 1, 0),
      ("动效档位", "跟随系统、完整或减少动效", 2, 0),
      ("界面亮度", "低、中、高三档", 3, 0),
      ("文档阅读宽度", "窄、中、宽三种正文列宽", 4, 0),
      ("信息密度", "宽松、标准、紧凑", 5, 0),
      ("启动时恢复上次会话", "打开应用后回到退出前的路由与窗口布局", 0, 0),
    ]
    1 => [
      ("启用背景", "关闭后界面恢复原样，不读取本地文件", 0, 4),
      ("作用范围", "仅工作台或整个应用", 6, 0),
      ("背景模糊", "只模糊背景媒体，不模糊面板", 0, 6),
      ("自动遮罩", "在背景上盖一层主题色薄纱保证对比度", 0, 7),
    ]
    2 => [
      ("回车发送消息", "关闭后回车换行，⌘↵ 才发送", 0, 8),
      ("自动滚动到最新", "新消息到达时保持视口在底部", 0, 9),
      ("显示 Token 计数", "在标题栏显示输入与输出用量", 0, 10),
      ("发送后清空草稿", "空草稿不保留在 composer 里", 0, 11),
    ]
    3 => [
      ("全权限模式", "跳过工作区写权限的逐次确认", 0, 12),
      ("工具调用前审批", "每次工具调用都需要一次决议", 0, 13),
      ("允许静默工具", "读文件等只读工具不打断会话", 0, 14),
      ("危险操作二次确认", "删除、覆盖与推送需要再次确认", 0, 15),
    ]
    4 => [
      ("自动压缩上下文", "接近窗口上限时自动压缩历史", 0, 16),
      ("写入长期记忆", "把稳定的偏好与决定写入记忆", 0, 17),
      ("引用历史会话", "允许 @ 引用其它会话的片段", 0, 18),
      ("压缩前确认", "压缩会丢弃早期上下文，先提示一次", 0, 19),
    ]
    5 => [
      ("跟随系统终端主题", "终端配色与系统外观一致", 0, 20),
      ("用外部应用打开文件", "文件查看器提供「在应用中打开」", 0, 21),
      ("显示隐藏文件", "文件树里显示以点开头的条目", 0, 22),
      ("关闭终端时保留会话", "关掉面板后 PTY 仍在后台运行", 0, 23),
    ]
    6 => [
      ("并行子 Agent", "允许同时运行多个子 Agent", 0, 24),
      ("任务结束通知", "长任务完成时发系统通知", 0, 25),
      ("失败自动重试", "工具失败后按退避重试一次", 0, 26),
      ("保留任务日志", "后台任务结束后保留日志 7 天", 0, 27),
    ]
    _ => [
      ("启用遥测", "只上报匿名性能指标", 0, 28),
      ("实验性功能", "打开尚未稳定的面板与命令", 0, 29),
      ("详细日志", "把 Runtime 协议帧写进日志", 0, 30),
      ("开发者模式", "显示内部面板与状态快照", 0, 31),
    ]
  }
}

///|
pub fn settings_tab_slots(ps : PageShell, scroll : Double) -> Array[RectD] {
  let out : Array[RectD] = []
  let x = ps.content.x
  let y0 = ps.content.y - scroll + PAGE_INTRO_H
  let mut i = 0
  while i < 8 {
    out.push(RectD::new(x~, y=y0 + i.to_double() * 36.0, w=176.0, h=34.0))
    i = i + 1
  }
  out
}

///|
pub fn settings_row_slots(model : Model, ps : PageShell) -> Array[RectD] {
  let out : Array[RectD] = []
  let x = ps.content.x + 192.0
  let w = (ps.content.w - 192.0).max(240.0)
  let y0 = ps.content.y - model.page_scroll + PAGE_INTRO_H
  for _row in settings_rows(model.settings_tab) {
    out.push(RectD::new(x~, y=y0 + out.length().to_double() * 60.0, w~, h=52.0))
  }
  out
}

///|
pub fn settings_control_rect(r : RectD) -> RectD {
  RectD::new(x=r.right() - 116.0, y=r.y + 14.0, w=100.0, h=24.0)
}

///|
fn settings_value(model : Model, kind : Int) -> String {
  match kind {
    1 => if model.language_zh { "中文" } else { "English" }
    2 => match model.motion {
      0 => "跟随系统"
      1 => "完整"
      _ => "减少"
    }
    3 => match model.light {
      0 => "低"
      1 => "中"
      _ => "高"
    }
    4 => match model.doc_width {
      0 => "窄"
      1 => "中"
      _ => "宽"
    }
    5 => match model.density {
      0 => "宽松"
      1 => "标准"
      _ => "紧凑"
    }
    6 => if model.bg_scope == 0 { "仅工作台" } else { "整个应用" }
    _ => ""
  }
}

///|
fn settings_content_height(model : Model, _w : Double) -> Double {
  let rows = settings_rows(model.settings_tab).length().to_double()
  PAGE_INTRO_H + 18.0 + rows * 60.0 + 24.0
}

///|
fn paint_settings(
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
  page_intro(ctx, ts, intro, "设置", "全局外观、交互偏好、启动行为与权限控制", p)
  let tabs = settings_tab_slots(ps, model.page_scroll)
  let labels = settings_tab_labels()
  let mut i = 0
  while i < tabs.length() {
    let r = tabs[i]
    let active = i == model.settings_tab
    if active {
      round_fill(ctx, rect_of(r), 8.0, p.accent_soft)
      round_stroke(ctx, rect_of(r), 8.0, p.accent_border, 1.0)
    }
    tline(ctx, ts, labels[i], font_ui(12.5, if active { 600 } else { 500 }), if active { p.accent } else { p.text_2 }, r.x + 12.0, r.y + r.h / 2.0, r.w - 24.0)
    i = i + 1
  }
  let rows = settings_row_slots(model, ps)
  let defs = settings_rows(model.settings_tab)
  let panel_r = RectD::new(
    x=ps.content.x + 192.0,
    y=ps.content.y - model.page_scroll + PAGE_INTRO_H,
    w=(ps.content.w - 192.0).max(240.0),
    h=(rows.length().to_double() * 60.0 + 12.0).max(60.0),
  )
  page_card(ctx, panel_r, p)
  let mut i = 0
  while i < rows.length() && i < defs.length() {
    let r = rows[i]
    let (label, desc, kind, arg) = defs[i]
    if i > 0 {
      hair(ctx, r.x, r.y - 4.0, r.right(), r.y - 4.0, p.border)
    }
    tline(ctx, ts, label, font_ui(12.5, 500), p.text, r.x + 16.0, r.y + 18.0, r.w - 160.0)
    tline(ctx, ts, desc, font_ui(11.0, 400), p.text_3, r.x + 16.0, r.y + 37.0, r.w - 160.0)
    let ctl = settings_control_rect(r)
    if kind == 0 {
      page_toggle(ctx, RectD::new(x=ctl.right() - 36.0, y=ctl.y + 2.0, w=36.0, h=20.0), model.toggles[arg], p)
    } else {
      round_fill(ctx, rect_of(ctl), 6.0, p.surface_2)
      round_stroke(ctx, rect_of(ctl), 6.0, p.border, 1.0)
      tline(ctx, ts, settings_value(model, kind), font_ui(11.0, 500), p.text_2, ctl.x + 10.0, ctl.y + ctl.h / 2.0, ctl.w - 26.0)
      icon(ctx, "chevron-right", rect(ctl.right() - 20.0, ctl.y + 6.0, 12.0, 12.0), 10.0, p.text_faint, 1.5)
    }
    i = i + 1
  }
}

// ---------------------------------------------------------------------------
// Statistics

///|
pub fn stats_range_labels() -> Array[String] {
  ["7 天", "14 天", "30 天"]
}

///|
pub fn stats_days(model : Model) -> Array[UsageDay] {
  let n = match model.stats_range {
    0 => 7
    1 => 14
    _ => 30
  }
  let total = model.usage_days.length()
  let take = if n < total { n } else { total }
  let out : Array[UsageDay] = []
  let mut i = total - take
  while i < total {
    out.push(model.usage_days[i])
    i = i + 1
  }
  out
}

///|
pub fn stats_range_rect(ps : PageShell, scroll : Double) -> RectD {
  RectD::new(
    x=ps.content.x,
    y=ps.content.y - scroll + PAGE_INTRO_H,
    w=ps.content.w,
    h=PAGE_TABS_H,
  )
}

///|
pub fn stats_metric_slots(ps : PageShell, scroll : Double) -> Array[RectD] {
  let out : Array[RectD] = []
  let y = ps.content.y - scroll + PAGE_INTRO_H + PAGE_TABS_H + 18.0
  let gap = 12.0
  let w = (ps.content.w - gap * 2.0) / 3.0
  let mut i = 0
  while i < 3 {
    out.push(RectD::new(x=ps.content.x + (w + gap) * i.to_double(), y~, w~, h=88.0))
    i = i + 1
  }
  out
}

///|
pub fn stats_chart_rect(ps : PageShell, scroll : Double) -> RectD {
  let y = ps.content.y - scroll + PAGE_INTRO_H + PAGE_TABS_H + 18.0 + 100.0
  RectD::new(x=ps.content.x, y~, w=ps.content.w, h=196.0)
}

///|
pub fn stats_model_slots(model : Model, ps : PageShell) -> Array[RectD] {
  let out : Array[RectD] = []
  let y0 = ps.content.y - model.page_scroll + PAGE_INTRO_H + PAGE_TABS_H + 18.0 + 100.0 + 238.0
  let mut i = 0
  while i < model.usage_models.length() {
    out.push(RectD::new(x=ps.content.x, y=y0 + i.to_double() * 44.0, w=ps.content.w, h=40.0))
    i = i + 1
  }
  out
}

///|
fn stats_content_height(model : Model, _w : Double) -> Double {
  PAGE_INTRO_H + 18.0 + 88.0 + 12.0 + 196.0 + 16.0 + 50.0 + model.usage_models.length().to_double() * 44.0 + 24.0
}

///|
fn paint_statistics(
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
  page_intro(ctx, ts, intro, "用量统计", "Token 消耗、趋势与按模型拆分（本机用量）", p)
  page_segmented(ctx, ts, stats_range_rect(ps, model.page_scroll), stats_range_labels(), model.stats_range, p)
  let days = stats_days(model)
  let mut total_in = 0
  let mut total_out = 0
  for day in days {
    total_in = total_in + day.input
    total_out = total_out + day.output
  }
  let metrics = stats_metric_slots(ps, model.page_scroll)
  let labels = ["总输入", "总输出", "估算成本"]
  let values = [fmt_tokens(total_in), fmt_tokens(total_out), "$\{cost_of(days)}"]
  let cap = ["最近 \{days.length()} 天", "最近 \{days.length()} 天", "按当前价目估算"]
  let mut i = 0
  while i < metrics.length() {
    page_card(ctx, metrics[i], p)
    tline(ctx, ts, labels[i], font_ui(12.0, 400), p.text_3, metrics[i].x + 16.0, metrics[i].y + 22.0, metrics[i].w - 32.0)
    tline(ctx, ts, values[i], font_ui(24.0, 600), p.text, metrics[i].x + 16.0, metrics[i].y + 52.0, metrics[i].w - 32.0)
    tline(ctx, ts, cap[i], font_ui(10.5, 400), p.text_faint, metrics[i].x + 16.0, metrics[i].y + 74.0, metrics[i].w - 32.0)
    i = i + 1
  }
  let chart = stats_chart_rect(ps, model.page_scroll)
  page_card(ctx, chart, p)
  tline(ctx, ts, "每日 Token 用量", font_ui(12.5, 600), p.text, chart.x + 16.0, chart.y + 20.0, chart.w - 200.0)
  tline_r(ctx, ts, "输入（紫）· 输出（蓝）", font_ui(10.5, 400), p.text_faint, chart.right() - 16.0, chart.y + 20.0, 200.0)
  page_bar_chart(ctx, ts, RectD::new(x=chart.x + 16.0, y=chart.y + 36.0, w=chart.w - 32.0, h=chart.h - 52.0), days, p)
  let rows = stats_model_slots(model, ps)
  let head = RectD::new(x=ps.content.x, y=rows[0].y - 26.0, w=ps.content.w, h=20.0)
  tline(ctx, ts, "按模型", font_ui(12.5, 600), p.text, head.x, head.y + 10.0, 120.0)
  tline_r(ctx, ts, "输入 / 输出 / 成本", font_ui(10.5, 400), p.text_faint, head.right() - 16.0, head.y + 10.0, 220.0)
  let mut i = 0
  while i < rows.length() {
    let r = rows[i]
    let m = model.usage_models[i]
    page_card(ctx, r, p)
    tline(ctx, ts, m.name, font_mono(11.5), p.text, r.x + 14.0, r.y + r.h / 2.0, r.w - 340.0)
    let line = "\{fmt_tokens(m.input)} / \{fmt_tokens(m.output)}"
    tline_r(ctx, ts, line, font_mono(10.5), p.text_3, r.right() - 90.0, r.y + r.h / 2.0, 160.0)
    tline_r(ctx, ts, m.cost, font_mono(11.0), p.text_2, r.right() - 14.0, r.y + r.h / 2.0, 70.0)
    i = i + 1
  }
}

///|
/// Rough billed cost for the visible window, summed from the demo day volume at
/// a blended $7/M input and $22/M output, matching the per-model table's scale.
fn cost_of(days : Array[UsageDay]) -> String {
  let mut total = 0.0
  for day in days {
    total = total + day.input.to_double() * 7.0 / 1000000.0 + day.output.to_double() * 22.0 / 1000000.0
  }
  fmt2(total)
}

///|
/// Fixed two-decimal formatter for demo money and score values, so the pages
/// read "12.34" instead of a float dump without pulling in a formatting dep.
fn fmt2(x : Double) -> String {
  let cents = (x * 100.0).round().to_int()
  let neg = cents < 0
  let a = if neg { -cents } else { cents }
  let whole = a / 100
  let frac = a % 100
  let pad = if frac < 10 { "0" } else { "" }
  let sign = if neg { "-" } else { "" }
  "\{sign}\{whole}.\{pad}\{frac}"
}

// ---------------------------------------------------------------------------
// Diagnostics

///|
pub fn diag_actions(ps : PageShell, scroll : Double) -> Array[RectD] {
  let out : Array[RectD] = []
  if ps.content.w < 680.0 {
    return out
  }
  let labels = ["重新连接", "重启 Runtime", "检查更新", "导出日志"]
  let widths = [78.0, 92.0, 78.0, 78.0]
  let mut x = ps.content.right()
  let y = ps.content.y - scroll + 14.0
  let mut i = widths.length() - 1
  while i >= 0 {
    let w = widths[i]
    x = x - w
    out.push(RectD::new(x~, y~, w~, h=28.0))
    x = x - 8.0
    i = i - 1
  }
  ignore(labels)
  out
}

///|
pub fn diag_check_slots(model : Model, ps : PageShell) -> Array[RectD] {
  let out : Array[RectD] = []
  let y0 = page_body_top(ps, model.page_scroll)
  for _row in model.checks {
    out.push(RectD::new(x=ps.content.x, y=y0 + out.length().to_double() * 72.0, w=ps.content.w, h=64.0))
  }
  out
}

///|
pub fn diag_env_slots(model : Model, ps : PageShell) -> Array[RectD] {
  let out : Array[RectD] = []
  let y0 = page_body_top(ps, model.page_scroll) + model.checks.length().to_double() * 72.0 + 36.0
  let gap = 12.0
  let w = (ps.content.w - gap * 2.0) / 3.0
  let mut i = 0
  while i < 6 {
    let col = i % 3
    let row = i / 3
    out.push(RectD::new(x=ps.content.x + (w + gap) * col.to_double(), y=y0 + row.to_double() * 88.0, w~, h=80.0))
    i = i + 1
  }
  out
}

///|
fn diag_content_height(model : Model, _w : Double) -> Double {
  PAGE_INTRO_H + 18.0 + model.checks.length().to_double() * 72.0 + 36.0 + 2.0 * 88.0 + 24.0
}

///|
fn paint_diagnostics(
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
  page_intro(ctx, ts, intro, "诊断中心", "Runtime 进程健康、Bridge 协议与 Host 系统日志", p)
  let acts = diag_actions(ps, model.page_scroll)
  let labels = ["重新连接", "重启 Runtime", "检查更新", "导出日志"]
  let mut i = 0
  while i < acts.length() {
    page_btn(ctx, ts, acts[i], labels[i], false, p, hovered=hovering(model, acts[i]))
    i = i + 1
  }
  let rows = diag_check_slots(model, ps)
  let mut i = 0
  while i < rows.length() {
    let r = rows[i]
    let check = model.checks[i]
    page_card(ctx, r, p)
    dot(ctx, r.x + 18.0, r.y + r.h / 2.0, 8.0, if check.ok { p.green } else { p.red })
    tline(ctx, ts, check.name, font_ui(12.5, 600), p.text, r.x + 34.0, r.y + 22.0, r.w - 140.0)
    tline(ctx, ts, check.detail, font_mono(11.0), p.text_3, r.x + 34.0, r.y + 43.0, r.w - 140.0)
    let tag = if check.ok { "正常" } else { "需处理" }
    let tw = text_width(ts, tag, font_ui(10.5, 500)) + 18.0
    page_tag(ctx, ts, RectD::new(x=r.right() - 14.0 - tw, y=r.y + 20.0, w=tw, h=20.0), tag, if check.ok { p.green } else { p.red }, p)
    i = i + 1
  }
  let env = diag_env_slots(model, ps)
  let keys = ["宿主版本", "协议版本", "运行平台", "架构", "PTY 后端", "更新检查"]
  let vals = ["omp-host 0.2.8", "studio-protocol v3", "macOS 15.1", "arm64", "forkpty · zsh", "18m 前 · 无新版本"]
  let mut i = 0
  while i < env.length() {
    page_card(ctx, env[i], p)
    tline(ctx, ts, keys[i], font_ui(11.0, 400), p.text_3, env[i].x + 14.0, env[i].y + 20.0, env[i].w - 28.0)
    tline(ctx, ts, vals[i], font_mono(12.0), p.text, env[i].x + 14.0, env[i].y + 44.0, env[i].w - 28.0)
    tline(ctx, ts, "已读取", font_ui(10.0, 400), p.text_faint, env[i].x + 14.0, env[i].y + 64.0, env[i].w - 28.0)
    i = i + 1
  }
}

// ---------------------------------------------------------------------------
// Evaluation

///|
pub fn eval_filter_labels() -> Array[String] {
  ["全部", "通过", "失败", "运行中"]
}

///|
pub fn eval_filter_rect(ps : PageShell, scroll : Double) -> RectD {
  RectD::new(
    x=ps.content.x,
    y=ps.content.y - scroll + PAGE_INTRO_H,
    w=ps.content.w,
    h=PAGE_TABS_H,
  )
}

///|
pub fn eval_metric_slots(ps : PageShell, scroll : Double) -> Array[RectD] {
  let out : Array[RectD] = []
  let y = ps.content.y - scroll + PAGE_INTRO_H + PAGE_TABS_H + 18.0
  let gap = 12.0
  let w = (ps.content.w - gap * 2.0) / 3.0
  let mut i = 0
  while i < 3 {
    out.push(RectD::new(x=ps.content.x + (w + gap) * i.to_double(), y~, w~, h=88.0))
    i = i + 1
  }
  out
}

///|
pub fn eval_rows(model : Model) -> Array[Int] {
  let out : Array[Int] = []
  let mut i = 0
  for run in model.eval_runs {
    let keep = match model.eval_filter {
      0 => true
      1 => run.status == 1
      2 => run.status == 2
      _ => run.status == 0
    }
    if keep {
      out.push(i)
    }
    i = i + 1
  }
  out
}

///|
pub fn eval_row_slots(model : Model, ps : PageShell) -> Array[RectD] {
  let out : Array[RectD] = []
  let y0 = ps.content.y - model.page_scroll + PAGE_INTRO_H + PAGE_TABS_H + 18.0 + 104.0
  for _i in eval_rows(model) {
    out.push(RectD::new(x=ps.content.x, y=y0 + out.length().to_double() * 72.0, w=ps.content.w, h=64.0))
  }
  out
}

///|
fn eval_content_height(model : Model, _w : Double) -> Double {
  PAGE_INTRO_H + 18.0 + 88.0 + 16.0 + eval_rows(model).length().to_double() * 72.0 + 24.0
}

///|
fn paint_evaluation(
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
  page_intro(ctx, ts, intro, "评测", "评测运行、评分与对比", p)
  page_segmented(ctx, ts, eval_filter_rect(ps, model.page_scroll), eval_filter_labels(), model.eval_filter, p)
  let mut passed = 0
  let mut failed = 0
  let mut running = 0
  let mut sum = 0.0
  let mut scored = 0
  for run in model.eval_runs {
    if run.status == 1 {
      passed = passed + 1
      sum = sum + run.score
      scored = scored + 1
    } else if run.status == 2 {
      failed = failed + 1
      sum = sum + run.score
      scored = scored + 1
    } else {
      running = running + 1
    }
  }
  let total = model.eval_runs.length()
  let avg = if scored > 0 { sum / scored.to_double() } else { 0.0 }
  let metrics = eval_metric_slots(ps, model.page_scroll)
  let labels = ["通过率", "平均分", "在跑 / 总运行"]
  let values = [
    if total > 0 { "\{(passed * 100 / total)}%" } else { "—" },
    "\{fmt2(avg * 100.0)}",
    "\{running} / \{total}",
  ]
  let caps = ["\{passed} 通过 · \{failed} 失败", "未加权，按已完成的运行", "队列与历史合计"]
  let mut i = 0
  while i < metrics.length() {
    page_card(ctx, metrics[i], p)
    tline(ctx, ts, labels[i], font_ui(11.5, 400), p.text_3, metrics[i].x + 16.0, metrics[i].y + 20.0, metrics[i].w - 32.0)
    tline(ctx, ts, values[i], font_ui(24.0, 600), p.text, metrics[i].x + 16.0, metrics[i].y + 50.0, metrics[i].w - 32.0)
    tline(ctx, ts, caps[i], font_ui(10.5, 400), p.text_faint, metrics[i].x + 16.0, metrics[i].y + 74.0, metrics[i].w - 32.0)
    i = i + 1
  }
  let rows = eval_row_slots(model, ps)
  let ids = eval_rows(model)
  let mut i = 0
  while i < rows.length() && i < ids.length() {
    let r = rows[i]
    let run = model.eval_runs[ids[i]]
    page_card(ctx, r, p)
    tline(ctx, ts, run.name, font_ui(12.5, 500), p.text, r.x + 14.0, r.y + 22.0, r.w - 300.0)
    tline(ctx, ts, run.when, font_ui(10.5, 400), p.text_faint, r.x + 14.0, r.y + 42.0, r.w - 260.0)
    let color = match run.status {
      1 => p.green
      2 => p.red
      _ => p.amber
    }
    let tag = eval_status_label(run.status)
    let tw = text_width(ts, tag, font_ui(10.5, 500)) + 18.0
    page_tag(ctx, ts, RectD::new(x=r.right() - 14.0 - tw, y=r.y + 20.0, w=tw, h=20.0), tag, color, p)
    // Status tags differ in width ("通过" vs "运行中"), so the track ends on a
    // fixed column that clears the widest one instead of running under it.
    let bar = RectD::new(x=r.right() - 236.0, y=r.y + 24.0, w=150.0, h=6.0)
    round_fill(ctx, rect_of(bar), 3.0, p.surface_3)
    let shown = run.score.max(0.0).min(1.0)
    if shown > 0.0 {
      round_fill(ctx, rect(bar.x, bar.y, bar.w * shown, bar.h), 3.0, color)
    }
    tline_r(ctx, ts, if run.status == 0 { "—" } else { "\{(run.score * 100.0).round().to_int()}" }, font_mono(10.5), p.text_3, bar.x - 8.0, r.y + 27.0, 40.0)
    i = i + 1
  }
}

// ---------------------------------------------------------------------------
// Media

///|
pub fn media_filter_labels() -> Array[String] {
  ["全部", "图片", "音频", "视频"]
}

///|
pub fn media_filter_rect(ps : PageShell, scroll : Double) -> RectD {
  RectD::new(
    x=ps.content.x,
    y=ps.content.y - scroll + PAGE_INTRO_H,
    w=(ps.content.w - 180.0).max(240.0),
    h=PAGE_TABS_H,
  )
}

///|
pub fn media_action_slots(ps : PageShell, scroll : Double) -> Array[RectD] {
  let out : Array[RectD] = []
  if ps.content.w < 560.0 {
    return out
  }
  let y = ps.content.y - scroll + PAGE_INTRO_H + 2.0
  out.push(RectD::new(x=ps.content.right() - 164.0, y~, w=76.0, h=28.0))
  out.push(RectD::new(x=ps.content.right() - 80.0, y~, w=80.0, h=28.0))
  out
}

///|
pub fn media_items_filtered(model : Model) -> Array[Int] {
  let out : Array[Int] = []
  let mut i = 0
  for item in model.media_items {
    let keep = model.media_filter == 0 || item.kind == model.media_filter - 1
    if keep {
      out.push(i)
    }
    i = i + 1
  }
  out
}

///|
fn media_cols(w : Double) -> Int {
  if w >= 880.0 {
    4
  } else if w >= 620.0 {
    3
  } else {
    2
  }
}

///|
pub fn media_cell_slots(model : Model, ps : PageShell) -> Array[RectD] {
  let out : Array[RectD] = []
  let y0 = ps.content.y - model.page_scroll + PAGE_INTRO_H + PAGE_TABS_H + 18.0
  let cols = media_cols(ps.content.w)
  let gap = 12.0
  let cw = (ps.content.w - gap * (cols - 1).to_double()) / cols.to_double()
  for _i in media_items_filtered(model) {
    let n = out.length()
    let col = n % cols
    let row = n / cols
    out.push(RectD::new(x=ps.content.x + (cw + gap) * col.to_double(), y=y0 + row.to_double() * 150.0, w=cw, h=138.0))
  }
  out
}

///|
///|
/// Detail-card actions for the selected media item: 查看 / 另存为 / 删除, laid
/// out from the right edge of the detail card.
pub fn media_detail_action_slots(model : Model, ps : PageShell) -> Array[RectD] {
  let detail = media_detail_rect(model, ps)
  [
    RectD::new(x=detail.right() - 250.0, y=detail.y + 22.0, w=72.0, h=30.0),
    RectD::new(x=detail.right() - 170.0, y=detail.y + 22.0, w=72.0, h=30.0),
    RectD::new(x=detail.right() - 90.0, y=detail.y + 22.0, w=76.0, h=30.0),
  ]
}

///|
pub fn media_detail_rect(model : Model, ps : PageShell) -> RectD {
  let rows = media_cell_slots(model, ps)
  let cols = media_cols(ps.content.w)
  let lines = (rows.length() + cols - 1) / cols
  let y = ps.content.y - model.page_scroll + PAGE_INTRO_H + PAGE_TABS_H + 18.0 + lines.to_double() * 150.0 + 8.0
  RectD::new(x=ps.content.x, y~, w=ps.content.w, h=76.0)
}

///|
fn media_content_height(model : Model, w : Double) -> Double {
  let n = media_items_filtered(model).length()
  let cols = media_cols(w)
  let lines = (n + cols - 1) / cols
  PAGE_INTRO_H + 18.0 + lines.to_double() * 150.0 + 8.0 + 76.0 + 24.0
}

///|
/// HSV → RGB for the generated thumbnail tint: fixed saturation and value, the
/// hue comes from the fixture so every tile keeps its own colour.
fn hue_color(hue : Double, alpha : Double) -> @graphics.Color {
  let h = (hue % 360.0) / 60.0
  let s = 0.42
  let v = 0.55
  let c = v * s
  let x = c * (1.0 - ((h % 2.0) - 1.0).abs())
  let m = v - c
  let (r, g, b) = if h < 1.0 {
    (c, x, 0.0)
  } else if h < 2.0 {
    (x, c, 0.0)
  } else if h < 3.0 {
    (0.0, c, x)
  } else if h < 4.0 {
    (0.0, x, c)
  } else if h < 5.0 {
    (x, 0.0, c)
  } else {
    (c, 0.0, x)
  }
  rgba8(((r + m) * 255.0).to_int(), ((g + m) * 255.0).to_int(), ((b + m) * 255.0).to_int(), alpha)
}

///|
fn paint_media(
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
  page_intro(ctx, ts, intro, "媒体", "产物库：图片、音频、视频与托管文件", p)
  page_segmented(ctx, ts, media_filter_rect(ps, model.page_scroll), media_filter_labels(), model.media_filter, p)
  let acts = media_action_slots(ps, model.page_scroll)
  if acts.length() >= 2 {
    page_btn(ctx, ts, acts[0], "导入", false, p, hovered=hovering(model, acts[0]))
    page_btn(ctx, ts, acts[1], "刷新", false, p, hovered=hovering(model, acts[1]))
  }
  let rows = media_cell_slots(model, ps)
  let ids = media_items_filtered(model)
  let mut i = 0
  while i < rows.length() && i < ids.length() {
    let r = rows[i]
    let item = model.media_items[ids[i]]
    page_card(ctx, r, p)
    let thumb = RectD::new(x=r.x + 6.0, y=r.y + 6.0, w=r.w - 12.0, h=74.0)
    round_fill(ctx, rect_of(thumb), 7.0, hue_color(item.hue, 0.55))
    round_stroke(ctx, rect_of(thumb), 7.0, rgba8(255, 255, 255, 0.08), 1.0)
    let kind_icon = match item.kind {
      0 => "image"
      1 => "mic"
      _ => "video"
    }
    icon(ctx, kind_icon, rect(thumb.x + 10.0, thumb.y + 10.0, 16.0, 16.0), 14.0, rgba8(255, 255, 255, 0.72), 1.6)
    tline(ctx, ts, item.name, font_ui(11.0, 500), p.text, r.x + 10.0, r.y + 94.0, r.w - 20.0)
    tline(ctx, ts, "\{media_kind_label(item.kind)} · \{item.size} · \{item.when}", font_ui(10.0, 400), p.text_3, r.x + 10.0, r.y + 112.0, r.w - 20.0)
    if ids[i] == model.media_sel {
      round_stroke(ctx, rect_of(r), 10.0, p.accent_border, 1.5)
    }
    i = i + 1
  }
  if rows.length() == 0 {
    tline_c(ctx, ts, "还没有生成或导入的文件", font_ui(12.0, 400), p.text_3, ps.content.x, page_body_top(ps, model.page_scroll) + 60.0, ps.content.w)
    return
  }
  if model.media_items.length() == 0 {
    return
  }
  let detail = media_detail_rect(model, ps)
  page_card(ctx, detail, p)
  let sel = model.media_items[model.media_sel]
  tline(ctx, ts, sel.name, font_ui(12.5, 600), p.text, detail.x + 16.0, detail.y + 20.0, detail.w - 320.0)
  tline(ctx, ts, "\{media_kind_label(sel.kind)} · \{sel.size} · 最近 \{sel.when} · 保存在本机产物库", font_ui(11.0, 400), p.text_3, detail.x + 16.0, detail.y + 42.0, detail.w - 320.0)
  let acts = media_detail_action_slots(model, ps)
  page_btn(ctx, ts, acts[0], "查看", false, p, hovered=hovering(model, acts[0]))
  page_btn(ctx, ts, acts[1], "另存为", false, p, hovered=hovering(model, acts[1]))
  page_btn(ctx, ts, acts[2], "删除", false, p, hovered=hovering(model, acts[2]))
}

// ---------------------------------------------------------------------------
// Agent Hub

///|
pub fn hub_spawn_rect(ps : PageShell, scroll : Double) -> RectD {
  RectD::new(x=ps.content.right() - 112.0, y=ps.content.y - scroll + 14.0, w=112.0, h=30.0)
}

///|
pub fn hub_metric_slots(ps : PageShell, scroll : Double) -> Array[RectD] {
  let out : Array[RectD] = []
  let y = ps.content.y - scroll + PAGE_INTRO_H
  let gap = 12.0
  let w = (ps.content.w - gap * 2.0) / 3.0
  let mut i = 0
  while i < 3 {
    out.push(RectD::new(x=ps.content.x + (w + gap) * i.to_double(), y~, w~, h=76.0))
    i = i + 1
  }
  out
}

///|
pub fn hub_row_slots(model : Model, ps : PageShell) -> Array[RectD] {
  let out : Array[RectD] = []
  let y0 = ps.content.y - model.page_scroll + PAGE_INTRO_H + 88.0
  let mut i = 0
  while i < model.agents.length() {
    out.push(RectD::new(x=ps.content.x, y=y0 + i.to_double() * 80.0, w=ps.content.w, h=72.0))
    i = i + 1
  }
  out
}

///|
pub fn hub_toggle_rect(r : RectD) -> RectD {
  RectD::new(x=r.right() - 56.0, y=r.y + 16.0, w=36.0, h=20.0)
}

///|
///|
/// Detail-card actions for the selected agent: 打开对话 / 检查 / 终止 or 唤醒.
pub fn hub_detail_action_slots(model : Model, ps : PageShell) -> Array[RectD] {
  let detail = hub_detail_rect(model, ps)
  [
    RectD::new(x=detail.right() - 268.0, y=detail.y + 32.0, w=84.0, h=30.0),
    RectD::new(x=detail.right() - 176.0, y=detail.y + 32.0, w=72.0, h=30.0),
    RectD::new(x=detail.right() - 96.0, y=detail.y + 32.0, w=80.0, h=30.0),
  ]
}

///|
pub fn hub_detail_rect(model : Model, ps : PageShell) -> RectD {
  let y = ps.content.y - model.page_scroll + PAGE_INTRO_H + 88.0 + model.agents.length().to_double() * 80.0 + 8.0
  RectD::new(x=ps.content.x, y~, w=ps.content.w, h=96.0)
}

///|
fn hub_content_height(model : Model, _w : Double) -> Double {
  PAGE_INTRO_H + 88.0 + model.agents.length().to_double() * 80.0 + 8.0 + 96.0 + 24.0
}

///|
fn paint_agent_hub(
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
  page_intro(ctx, ts, intro, "Agent Hub", "多代理名册、状态监控与协同管理", p)
  page_btn(ctx, ts, hub_spawn_rect(ps, model.page_scroll), "新建子代理", true, p, hovered=hovering(model, hub_spawn_rect(ps, model.page_scroll)))
  let mut active = 0
  let mut idle = 0
  let mut off = 0
  for agent in model.agents {
    if agent.on {
      active = active + 1
    } else {
      off = off + 1
    }
    if agent.on && agent.scope == "全局" {
      idle = idle + 1
    }
  }
  let metrics = hub_metric_slots(ps, model.page_scroll)
  let labels = ["代理名册", "活跃", "已停用"]
  let values = ["\{model.agents.length()}", "\{active}", "\{off}"]
  let caps = ["全部已注册子代理", "\{idle} 个全局作用域", "开关关闭后不参与分派"]
  let mut i = 0
  while i < 3 {
    page_card(ctx, metrics[i], p)
    tline(ctx, ts, labels[i], font_ui(11.5, 400), p.text_3, metrics[i].x + 16.0, metrics[i].y + 18.0, metrics[i].w - 32.0)
    tline(ctx, ts, values[i], font_ui(22.0, 600), p.text, metrics[i].x + 16.0, metrics[i].y + 46.0, metrics[i].w - 32.0)
    tline(ctx, ts, caps[i], font_ui(10.0, 400), p.text_faint, metrics[i].x + 16.0, metrics[i].y + 64.0, metrics[i].w - 32.0)
    i = i + 1
  }
  let rows = hub_row_slots(model, ps)
  let mut i = 0
  while i < rows.length() {
    let r = rows[i]
    let agent = model.agents[i]
    page_card(ctx, r, p)
    if i == model.hub_sel {
      round_stroke(ctx, rect_of(r), 10.0, p.accent_border, 1.5)
    }
    avatar(ctx, r.x + 32.0, r.y + r.h / 2.0, 32.0, if agent.on { p.accent } else { p.surface_3 }, first_char(agent.name), ts, p)
    tline(ctx, ts, agent.name, font_ui(13.0, 600), p.text, r.x + 58.0, r.y + 24.0, r.w - 240.0)
    tline(ctx, ts, agent.model, font_mono(10.5), p.text_3, r.x + 58.0, r.y + 43.0, r.w - 240.0)
    tline(ctx, ts, agent.desc, font_ui(10.5, 400), p.text_faint, r.x + 58.0, r.y + 61.0, r.w - 240.0)
    let sw = text_width(ts, agent.scope, font_ui(10.0, 500)) + 16.0
    page_tag(ctx, ts, RectD::new(x=r.right() - 70.0 - sw, y=r.y + 42.0, w=sw, h=20.0), agent.scope, p.text_3, p)
    page_toggle(ctx, hub_toggle_rect(r), agent.on, p)
    i = i + 1
  }
  let detail = hub_detail_rect(model, ps)
  page_card(ctx, detail, p)
  let sel = model.agents[model.hub_sel]
  tline(ctx, ts, "\{sel.name} · \{sel.model}", font_ui(13.0, 600), p.text, detail.x + 16.0, detail.y + 22.0, detail.w - 360.0)
  tline(ctx, ts, sel.desc, font_ui(11.0, 400), p.text_3, detail.x + 16.0, detail.y + 44.0, detail.w - 360.0)
  tline(ctx, ts, "作用域 \{sel.scope} · 状态 \{if sel.on { "可用" } else { "已停用" }}", font_ui(10.5, 400), p.text_faint, detail.x + 16.0, detail.y + 66.0, detail.w - 360.0)
  let acts = hub_detail_action_slots(model, ps)
  page_btn(ctx, ts, acts[0], "打开对话", false, p, hovered=hovering(model, acts[0]))
  page_btn(ctx, ts, acts[1], "检查", false, p, hovered=hovering(model, acts[1]))
  page_btn(ctx, ts, acts[2], if sel.on { "终止" } else { "唤醒" }, false, p, hovered=hovering(model, acts[2]))
}

///|
pub fn first_char(s : String) -> String {
  let mut out = ""
  for c in s.iter() {
    if out == "" {
      out = c.to_string()
    }
  }
  if out == "" { "?" } else { out }
}
