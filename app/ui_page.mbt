// Shared widgets for the secondary pages: text lines with real metrics, cards,
// buttons, toggles, segmented controls and the token chart. Pages compose these
// so spacing and radius stay uniform across the ten routes.

///|
fn line_box(f : @text.FontSpec) -> Double {
  f.size * 1.45
}

///|
/// Left-aligned single line, vertically centred on `cy`. Returns its width, so
/// callers that compose a line inline (the composer caret, the search caret)
/// can advance by exactly the painted advance.
pub fn tline_w(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  s : String,
  f : @text.FontSpec,
  color : @graphics.Color,
  x : Double,
  cy : Double,
  max_w : Double,
) -> Double {
  if s == "" {
    return 0.0
  }
  let text = if max_w > 0.0 { ellipsize(ts, s, f, max_w) } else { s }
  let w = text_width(ts, text, f)
  let lh = line_box(f)
  put(ctx, rect(x, cy - lh / 2.0, if max_w > 0.0 { max_w } else { w + 2.0 }, lh), text, f, color)
  w
}

///|
/// Same line, used for its paint only. `tline` returning Unit keeps every
/// statement position in the painters free of `ignore(…)` noise.
pub fn tline(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  s : String,
  f : @text.FontSpec,
  color : @graphics.Color,
  x : Double,
  cy : Double,
  max_w : Double,
) -> Unit {
  let _ = tline_w(ctx, ts, s, f, color, x, cy, max_w)
}

///|
pub fn tline_c(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  s : String,
  f : @text.FontSpec,
  color : @graphics.Color,
  x : Double,
  cy : Double,
  w : Double,
) -> Unit {
  let lh = line_box(f)
  put_c(ctx, rect(x, cy - lh / 2.0, w, lh), ellipsize(ts, s, f, w - 4.0), f, color)
}

///|
/// Right-aligned line whose right edge is `right`.
pub fn tline_r(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  s : String,
  f : @text.FontSpec,
  color : @graphics.Color,
  right : Double,
  cy : Double,
  max_w : Double,
) -> Unit {
  if s == "" {
    return
  }
  let text = if max_w > 0.0 { ellipsize(ts, s, f, max_w) } else { s }
  let w = text_width(ts, text, f)
  let lh = line_box(f)
  put_r(ctx, rect(right - w, cy - lh / 2.0, w + 1.0, lh), text, f, color)
}

///|
pub fn page_card(
  ctx : @common.PaintContext,
  r : RectD,
  p : Palette,
) -> Unit {
  round_fill(ctx, rect_of(r), 10.0, p.surface)
  round_stroke(ctx, rect_of(r), 10.0, p.border, 1.0)
}

///|
pub fn page_hr(
  ctx : @common.PaintContext,
  x : Double,
  y : Double,
  w : Double,
  p : Palette,
) -> Unit {
  hair(ctx, x, y, x + w, y, p.border)
}

///|
/// `.btn` — 32 high, radius 8, 12.5/500. A hovered button swaps its surface for
/// the reference's `--surface-hover` overlay and lifts its label to `--text`;
/// the primary variant darkens to `--accent-hover` instead.
pub fn page_btn(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  r : RectD,
  label : String,
  primary : Bool,
  p : Palette,
  hovered? : Bool = false,
) -> Unit {
  if primary {
    if hovered {
      round_fill(ctx, rect_of(r), 8.0, p.accent_hover)
    } else {
      round_fill(ctx, rect_of(r), 8.0, p.accent)
    }
    tline_c(ctx, ts, label, font_ui(12.5, 600), p.on_accent, r.x, r.y + r.h / 2.0, r.w)
  } else if hovered {
    round_fill(ctx, rect_of(r), 8.0, p.surface_hover)
    round_stroke(ctx, rect_of(r), 8.0, p.border_strong, 1.0)
    tline_c(ctx, ts, label, font_ui(12.5, 500), p.text, r.x, r.y + r.h / 2.0, r.w)
  } else {
    round_fill(ctx, rect_of(r), 8.0, p.surface)
    round_stroke(ctx, rect_of(r), 8.0, p.border_strong, 1.0)
    tline_c(ctx, ts, label, font_ui(12.5, 500), p.text_2, r.x, r.y + r.h / 2.0, r.w)
  }
}

///|
/// Segmented control: one bordered track, `active` slot filled.
pub fn page_segmented(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  r : RectD,
  labels : Array[String],
  active : Int,
  p : Palette,
) -> Unit {
  round_fill(ctx, rect_of(r), 8.0, p.surface_2)
  let cell = r.w / labels.length().to_double()
  let mut i = 0
  while i < labels.length() {
    let cell_r = RectD::new(x=r.x + cell * i.to_double(), y=r.y, w=cell, h=r.h)
    if i == active {
      round_fill(ctx, inset_rect(rect_of(cell_r), 2.0), 6.0, p.surface)
      round_stroke(ctx, inset_rect(rect_of(cell_r), 2.0), 6.0, p.border, 1.0)
    }
    let fg = if i == active { p.text } else { p.text_3 }
    tline_c(ctx, ts, labels[i], font_ui(11.5, if i == active { 600 } else { 500 }), fg, cell_r.x, cell_r.y + cell_r.h / 2.0, cell_r.w)
    i = i + 1
  }
}

