// Low-level drawing helpers shared by every part of the workbench: rects,
// rounded surfaces, text with real font metrics and Lucide icons painted as
// vector paths inside the app canvas.

///|
/// True when the pointer is over `r`. Hover lives on the model because the
/// canvas has no per-control pointer callback: painters ask this themselves.
pub fn hovering(model : Model, r : RectD) -> Bool {
  model.hover_on && r.contains(model.hover_x, model.hover_y)
}

///|
pub fn rect(
  x : Double,
  y : Double,
  w : Double,
  h : Double,
) -> @geometry.Rect {
  @geometry.Rect::new(x~, y~, width=w, height=h)
}

///|
pub fn rect_of(r : RectD) -> @geometry.Rect {
  @geometry.Rect::new(x=r.x, y=r.y, width=r.w, height=r.h)
}

///|
pub fn inset_rect(r : @geometry.Rect, d : Double) -> @geometry.Rect {
  rect(r.origin.x + d, r.origin.y + d, r.size.width - d * 2.0, r.size.height - d * 2.0)
}

///|
pub fn trim(r : @geometry.Rect, l : Double, t : Double, right : Double, b : Double) -> @geometry.Rect {
  rect(
    r.origin.x + l,
    r.origin.y + t,
    r.size.width - l - right,
    r.size.height - t - b,
  )
}

///|
pub fn shift(r : @geometry.Rect, dx : Double, dy : Double) -> @geometry.Rect {
  rect(r.origin.x + dx, r.origin.y + dy, r.size.width, r.size.height)
}

///|
pub fn fill(ctx : @common.PaintContext, r : @geometry.Rect, color : @graphics.Color) -> Unit {
  @views.fill_rect(ctx, r, color)
}

///|
pub fn round_fill(
  ctx : @common.PaintContext,
  r : @geometry.Rect,
  radius : Double,
  color : @graphics.Color,
) -> Unit {
  @views.fill_rounded_rect(
    ctx,
    @graphics.RoundedRect::new(rect=r, radius=radius),
    @graphics.Brush::solid(color),
  )
}

///|
pub fn round_stroke(
  ctx : @common.PaintContext,
  r : @geometry.Rect,
  radius : Double,
  color : @graphics.Color,
  width : Double,
) -> Unit {
  @views.stroke_rounded_rect(
    ctx,
    @graphics.RoundedRect::new(rect=r, radius=radius),
    @graphics.Brush::solid(color),
    width,
  )
}

///|
pub fn line(
  ctx : @common.PaintContext,
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
  color : @graphics.Color,
  width : Double,
) -> Unit {
  let verbs : Array[@graphics.PathVerb] = [
    @graphics.PathVerb::MoveTo(@geometry.Point::new(x=x1, y=y1)),
    @graphics.PathVerb::LineTo(@geometry.Point::new(x=x2, y=y2)),
  ]
  @views.draw_path(
    ctx,
    @graphics.PathSpec::new(
      verbs~,
      stroke=Some(@graphics.Brush::solid(color)),
      stroke_width=width,
      stroke_cap=Some(@graphics.StrokeCap::Round),
    ),
  )
}

///|
pub fn shadow(
  ctx : @common.PaintContext,
  r : @geometry.Rect,
  radius : Double,
  color : @graphics.Color,
  blur : Double,
  dy : Double,
) -> Unit {
  @views.draw_shadow(
    ctx,
    @graphics.ShadowSpec::new(
      rect=@graphics.RoundedRect::new(rect=r, radius=radius),
      color~,
      offset=@geometry.Point::new(x=0.0, y=dy),
      blur_radius=blur,
      spread=0.0,
    ),
  )
}

///|
pub fn clip_round(
  ctx : @common.PaintContext,
  r : @geometry.Rect,
  radius : Double,
) -> Unit {
  @views.push_rounded_clip(ctx, @graphics.RoundedRect::new(rect=r, radius=radius))
}

///|
pub fn unclip(ctx : @common.PaintContext) -> Unit {
  @views.pop_rounded_clip(ctx)
}

///|
pub fn clip_rect(ctx : @common.PaintContext, r : @geometry.Rect) -> Unit {
  @views.push_clip(ctx, r)
}

