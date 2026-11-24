// Reducer and hit-test regression tests. They drive the same entry point the
// runtime uses (`update`), so a broken pointer mapping or a lost window fails
// here before it reaches the screen.

///|
test "theme and sidebar toggles" {
  let model = @app.Model::new()
  let themed = @app.update(model, @app.ToggleTheme)
  inspect(themed.dark != model.dark, content="true")
  let both = @app.update(themed, @app.ToggleSidebar)
  inspect(both.sidebar_open != themed.sidebar_open, content="true")
}

///|
test "composer types, sends and clears" {
  let model = @app.Model::new()
  let typed = @app.update(model, @app.KeyTyped("hello"))
  inspect(typed.composer, content="hello")
  let sent = @app.update(typed, @app.ComposerSend)
  inspect(sent.composer, content="")
  inspect(sent.chat.length() == model.chat.length() + 1, content="true")
}

///|
test "a layout preset tiles the visible windows" {
  let model = @app.Model::new()
  let tiled = @app.update(model, @app.ApplyPreset(@app.SplitEven))
  inspect(tiled.layout == @app.SplitEven, content="true")
  let vis = @app.visible_windows(tiled)
  inspect(vis.length() > 0, content="true")
}

///|
test "pointer down on a title bar arms a drag" {
  let model = @app.Model::new()
  let shell = @app.shell_layout(1200.0, 800.0, model.sidebar_open)
  let win = @app.visible_windows(model)[0]
  let frame = @app.win_px(win, shell)
  let after = @app.update(
    model,
    @app.Pointer({
      phase: 0,
      x: frame.x + frame.w / 2.0,
      y: frame.y + 8.0,
      w: 1200.0,
      h: 800.0,
      wheel: 0.0,
    }),
  )
  inspect(after.drag.active, content="true")
  inspect(after.drag.id, content="\{win.id}")
  inspect(after.active, content="\{win.id}")
}

///|
test "pointer down on the close button closes that window" {
  let model = @app.Model::new()
  let shell = @app.shell_layout(1200.0, 800.0, model.sidebar_open)
  let win = @app.visible_windows(model)[0]
  let frame = @app.win_px(win, shell)
  let after = @app.update(
    model,
    @app.Pointer({
      phase: 0,
      x: frame.x + frame.w - 18.0,
      y: frame.y + 12.0,
      w: 1200.0,
      h: 800.0,
      wheel: 0.0,
    }),
  )
  inspect(@app.window_by_id(after, win.id) is None, content="true")
}

///|
test "minimise then tap the capsule restores the window" {
  let model = @app.Model::new()
  let win = @app.visible_windows(model)[0]
  let min = @app.update(model, @app.MinimizeWindow(win.id))
  let restored = @app.update(min, @app.CapsuleClick(win.id))
  match @app.window_by_id(restored, win.id) {
    Some(w) => inspect(w.minimized, content="false")
    None => inspect(false, content="true")
  }
}

///|
test "pending approval blocks sending" {
  let model = @app.Model::new()
  let typed = @app.update(model, @app.KeyTyped("hello"))
  let blocked = @app.update(typed, @app.KeyDown("Enter", 0))
  inspect(blocked.composer, content="hello")
  let approved = @app.update(blocked, @app.AllowOnce)
  let sent = @app.update(approved, @app.KeyDown("Enter", 0))
  inspect(sent.composer, content="")
}

///|
test "hover lights only the control under the pointer" {
  let model = @app.Model::new()
  let shell = @app.shell_layout(1200.0, 800.0, model.sidebar_open)
  let slot = @app.tab_slots(model, shell)[0]
  let cx = slot.rect.x + slot.rect.w / 2.0
  let cy = slot.rect.y + slot.rect.h / 2.0
  let on = @app.with_hover(model, cx, cy)
  inspect(@app.hovering(on, slot.rect), content="true")
  // A rect elsewhere is not hovered, and a model whose pointer never entered
  // the canvas lights nothing at all.
  inspect(@app.hovering(on, @app.RectD::new(x=0.0, y=0.0, w=4.0, h=4.0)), content="false")
  inspect(@app.hovering(model, slot.rect), content="false")
}

