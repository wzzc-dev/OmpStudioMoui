// Interaction paint: the three timed surfaces beside the shell (press feedback,
// tooltip dwell, toast lifetime) and the modal sheet. Everything is painted
// from the same rects `interact.mbt` uses for the hit test, so a control can
// never show feedback somewhere it cannot be clicked.
//
// Z order is the reference's: controls belong to the page, the dialog takes
// --z-modal (80), the tip --z-tip (90, and TipHost is a body portal, so it
// survives above a dialog) and the toast --z-toast (100). A dialog opening
// clears the tip so the sheet is not read through a bubble.

///|
pub fn paint_interaction(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  model : Model,
  shell : Shell,
  p : Palette,
  w : Double,
  h : Double,
) -> Unit {
  if !model.palette_open && model.modal == MNone {
    let list = controls(model, shell)
    paint_focus_ring(ctx, model, list, p)
    paint_press_feedback(ctx, model, list, p)
  }
  if modal_kind(model) != MNone {
    paint_modal_sheet(ctx, ts, model, p, w, h)
  }
  if model.modal == MNone && model.tip_ctl != CNone && model.tip_text != "" {
    paint_tip_bubble(ctx, ts, model, p, shell, w, h)
  }
  if model.toast_text != "" {
    paint_toast(ctx, ts, model, p, w, h)
  }
}

// ---------------------------------------------------------------------------
// Press and focus

///|
/// A pressed control is pushed one pixel down and tinted with `--surface-active`
/// in the reference. A canvas cannot move painted content after the fact, so the
/// push is drawn as the tint plus a hairline on the rect's top edge: the same
/// reading at 1x, without repainting the control.
fn paint_press_feedback(
  ctx : @common.PaintContext,
  model : Model,
  list : Array[CtlRec],
  p : Palette,
) -> Unit {
  if model.press_ctl == CNone {
    return
  }
  let alpha = press_alpha(model)
  if alpha <= 0.0 {
    return
  }
  match ctl_rect(list, model.press_ctl) {
    None => ()
    Some(r) => {
      let shape = rect_of(r)
      round_fill(ctx, shape, ctl_radius(model.press_ctl, r), p.surface_active.with_alpha(0.9 * alpha))
      fill(ctx, rect(r.x, r.y, r.w, 1.0), p.text.with_alpha(0.06 * alpha))
      round_stroke(ctx, shape, ctl_radius(model.press_ctl, r), p.border_strong.with_alpha(0.7 * alpha), 1.0)
    }
  }
}

///|
/// The keyboard ring: 2px accent with a 2px offset, exactly the reference's
/// `:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px }`.
fn paint_focus_ring(
  ctx : @common.PaintContext,
  model : Model,
  list : Array[CtlRec],
  p : Palette,
) -> Unit {
  if !model.focus_kb || model.focus_ctl == CNone {
    return
  }
  match ctl_rect(list, model.focus_ctl) {
    None => ()
    Some(r) => {
      let ring = rect(r.x - 2.0, r.y - 2.0, r.w + 4.0, r.h + 4.0)
      round_stroke(ctx, ring, ctl_radius(model.focus_ctl, r) + 2.0, p.accent, 2.0)
    }
  }
}

///|
/// Radius of the control's own shape, so the ring traces it instead of forcing
/// one radius onto every button (the reference calls this out in base.css).
fn ctl_radius(ctl : Ctl, r : RectD) -> Double {
  match ctl {
    CPageNav(_) | CPlusTab | CPageTheme => r.h / 2.0
    CWinMin(_) | CWinMax(_) | CWinClose(_) => 6.0
    CTab(_) | CTabClose(_) => 7.0
    _ => 8.0
  }
}

// ---------------------------------------------------------------------------
// Tooltip

///|
/// TipHost bubble: 11px text, 3/8 padding, 4px radius, `--text` on `--bg`,
/// 6px off the control (below it near the top edge, so the topbar's own tips
/// are not clipped).
fn paint_tip_bubble(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  model : Model,
  p : Palette,
  shell : Shell,
  w : Double,
  h : Double,
) -> Unit {
  let alpha = tip_alpha(model)
  if alpha <= 0.0 {
    return
  }
  let list = controls(model, shell)
  let anchor = match ctl_rect(list, model.tip_ctl) {
    Some(r) => r
    None => model.tip_rect
  }
  let f = font_ui(11.0, 400)
  let text = ellipsize(ts, model.tip_text, f, 204.0)
  let bw = (text_width(ts, text, f) + 16.0).max(28.0)
  let bh = 22.0
  let below = anchor.y < 64.0
  let by = if below { anchor.y + anchor.h + 6.0 } else { anchor.y - 6.0 - bh }
  let bx = (anchor.x + anchor.w / 2.0 - bw / 2.0).max(4.0).min((w - bw - 4.0).max(4.0))
  let bubble = rect(bx, by.max(4.0), bw, bh)
  shadow(ctx, bubble, 4.0, p.shadow.with_alpha(0.35 * alpha), 10.0, 3.0)
  round_fill(ctx, bubble, 4.0, p.text.with_alpha(alpha))
  put_c(ctx, bubble, text, f, p.bg.with_alpha(alpha))
}

