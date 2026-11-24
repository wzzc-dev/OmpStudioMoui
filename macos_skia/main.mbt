///|
/// Window size for this run. The docs screenshots are a 1600x1000 CSS viewport
/// captured at 1.125, so the QA harness sets `OMP_WIN_W` / `OMP_WIN_H` to render
/// at that same size and diff region by region; without them the window keeps
/// its default 1440x900.
fn env_dim(name : String, fallback : Double) -> Double {
  match @env.get_env_var(name) {
    Some(raw) => {
      let parsed = try @string.parse_double(raw) catch {
        _ => fallback
      }
      if parsed >= 320.0 && parsed <= 3840.0 {
        parsed
      } else {
        fallback
      }
    }
    None => fallback
  }
}

///|
/// Start page for this run. The QA harness sets `OMP_ROUTE` to capture a
/// secondary page straight after launch; without it the app opens on the
/// workbench, exactly like a normal start.
fn env_route() -> @app.Route {
  match @env.get_env_var("OMP_ROUTE") {
    Some(slug) => @app.route_by_slug(slug)
    None => @app.Workbench
  }
}

///|
/// `OMP_PALETTE=1` opens the ⌘K palette at launch, so the panel can be captured
/// without a keystroke; `OMP_PALETTE_QUERY` pre-types a filter (`zzz` reaches the
/// empty state). Without the flag the app starts with the palette closed.
fn env_flag(name : String) -> Bool {
  match @env.get_env_var(name) {
    Some(raw) => raw == "1"
    None => false
  }
}

///|
fn env_text(name : String) -> String {
  match @env.get_env_var(name) {
    Some(raw) => raw
    None => ""
  }
}

///|
/// `OMP_HOVER_X` / `OMP_HOVER_Y` park the pointer so a hover state lands in the
/// frame; a missing or malformed value parks it outside every control.
fn env_hover() -> (Double, Double) {
  let x = match @env.get_env_var("OMP_HOVER_X") {
    Some(raw) =>
      try @string.parse_double(raw) catch {
        _ => -1.0
      }
    None => -1.0
  }
  let y = match @env.get_env_var("OMP_HOVER_Y") {
    Some(raw) =>
      try @string.parse_double(raw) catch {
        _ => -1.0
      }
    None => -1.0
  }
  (x, y)
}

///|
/// The QA switches are read here and handed to the app as plain values: the
/// palette and its query, a dialog to land settled, the focus ring, a toast,
/// and `OMP_TIP=1` to latch the dwell tip of the control under the parked
/// pointer (so the bubble is in the shot without half a second of mouse time).
fn main {
  let (hx, hy) = env_hover()
  let runtime = @runtime.new_program_with_dimensions(
    program=@app.program_qa_state(
      env_route(),
      env_flag("OMP_PALETTE"),
      env_text("OMP_PALETTE_QUERY"),
      env_text("OMP_MODAL"),
      env_flag("OMP_FOCUS"),
      env_text("OMP_TOAST"),
      env_flag("OMP_TIP"),
      hx,
      hy,
    ),
    width=env_dim("OMP_WIN_W", 1440.0),
    height=env_dim("OMP_WIN_H", 900.0),
  )
  // The workbench draws its own 36px titlebar with the window menus and the
  // sidebar toggle. Hiding the native titlebar (keeping its traffic lights on
  // top of the custom bar) is what the reference shell does through the Window
  // Controls Overlay, so the replica does not end up with two titlebars.
  let options = @platform_host.MacosHostAppOptions::new(
    transparent_titlebar=true,
    show_after_first_present=true,
  )
  @apphost.run_app("OmpStudioMoui", runtime)
    .render_all(@render_skia.from_env(platform=@render_skia.NativeGpuPlatform::MacOS))
    .backend(@platform_host.entry(options=options))
    .run()
}
