
import UIKit
import GBMChallengeKit
import GBMChallengeiOS

class Coordinator {
    
    private let navigationController = UINavigationController()
    
    private lazy var auth: BiometryAuthType = BiometryAuth()
    
    private lazy var repo: IPCRepositoryType = makeRepository()
    
    private var animated: Bool = true
    
    convenience init(auth: BiometryAuthType, repo: IPCRepositoryType, animated: Bool) {
        self.init()
        self.auth = auth
        self.repo = repo
        self.animated = animated
    }
    
    func configureWindow(_ window: UIWindow) {
        window.rootViewController = makeInitialViewController()
        window.makeKeyAndVisible()
    }
    
    private func makeInitialViewController() -> UIViewController {
        navigationController.setViewControllers([makeLoginViewController()], animated: false)
        return navigationController
    }
    
    private func makeLoginViewController() -> LoginViewController {
        let vc = LoginUIComposer.composeLoginViewController(auth: auth)
        vc.delegate = self
        return vc
    }
    
    private func makeRepository() -> IPCRepository {
        let storeURL = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]).appendingPathComponent("IPCCache.store")
        let store = IPCFileStore(storeURL: storeURL)
        let localFetcher = IPCLocalFetcher(store: store)
        let apiURL = IPCFeedEndpoint.get.url(baseURL: URL(string: "https://run.mocky.io")!)
        let remoteFetcher = IPCRemoteFetcher(client: HTTPClient(session: .shared), url: apiURL)
        let repo = IPCRepository(cacheFetcher: localFetcher, remoteFetcher: remoteFetcher, cacheStore: localFetcher)
        return repo
    }
    
    private func makeIPCFeedViewController() -> IPCFeedViewController {
        let counter = CountdownCounter(interval: .seconds(1), times: 60)
        let rangeOptions = RangeOption.defaultOptions
        let vc = IPCFeedUIComposer.composeIPCViewController(repository: repo, counter: counter, rangeOptions: rangeOptions)
        vc.delegate = self
        return vc
    }
    
    private func showErrorAlert(message: String, presentingViewController: UIViewController) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: {[unowned alert, unowned self] _ in
            alert.dismiss(animated: animated, completion: nil)
        }))
        presentingViewController.present(alert, animated: animated, completion: nil)
    }
}

extension Coordinator: LoginViewControllerDelegate {
    
    func loginViewControllerDidLoginUser(_ viewController: LoginViewController) {
        let vc = makeIPCFeedViewController()
        navigationController.setViewControllers([vc], animated: animated)
    }
    
    func loginViewController(_ viewController: LoginViewController, didReceiveLoginError error: Error) {
        showErrorAlert(message: error.localizedDescription, presentingViewController: viewController)
    }
}

extension Coordinator: IPCFeedViewControllerDelegate {
    func ipcFeedViewController(_ viewController: IPCFeedViewController, didReceiveFetchingError error: Error) {
        showErrorAlert(message: error.localizedDescription, presentingViewController: viewController)
    }
}
