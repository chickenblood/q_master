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
      super.scene(scene, willConnectTo: session, options: connectionOptions)
  }
}