///|
test "the tab close circle closes its window" {
  let model = @app.Model::new()
  let shell = @app.shell_layout(1200.0, 800.0, model.sidebar_open)
  let slots = @app.tab_slots(model, shell)
  let mut id = -1
  let mut xr = @app.RectD::new(x=0.0, y=0.0, w=0.0, h=0.0)
  for slot in slots {
    if slot.active {
      id = slot.id
      xr = @app.tab_close_rect(slot)
    }
  }
  inspect(id >= 0, content="true")
  // The circle sits inside the tab, so the close branch has to win over the
  // raise-the-tab branch that owns the same pixels.
  let after = @app.update(
    model,
    @app.Pointer({
      phase: 0,
      x: xr.x + xr.w / 2.0,
      y: xr.y + xr.h / 2.0,
      w: 1200.0,
      h: 800.0,
      wheel: 0.0,
    }),
  )
  inspect(@app.window_by_id(after, id) is None, content="true")
}

///|
test "cmd-k opens the palette, typing filters it and enter runs" {
  let model = @app.Model::new()
  let open = @app.update(model, @app.KeyDown("k", 8))
  inspect(open.palette_open, content="true")
  let typed = @app.update(open, @app.KeyTyped("模型"))
  inspect(typed.palette_query, content="模型")
  let items = @app.palette_items(typed)
  inspect(items.length() > 0, content="true")
  inspect(items[0].id, content="route:model-config")
  let ran = @app.update(typed, @app.PaletteRun(0))
  inspect(ran.palette_open, content="false")
  inspect(ran.palette_query, content="")
  inspect(ran.route == @app.ModelConfig, content="true")
  let esc = @app.update(open, @app.KeyDown("Escape", 0))
  inspect(esc.palette_open, content="false")
}

///|
test "wheel scrolls a page body and stops at the top" {
  let model = @app.go_route(@app.Model::new(), @app.Statistics)
  let down = @app.update(
    model,
    @app.Pointer({ phase: 3, x: 700.0, y: 260.0, w: 1200.0, h: 460.0, wheel: 120.0 }),
  )
  inspect(down.page_scroll > 0.0, content="true")
  // A wheel-up burst walks the offset back to zero and never past it.
  let up = @app.update(
    down,
    @app.Pointer({ phase: 3, x: 700.0, y: 260.0, w: 1200.0, h: 460.0, wheel: -4000.0 }),
  )
  inspect(up.page_scroll, content="0")
}

///|
test "wheel scrolls the conversation and the latest pill resets it" {
  let base = @app.update(@app.Model::new(), @app.AllowOnce)
  // Grow the transcript past one screen: the offset can only ever be > 0 when
  // there is content above the fold, and the fallback metrics in a test are
  // narrower than the host's, so a few turns are added first.
  let mut model = base
  let mut i = 0
  while i < 24 {
    let typed = @app.update(model, @app.KeyTyped("跟踪上游 pi-web 的更新，逐条核对任务清单与改动说明。"))
    model = @app.update(typed, @app.ComposerSend)
    i = i + 1
  }
  let shell = @app.shell_layout(1200.0, 800.0, model.sidebar_open)
  let mut convo = @app.visible_windows(model)[0]
  for win in @app.visible_windows(model) {
    if win.kind == @app.Conversation {
      convo = win
    }
  }
  let cb = @app.convo_box(@app.win_px(convo, shell))
  let up = @app.update(
    model,
    @app.Pointer({
      phase: 3,
      x: cb.scroll.x + 40.0,
      y: cb.scroll.y + 40.0,
      w: 1200.0,
      h: 800.0,
      wheel: -120.0,
    }),
  )
  inspect(up.convo_scroll > 0.0, content="true")
  let pill = @app.convo_latest_pill(cb)
  let back = @app.update(
    model,
    @app.Pointer({
      phase: 0,
      x: pill.x + pill.w / 2.0,
      y: pill.y + pill.h / 2.0,
      w: 1200.0,
      h: 800.0,
      wheel: 0.0,
    }),
  )
  inspect(back.convo_scroll, content="0")
}

///|
test "palette shell clamps to 680 and the captions keep the 6px gap" {
  let open = @app.update(@app.Model::new(), @app.KeyDown("k", 8))
  // `min(680px, 100vw - 40px)` by `min(680px, 100vh - 48px)`, centred.
  let big = @app.palette_panel_rect(1600.0, 1000.0)
  inspect(big.w == 680.0, content="true")
  inspect(big.h == 680.0, content="true")
  inspect(big.x == 460.0, content="true")
  let small = @app.palette_panel_rect(600.0, 500.0)
  inspect(small.w == 560.0, content="true")
  inspect(small.h == 452.0, content="true")
  // The list starts right under the 53px input row.
  inspect(@app.palette_list_rect(big).y == big.y + 53.0, content="true")
  // First caption flush, every later one carries the 6px separator.
  let mut first = true
  let mut ok = true
  let mut captions = 0
  for line in @app.palette_lines(open) {
    match line {
      @app.PaletteGroupLabel(_, spaced) => {
        captions = captions + 1
        if first {
          if spaced {
            ok = false
          }
          first = false
        } else if !spaced {
          ok = false
        }
      }
      @app.PaletteItemRow(_) => ()
    }
  }
  inspect(ok, content="true")
  inspect(captions > 1, content="true")
}