///|
pub fn unclip_rect(ctx : @common.PaintContext) -> Unit {
  @views.pop_clip(ctx)
}

// ---------------------------------------------------------------------------
// Fonts

///|
pub fn font_ui(size : Double, weight : Int32) -> @text.FontSpec {
  @text.FontSpec::new(size~, weight=weight, line_height=size * 1.45)
}

///|
pub fn font_mono(size : Double) -> @text.FontSpec {
  @text.FontSpec::new(
    families=@text.FontFamilyStack::monospace(),
    size~,
    weight=440,
    line_height=size * 1.55,
  )
}

///|
pub fn text_width(
  ts : @core.TextSystem,
  s : String,
  f : @text.FontSpec,
) -> Double {
  ts.measure_text(@core.TextLayoutInput::new(text=s, font=f)).size.width
}

///|
pub fn text_height(ts : @core.TextSystem, s : String, f : @text.FontSpec) -> Double {
  ts.measure_text(@core.TextLayoutInput::new(text=s, font=f)).size.height
}

///|
pub fn put(
  ctx : @common.PaintContext,
  r : @geometry.Rect,
  s : String,
  f : @text.FontSpec,
  color : @graphics.Color,
) -> Unit {
  if s == "" || r.size.width <= 0.0 || r.size.height <= 0.0 {
    return
  }
  @views.draw_text(
    ctx,
    @text.TextRun::new(
      text=s,
      frame=r,
      font=f,
      color~,
      align=@text.TextAlign::TextStart,
    ),
  )
}

///|
pub fn put_c(
  ctx : @common.PaintContext,
  r : @geometry.Rect,
  s : String,
  f : @text.FontSpec,
  color : @graphics.Color,
) -> Unit {
  if s == "" || r.size.width <= 0.0 || r.size.height <= 0.0 {
    return
  }
  @views.draw_text(
    ctx,
    @text.TextRun::new(
      text=s,
      frame=r,
      font=f,
      color~,
      align=@text.TextAlign::TextCenter,
    ),
  )
}

///|
pub fn put_r(
  ctx : @common.PaintContext,
  r : @geometry.Rect,
  s : String,
  f : @text.FontSpec,
  color : @graphics.Color,
) -> Unit {
  if s == "" || r.size.width <= 0.0 || r.size.height <= 0.0 {
    return
  }
  @views.draw_text(
    ctx,
    @text.TextRun::new(
      text=s,
      frame=r,
      font=f,
      color~,
      align=@text.TextAlign::TextEnd,
    ),
  )
}

///|
/// Draws one line of text with its left edge at `x`, vertically centred in a
/// band of `h` starting at `y`. Returns the advance width.
pub fn put_at(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  s : String,
  f : @text.FontSpec,
  color : @graphics.Color,
  x : Double,
  y : Double,
  h : Double,
  max_w : Double,
) -> Unit {
  let w = text_width(ts, s, f)
  let frame = rect(x, y, if max_w > 0.0 { max_w } else { w.max(1.0) }, h)
  put(ctx, frame, s, f, color)
}

///|
pub fn put_at_r(
  ctx : @common.PaintContext,
  s : String,
  f : @text.FontSpec,
  color : @graphics.Color,
  right : Double,
  y : Double,
  h : Double,
  w : Double,
) -> Unit {
  put_r(ctx, rect(right - w, y, w, h), s, f, color)
}

// ---------------------------------------------------------------------------
// Text wrapping: CJK breaks per character, ASCII per word.

///|
fn is_cjk(c : Char) -> Bool {
  let n = c.to_int()
  n >= 0x2E80 && n <= 0x9FFF || n >= 0xAC00 && n <= 0xD7A3 || n >= 0xF900 && n <= 0xFAFF || n >= 0xFF01 && n <= 0xFF60 || n >= 0x3000 && n <= 0x303F
}

///|
struct Token {
  text : String
  space : Bool
  cjk : Bool
}

