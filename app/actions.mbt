// Model transitions for the window manager and the document actions. Pointer
// and keyboard handling call into these, so every mutation stays in one place.

///|
fn with_windows(model : Model, windows : Array[WindowRec]) -> Model {
  { ..model, windows, }
}

///|
fn copy_windows(model : Model) -> Array[WindowRec] {
  let out : Array[WindowRec] = []
  for window in model.windows {
    out.push(window)
  }
  out
}

///|
pub fn window_index(model : Model, id : Int) -> Int {
  let mut i = 0
  let mut found = -1
  for window in model.windows {
    if window.id == id && found < 0 {
      found = i
    }
    i = i + 1
  }
  found
}

///|
fn replace_window(model : Model, id : Int, win : WindowRec) -> Model {
  let ws = copy_windows(model)
  let i = window_index(model, id)
  if i >= 0 {
    ws[i] = win
  }
  with_windows(model, ws)
}

///|
pub fn raise_window(model : Model, id : Int) -> Model {
  { ..model, active: id, }
}

///|
pub fn close_window(model : Model, id : Int) -> Model {
  let ws : Array[WindowRec] = []
  for window in model.windows {
    if window.id != id {
      ws.push(window)
    }
  }
  let mut active = model.active
  if active == id {
    active = -1
    for window in ws {
      if !window.minimized && active < 0 {
        active = window.id
      }
    }
  }
  { ..model, windows: ws, active, }
}

///|
pub fn minimize_window(model : Model, id : Int) -> Model {
  let mut out = model
  match window_by_id(model, id) {
    Some(win) => {
      out = replace_window(model, id, { ..win, minimized: true })
      if model.active == id {
        let mut next = -1
        for w in out.windows {
          if !w.minimized && w.id != id && next < 0 {
            next = w.id
          }
        }
        out = { ..out, active: next, }
      }
    }
    None => ()
  }
  out
}

///|
/// Restore a minimised window (clicking its tab or its capsule).
pub fn restore_window(model : Model, id : Int) -> Model {
  match window_by_id(model, id) {
    Some(win) => raise_window(replace_window(model, id, { ..win, minimized: false }), id)
    None => model
  }
}

///|
pub fn toggle_minimize(model : Model, id : Int) -> Model {
  match window_by_id(model, id) {
    Some(win) =>
      if win.minimized {
        restore_window(model, id)
      } else {
        minimize_window(model, id)
      }
    None => model
  }
}

///|
pub fn toggle_maximize(model : Model, id : Int) -> Model {
  match window_by_id(model, id) {
    Some(win) =>
      if win.maximized {
        raise_window(replace_window(model, id, { ..win, maximized: false, rect: win.pre_rect }), id)
      } else {
        let full = RectD::new(x=0.004, y=0.006, w=0.992, h=0.988)
        raise_window(replace_window(model, id, {
          ..win,
          maximized: true,
          pre_rect: win.rect,
          rect: full,
        }), id)
      }
    None => model
  }
}

///|
pub fn set_window_rect(model : Model, id : Int, rect : RectD) -> Model {
  match window_by_id(model, id) {
    Some(win) => replace_window(model, id, { ..win, rect, })
    None => model
  }
}

///|
pub fn select_thread(model : Model, id : Int) -> Model {
  let mut out = { ..model, current_thread: id, }
  let mut existing = -1
  for window in model.windows {
    let is_convo = match window.kind {
      Conversation => true
      _ => false
    }
    if is_convo && window.thread == id {
      existing = window.id
    }
  }
  if existing >= 0 {
    out = restore_window(out, existing)
  } else {
    let mut title = "未命名会话"
    for thread in model.threads {
      if thread.id == id {
        title = thread.title
      }
    }
    out = new_conversation_window(out, id, title)
  }
  out
}

///|
pub fn new_conversation_window(model : Model, thread : Int, title : String) -> Model {
  let n = model.windows.length()
  let x = 0.06 + (n.to_double() * 0.03).min(0.3)
  let y = 0.08 + (n.to_double() * 0.02).min(0.2)
  let rect = RectD::new(x~, y~, w=0.62, h=0.74)
  let win = {
    id: model.next_id,
    kind: Conversation,
    title,
    badge: "",
    thread,
    rect,
    pre_rect: rect,
    maximized: false,
    minimized: false,
  }
  let ws = copy_windows(model)
  ws.push(win)
  {
    ..model,
    windows: ws,
    active: model.next_id,
    next_id: model.next_id + 1,
  }
}

///|
pub fn new_thread(model : Model) -> Model {
  let threads : Array[Thread] = []
  for thread in model.threads {
    threads.push(thread)
  }
  let id = threads.length()
  threads.push({
    id,
    title: "新建对话",
    status: Running,
    pinned: false,
    project: "omp-web",
    path: "D:/Project/omp-web",
    when: "now",
    unread: 0,
    sub: 0,
  })
  select_thread({ ..model, threads, }, id)
}

///|
/// Lay every visible window into a preset's slots; the first N windows fill the
/// slots and the rest keep their rect.
pub fn apply_preset(model : Model, preset : LayoutPreset) -> Model {
  let slots = preset.slots()
  let vis = visible_windows(model)
  let ws = copy_windows(model)
  let mut i = 0
  let mut j = 0
  for win in ws {
    if !win.minimized && j < slots.length() {
      let slot = slots[j]
      let pad = 0.002
      ws[i] = {
        ..win,
        maximized: false,
        pre_rect: win.rect,
        rect: RectD::new(
          x=slot.x + pad,
          y=slot.y + pad,
          w=(slot.w - pad * 2.0).max(0.05),
          h=(slot.h - pad * 2.0).max(0.05),
        ),
      }
      j = j + 1
    }
    i = i + 1
  }
  ignore(vis)
  { ..model, windows: ws, layout: preset, picker: -1, }
}

///|
pub fn send_composer(model : Model) -> Model {
  let text = model.composer
  if text == "" {
    return model
  }
  let chat : Array[ChatItem] = []
  for item in model.chat {
    chat.push(item)
  }
  chat.push(UserSay("S", "你 · 现在", text))
  {
    ..model,
    chat,
    composer: "",
  }
}

///|
pub fn push_composer(model : Model, s : String) -> Model {
  { ..model, composer: model.composer + s, }
}

///|
pub fn pop_composer(model : Model) -> Model {
  let s = model.composer
  if s == "" {
    return model
  }
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
  { ..model, composer: String::from_array(keep[:]), }
}
