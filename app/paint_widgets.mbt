// Reusable painting pieces: panels, pills, chips, icon buttons, the brand mark
// and the small status dots that carry OMP Studio's state colours.

///|
pub fn panel(
  ctx : @common.PaintContext,
  r : RectD,
  radius : Double,
  fill_color : @graphics.Color,
  stroke_color : @graphics.Color,
) -> Unit {
  let gr = rect_of(r)
  if stroke_color.a > 0.0 {
    round_fill(ctx, gr, radius, stroke_color)
    round_fill(ctx, inset_rect(gr, 1.0), (radius - 1.0).max(0.0), fill_color)
  } else {
    round_fill(ctx, gr, radius, fill_color)
  }
}

///|
pub fn hair(
  ctx : @common.PaintContext,
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
  color : @graphics.Color,
) -> Unit {
  line(ctx, x1, y1, x2, y2, color, 1.0)
}

///|
pub fn status_dot(
  ctx : @common.PaintContext,
  cx : Double,
  cy : Double,
  color : @graphics.Color,
) -> Unit {
  dot(ctx, cx, cy, 5.0, color)
}

///|
pub fn avatar(
  ctx : @common.PaintContext,
  cx : Double,
  cy : Double,
  d : Double,
  fill_color : @graphics.Color,
  letter : String,
  ts : @core.TextSystem,
  pal : Palette,
) -> Unit {
  let r = rect(cx - d / 2.0, cy - d / 2.0, d, d)
  round_fill(ctx, r, d / 2.0, fill_color)
  let f = font_ui(d * 0.42, 600)
  put_c(ctx, r, letter, f, if pal.dark { pal.on_accent } else { solid(255, 255, 255) })
}

///|
/// The π mark used for the OMP Studio logo tile.
pub fn brand_mark(
  ctx : @common.PaintContext,
  r : RectD,
  color : @graphics.Color,
  tile : @graphics.Color,
) -> Unit {
  let gr = rect_of(r)
  round_fill(ctx, gr, 9.0, tile)
  let pad = r.w * 0.24
  let x0 = r.x + pad
  let x1 = r.x + r.w - pad
  let top = r.y + r.h * 0.3
  let bottom = r.y + r.h * 0.72
  let w = (r.w * 0.09).max(1.4)
  line(ctx, x0, top, x1, top, color, w)
  line(ctx, x0 + (x1 - x0) * 0.28, top, x0 + (x1 - x0) * 0.28, bottom, color, w)
  line(ctx, x0 + (x1 - x0) * 0.78, top, x0 + (x1 - x0) * 0.78, bottom, color, w)
}

///|
pub fn chip(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  r : RectD,
  s : String,
  fg : @graphics.Color,
  bg : @graphics.Color,
  stroke : @graphics.Color,
  size : Double,
) -> Unit {
  let gr = rect_of(r)
  let rad = r.h / 2.0
  if stroke.a > 0.0 {
    round_fill(ctx, gr, rad, stroke)
    round_fill(ctx, inset_rect(gr, 1.0), rad - 1.0, bg)
  } else {
    round_fill(ctx, gr, rad, bg)
  }
  let f = font_ui(size, 500)
  put_c(ctx, gr, ellipsize(ts, s, f, r.w - 10.0), f, fg)
}

///|
pub fn badge_dot(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  r : RectD,
  s : String,
  color : @graphics.Color,
) -> Unit {
  let gr = rect_of(r)
  round_fill(ctx, gr, r.h / 2.0, color)
  let f = font_ui(9.5, 600)
  put_c(ctx, gr, s, f, solid(255, 255, 255))
}

///|
pub fn outline_button(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  r : RectD,
  label : String,
  fg : @graphics.Color,
  fill_color : @graphics.Color,
  stroke : @graphics.Color,
) -> Unit {
  panel(ctx, r, 9.0, fill_color, stroke)
  put_c(ctx, rect_of(r), label, font_ui(11.5, 500), fg)
}

///|
pub fn primary_button(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  r : RectD,
  label : String,
  fill_color : @graphics.Color,
  fg : @graphics.Color,
) -> Unit {
  panel(ctx, r, 9.0, fill_color, @graphics.Color::rgba(r=0.0, g=0.0, b=0.0, a=0.0))
  put_c(ctx, rect_of(r), label, font_ui(11.5, 600), fg)
}

///|
pub fn section_head(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  x : Double,
  y : Double,
  w : Double,
  label : String,
  pal : Palette,
) -> Unit {
  let f = @text.FontSpec::new(size=11.0, weight=600, letter_spacing=0.4)
  put(ctx, rect(x, y - 4.0, w, 18.0), label, f, pal.text_3)
}

///|
pub fn icon_button(
  ctx : @common.PaintContext,
  r : RectD,
  name : String,
  color : @graphics.Color,
  glyph : Double,
) -> Unit {
  icon(ctx, name, rect_of(r), glyph, color, 1.6)
}

///|
pub fn chevron_down(
  ctx : @common.PaintContext,
  cx : Double,
  cy : Double,
  color : @graphics.Color,
  size : Double,
) -> Unit {
  icon_c(ctx, "chevron-down", cx, cy, size, color, 1.7)
}

///|
pub fn wrap_lines(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  s : String,
  f : @text.FontSpec,
  color : @graphics.Color,
  r : RectD,
  line_h : Double,
  max_lines : Int,
) -> Unit {
  ignore(put_wrapped(ctx, ts, s, f, color, r.x, r.y, r.w, line_h, max_lines))
}

///|
/// A vertical scrollbar thumb on the right of a scroll area.
pub fn scroll_thumb(
  ctx : @common.PaintContext,
  r : RectD,
  color : @graphics.Color,
) -> Unit {
  let w = 3.0
  round_fill(ctx, rect(r.x + r.w - w - 2.0, r.y, w, r.h), w / 2.0, color)
}

///|
/// Draws a dashed 1px divider.
pub fn dashed(
  ctx : @common.PaintContext,
  x1 : Double,
  y : Double,
  x2 : Double,
  color : @graphics.Color,
) -> Unit {
  let mut x = x1
  while x < x2 {
    let e = (x + 3.0).min(x2)
    hair(ctx, x, y, e, y, color)
    x = x + 6.0
  }
}