fn tokenize(s : String) -> Array[Token] {
  let out : Array[Token] = []
  let mut buf = ""
  let mut pending_space = false
  for c in s.iter() {
    if c == ' ' || c == '\n' || c == '\t' {
      if buf != "" {
        out.push({ text: buf, space: pending_space, cjk: false })
        buf = ""
      }
      pending_space = true
    } else if is_cjk(c) {
      if buf != "" {
        out.push({ text: buf, space: pending_space, cjk: false })
        buf = ""
      }
      out.push({ text: c.to_string(), space: pending_space, cjk: true })
      pending_space = false
    } else {
      buf = buf + c.to_string()
    }
  }
  if buf != "" {
    out.push({ text: buf, space: pending_space, cjk: false })
  }
  out
}

///|
pub fn wrap_text(
  ts : @core.TextSystem,
  s : String,
  f : @text.FontSpec,
  max_w : Double,
) -> Array[String] {
  let lines : Array[String] = []
  if s == "" {
    return lines
  }
  let tokens = tokenize(s)
  let space_w = text_width(ts, " ", f)
  let mut line = ""
  let mut line_w = 0.0
  let mut last_space = false
  for t in tokens {
    let tw = text_width(ts, t.text, f)
    let sep = if line == "" { 0.0 } else if t.space { space_w } else { 0.0 }
    if line != "" && line_w + sep + tw > max_w {
      lines.push(line)
      line = t.text
      line_w = tw
      last_space = t.space
    } else {
      if line != "" && t.space {
        line = line + " "
        line_w = line_w + space_w
      }
      line = line + t.text
      line_w = line_w + tw
      last_space = t.space
    }
  }
  if line != "" {
    lines.push(line)
  }
  ignore(last_space)
  lines
}

///|
/// Shortens a single line to `max_w` with an ellipsis. Text painting does not
/// clip by itself, so every label that shares a row with a chip or a button
/// has to be cut before it is drawn.
pub fn ellipsize(
  ts : @core.TextSystem,
  s : String,
  f : @text.FontSpec,
  max_w : Double,
) -> String {
  if max_w <= 0.0 || s == "" {
    return ""
  }
  if text_width(ts, s, f) <= max_w {
    return s
  }
  let dots = "…"
  let limit = (max_w - text_width(ts, dots, f)).max(0.0)
  let mut out = ""
  let mut w = 0.0
  let mut i = 0
  while i < s.length() {
    match s.get_char(i) {
      Some(c) => {
        let cw = text_width(ts, c.to_string(), f)
        if w + cw > limit {
          break
        }
        out = out + c.to_string()
        w = w + cw
      }
      None => break
    }
    i = i + 1
  }
  out + dots
}

///|
/// Draws a wrapped paragraph, returns the consumed height.
pub fn put_wrapped(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  s : String,
  f : @text.FontSpec,
  color : @graphics.Color,
  x : Double,
  y : Double,
  w : Double,
  line_h : Double,
  max_lines : Int,
) -> Double {
  let lines = wrap_text(ts, s, f, w)
  let mut cy = y
  let mut i = 0
  for text in lines {
    if i >= max_lines {
      break
    }
    put(ctx, rect(x, cy, w, line_h), text, f, color)
    cy = cy + line_h
    i = i + 1
  }
  cy - y
}

// ---------------------------------------------------------------------------
// Lucide icons: parsed from the vendored SVG path data into vector verbs.

///|
struct ScanState {
  s : String
  pos : Ref[Int32]
  cmd : Ref[Char]
  cx : Ref[Double]
  cy : Ref[Double]
  sx : Ref[Double]
  sy : Ref[Double]
  ctrl_x : Ref[Double]
  ctrl_y : Ref[Double]
  have_ctrl : Ref[Bool]
}

///|
fn scan_peek(st : ScanState) -> Char? {
  let i = st.pos.val
  if i >= st.s.length() {
    None
  } else {
    st.s.get_char(i)
  }
}

///|
fn is_num_start(c : Char) -> Bool {
  let n = c.to_int()
  let zero = '0'.to_int()
  let nine = '9'.to_int()
  n >= zero && n <= nine || c == '.' || c == '-' || c == '+'
}

///|
fn skip_seps(st : ScanState) -> Unit {
  let mut go = true
  while go {
    match scan_peek(st) {
      Some(c) =>
        if c == ' ' || c == ',' || c == '\n' {
          st.pos.val = st.pos.val + 1
        } else {
          go = false
        }
      None => go = false
    }
  }
}

