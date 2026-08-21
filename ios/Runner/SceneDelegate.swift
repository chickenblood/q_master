import Flutter
import UIKit
import receive_sharing_intent

class SceneDelegate: FlutterSceneDelegate {
  // Handle warm AirDrop delivery: app is already running and receives a file via AirDrop.
  // This is called before the URL is passed to receive_sharing_intent, so we can copy it while
  // the security scope is still active.
  override func scene(
    _ scene: UIScene,
    openURLContexts URLContexts: Set<UIOpenURLContext>
  ) {
    for context in URLContexts where context.url.isFileURL {
      _ = context.url.stableAirDropCopy()
    }

    // Work-around to prevent other libraries like flutter_branch_sdk from absorbing links meant to be handled by receive_sharing_intent.
    if ReceiveSharingIntentPlugin.instance.scene(scene, openURLContexts: URLContexts) {
      return
    }

    super.scene(scene, openURLContexts: URLContexts)
  }

  // Optional - only needed when multiple libraries handle incoming URLs.
  // Called on a cold start when the scene connects. The shared URL (if any)
  // is delivered here via connectionOptions instead of the launchOptions.
  override func scene(
      _ scene: UIScene,
      willConnectTo session: UISceneSession,
      options connectionOptions: UIScene.ConnectionOptions
  ) {
      // Work-around to prevent other libraries like flutter_branch_sdk from absorbing links meant to be handled by receive_sharing_intent.
      _ = ReceiveSharingIntentPlugin.instance.scene(scene, willConnectTo: session, options: connectionOptions)
      super.scene(scene, willConnectTo: session, options: connectionOptions)
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
      .urls(for: .cachesDirectory, in: .userDomainMask)[0]
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
