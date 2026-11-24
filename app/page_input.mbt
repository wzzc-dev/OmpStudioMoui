// Page interaction: the rail, the page head, the page body and the wheel.
// Every control is tested against the helper its painter used, so a control is
// never clickable where it is not drawn. Transitions go through `Msg` and
// `update` exactly like the workbench, with the page shell passed where the
// layout helper needs it.

///|
/// Cell index of a segmented control at a point; -1 when the point misses it.
/// `page_segmented` paints equal cells, so the index is plain cell arithmetic.
fn segmented_at(r : RectD, x : Double, y : Double, n : Int) -> Int {
  if !r.contains(x, y) {
    return -1
  }
  let cell = r.w / n.to_double()
  let i = ((x - r.x) / cell).to_int()
  if i < 0 {
    0
  } else if i >= n {
    n - 1
  } else {
    i
  }
}

///|
/// The local action echo: the page pill under the body says what just happened
/// until a real toast surface lands in stage 2.
pub fn set_note(model : Model, note : String) -> Model {
  { ..model, page_note: note }
}

///|
/// Rail route under a point. The rail is shared with the workbench shell: same
/// 44px column, same six slots, same order as `rail_routes`.
fn page_rail_route(model : Model, pm : PointerMsg) -> Route? {
  let shell = shell_layout(pm.w, pm.h, model.sidebar_open, sidebar_w=model.sidebar_w)
  let slots = rail_slots(shell)
  let routes = rail_routes()
  let mut i = 0
  while i < slots.length() && i < routes.length() {
    if slots[i].contains(pm.x, pm.y) {
      return Some(routes[i])
    }
    i = i + 1
  }
  None
}

///|
/// Page head: back button, the 186px title slot, the nav bubbles and the theme
/// toggle. Bubbles that would overflow into the theme button are not clickable,
/// matching the reference's hidden-overflow rule.
fn page_head_msg(_model : Model, ps : PageShell, x : Double, y : Double) -> Msg? {
  if page_back_btn(ps).contains(x, y) {
    return Some(GoBack)
  }
  if page_theme_btn(ps).contains(x, y) {
    return Some(ToggleTheme)
  }
  let slots = page_nav_slots(ps)
  let routes = page_nav_routes()
  let mut i = 0
  while i < slots.length() && i < routes.length() {
    let s = slots[i]
    if s.contains(x, y) && s.right() <= page_theme_btn(ps).x - 8.0 {
      return Some(GoRoute(routes[i]))
    }
    i = i + 1
  }
  None
}

///|
pub fn page_pointer(model : Model, pm : PointerMsg) -> Model {
  let ps = page_shell(pm.w, pm.h)
  let framed = { ..model, frame_w: pm.w, frame_h: pm.h }
  // Wheel arrives as phase 3 (see `pointer_msg`), clamped by the page body.
  if pm.phase == 3 {
    return page_scroll_by(framed, pm.wheel, ps)
  }
  if pm.phase != 0 {
    return framed
  }
  match page_rail_route(framed, pm) {
    Some(route) => go_route(framed, route)
    None => {
      match page_head_msg(framed, ps, pm.x, pm.y) {
        Some(msg) => update(framed, msg)
        None => page_body_click(framed, ps, pm.x, pm.y)
      }
    }
  }
}

///|
fn page_body_click(model : Model, ps : PageShell, x : Double, y : Double) -> Model {
  match model.route {
    Home => home_click(model, ps, x, y)
    History => history_click(model, ps, x, y)
    Capabilities => caps_click(model, ps, x, y)
    ModelConfig => model_config_click(model, ps, x, y)
    Settings => settings_click(model, ps, x, y)
    Statistics => stats_click(model, ps, x, y)
    Diagnostics => diag_click(model, ps, x, y)
    Evaluation => eval_click(model, ps, x, y)
    Media => media_click(model, ps, x, y)
    AgentHub => hub_click(model, ps, x, y)
    Workbench => model
  }
}