///|
fn read_num(st : ScanState) -> Double {
  skip_seps(st)
  let start = st.pos.val
  let mut sign = 1.0
  if scan_peek(st) is Some(c) {
    if c == '-' {
      sign = -1.0
      st.pos.val = st.pos.val + 1
    } else if c == '+' {
      st.pos.val = st.pos.val + 1
    }
  }
  let mut int_part = 0.0
  let mut got = false
  let mut go = true
  while go {
    match scan_peek(st) {
      Some(c) =>
        if c >= '0' && c <= '9' {
          int_part = int_part * 10.0 + (c.to_int() - '0'.to_int()).to_double()
          st.pos.val = st.pos.val + 1
          got = true
        } else {
          go = false
        }
      None => go = false
    }
  }
  let mut frac = 0.0
  let mut scale = 1.0
  if scan_peek(st) is Some(c) {
    if c == '.' {
      st.pos.val = st.pos.val + 1
      let mut g2 = true
      while g2 {
        match scan_peek(st) {
          Some(d) =>
            if d >= '0' && d <= '9' {
              frac = frac * 10.0 + (d.to_int() - '0'.to_int()).to_double()
              scale = scale * 10.0
              st.pos.val = st.pos.val + 1
              got = true
            } else {
              g2 = false
            }
          None => g2 = false
        }
      }
    }
  }
  // exponent
  if scan_peek(st) is Some(c) {
    if c == 'e' || c == 'E' {
      let save = st.pos.val
      st.pos.val = st.pos.val + 1
      let mut esign = 1.0
      if scan_peek(st) is Some(d) {
        if d == '-' {
          esign = -1.0
          st.pos.val = st.pos.val + 1
        } else if d == '+' {
          st.pos.val = st.pos.val + 1
        }
      }
      let mut ev = 0.0
      let mut ge = true
      while ge {
        match scan_peek(st) {
          Some(d) =>
            if d >= '0' && d <= '9' {
              ev = ev * 10.0 + (d.to_int() - '0'.to_int()).to_double()
              st.pos.val = st.pos.val + 1
            } else {
              ge = false
            }
          None => ge = false
        }
      }
      if ev == 0.0 {
        st.pos.val = save
      } else {
        let factor = 1.0
        let mut k = 0.0
        while k < ev {
          // pow10 by repeated multiply keeps this allocation free
          k = k + 1.0
        }
        let mut p = 1.0
        let mut j = 0.0
        while j < ev {
          p = p * 10.0
          j = j + 1.0
        }
        return sign * (int_part + frac / scale) * p * factor * (if esign < 0.0 { 0.1 } else { 1.0 }) * (if esign < 0.0 { 1.0 } else { 1.0 })
      }
    }
  }
  ignore(got)
  sign * (int_part + frac / scale)
}

///|
fn push_pt(
  out : Array[@graphics.PathVerb],
  p : @geometry.Point,
) -> Unit {
  out.push(@graphics.PathVerb::MoveTo(p))
}

///|
fn scale_pt(p : @geometry.Point, k : Double, ox : Double, oy : Double) -> @geometry.Point {
  @geometry.Point::new(x=ox + p.x * k, y=oy + p.y * k)
}

///|
/// Signed angle between two vectors, in radians.
fn angle_between(ux : Double, uy : Double, vx : Double, vy : Double) -> Double {
  let dot = ux * vx + uy * vy
  let len = ((ux * ux + uy * uy).sqrt()) * ((vx * vx + vy * vy).sqrt())
  let mut a = if len == 0.0 { 0.0 } else { @math.acos(dot / len) }
  if ux * vy - uy * vx < 0.0 {
    a = -a
  }
  a
}

