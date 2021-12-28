
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var coordinator: Coordinator?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = (scene as? UIWindowScene) else { return }
        let coordinator = Coordinator()
        let window = UIWindow(windowScene: scene)
        coordinator.configureWindow(window)
        
        self.window = window
        self.coordinator = coordinator
    }

}