// ---------------------------------------------------------------------------
// Toast

///|
/// A notice from the bottom edge: 8/14 padding, `--r-8`, `--border-float`,
/// 24px above the bottom, at most 560 wide.
fn paint_toast(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  model : Model,
  p : Palette,
  w : Double,
  h : Double,
) -> Unit {
  let alpha = toast_alpha(model)
  if alpha <= 0.0 {
    return
  }
  let f = font_ui(12.0, 400)
  let max_box = (w - 48.0).min(560.0).max(120.0)
  let text = ellipsize(ts, model.toast_text, f, (max_box - 49.0).max(60.0))
  let tw = text_width(ts, text, f)
  // 14 left pad + 13 icon + 8 gap + text + 14 right pad, the reference's
  // `.toast` row; height is the 12px line box plus its 8px block padding.
  let bw = (14.0 + 13.0 + 8.0 + tw + 14.0).max(96.0)
  let bh = line_box(f) + 16.0
  let bx = (w - bw) / 2.0
  let by = h - 24.0 - bh - toast_lift(model)
  let box = rect(bx, by, bw, bh.min(h - by - 4.0))
  shadow(ctx, box, 8.0, p.shadow.with_alpha(0.4 * alpha), 18.0, 6.0)
  round_fill(ctx, box, 8.0, p.surface.with_alpha(alpha))
  round_stroke(ctx, box, 8.0, p.border_float.with_alpha(alpha), 1.0)
  // The default ToastHost icon is `info`, 13px, one pixel into the text line.
  let bx0 = box.origin.x
  let by0 = box.origin.y
  let bw0 = box.size.width
  icon_at(ctx, "info", bx0 + 14.0, by0 + 9.0, 13.0, p.text.with_alpha(alpha), 1.6)
  let band = rect(bx0 + 35.0, by0 + 8.0, (tw + 1.0).min(bw0 - 49.0), bh - 16.0)
  put(ctx, band, text, f, p.text.with_alpha(alpha))
}

// ---------------------------------------------------------------------------
// Modal sheet

///|
/// Backdrop + sheet. The backdrop is 0.5 ink over light, 0.6 black over dark
/// (`:root[data-theme="dark"] .modal-backdrop`); the sheet arrives on
/// `omp-sheet-in` (translate 8px, scale .98 → 1) and leaves on the reverse.
fn paint_modal_sheet(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  model : Model,
  p : Palette,
  w : Double,
  h : Double,
) -> Unit {
  let kind = modal_kind(model)
  if kind == MNone {
    return
  }
  let fade = modal_fade(model)
  let backdrop = if p.dark {
    @graphics.Color::rgba(r=0.0, g=0.0, b=0.0, a=0.6 * fade)
  } else {
    @graphics.Color::rgba(r=15.0 / 255.0, g=15.0 / 255.0, b=25.0 / 255.0, a=0.5 * fade)
  }
  fill(ctx, rect(0.0, 0.0, w, h), backdrop)
  let base = modal_box(model, w, h)
  let (scale, dy) = modal_motion(model)
  let cx = base.x + base.w / 2.0
  let cy = base.y + base.h / 2.0
  let sheet = RectD::new(
    x=cx - base.w * scale / 2.0,
    y=cy - base.h * scale / 2.0 + dy,
    w=base.w * scale,
    h=base.h * scale,
  )
  shadow(ctx, rect_of(sheet), 10.0, p.shadow.with_alpha(0.5), 46.0, 18.0)
  round_fill(ctx, rect_of(sheet), 10.0, p.surface)
  round_stroke(ctx, rect_of(sheet), 10.0, p.border_float, 1.0)
  match kind {
    MConfirm => paint_modal_confirm(ctx, ts, model, sheet, p)
    MRename => paint_modal_rename(ctx, ts, model, sheet, p)
    MShortcuts => paint_modal_shortcuts(ctx, ts, model, sheet, p)
    MNone => ()
  }
}

///|
fn paint_modal_confirm(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  model : Model,
  sheet : RectD,
  p : Palette,
) -> Unit {
  label(ctx, ts, "重置布局", sheet.x + 20.0, sheet.y + 16.0, 20.0, 14.0, 600, p.text)
  ignore(
    put_wrapped(
      ctx,
      ts,
      "当前窗口排布会回到默认的四宫格。窗口内容不会改变，只是位置与大小重置。",
      font_ui(14.0, 400),
      p.text_2,
      sheet.x + 20.0,
      sheet.y + 48.0,
      (sheet.w - 40.0).max(1.0),
      20.0,
      2,
    ),
  )
  paint_modal_buttons(ctx, model, sheet, p, "取消", "重置布局")
}