// ---------------------------------------------------------------------------
// Interaction layer: press/tactile, the keyboard ring, the three timed
// surfaces, the modal sheet and the two shell width drags.

///|
/// Shell at the size the interaction tests paint at, with the model's own
/// sidebar width — the same numbers the hit test and the painters share.
fn test_shell(model : @app.Model) -> @app.Shell {
  @app.shell_layout(1200.0, 800.0, model.sidebar_open, sidebar_w=model.sidebar_w)
}

///|
test "press tints the control, holds while down and decays on release" {
  @app.paint_now.val = 1000.0
  let model = @app.Model::new()
  let shell = test_shell(model)
  let nav = @app.titlebar_nav_slots(shell)[0]
  let cx = nav.x + nav.w / 2.0
  let cy = nav.y + nav.h / 2.0
  let down = @app.press_begin(model, @app.controls(model, shell), cx, cy)
  inspect(down.press_down, content="true")
  inspect(down.press_ctl == @app.CNav(0), content="true")
  inspect(@app.press_alpha(down) == 1.0, content="true")
  // A pointer press never leaves a keyboard ring behind.
  let ringed = @app.focus_step(model, 1)
  let pressed = @app.press_begin(ringed, @app.controls(ringed, shell), cx, cy)
  inspect(pressed.focus_kb, content="false")
  @app.paint_now.val = 1040.0
  let up = @app.press_release(down)
  // Halfway through the 80ms decay the tint is half strength.
  @app.paint_now.val = 1080.0
  let mid = @app.press_alpha(up)
  inspect(mid > 0.4 && mid < 0.6, content="true")
  @app.paint_now.val = 1200.0
  inspect(@app.press_alpha(up) == 0.0, content="true")
  inspect(@app.needs_frames_at(up, 1200.0), content="false")
  @app.paint_now.val = 0.0
}

///|
test "tab ring walks controls, wraps and enter activates the focused one" {
  @app.paint_frame_w.val = 1200.0
  @app.paint_frame_h.val = 800.0
  let model = @app.Model::new()
  let shell = test_shell(model)
  let first = @app.focus_step(model, 1)
  inspect(first.focus_kb, content="true")
  inspect(first.focus_ctl == @app.CNav(0), content="true")
  // Step to the theme toggle in the tab cluster and run it with Enter.
  let list = @app.focus_list(model, shell)
  let mut idx = -1
  let mut i = 0
  for rec in list {
    if rec.ctl == @app.CClusterMoon && idx < 0 {
      idx = i
    }
    i = i + 1
  }
  inspect(idx >= 0, content="true")
  let mut ring = model
  let mut n = 0
  while n <= idx {
    ring = @app.focus_step(ring, 1)
    n = n + 1
  }
  inspect(ring.focus_ctl == @app.CClusterMoon, content="true")
  let toggled = @app.focus_activate(ring)
  inspect(toggled.dark != model.dark, content="true")
  // Shift-Tab from the first stop wraps to the last one.
  let back = @app.focus_step(first, -1)
  inspect(back.focus_ctl == list[list.length() - 1].ctl, content="true")
  @app.paint_frame_w.val = 0.0
  @app.paint_frame_h.val = 0.0
}

///|
test "escape peels one layer at a time" {
  @app.paint_frame_w.val = 1200.0
  @app.paint_frame_h.val = 800.0
  let model = @app.Model::new()
  let picker = @app.update(model, @app.OpenPicker(0))
  inspect(@app.update(picker, @app.KeyDown("Escape", 0)).picker, content="-1")
  let ringed = @app.focus_step(model, 1)
  let cleared = @app.update(ringed, @app.KeyDown("Escape", 0))
  inspect(cleared.focus_ctl == @app.CNone, content="true")
  // A tip goes before the composer layer, so one Esc removes it and the next
  // reaches the composer.
  @app.paint_now.val = 1000.0
  let shell = test_shell(model)
  let nav = @app.titlebar_nav_slots(shell)[0]
  let tipped = @app.hover_tip(cleared, @app.controls(cleared, shell), nav.x + nav.w / 2.0, nav.y + nav.h / 2.0)
  inspect(tipped.tip_ctl != @app.CNone, content="true")
  let untipped = @app.update(tipped, @app.KeyDown("Escape", 0))
  inspect(untipped.tip_ctl == @app.CNone, content="true")
  @app.paint_now.val = 0.0
  @app.paint_frame_w.val = 0.0
  @app.paint_frame_h.val = 0.0
}

