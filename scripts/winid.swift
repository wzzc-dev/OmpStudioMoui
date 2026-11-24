// winid.swift — 通过 CoreGraphics 找到某个进程的主窗口（CGWindowID）。
//
// 用法:
//   winid <pid>            输出 "<window-id> <width>x<height> <title>"
//   winid <pid> --activate 先激活应用（置前）再输出
//   winid --list           列出所有 layer 0 窗口，便于调试
//
// 退出码: 0 找到窗口 / 3 进程没有可用窗口 / 2 参数或运行错误
//
// 只使用公开的 Quartz 窗口列表 API；读取窗口标题需要屏幕录制权限，
// 没有权限时标题为空，但 id 和尺寸仍然可用。

import CoreGraphics
import Foundation
import AppKit

let kLayerZero = 0
let kMinSide: Double = 200.0

func fail(_ message: String, _ code: Int32) -> Never {
  FileHandle.standardError.write(("winid: " + message + "\n").data(using: .utf8)!)
  exit(code)
}

func windowList() -> [[String: Any]] {
  let options: CGWindowListOption = [.optionAll]
  return CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] ?? []
}

/// 解析一个窗口字典里关心的字段。
struct Window {
  let id: Int
  let pid: Int
  let layer: Int
  let onscreen: Bool
  let width: Double
  let height: Double
  let title: String
  let owner: String

  init?(_ raw: [String: Any]) {
    guard let id = raw[kCGWindowNumber as String] as? Int,
          let pid = raw[kCGWindowOwnerPID as String] as? Int,
          let layer = raw[kCGWindowLayer as String] as? Int,
          let bounds = raw[kCGWindowBounds as String] as? [String: Any],
          let width = bounds["Width"] as? Double,
          let height = bounds["Height"] as? Double
    else { return nil }
    self.id = id
    self.pid = pid
    self.layer = layer
    self.onscreen = raw[kCGWindowIsOnscreen as String] as? Bool ?? false
    self.width = width
    self.height = height
    self.title = raw[kCGWindowName as String] as? String ?? ""
    self.owner = raw[kCGWindowOwnerName as String] as? String ?? ""
  }
}

let arguments = CommandLine.arguments.dropFirst()
if arguments.contains("--list") {
  for raw in windowList() {
    guard let window = Window(raw), window.layer == kLayerZero,
          window.width > 1, window.height > 1
    else { continue }
    let screen = window.onscreen ? "on" : "off"
    print("\(window.id)\t\(Int(window.width))x\(Int(window.height))\t\(screen)\t\(window.owner)\t\(window.title)")
  }
  exit(0)
}

guard let pidArgument = arguments.first, let targetPID = Int32(pidArgument) else {
  fail("用法: winid <pid> [--activate] | winid --list", 2)
}

let shouldActivate = arguments.contains("--activate")

/// 候选窗口按 (是否在屏, 面积, 标题是否非空) 排序，取主窗口。
func mainWindow(for pid: Int32) -> Window? {
  var candidates: [Window] = []
  for raw in windowList() {
    guard let window = Window(raw) else { continue }
    guard window.pid == Int(pid), window.layer == kLayerZero else { continue }
    guard window.width >= kMinSide, window.height >= kMinSide else { continue }
    candidates.append(window)
  }
  // 优先在屏窗口，其次面积大的，标题非空只作为最后加分项（避免把透明辅助窗口当主窗口）。
  let ranked = candidates.sorted { a, b in
    if a.onscreen != b.onscreen { return a.onscreen }
    let areaA = a.width * a.height
    let areaB = b.width * b.height
    if areaA != areaB { return areaA > areaB }
    return !a.title.isEmpty && b.title.isEmpty
  }
  return ranked.first
}

guard let window = mainWindow(for: targetPID) else {
  fail("pid \(targetPID) 没有可用的 layer0 窗口（可能还没上屏、被最小化，或进程已退出）", 3)
}

if shouldActivate {
  if let app = NSRunningApplication(processIdentifier: targetPID) {
    if #available(macOS 14.0, *) {
      app.activate()
    } else {
      app.activate(options: [.activateIgnoringOtherApps])
    }
  }
}

print("\(window.id) \(Int(window.width))x\(Int(window.height)) \(window.title)")
exit(0)