///|
fn arc_verbs(
  out : Array[@graphics.PathVerb],
  x1 : Double,
  y1 : Double,
  rx_in : Double,
  ry_in : Double,
  rot_deg : Double,
  large : Bool,
  sweep : Bool,
  x2 : Double,
  y2 : Double,
) -> Unit {
  let mut rx = rx_in.abs()
  let mut ry = ry_in.abs()
  if rx == 0.0 || ry == 0.0 {
    out.push(@graphics.PathVerb::LineTo(@geometry.Point::new(x=x2, y=y2)))
    return
  }
  let phi = rot_deg * 3.141592653589793 / 180.0
  let cos_phi = @math.cos(phi)
  let sin_phi = @math.sin(phi)
  let dx2 = (x1 - x2) / 2.0
  let dy2 = (y1 - y2) / 2.0
  let x1p = cos_phi * dx2 + sin_phi * dy2
  let y1p = -sin_phi * dx2 + cos_phi * dy2
  let lambda = (x1p * x1p) / (rx * rx) + (y1p * y1p) / (ry * ry)
  if lambda > 1.0 {
    let s = lambda.sqrt()
    rx = rx * s
    ry = ry * s
  }
  let rx2 = rx * rx
  let ry2 = ry * ry
  let x1p2 = x1p * x1p
  let y1p2 = y1p * y1p
  let num = rx2 * ry2 - rx2 * y1p2 - ry2 * x1p2
  let den = rx2 * y1p2 + ry2 * x1p2
  let mut coef = if den == 0.0 { 0.0 } else { (num / den).max(0.0).sqrt() }
  if large == sweep {
    coef = -coef
  }
  let cxp = coef * rx * y1p / ry
  let cyp = -coef * ry * x1p / rx
  let cx = cos_phi * cxp - sin_phi * cyp + (x1 + x2) / 2.0
  let cy = sin_phi * cxp + cos_phi * cyp + (y1 + y2) / 2.0
  let theta1 = angle_between(
    1.0,
    0.0,
    (x1p - cxp) / rx,
    (y1p - cyp) / ry,
  )
  let mut dtheta = angle_between(
    (x1p - cxp) / rx,
    (y1p - cyp) / ry,
    (-x1p - cxp) / rx,
    (-y1p - cyp) / ry,
  )
  if !sweep && dtheta > 0.0 {
    dtheta = dtheta - 2.0 * 3.141592653589793
  }
  if sweep && dtheta < 0.0 {
    dtheta = dtheta + 2.0 * 3.141592653589793
  }
  let segments = @math.ceil(dtheta.abs() / (3.141592653589793 / 2.0)).to_int()
  let n = if segments < 1 { 1 } else { segments }
  let delta = dtheta / n.to_double()
  let t = (4.0 / 3.0) * @math.tan(delta / 4.0)
  let mut th = theta1
  let mut i = 1
  while i <= n {
    let c1 = @math.cos(th)
    let s1 = @math.sin(th)
    let th2 = th + delta
    let c2 = @math.cos(th2)
    let s2 = @math.sin(th2)
    let p1x = cx + rx * c1 * cos_phi - ry * s1 * sin_phi
    let p1y = cy + rx * c1 * sin_phi + ry * s1 * cos_phi
    let p2x = cx + rx * c2 * cos_phi - ry * s2 * sin_phi
    let p2y = cy + rx * c2 * sin_phi + ry * s2 * cos_phi
    let c1x = p1x + t * (-rx * s1 * cos_phi - ry * c1 * sin_phi)
    let c1y = p1y + t * (-rx * s1 * sin_phi + ry * c1 * cos_phi)
    let c2x = p2x + t * (rx * s2 * cos_phi + ry * c2 * sin_phi)
    let c2y = p2y + t * (rx * s2 * sin_phi - ry * c2 * cos_phi)
    out.push(
      @graphics.PathVerb::CubicTo(
        @geometry.Point::new(x=c1x, y=c1y),
        @geometry.Point::new(x=c2x, y=c2y),
        @geometry.Point::new(x=p2x, y=p2y),
      ),
    )
    th = th2
    i = i + 1
  }
}