// ---------------------------------------------------------------------------
// Home

///|
fn home_click(model : Model, ps : PageShell, x : Double, y : Double) -> Model {
  let quick = home_quick_slots(model, ps)
  let mut i = 0
  while i < quick.length() {
    if quick[i].contains(x, y) {
      // The first two quick actions are real: open a folder, restore the newest
      // session. The other two stay disabled, as in the reference.
      if i == 0 {
        return set_note(model, "已打开本地文件夹选择器")
      }
      if i == 1 {
        return update(model, HistoryRow(0))
      }
      return model
    }
    i = i + 1
  }
  let cards = home_project_slots(model, ps)
  let mut i = 0
  while i < cards.length() && i < model.project_cards.length() {
    if cards[i].contains(x, y) {
      return set_note(model, "切换到项目 " + model.project_cards[i].name)
    }
    i = i + 1
  }
  if home_token_card(ps, model.page_scroll).contains(x, y) {
    return update(model, GoRoute(Statistics))
  }
  model
}

// ---------------------------------------------------------------------------
// History

///|
fn history_click(model : Model, ps : PageShell, x : Double, y : Double) -> Model {
  let (search, tabs) = history_toolbar_slots(model, ps)
  if search.contains(x, y) {
    return update(model, HistoryFocus)
  }
  let filter = segmented_at(tabs, x, y, 3)
  if filter >= 0 {
    return update(model, HistoryFilter(filter))
  }
  let rows = history_row_slots(model, ps)
  let ids = history_filtered_ids(model)
  let mut i = 0
  while i < rows.length() && i < ids.length() {
    if rows[i].contains(x, y) {
      return update(model, HistoryRow(ids[i]))
    }
    i = i + 1
  }
  model
}

// ---------------------------------------------------------------------------
// Capabilities

///|
fn caps_click(model : Model, ps : PageShell, x : Double, y : Double) -> Model {
  let tab = segmented_at(caps_tabs_rect(ps, model.page_scroll), x, y, 5)
  if tab >= 0 {
    return update(model, CapsTab(tab))
  }
  let rows = caps_row_slots(model, ps)
  let ids = caps_rows(model)
  let mut i = 0
  while i < rows.length() && i < ids.length() {
    if caps_row_action(rows[i]).contains(x, y) {
      let id = ids[i]
      if model.skills[id].kind == 3 {
        return update(model, CapsRun(id))
      }
      return update(model, ToggleSkill(id))
    }
    i = i + 1
  }
  model
}

// ---------------------------------------------------------------------------
// Model configuration

///|
fn model_config_click(model : Model, ps : PageShell, x : Double, y : Double) -> Model {
  let tab = segmented_at(model_tabs_rect(ps, model.page_scroll), x, y, 4)
  if tab >= 0 {
    return update(model, ModelTab(tab))
  }
  match model.model_tab {
    0 => {
      let rows = provider_row_slots(model, ps)
      let mut i = 0
      while i < rows.length() {
        let r = rows[i]
        if provider_test_rect(r).contains(x, y) {
          return update(model, TestProvider(i))
        }
        if provider_toggle_rect(r).contains(x, y) {
          return update(model, ToggleProvider(i))
        }
        if r.contains(x, y) {
          return update(model, SelectProvider(i))
        }
        i = i + 1
      }
      model
    }
    1 => {
      let rows = model_row_slots(model, ps)
      let mut i = 0
      while i < rows.length() {
        if rows[i].contains(x, y) {
          return update(model, SelectModel(i))
        }
        i = i + 1
      }
      model
    }
    2 => {
      let rows = role_row_slots(model, ps)
      let mut i = 0
      while i < rows.length() {
        if rows[i].contains(x, y) {
          return update(model, CycleRoleModel(i))
        }
        i = i + 1
      }
      model
    }
    _ => model
  }
}

// ---------------------------------------------------------------------------
// Settings

