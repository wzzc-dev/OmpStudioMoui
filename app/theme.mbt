// Design tokens lifted from omp-studio apps/renderer/src/styles/tokens.css so the
// replica keeps the original contrast ratios instead of eyeballing them.

///|
pub struct Palette {
  dark : Bool
  bg : @graphics.Color
  bg_inset : @graphics.Color
  surface : @graphics.Color
  surface_2 : @graphics.Color
  surface_3 : @graphics.Color
  /// Translucent overlay the reference paints over a surface for `:hover`
  /// (`--surface-hover`), and its pressed twin (`--surface-active`).
  surface_hover : @graphics.Color
  surface_active : @graphics.Color
  border : @graphics.Color
  border_strong : @graphics.Color
  /// `--border-float`: the frame of a surface that floats free of the page
  /// (modal, plan dialog, toast), dark enough to separate it on its own.
  border_float : @graphics.Color
  text : @graphics.Color
  text_2 : @graphics.Color
  text_3 : @graphics.Color
  text_faint : @graphics.Color
  accent : @graphics.Color
  /// `--accent-hover`: the primary button's hover fill (lighter on dark, deeper
  /// on light), kept apart from `accent` so hover never changes the identity.
  accent_hover : @graphics.Color
  accent_soft : @graphics.Color
  accent_border : @graphics.Color
  on_accent : @graphics.Color
  green : @graphics.Color
  amber : @graphics.Color
  red : @graphics.Color
  blue : @graphics.Color
  orange : @graphics.Color
  window_bg : @graphics.Color
  window_bg_alt : @graphics.Color
  shadow : @graphics.Color
}

///|
pub fn rgba8(r : Int, g : Int, b : Int, alpha : Double) -> @graphics.Color {
  @graphics.Color::rgba(
    r=r.to_double() / 255.0,
    g=g.to_double() / 255.0,
    b=b.to_double() / 255.0,
    a=alpha,
  )
}

///|
pub fn solid(r : Int, g : Int, b : Int) -> @graphics.Color {
  rgba8(r, g, b, 1.0)
}

///|
pub fn Palette::new(dark : Bool) -> Palette {
  if dark {
    {
      dark: true,
      bg: solid(0x12, 0x15, 0x19),
      bg_inset: solid(0x0e, 0x10, 0x13),
      surface: solid(0x1a, 0x1b, 0x1f),
      surface_2: solid(0x22, 0x23, 0x29),
      surface_3: solid(0x2b, 0x2c, 0x33),
      surface_hover: rgba8(235, 235, 245, 0.05),
      surface_active: rgba8(235, 235, 245, 0.09),
      border: rgba8(255, 255, 255, 0.07),
      border_strong: rgba8(255, 255, 255, 0.12),
      border_float: solid(0x46, 0x50, 0x5f),
      text: solid(0xe7, 0xe8, 0xeb),
      text_2: solid(0xa7, 0xab, 0xb4),
      text_3: solid(0x8b, 0x90, 0x9a),
      text_faint: solid(0x7c, 0x82, 0x8c),
      accent: solid(0x9e, 0x8c, 0xfc),
      accent_hover: solid(0xb0, 0xa2, 0xff),
      accent_soft: rgba8(158, 140, 252, 0.14),
      accent_border: rgba8(158, 140, 252, 0.4),
      on_accent: solid(0x12, 0x13, 0x16),
      green: solid(0x46, 0xb9, 0x83),
      amber: solid(0xe0, 0xa2, 0x3c),
      red: solid(0xf0, 0x65, 0x68),
      blue: solid(0x5d, 0xa9, 0xe0),
      orange: solid(0xff, 0x7a, 0x45),
      window_bg: solid(0x16, 0x18, 0x1d),
      window_bg_alt: solid(0x19, 0x1b, 0x20),
      shadow: rgba8(0, 0, 0, 0.55),
    }
  } else {
    {
      dark: false,
      bg: solid(0xfb, 0xfb, 0xfc),
      bg_inset: solid(0xff, 0xff, 0xff),
      surface: solid(0xff, 0xff, 0xff),
      surface_2: solid(0xf2, 0xf2, 0xf5),
      surface_3: solid(0xe8, 0xe8, 0xec),
      surface_hover: rgba8(20, 20, 30, 0.045),
      surface_active: rgba8(20, 20, 30, 0.08),
      border: rgba8(15, 18, 25, 0.09),
      border_strong: rgba8(15, 18, 25, 0.16),
      border_float: solid(0x9b, 0x95, 0x8c),
      text: solid(0x1d, 0x21, 0x29),
      text_2: solid(0x4e, 0x55, 0x60),
      text_3: solid(0x5c, 0x63, 0x6e),
      text_faint: solid(0x6d, 0x74, 0x80),
      accent: solid(0x6e, 0x56, 0xcf),
      accent_hover: solid(0x5f, 0x48, 0xc0),
      accent_soft: rgba8(110, 86, 207, 0.1),
      accent_border: rgba8(110, 86, 207, 0.35),
      on_accent: solid(0xff, 0xff, 0xff),
      green: solid(0x13, 0x7a, 0x52),
      amber: solid(0x8f, 0x5a, 0x05),
      red: solid(0xc0, 0x27, 0x2c),
      blue: solid(0x1f, 0x6b, 0xa3),
      orange: solid(0xc2, 0x41, 0x0c),
      window_bg: solid(0xff, 0xff, 0xff),
      window_bg_alt: solid(0xfa, 0xfa, 0xfc),
      shadow: rgba8(18, 31, 48, 0.18),
    }
  }
}

///|
pub fn app_theme(dark : Bool) -> @moui.Theme {
  if dark {
    @views.desktop_dark_theme()
  } else {
    @views.desktop_light_theme()
  }
}

///|
pub fn hairline(
  color : @graphics.Color,
  width : Double,
) -> @graphics.BorderStyle {
  @graphics.BorderStyle::new(brush=@graphics.Brush::solid(color), width~)
}

///|
pub fn Palette::line_style(self : Palette) -> @graphics.BorderStyle {
  hairline(self.border, 1.0)
}

///|
pub fn Palette::strong_line(self : Palette) -> @graphics.BorderStyle {
  hairline(self.border_strong, 1.0)
}

///|
pub fn Palette::window_shadow(self : Palette) -> @graphics.ShadowStyle {
  @graphics.ShadowStyle::new(
    color=self.shadow,
    offset=@geometry.Point::new(x=0.0, y=10.0),
    blur_radius=26.0,
    spread=0.0,
  )
}

///|
pub fn Palette::soft_shadow(self : Palette) -> @graphics.ShadowStyle {
  @graphics.ShadowStyle::new(
    color=self.shadow,
    offset=@geometry.Point::new(x=0.0, y=4.0),
    blur_radius=12.0,
    spread=0.0,
  )
}

///|
pub fn ui_font(size : Double, weight : Int32) -> @text.FontSpec {
  @text.FontSpec::new(size~, weight=weight)
}

///|
pub fn mono_font(size : Double) -> @text.FontSpec {
  @text.FontSpec::new(
    families=@text.FontFamilyStack::monospace(),
    size~,
    weight=430,
  )
}