///|
fn parse_svg_path(d : String) -> Array[@graphics.PathVerb] {
  let out : Array[@graphics.PathVerb] = []
  let st = {
    s: d,
    pos: Ref::new(0),
    cmd: Ref::new('M'),
    cx: Ref::new(0.0),
    cy: Ref::new(0.0),
    sx: Ref::new(0.0),
    sy: Ref::new(0.0),
    ctrl_x: Ref::new(0.0),
    ctrl_y: Ref::new(0.0),
    have_ctrl: Ref::new(false),
  }
  let mut running = true
  while running {
    skip_seps(st)
    let c = match scan_peek(st) {
      Some(c) => c
      None => break
    }
    if (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') {
      st.cmd.val = c
      st.pos.val = st.pos.val + 1
    }
    let rel = st.cmd.val >= 'a' && st.cmd.val <= 'z'
    let upper = st.cmd.val.to_ascii_uppercase()
    let ox = if rel { st.cx.val } else { 0.0 }
    let oy = if rel { st.cy.val } else { 0.0 }
    match upper {
      'M' => {
        // The vendored table joins Lucide's separate <path> elements into one
        // string, so every moveto starts a fresh subpath at the icon origin —
        // a lowercase `m` after another subpath is absolute-from-origin, not
        // relative to where the previous subpath ended. Reading it relative
        // throws the rest of the glyph off the 24×24 box (the close `x` and
        // both title-bar arrows came out as stray strokes).
        let x = read_num(st)
        let y = read_num(st)
        out.push(@graphics.PathVerb::MoveTo(@geometry.Point::new(x=x, y=y)))
        st.cx.val = x
        st.cy.val = y
        st.sx.val = x
        st.sy.val = y
        st.have_ctrl.val = false
        // implicit lineto for extra pairs
        st.cmd.val = if rel { 'l' } else { 'L' }
      }
      'L' => {
        let x = read_num(st) + ox
        let y = read_num(st) + oy
        out.push(@graphics.PathVerb::LineTo(@geometry.Point::new(x=x, y=y)))
        st.cx.val = x
        st.cy.val = y
        st.have_ctrl.val = false
      }
      'H' => {
        let x = read_num(st) + ox
        out.push(@graphics.PathVerb::LineTo(@geometry.Point::new(x=x, y=st.cy.val)))
        st.cx.val = x
        st.have_ctrl.val = false
      }
      'V' => {
        let y = read_num(st) + oy
        out.push(@graphics.PathVerb::LineTo(@geometry.Point::new(x=st.cx.val, y=y)))
        st.cy.val = y
        st.have_ctrl.val = false
      }
      'C' => {
        let c1x = read_num(st) + ox
        let c1y = read_num(st) + oy
        let c2x = read_num(st) + ox
        let c2y = read_num(st) + oy
        let x = read_num(st) + ox
        let y = read_num(st) + oy
        out.push(
          @graphics.PathVerb::CubicTo(
            @geometry.Point::new(x=c1x, y=c1y),
            @geometry.Point::new(x=c2x, y=c2y),
            @geometry.Point::new(x=x, y=y),
          ),
        )
        st.ctrl_x.val = c2x
        st.ctrl_y.val = c2y
        st.cx.val = x
        st.cy.val = y
        st.have_ctrl.val = true
      }
      'S' => {
        let c1x = if st.have_ctrl.val { st.cx.val * 2.0 - st.ctrl_x.val } else { st.cx.val }
        let c1y = if st.have_ctrl.val { st.cy.val * 2.0 - st.ctrl_y.val } else { st.cy.val }
        let c2x = read_num(st) + ox
        let c2y = read_num(st) + oy
        let x = read_num(st) + ox
        let y = read_num(st) + oy
        out.push(
          @graphics.PathVerb::CubicTo(
            @geometry.Point::new(x=c1x, y=c1y),
            @geometry.Point::new(x=c2x, y=c2y),
            @geometry.Point::new(x=x, y=y),
          ),
        )
        st.ctrl_x.val = c2x
        st.ctrl_y.val = c2y
        st.cx.val = x
        st.cy.val = y
        st.have_ctrl.val = true
      }
      'Q' => {
        let c1x = read_num(st) + ox
        let c1y = read_num(st) + oy
        let x = read_num(st) + ox
        let y = read_num(st) + oy
        out.push(
          @graphics.PathVerb::QuadTo(
            @geometry.Point::new(x=c1x, y=c1y),
            @geometry.Point::new(x=x, y=y),
          ),
        )
        st.ctrl_x.val = c1x
        st.ctrl_y.val = c1y
        st.cx.val = x
        st.cy.val = y
        st.have_ctrl.val = true
      }
      'T' => {
        let c1x = if st.have_ctrl.val { st.cx.val * 2.0 - st.ctrl_x.val } else { st.cx.val }
        let c1y = if st.have_ctrl.val { st.cy.val * 2.0 - st.ctrl_y.val } else { st.cy.val }
        let x = read_num(st) + ox
        let y = read_num(st) + oy
        out.push(
          @graphics.PathVerb::QuadTo(
            @geometry.Point::new(x=c1x, y=c1y),
            @geometry.Point::new(x=x, y=y),
          ),
        )
        st.ctrl_x.val = c1x
        st.ctrl_y.val = c1y
        st.cx.val = x
        st.cy.val = y
        st.have_ctrl.val = true
      }
      'A' => {
        let rx = read_num(st)
        let ry = read_num(st)
        let rot = read_num(st)
        let large = read_num(st) != 0.0
        let sweep = read_num(st) != 0.0
        let x = read_num(st) + ox
        let y = read_num(st) + oy
        arc_verbs(out, st.cx.val, st.cy.val, rx, ry, rot, large, sweep, x, y)
        st.cx.val = x
        st.cy.val = y
        st.have_ctrl.val = false
      }
      'Z' => {
        out.push(@graphics.PathVerb::Close)
        st.cx.val = st.sx.val
        st.cy.val = st.sy.val
        st.have_ctrl.val = false
      }
      _ => {
        // unknown command: stop rather than loop forever
        running = false
      }
    }
    if upper == 'M' {
      // continue with line-to pairs, next iteration picks it up
    }
  }
  out
}

