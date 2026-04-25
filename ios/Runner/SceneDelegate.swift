import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  // Handle warm AirDrop delivery: app is already running and receives a file via AirDrop.
  // This is called before the URL is passed to share_handler, so we can copy it while
  // the security scope is still active.
  override func scene(
    _ scene: UIScene,
    openURLContexts URLContexts: Set<UIOpenURLContext>
  ) {
    for context in URLContexts where context.url.isFileURL {
      _ = context.url.stableAirDropCopy()
    }
    super.scene(scene, openURLContexts: URLContexts)
  }
}

extension URL {
  /// Copies a security-scoped file URL to Documents/Inbox while the scope is active.
  /// This ensures AirDrop files remain accessible after the security scope expires.
  /// Falls back to the original URL on copy failure.
  func stableAirDropCopy() -> URL {
    let accessed = startAccessingSecurityScopedResource()
    defer { if accessed { stopAccessingSecurityScopedResource() } }

    let inbox = FileManager.default
      .urls(for: .documentDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("Inbox")
    let dest = inbox.appendingPathComponent(lastPathComponent)

    do {
      try FileManager.default.createDirectory(at: inbox, withIntermediateDirectories: true)
      if FileManager.default.fileExists(atPath: dest.path) {
        try FileManager.default.removeItem(at: dest)
      }
      try FileManager.default.copyItem(at: self, to: dest)
      return dest
    } catch {
      return self
    }
  }
}