///|
fn paint_modal_rename(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  model : Model,
  sheet : RectD,
  p : Palette,
) -> Unit {
  label(ctx, ts, "重命名会话", sheet.x + 20.0, sheet.y + 16.0, 20.0, 14.0, 600, p.text)
  let field = modal_input_rect(sheet)
  round_fill(ctx, rect_of(field), 9.0, p.bg_inset)
  round_stroke(ctx, rect_of(field), 9.0, if model.modal_focus == 2 { p.accent_border } else { p.border_strong }, 1.0)
  let f = font_ui(14.0, 400)
  let tx = field.x + 10.0
  let band = rect(field.x + 10.0, field.y, (field.w - 20.0).max(1.0), field.h)
  if model.modal_input == "" {
    put(ctx, band, "输入新的会话名称…", f, p.text_faint)
  } else {
    put(ctx, band, ellipsize(ts, model.modal_input, f, band.size.width), f, p.text)
    // Caret after the text: a canvas has no text cursor, so the field draws
    // its own, blinking on the paint clock.
    let caret_x = tx + text_width(ts, model.modal_input, f)
    if (paint_now.val / 280.0).to_int() % 2 == 0 {
      let caret = rect(caret_x.min(field.right() - 8.0), field.y + 7.0, 1.5, field.h - 14.0)
      fill(ctx, caret, p.text)
    }
  }
  label(ctx, ts, "重命名会同步到窗口 Tab、侧栏与最近会话。", sheet.x + 20.0, field.bottom() + 4.0, 16.0, 11.0, 400, p.text_faint)
  paint_modal_buttons(ctx, model, sheet, p, "取消", "重命名")
}

///|
fn paint_modal_shortcuts(
  ctx : @common.PaintContext,
  ts : @core.TextSystem,
  model : Model,
  sheet : RectD,
  p : Palette,
) -> Unit {
  label(ctx, ts, "快捷键", sheet.x + 20.0, sheet.y + 16.0, 20.0, 14.0, 600, p.text)
  // Only keys the reducer answers appear here: a table that lists a shortcut
  // the app ignores is worse than a shorter table.
  let rows = [
    ("新建会话窗", "⇧⌘O"),
    ("命令面板", "⌘K"),
    ("切换侧栏", "⌘B"),
    ("重命名当前会话", "F2"),
    ("快捷键表", "⌘/"),
    ("关闭当前一层", "Esc"),
  ]
  let mut i = 0
  let row_h = 24.0
  for pair in rows {
    let y = sheet.y + 46.0 + i.to_double() * row_h
    label(ctx, ts, pair.0, sheet.x + 20.0, y, row_h, 13.0, 400, p.text_2)
    let kf = font_mono(11.0)
    let kw = text_width(ts, pair.1, kf) + 16.0
    let chip = rect(sheet.right() - 20.0 - kw, y + 3.0, kw, 18.0)
    round_fill(ctx, chip, 5.0, p.surface_2)
    round_stroke(ctx, chip, 5.0, p.border, 1.0)
    put_c(ctx, chip, pair.1, kf, p.text_3)
    i = i + 1
  }
  paint_modal_buttons(ctx, model, sheet, p, "", "关闭")
}

///|
/// Footer buttons: 28px tall, `--r-btn` 9, right-aligned with an 8px gap. The
/// primary is the accent fill, the cancel an outlined surface; the focused one
/// carries the 2px offset accent ring so Tab and hover read the same.
fn paint_modal_buttons(
  ctx : @common.PaintContext,
  model : Model,
  sheet : RectD,
  p : Palette,
  cancel_label : String,
  confirm_label : String,
) -> Unit {
  let buttons = modal_buttons(model, sheet)
  if buttons.has_cancel {
    paint_modal_btn(ctx, rect_of(buttons.cancel), cancel_label, false, model.modal_focus == 1, p)
  }
  paint_modal_btn(ctx, rect_of(buttons.confirm), confirm_label, true, model.modal_focus == 0, p)
}

///|
fn paint_modal_btn(
  ctx : @common.PaintContext,
  r : @geometry.Rect,
  text : String,
  primary : Bool,
  focused : Bool,
  p : Palette,
) -> Unit {
  if primary {
    round_fill(ctx, r, 9.0, if focused { p.accent_hover } else { p.accent })
    put_c(ctx, r, text, font_ui(12.0, 500), p.on_accent)
  } else {
    round_fill(ctx, r, 9.0, p.surface_2)
    round_stroke(ctx, r, 9.0, if focused { p.accent_border } else { p.border }, 1.0)
    put_c(ctx, r, text, font_ui(12.0, 500), p.text_2)
  }
  if focused {
    let ring = rect(r.origin.x - 2.0, r.origin.y - 2.0, r.size.width + 4.0, r.size.height + 4.0)
    round_stroke(ctx, ring, 11.0, p.accent, 2.0)
  }
}