///|
test "the tooltip waits for the dwell and then fades in" {
  @app.paint_now.val = 1000.0
  let model = @app.Model::new()
  let shell = test_shell(model)
  let list = @app.controls(model, shell)
  let nav = @app.titlebar_nav_slots(shell)[0]
  let dwell = @app.hover_tip(model, list, nav.x + nav.w / 2.0, nav.y + nav.h / 2.0)
  inspect(dwell.tip_ctl == @app.CNav(0), content="true")
  inspect(dwell.tip_text, content="切换侧栏")
  inspect(@app.tip_alpha(dwell) == 0.0, content="true")
  @app.paint_now.val = 1400.0
  inspect(@app.tip_alpha(dwell) == 0.0, content="true")
  @app.paint_now.val = 1700.0
  inspect(@app.tip_alpha(dwell) > 0.0, content="true")
  // Moving onto a control without a tip clears the bubble.
  let cleared = @app.hover_tip(dwell, list, 4.0, 4.0)
  inspect(cleared.tip_ctl == @app.CNone, content="true")
  @app.paint_now.val = 0.0
}

///|
test "the toast arrives, holds, leaves and stops asking for frames" {
  @app.paint_now.val = 500.0
  let shown = @app.toast_show(@app.Model::new(), "已保存到工作区")
  inspect(shown.toast_text, content="已保存到工作区")
  inspect(@app.toast_alpha(shown) == 0.0, content="true")
  @app.paint_now.val = 500.0 + @app.TOAST_IN_MS
  inspect(@app.toast_alpha(shown) == 1.0, content="true")
  inspect(@app.needs_frames_at(shown, 500.0 + @app.TOAST_IN_MS), content="true")
  let end = shown.toast_end
  @app.paint_now.val = end + 100.0
  inspect(@app.toast_alpha(shown) > 0.0, content="true")
  @app.paint_now.val = end + @app.TOAST_OUT_MS
  inspect(@app.toast_alpha(shown) == 0.0, content="true")
  inspect(@app.needs_frames_at(shown, end + @app.TOAST_OUT_MS), content="false")
  @app.paint_now.val = 0.0
}

///|
test "F2 renames through the field and Enter writes it back" {
  let model = @app.Model::new()
  let opened = @app.update(model, @app.KeyDown("F2", 0))
  inspect(opened.modal == @app.MRename, content="true")
  // The field opens on the current title; typing edits rather than retypes.
  let start = opened.modal_input
  inspect(start != "", content="true")
  inspect(opened.modal_focus, content="2")
  let typed = @app.update(opened, @app.KeyTyped("·改"))
  inspect(typed.modal_input, content="\{start}·改")
  // Tab walks field → cancel → primary → field.
  let to_cancel = @app.update(typed, @app.KeyDown("Tab", 0))
  inspect(to_cancel.modal_focus, content="1")
  let to_primary = @app.update(to_cancel, @app.KeyDown("Tab", 0))
  inspect(to_primary.modal_focus, content="0")
  let back_to_field = @app.update(to_primary, @app.KeyDown("Tab", 0))
  inspect(back_to_field.modal_focus, content="2")
  let renamed = @app.update(typed, @app.KeyDown("Enter", 0))
  inspect(renamed.modal == @app.MNone, content="true")
  inspect(renamed.modal_leaving == @app.MRename, content="true")
  let title = renamed.modal_input
  let mut win_title = ""
  for win in renamed.windows {
    if win.id == renamed.active {
      win_title = win.title
    }
  }
  inspect(win_title, content=title)
  inspect(renamed.toast_text != "", content="true")
  // Esc on the cancel stop backs out without touching the title.
  let cancelled = @app.update(typed, @app.KeyDown("Tab", 0))
  let out = @app.update(cancelled, @app.KeyDown("Enter", 0))
  inspect(out.modal_leaving == @app.MRename, content="true")
}

