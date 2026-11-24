// App entry: the whole workbench is one measured canvas. `update` lives in
// input.mbt; this file only translates host events into Msg values and paints
// the scene with the text system handed over by the layout pass.

///|
/// The text system is owned by layout; the draw pass has no access to it, so the
/// measure callback stashes the host text system for the paint that follows.
let app_text : Ref[@core.TextSystem] = Ref(@core.TextSystem::fallback())

///|
fn pointer_msg(ev : @core.PointerEvent, w : Double, h : Double) -> Msg {
  let wheel = ev.wheel_delta.x + ev.wheel_delta.y
  let phase = match ev.phase {
    @core.PointerPhase::Down => 0
    @core.PointerPhase::Up => 1
    @core.PointerPhase::Move => if wheel != 0.0 { 3 } else { 2 }
    _ => 4
  }
  Pointer({
    phase,
    x: ev.position.x,
    y: ev.position.y,
    w,
    h,
    wheel,
  })
}

///|
fn key_msg(ev : @core.KeyboardEvent) -> Msg {
  let m = ev.modifiers
  let mods = (if m.shift { 1 } else { 0 }) +
    (if m.control { 2 } else { 0 }) +
    (if m.alt { 4 } else { 0 }) +
    (if m.meta { 8 } else { 0 })
  KeyDown(ev.key, mods)
}

///|
fn text_msg(ev : @core.TextInputEvent) -> Msg {
  match ev {
    InsertText(s) => KeyTyped(s)
    ReplaceText(_range, s) => KeyTyped(s)
    CompositionEnd(s) => KeyTyped(s)
    _ => KeyTyped("")
  }
}

///|
pub fn view(model : Model) -> @moui.View[Msg] {
  // The canvas keeps both the text system and the paint clock: the measure
  // pass stashes the text system and the frame size, the draw pass stashes the
  // clock before painting, so interaction timestamps and page scrolling read
  // the same numbers the last frame was drawn with.
  let view = canvas(
    model,
    measure=fn(constraints, ts) {
      app_text.val = ts
      paint_frame_w.val = constraints.max.width
      paint_frame_h.val = constraints.max.height
      constraints.constrain(constraints.max)
    },
    draw=fn(ctx, frame, now, ts) {
      let area = @geometry.Rect::new(
        x=0.0,
        y=0.0,
        width=frame.size.width,
        height=frame.size.height,
      )
      paint_scene(ctx, ts, model, area, now)
    },
  )
  view
    .on_pointer(fn(ev, frame) {
      pointer_msg(ev, frame.size.width, frame.size.height)
    })
    .on_keyboard_input(
      key_handler=fn(ev) { key_msg(ev) },
      text_input_handler=fn(ev) { text_msg(ev) },
    )
}

///|
pub fn program() -> @moui.Program[Model, Msg] {
  @moui.Program::simple(init=Model::new(), update=update, view=view)
}

///|
/// Entry with a chosen start route. The QA harness sets `OMP_ROUTE` so every
/// secondary page can be captured without driving the rail first; routing a
/// fresh model through `go_route` keeps the startup state identical to a click.
pub fn program_at(start : Route) -> @moui.Program[Model, Msg] {
  program_qa(start, false, -1.0, -1.0)
}

///|
/// QA entry: the start route plus the two states a screenshot cannot reach on
/// its own — the ⌘K palette already open, and a pointer parked at (hx, hy) so a
/// hover state is in the frame. A negative coordinate leaves the pointer away,
/// which is the normal start.
pub fn program_qa(
  start : Route,
  palette : Bool,
  hx : Double,
  hy : Double,
) -> @moui.Program[Model, Msg] {
  program_qa_query(start, palette, "", hx, hy)
}

///|
/// Same QA entry with a pre-typed palette query, so the filtered list and the
/// empty state (`OMP_PALETTE_QUERY=zzz`) can be captured like the full one.
pub fn program_qa_query(
  start : Route,
  palette : Bool,
  query : String,
  hx : Double,
  hy : Double,
) -> @moui.Program[Model, Msg] {
  program_qa_state(start, palette, query, "", false, "", false, hx, hy)
}

///|
/// QA entry that also lands a timed layer in its settled state: a dialog
/// (`OMP_MODAL=confirm|rename|shortcuts`), the keyboard ring on its first stop
/// (`OMP_FOCUS=1`), a toast still holding (`OMP_TOAST=文字`) and the dwell tip
/// of the control under the parked pointer (`OMP_TIP=1`). The timestamps are
/// stamped far in the past so the captured frame is the finished state, not the
/// enter animation.
pub fn program_qa_state(
  start : Route,
  palette : Bool,
  query : String,
  modal : String,
  focus : Bool,
  toast : String,
  tip : Bool,
  hx : Double,
  hy : Double,
) -> @moui.Program[Model, Msg] {
  let base = if start == Workbench { Model::new() } else { go_route(Model::new(), start) }
  let seeded = { ..base, palette_open: palette, palette_query: query }
  let initial = qa_seed(with_hover(seeded, hx, hy), modal, focus, toast, tip)
  @moui.Program::simple(init=initial, update=update, view=view)
}

///|
/// Stamp a QA frame's interaction layers. A dialog that is leaving keeps its
/// shell but no longer owns the app, so the modal is opened the normal way and
/// only its clock is pushed back. The tip is latched the same way a real dwell
/// would latch it, at the parked pointer, then its start is pushed back past
/// the 500ms delay so the bubble is fully up in the captured frame.
fn qa_seed(model : Model, modal : String, focus : Bool, toast : String, tip : Bool) -> Model {
  let mut m = model
  if modal != "" {
    let kind = match modal {
      "rename" => MRename
      "shortcuts" => MShortcuts
      _ => MConfirm
    }
    m = modal_open_now(m, kind)
    m = { ..m, modal_open: -10000.0, }
  }
  if toast != "" {
    m = toast_show(m, toast)
    m = { ..m, toast_start: -10000.0, toast_end: 1000000000.0 }
  }
  if focus {
    m = focus_step(m, 1)
  }
  if tip && m.hover_on {
    // A real dwell latches the tip on the first pointer move over the control;
    // replay that call once so the frame shows the same bubble the pointer
    // would have produced after 500ms.
    let list = controls(m, shell_of(m))
    m = hover_tip(m, list, m.hover_x, m.hover_y)
    m = { ..m, tip_start: -10000.0 }
  }
  m
}

///|
/// Pointer position for the next paint. QA and the tests park the pointer on a
/// control this way, so a hover state is in the frame without driving the
/// mouse; a negative coordinate parks it outside every control.
pub fn with_hover(model : Model, x : Double, y : Double) -> Model {
  { ..model, hover_x: x, hover_y: y, hover_on: x >= 0.0 && y >= 0.0 }
}