///|
fn scale_verbs(
  verbs : Array[@graphics.PathVerb],
  k : Double,
  ox : Double,
  oy : Double,
) -> Array[@graphics.PathVerb] {
  let out : Array[@graphics.PathVerb] = []
  for v in verbs {
    match v {
      @graphics.PathVerb::MoveTo(p) => out.push(@graphics.PathVerb::MoveTo(scale_pt(p, k, ox, oy)))
      @graphics.PathVerb::LineTo(p) => out.push(@graphics.PathVerb::LineTo(scale_pt(p, k, ox, oy)))
      @graphics.PathVerb::QuadTo(a, b) =>
        out.push(
          @graphics.PathVerb::QuadTo(scale_pt(a, k, ox, oy), scale_pt(b, k, ox, oy)),
        )
      @graphics.PathVerb::CubicTo(a, b, c) =>
        out.push(
          @graphics.PathVerb::CubicTo(
            scale_pt(a, k, ox, oy),
            scale_pt(b, k, ox, oy),
            scale_pt(c, k, ox, oy),
          ),
        )
      @graphics.PathVerb::Close => out.push(@graphics.PathVerb::Close)
    }
  }
  out
}

///|
/// Paint a Lucide icon centred in `r`, sized to `size`.
pub fn icon(
  ctx : @common.PaintContext,
  name : String,
  r : @geometry.Rect,
  size : Double,
  color : @graphics.Color,
  stroke : Double,
) -> Unit {
  let cx = r.origin.x + (r.size.width - size) / 2.0
  let cy = r.origin.y + (r.size.height - size) / 2.0
  icon_at(ctx, name, cx, cy, size, color, stroke)
}

///|
/// The vendored Lucide subset is smaller than the full set, so names the UI
/// asks for but the subset does not carry fall back to the closest glyph it
/// does. Without this those buttons paint an empty box.
fn icon_alias(name : String) -> String {
  match name {
    "app-window" => "grid-3x3"
    "history" => "clock"
    "layers" => "folder-open"
    "gauge" => "bar-chart-3"
    "bot" => "users"
    "pulse" => "activity"
    "sparkles" => "star"
    "message-square" => "message-circle"
    "file-diff" => "file-text"
    "file-check" => "file-text"
    "arrow-up" => "chevron-up"
    "arrow-down" => "chevron-down"
    "ellipsis" => "more-horizontal"
    "circle-alert" => "alert-circle"
    "lock-open" => "unlock"
    "mic" => "bell"
    "rotate-cw" => "refresh-cw"
    _ => name
  }
}