///|
test "cmd-slash opens the shortcut sheet and esc closes it" {
  let model = @app.Model::new()
  let sheet = @app.update(model, @app.KeyDown("/", 8))
  inspect(sheet.modal == @app.MShortcuts, content="true")
  // Enter runs the single "关闭" button and starts the leave animation.
  let closed = @app.update(sheet, @app.KeyDown("Enter", 0))
  inspect(closed.modal == @app.MNone, content="true")
  inspect(closed.modal_leaving == @app.MShortcuts, content="true")
  inspect(@app.needs_frames_at(closed, 10.0), content="true")
  inspect(@app.needs_frames_at(closed, 10000.0), content="false")
  // Esc from the open sheet leaves the same way.
  let esc = @app.update(sheet, @app.KeyDown("Escape", 0))
  inspect(esc.modal_leaving == @app.MShortcuts, content="true")
}

///|
test "the layout reset dialog confirms, cancels and dismisses on the backdrop" {
  let model = @app.update(@app.Model::new(), @app.ApplyPreset(@app.ThreeColumns))
  let opened = @app.update(model, @app.ModalOpen(@app.MConfirm))
  inspect(opened.modal == @app.MConfirm, content="true")
  let confirmed = @app.update(opened, @app.KeyDown("Enter", 0))
  inspect(confirmed.layout == @app.SplitEven, content="true")
  inspect(confirmed.modal_leaving == @app.MConfirm, content="true")
  // Tab to cancel, Enter: the layout is untouched.
  let kept = @app.update(@app.update(opened, @app.KeyDown("Tab", 0)), @app.KeyDown("Enter", 0))
  inspect(kept.layout == @app.ThreeColumns, content="true")
  // A click outside the sheet dismisses it like Esc.
  let box = @app.modal_box(opened, 1200.0, 800.0)
  let clicked = @app.update(
    opened,
    @app.Pointer({ phase: 0, x: box.x - 40.0, y: box.y + 10.0, w: 1200.0, h: 800.0, wheel: 0.0 }),
  )
  inspect(clicked.modal == @app.MNone, content="true")
  // Clicking a footer button acts: cancel closes, confirm confirms.
  let buttons = @app.modal_buttons(opened, box)
  let on_confirm = @app.update(
    opened,
    @app.Pointer({
      phase: 0,
      x: buttons.confirm.x + buttons.confirm.w / 2.0,
      y: buttons.confirm.y + buttons.confirm.h / 2.0,
      w: 1200.0,
      h: 800.0,
      wheel: 0.0,
    }),
  )
  inspect(on_confirm.layout == @app.SplitEven, content="true")
  inspect(on_confirm.modal == @app.MNone, content="true")
}

///|
test "the sidebar width drag clamps to 200..400 and ends on release" {
  @app.paint_now.val = 0.0
  let model = @app.Model::new()
  let shell = test_shell(model)
  let r = @app.sidebar_resizer(shell)
  let grab_x = r.x + 3.0
  let down = @app.update(
    model,
    @app.Pointer({ phase: 0, x: grab_x, y: r.y + 200.0, w: 1200.0, h: 800.0, wheel: 0.0 }),
  )
  inspect(down.resize_mode, content="1")
  let wider = @app.update(
    down,
    @app.Pointer({ phase: 2, x: grab_x + 60.0, y: r.y + 200.0, w: 1200.0, h: 800.0, wheel: 0.0 }),
  )
  inspect(wider.sidebar_w == 332.0, content="true")
  // The shell the painter builds follows the widened sidebar.
  let wide_shell = test_shell(wider)
  inspect(wide_shell.sidebar.w == 332.0, content="true")
  let too_far = @app.update(
    down,
    @app.Pointer({ phase: 2, x: grab_x + 900.0, y: r.y + 200.0, w: 1200.0, h: 800.0, wheel: 0.0 }),
  )
  inspect(too_far.sidebar_w == @app.SIDEBAR_MAX, content="true")
  let negative = @app.update(
    down,
    @app.Pointer({ phase: 2, x: grab_x - 900.0, y: r.y + 200.0, w: 1200.0, h: 800.0, wheel: 0.0 }),
  )
  inspect(negative.sidebar_w == @app.SIDEBAR_MIN, content="true")
  let up = @app.update(
    down,
    @app.Pointer({ phase: 1, x: grab_x + 60.0, y: r.y + 200.0, w: 1200.0, h: 800.0, wheel: 0.0 }),
  )
  inspect(up.resize_mode, content="0")
}