///|
fn settings_click(model : Model, ps : PageShell, x : Double, y : Double) -> Model {
  let tabs = settings_tab_slots(ps, model.page_scroll)
  let mut t = 0
  while t < tabs.length() {
    if tabs[t].contains(x, y) {
      return update(model, SettingsTab(t))
    }
    t = t + 1
  }
  let rows = settings_row_slots(model, ps)
  let defs = settings_rows(model.settings_tab)
  let mut i = 0
  while i < rows.length() && i < defs.length() {
    let (_, _, kind, arg) = defs[i]
    if settings_control_rect(rows[i]).contains(x, y) {
      match kind {
        0 => return update(model, ToggleSwitch(arg))
        1 => return update(model, SetLanguage(!model.language_zh))
        2 => return update(model, CycleMotion)
        3 => return update(model, CycleLight)
        4 => return update(model, CycleDocWidth)
        5 => return update(model, ToggleDensity)
        _ => return update(model, BgScope(if model.bg_scope == 0 { 1 } else { 0 }))
      }
    }
    i = i + 1
  }
  model
}

// ---------------------------------------------------------------------------
// Statistics

///|
fn stats_click(model : Model, ps : PageShell, x : Double, y : Double) -> Model {
  let range = segmented_at(stats_range_rect(ps, model.page_scroll), x, y, 3)
  if range >= 0 {
    return update(model, StatsRange(range))
  }
  let rows = stats_model_slots(model, ps)
  let mut i = 0
  while i < rows.length() && i < model.usage_models.length() {
    if rows[i].contains(x, y) {
      return set_note(model, "查看模型用量 " + model.usage_models[i].name)
    }
    i = i + 1
  }
  model
}

// ---------------------------------------------------------------------------
// Diagnostics

///|
fn diag_click(model : Model, ps : PageShell, x : Double, y : Double) -> Model {
  let acts = diag_actions(ps, model.page_scroll)
  let mut i = 0
  while i < acts.length() {
    if acts[i].contains(x, y) {
      return update(model, DiagAction(i))
    }
    i = i + 1
  }
  model
}

// ---------------------------------------------------------------------------
// Evaluation

///|
fn eval_click(model : Model, ps : PageShell, x : Double, y : Double) -> Model {
  let filter = segmented_at(eval_filter_rect(ps, model.page_scroll), x, y, 4)
  if filter >= 0 {
    return update(model, EvalFilter(filter))
  }
  let rows = eval_row_slots(model, ps)
  let ids = eval_rows(model)
  let mut i = 0
  while i < rows.length() && i < ids.length() {
    if rows[i].contains(x, y) {
      return set_note(model, "打开评测运行 " + model.eval_runs[ids[i]].name)
    }
    i = i + 1
  }
  model
}

// ---------------------------------------------------------------------------
// Media

///|
fn media_click(model : Model, ps : PageShell, x : Double, y : Double) -> Model {
  let filter = segmented_at(media_filter_rect(ps, model.page_scroll), x, y, 4)
  if filter >= 0 {
    return update(model, MediaFilter(filter))
  }
  let acts = media_action_slots(ps, model.page_scroll)
  if acts.length() >= 2 {
    if acts[0].contains(x, y) {
      return set_note(model, "已从本机导入 3 个文件")
    }
    if acts[1].contains(x, y) {
      return set_note(model, "产物库已刷新 · 12 项")
    }
  }
  let cells = media_cell_slots(model, ps)
  let ids = media_items_filtered(model)
  let mut i = 0
  while i < cells.length() && i < ids.length() {
    if cells[i].contains(x, y) {
      return update(model, MediaSelect(ids[i]))
    }
    i = i + 1
  }
  if cells.length() > 0 {
    let detail = media_detail_action_slots(model, ps)
    if detail[0].contains(x, y) {
      return set_note(model, "正在用系统查看器打开 " + model.media_items[model.media_sel].name)
    }
    if detail[1].contains(x, y) {
      return set_note(model, "已另存一份副本")
    }
    if detail[2].contains(x, y) {
      let keep : Array[MediaItem] = []
      let mut k = 0
      for item in model.media_items {
        if k != model.media_sel {
          keep.push(item)
        }
        k = k + 1
      }
      let sel = if keep.length() == 0 {
        0
      } else if model.media_sel >= keep.length() {
        keep.length() - 1
      } else {
        model.media_sel
      }
      return { ..model, media_items: keep, media_sel: sel, page_note: "已从产物库移除 1 个文件" }
    }
  }
  model
}