///|
pub fn icon_at(
  ctx : @common.PaintContext,
  name : String,
  x : Double,
  y : Double,
  size : Double,
  color : @graphics.Color,
  stroke : Double,
) -> Unit {
  let d = match @views.lucide_icon_path_data(icon_alias(name)) {
    Some(d) => d
    None => ""
  }
  if d == "" {
    return
  }
  let verbs = scale_verbs(parse_svg_path(d), size / 24.0, x, y)
  @views.draw_path(
    ctx,
    @graphics.PathSpec::new(
      verbs~,
      stroke=Some(@graphics.Brush::solid(color)),
      stroke_width=stroke * size / 24.0,
      stroke_cap=Some(@graphics.StrokeCap::Round),
      stroke_join=Some(@graphics.StrokeJoin::Round),
    ),
  )
}

///|
pub fn icon_w(
  ctx : @common.PaintContext,
  name : String,
  x : Double,
  y : Double,
  size : Double,
  color : @graphics.Color,
  stroke : Double,
) -> Unit {
  icon_at(ctx, name, x, y, size, color, stroke)
}

///|
pub fn icon_c(
  ctx : @common.PaintContext,
  name : String,
  cx : Double,
  cy : Double,
  size : Double,
  color : @graphics.Color,
  stroke : Double,
) -> Unit {
  icon_at(ctx, name, cx - size / 2.0, cy - size / 2.0, size, color, stroke)
}

///|
pub fn dot(ctx : @common.PaintContext, cx : Double, cy : Double, d : Double, color : @graphics.Color) -> Unit {
  round_fill(ctx, rect(cx - d / 2.0, cy - d / 2.0, d, d), d / 2.0, color)
}

///|
pub fn spinner(
  ctx : @common.PaintContext,
  cx : Double,
  cy : Double,
  d : Double,
  color : @graphics.Color,
  angle : Double,
) -> Unit {
  let r = d / 2.0
  let verbs : Array[@graphics.PathVerb] = []
  let steps = 16
  let mut i = 0
  while i <= steps {
    let a = angle + (i.to_double() / steps.to_double()) * 3.141592653589793 * 1.55
    let x = cx + r * @math.cos(a)
    let y = cy + r * @math.sin(a)
    verbs.push(
      @graphics.PathVerb::MoveTo(@geometry.Point::new(x=x, y=y)),
    )
    i = i + 1
  }
  i = 0
  while i <= steps {
    let a = angle + (i.to_double() / steps.to_double()) * 3.141592653589793 * 1.55
    let x = cx + r * @math.cos(a)
    let y = cy + r * @math.sin(a)
    verbs.push(
      @graphics.PathVerb::LineTo(@geometry.Point::new(x=x, y=y)),
    )
    i = i + 1
  }
  @views.draw_path(
    ctx,
    @graphics.PathSpec::new(
      verbs~,
      stroke=Some(@graphics.Brush::solid(color)),
      stroke_width=1.8,
      stroke_cap=Some(@graphics.StrokeCap::Round),
    ),
  )
}

///|
/// A ring with a coloured arc, used for the tool pills on the conversation
/// window edge (git / box / terminal counters).
pub fn ring_arc(
  ctx : @common.PaintContext,
  cx : Double,
  cy : Double,
  r : Double,
  color : @graphics.Color,
  start : Double,
  sweep : Double,
  width : Double,
) -> Unit {
  let steps = 22
  let verbs : Array[@graphics.PathVerb] = []
  let mut i = 0
  while i <= steps {
    let a = start + sweep * (i.to_double() / steps.to_double())
    let x = cx + r * @math.cos(a)
    let y = cy + r * @math.sin(a)
    if i == 0 {
      verbs.push(@graphics.PathVerb::MoveTo(@geometry.Point::new(x=x, y=y)))
    } else {
      verbs.push(@graphics.PathVerb::LineTo(@geometry.Point::new(x=x, y=y)))
    }
    i = i + 1
  }
  @views.draw_path(
    ctx,
    @graphics.PathSpec::new(
      verbs~,
      stroke=Some(@graphics.Brush::solid(color)),
      stroke_width=width,
      stroke_cap=Some(@graphics.StrokeCap::Round),
    ),
  )
}