///|
/// `.toggle` — 36×20 track, 16px knob.
pub fn page_toggle(
  ctx : @common.PaintContext,
  r : RectD,
  on : Bool,
  p : Palette,
) -> Unit {
  let track = RectD::new(x=r.x + (r.w - 36.0) / 2.0, y=r.y + (r.h - 20.0) / 2.0, w=36.0, h=20.0)
  round_fill(ctx, rect_of(track), 10.0, if on { p.accent } else { p.surface_3 })
  let kx = if on { track.right() - 18.0 } else { track.x + 2.0 }
  dot(ctx, kx + 8.0, track.y + 10.0, 16.0, if on { p.on_accent } else { p.text_3 })
}

///|
/// Section heading (`.home-h` / `.set-h`): 14/600 with 8px breathing room.
pub fn page_section(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  x : Double,
  y : Double,
  w : Double,
  label : String,
  p : Palette,
) -> Unit {
  tline(ctx, ts, label, font_ui(14.0, 600), p.text, x, y + 9.0, w)
}

///|
pub fn page_muted(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  s : String,
  x : Double,
  cy : Double,
  w : Double,
  p : Palette,
) -> Unit {
  tline(ctx, ts, s, font_ui(12.0, 400), p.text_3, x, cy, w)
}

///|
/// Small status chip: 20 high, radius 6, 11px label.
pub fn page_tag(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  r : RectD,
  label : String,
  color : @graphics.Color,
  p : Palette,
) -> Unit {
  round_fill(ctx, rect_of(r), 6.0, p.surface_2)
  round_stroke(ctx, rect_of(r), 6.0, p.border, 1.0)
  tline_c(ctx, ts, label, font_ui(11.0, 500), color, r.x, r.y + r.h / 2.0, r.w)
}

///|
/// Stacked bar chart for the usage page: input on the accent ramp, output on
/// the blue ramp, day labels under every other bar.
pub fn page_bar_chart(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  r : RectD,
  days : Array[UsageDay],
  p : Palette,
) -> Unit {
  if days.length() == 0 {
    return
  }
  let label_h = 20.0
  let plot_h = (r.h - label_h).max(20.0)
  let max_total = {
    let mut m = 1
    for day in days {
      let t = day.input + day.output
      if t > m {
        m = t
      }
    }
    m
  }
  let n = days.length()
  let slot = r.w / n.to_double()
  let bar_w = (slot * 0.42).max(4.0)
  let mut i = 0
  while i < n {
    let day = days[i]
    let total = day.input + day.output
    let h = plot_h * total.to_double() / max_total.to_double()
    let bx = r.x + slot * i.to_double() + (slot - bar_w) / 2.0
    let by = r.y + plot_h - h
    let in_h = h * day.input.to_double() / total.to_double()
    let out_h = h - in_h
    round_fill(ctx, rect(bx, by, bar_w, out_h.max(1.0)), 2.0, p.blue)
    round_fill(ctx, rect(bx, by + out_h, bar_w, in_h.max(1.0)), 2.0, p.accent)
    if i % 2 == 0 || i == n - 1 {
      tline_c(ctx, ts, day.label, font_ui(10.0, 400), p.text_3, r.x + slot * i.to_double(), r.y + plot_h + 10.0, slot)
    }
    i = i + 1
  }
  hair(ctx, r.x, r.y + plot_h, r.right(), r.y + plot_h, p.border)
}

///|
/// Text input frame used by the history search box.
pub fn page_input(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  r : RectD,
  value : String,
  placeholder : String,
  focused : Bool,
  p : Palette,
) -> Unit {
  round_fill(ctx, rect_of(r), 8.0, p.surface)
  round_stroke(ctx, rect_of(r), 8.0, if focused { p.accent_border } else { p.border_strong }, 1.0)
  let cy = r.y + r.h / 2.0
  let mut x = r.x + 12.0
  if value == "" {
    tline(ctx, ts, placeholder, font_ui(12.0, 400), p.text_faint, x, cy, r.w - 24.0)
  } else {
    x = x + tline_w(ctx, ts, value, font_ui(12.0, 400), p.text, x, cy, r.w - 24.0)
    if focused {
      hair(ctx, x + 1.0, r.y + 8.0, x + 1.0, r.y + r.h - 8.0, p.text)
    }
  }
  icon(ctx, "search", rect(r.right() - 28.0, cy - 7.0, 14.0, 14.0), 14.0, p.text_faint, 1.6)
}
