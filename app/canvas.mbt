// The shell canvas: one measured node that also receives the runtime paint
// clock. `measured_canvas` has the text system but no clock, `animated_canvas`
// the clock but no text system; interaction (press feedback, tooltip dwell,
// toast lifetime, sheet transitions) needs both, so this node implements the
// ViewNode contract directly and keeps `app_text` / `paint_now` in sync.

///|
/// The runtime paint clock in milliseconds, stashed by the paint pass for the
/// overlay painters and for `needs_frames`. Model timestamps are all stamped
/// from this one source, so an animation sampled at paint time and a duration
/// measured in `update` can never drift apart.
pub let paint_now : Ref[Double] = Ref(0.0)

///|
/// The frame size of the last paint. Keyboard input carries no coordinates of
/// its own, so the shell a key acts on (page scroll clamps, the focus ring, a
/// dialog's footer buttons) is read from what was actually painted rather than
/// from the last pointer event.
pub let paint_frame_w : Ref[Double] = Ref(0.0)

///|
pub let paint_frame_h : Ref[Double] = Ref(0.0)

///|
priv struct OmpCanvas {
  measure : (@core.Constraints, @core.TextSystem) -> @core.Size
  draw : (@common.PaintContext, @core.Rect, Double, @core.TextSystem) -> Unit
  /// Whether this frame should keep the host redraw loop alive. Asked at paint
  /// time with the clock being painted, so a decay ends by itself; a flag baked
  /// in at view-build time would keep the loop alive until the next event.
  needs_frame : (Double) -> Bool
}

///|
impl @core.ViewNode for OmpCanvas with fn identity(_self) {
  @core.ViewIdentity::new(kind="OmpCanvas")
}

///|
impl @core.ViewNode for OmpCanvas with fn layout(self, ctx) {
  @core.ViewLayoutResult::new(
    size=(self.measure)(ctx.constraints, ctx.text_system),
  )
}

///|
impl @core.ViewNode for OmpCanvas with fn paint(self, ctx) {
  let pctx = @common.PaintContext::new()
  (self.draw)(pctx, ctx.frame, ctx.now_ms, ctx.text_system)
  let commands = @common.PaintContext::finish(pctx)
  if (self.needs_frame)(ctx.now_ms) {
    @core.ViewPaintPlan::animating_commands(commands)
  } else {
    @core.ViewPaintPlan::commands(commands)
  }
}

///|
/// The canvas view: the text system comes from layout, the clock and the text
/// system both reach the draw callback.
pub fn[Msg] canvas(
  model : Model,
  measure~ : (@core.Constraints, @core.TextSystem) -> @core.Size,
  draw~ : (@common.PaintContext, @core.Rect, Double, @core.TextSystem) -> Unit,
) -> @core.View[Msg] {
  @core.View::from_node(
    OmpCanvas::{
      measure,
      draw,
      needs_frame: fn(now) { needs_frames_at(model, now) },
    },
  )
}