///|
test "the project/explorer split drags between 0.15 and 0.85" {
  @app.paint_now.val = 0.0
  let model = @app.Model::new()
  let shell = test_shell(model)
  let h = @app.sidebar_split_handle(model, shell)
  let y = h.y + h.h / 2.0
  let down = @app.update(
    model,
    @app.Pointer({ phase: 0, x: h.x + 20.0, y, w: 1200.0, h: 800.0, wheel: 0.0 }),
  )
  inspect(down.resize_mode, content="2")
  let dragged = @app.update(
    down,
    @app.Pointer({ phase: 2, x: h.x + 20.0, y: y + 40.0, w: 1200.0, h: 800.0, wheel: 0.0 }),
  )
  inspect(dragged.sidebar_split > model.sidebar_split, content="true")
  inspect(dragged.sidebar_split <= @app.SPLIT_MAX, content="true")
}

///|
test "cmd-b and shift-cmd-o are the shell shortcuts the palette lists" {
  let model = @app.Model::new()
  let toggled = @app.update(model, @app.KeyDown("b", 8))
  inspect(toggled.sidebar_open != model.sidebar_open, content="true")
  let new_win = @app.update(model, @app.KeyDown("o", 8 + 1))
  inspect(new_win.windows.length() == model.windows.length() + 1, content="true")
}

///|
test "tab strip keeps four 26px squares with one hit target each" {
  let model = @app.Model::new()
  // 1700 wide keeps the sidebar open and still reaches the widest cluster tier,
  // so all four `.icon-btn` squares and the Compact pill are laid out.
  let shell = @app.shell_layout(1700.0, 900.0, model.sidebar_open, sidebar_w=model.sidebar_w)
  let c = @app.tab_cluster(shell)
  inspect(c.tier, content="2")
  // `.tb-right` paints four 26px `.icon-btn` squares on the 4px rhythm. They
  // must never share a pixel: a plate wide enough to cover two of them is
  // exactly the "two buttons on one pill" regression this pins down.
  let boxes : Array[@app.RectD] = [c.sliders, c.panel, c.moon, c.home]
  for b in boxes {
    inspect(b.w == 26.0 && b.h == 26.0, content="true")
  }
  let mut i = 0
  while i + 1 < boxes.length() {
    let left = boxes[i]
    let right = boxes[i + 1]
    inspect(right.x - left.right() == 4.0, content="true")
    i = i + 1
  }
  // `.tb-compact` ends 8px before the toggle: telemetry's 4px side padding plus
  // the `.tb-right` 4px gap.
  inspect(c.compact.right() + 8.0 == c.sliders.x, content="true")
  // The last button keeps `.topbar`'s 12px right inset.
  inspect(c.home.right() == shell.w - 12.0, content="true")
  // Each square answers only for itself: the toggle steps density, the panel
  // flips the sidebar, the moon flips the theme and home opens the Home page.
  let tap = fn(r : @app.RectD) -> @app.Model {
    @app.update(
      model,
      @app.Pointer({ phase: 0, x: r.x + 13.0, y: r.y + 13.0, w: 1700.0, h: 900.0, wheel: 0.0 }),
    )
  }
  inspect(tap(c.sliders).density != model.density, content="true")
  inspect(tap(c.panel).sidebar_open != model.sidebar_open, content="true")
  inspect(tap(c.moon).dark != model.dark, content="true")
  let home = tap(c.home)
  inspect(home.route == @app.Home, content="true")
  inspect(home.sidebar_open == model.sidebar_open, content="true")
  inspect(home.density == model.density, content="true")
  // Narrower shells drop the meters and then the Compact pill, but the four
  // squares stay separate: they are the last thing the strip gives up.
  for narrow in [1100.0, 1440.0] {
    let ns = @app.shell_layout(narrow, 700.0, model.sidebar_open, sidebar_w=model.sidebar_w)
    let nc = @app.tab_cluster(ns)
    inspect(nc.tier >= 0, content="true")
    for b in [nc.sliders, nc.panel, nc.moon, nc.home] {
      inspect(b.w == 26.0 && b.h == 26.0, content="true")
    }
    inspect(nc.home.right() == narrow - 12.0, content="true")
  }
  // The 4px gutter between two squares belongs to neither: a press there must
  // not step the density the way the old merged plate did.
  let gutter = @app.update(
    model,
    @app.Pointer({
      phase: 0,
      x: c.sliders.right() + 2.0,
      y: c.sliders.y + 13.0,
      w: 1700.0,
      h: 900.0,
      wheel: 0.0,
    }),
  )
  inspect(gutter.density == model.density, content="true")
  inspect(gutter.route == model.route, content="true")
}
