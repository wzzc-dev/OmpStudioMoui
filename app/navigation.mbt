// Navigation and page-state transitions. Routing is a plain field on the model:
// the rail and the page-head row both dispatch `GoRoute`, and every page keeps
// its own scroll offset reset on entry so a page always opens at the top.

///|
pub fn go_route(model : Model, route : Route) -> Model {
  // The reference header always returns to the workbench; the statistics page
  // is opened from the home page's token card and returns there.
  let back = if route == Statistics { Home } else { Workbench }
  {
    ..model,
    route,
    back_route: back,
    page_scroll: 0.0,
    history_focus: false,
    composer_focus: false,
  }
}

///|
fn toggle_skill(model : Model, index : Int) -> Model {
  let rows : Array[SkillRow] = []
  let mut i = 0
  for row in model.skills {
    if i == index {
      rows.push({ ..row, on: !row.on })
    } else {
      rows.push(row)
    }
    i = i + 1
  }
  { ..model, skills: rows, }
}

///|
fn toggle_agent(model : Model, index : Int) -> Model {
  let rows : Array[AgentRow] = []
  let mut i = 0
  for row in model.agents {
    if i == index {
      rows.push({ ..row, on: !row.on })
    } else {
      rows.push(row)
    }
    i = i + 1
  }
  { ..model, agents: rows, }
}

///|
/// History row → workbench: focus the session that already owns this thread,
/// otherwise open one and adopt the row's title.
pub fn open_history_row(model : Model, index : Int) -> Model {
  if index < 0 || index >= model.history_rows.length() {
    return model
  }
  let row = model.history_rows[index]
  let mut existing = -1
  for window in model.windows {
    let is_convo = match window.kind {
      Conversation => true
      _ => false
    }
    if is_convo && window.thread == index {
      existing = window.id
    }
  }
  let opened = select_thread(model, index)
  let retitled = if existing >= 0 {
    opened
  } else {
    match window_by_id(opened, opened.active) {
      Some(win) => replace_window(opened, win.id, { ..win, title: row.title })
      None => opened
    }
  }
  go_route(retitled, Workbench)
}

///|
/// Pages report their laid-out content height so the wheel and the scrollbar
/// can agree on the clamp without the paint pass mutating the model.
pub fn page_max_scroll(model : Model, ps : PageShell) -> Double {
  (page_content_height(model, ps) - ps.body.h + 24.0).max(0.0)
}

///|
pub fn page_limits(model : Model, ps : PageShell) -> (Double, Double) {
  let limit = page_max_scroll(model, ps)
  (limit, ps.body.h)
}

///|
pub fn page_scroll_by(model : Model, delta : Double, ps : PageShell) -> Model {
  let (limit, _) = page_limits(model, ps)
  let next = (model.page_scroll + delta).max(0.0).min(limit)
  { ..model, page_scroll: next, }
}

///|
/// Wrap-around stepper for the enum-like settings values (motion, light, width).
pub fn next_cycle(cur : Int, n : Int) -> Int {
  (cur + 1) % n
}

///|
fn toggle_provider(model : Model, index : Int) -> Model {
  let rows : Array[ProviderRow] = []
  let mut i = 0
  for row in model.providers {
    if i == index {
      rows.push({ ..row, on: !row.on })
    } else {
      rows.push(row)
    }
    i = i + 1
  }
  { ..model, providers: rows, }
}

///|
/// Settings switches are a flat, tab-major array; the row definition carries the
/// slot as its argument, so the toggle and the hit-test index the same store.
fn toggle_switch(model : Model, slot : Int) -> Model {
  let out : Array[Bool] = []
  let mut i = 0
  for value in model.toggles {
    if i == slot {
      out.push(!value)
    } else {
      out.push(value)
    }
    i = i + 1
  }
  { ..model, toggles: out, }
}

///|
/// Role assignment cycles through the flattened model catalogue, which is the
/// same list the 模型定义 tab lists.
fn cycle_role_model(model : Model, index : Int) -> Model {
  let options : Array[String] = []
  for prov in model.providers {
    for name in prov.models {
      options.push(name)
    }
  }
  if options.length() == 0 || index < 0 || index >= model.role_routes.length() {
    return model
  }
  let rows : Array[RoleRoute] = []
  let mut i = 0
  for row in model.role_routes {
    if i == index {
      let mut at = 0
      let mut found = -1
      for name in options {
        if name == row.model && found < 0 {
          found = at
        }
        at = at + 1
      }
      let next = if found < 0 { 0 } else { (found + 1) % options.length() }
      rows.push({ ..row, model: options[next] })
    } else {
      rows.push(row)
    }
    i = i + 1
  }
  { ..model, role_routes: rows, }
}