// ---------------------------------------------------------------------------
// Agent Hub

///|
fn hub_click(model : Model, ps : PageShell, x : Double, y : Double) -> Model {
  if hub_spawn_rect(ps, model.page_scroll).contains(x, y) {
    let rows : Array[AgentRow] = []
    for agent in model.agents {
      rows.push(agent)
    }
    let name = "sub-agent-\{rows.length() + 1}"
    rows.push({
      name,
      model: "deepseek-v4-flash",
      desc: "新建的子代理草稿，等待分配任务",
      on: true,
      scope: "会话",
    })
    return {
      ..model,
      agents: rows,
      hub_sel: rows.length() - 1,
      page_note: "已新建 " + name,
    }
  }
  let rows = hub_row_slots(model, ps)
  let mut i = 0
  while i < rows.length() && i < model.agents.length() {
    if hub_toggle_rect(rows[i]).contains(x, y) {
      return update(model, ToggleAgent(i))
    }
    if rows[i].contains(x, y) {
      return update(model, HubSelect(i))
    }
    i = i + 1
  }
  let detail = hub_detail_action_slots(model, ps)
  if detail[0].contains(x, y) {
    return set_note(model, "打开 " + model.agents[model.hub_sel].name + " 的对话")
  }
  if detail[1].contains(x, y) {
    return set_note(model, "检查 " + model.agents[model.hub_sel].name + " · 模型与工具就绪")
  }
  if detail[2].contains(x, y) {
    return set_note(model, "已切换 " + model.agents[model.hub_sel].name + " 的运行状态")
  }
  model
}

// ---------------------------------------------------------------------------
// Page transitions that only need an index

///|
/// Provider / model / agent selection and the action echoes below stay here so
/// `update` reads as a routing table. Every one of them guards its index: page
/// hits and tests can both reach them.
pub fn select_model_note(model : Model, index : Int) -> Model {
  let rows = model_rows(model)
  if index < 0 || index >= rows.length() {
    return model
  }
  let (pi, mi) = rows[index]
  let name = model.providers[pi].models[mi]
  { ..model, active_model: index, page_note: "已切换模型 " + name }
}

///|
pub fn diag_action(model : Model, index : Int) -> Model {
  let labels = ["已重新连接 Runtime", "Runtime 已重启", "已检查更新 · 没有新版本", "日志已导出到 ~/Downloads"]
  if index < 0 || index >= labels.length() {
    return model
  }
  let note = labels[index]
  if index == 2 {
    { ..model, update_note: note, page_note: note }
  } else {
    set_note(model, note)
  }
}

///|
pub fn caps_run(model : Model, index : Int) -> Model {
  if index < 0 || index >= model.skills.length() {
    return model
  }
  set_note(model, "已执行 /" + model.skills[index].name)
}

///|
pub fn test_provider(model : Model, index : Int) -> Model {
  if index < 0 || index >= model.providers.length() {
    return model
  }
  let prov = model.providers[index]
  let verdict = if prov.key_ok { "连通 · 延迟 214ms" } else { "缺少凭证 · 无法连通" }
  set_note(model, prov.name + " " + verdict)
}

///|
pub fn refresh_models(model : Model, index : Int) -> Model {
  if index < 0 || index >= model.providers.length() {
    return model
  }
  set_note(model, "已刷新 " + model.providers[index].name + " 的模型目录")
}
