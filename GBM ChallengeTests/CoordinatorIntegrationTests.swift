
import XCTest
import GBMChallengeiOS
import GBMChallengeKit

@testable import GBM_Challenge

class CoordinatorIntegrationTests: XCTestCase {
    
    func test_configureWindow_setsWindowAsKeyAndVisible() {
        let (sut, window) = makeSUT()
        
        sut.configureWindow(window)
        
        XCTAssertEqual(window.makeKeyAndVisibleCallCount, 1)
    }
    
    func test_configureWindow_setsLoginVCAsRootVC() throws {
        let (sut, window) = makeSUT()
        
        sut.configureWindow(window)
        
        let root = window.rootViewController
        
        let rootNavigation = try XCTUnwrap(root as? UINavigationController, "Expected a navigation controller as root, got \(String(describing: root)) instead")
        
        let topController = rootNavigation.topViewController
        
        XCTAssertTrue(topController is LoginViewController, "Expected a login controller as top view controller, got \(String(describing: topController)) instead")
    }
    
    func test_onSuccessfulAuth_displayIPCFeed() throws {
        let auth = AuthSpy()
        let (sut, window) = makeSUT(auth: auth)
        let loginVC = try launchLoginViewController(sut: sut, window: window)
        
        simulateSuccessfulAuth(on: loginVC, auth: auth)
        
        let root = window.rootViewController
        
        let rootNavigation = try XCTUnwrap(root as? UINavigationController, "Expected a navigation controller as root, got \(String(describing: root)) instead")
        
        let topController = rootNavigation.topViewController
        
        XCTAssertTrue(topController is IPCFeedViewController, "Expected IPCFeed controller as top view controller, got \(String(describing: topController)) instead")
    }
    
    func test_onAuthFailure_displaysErrorAlert() throws {
        let auth = AuthSpy()
        let (sut, window) = makeSUT(auth: auth)
        let loginVC = try launchLoginViewController(sut: sut, window: window)
        
        simulateFailingAuth(on: loginVC, auth: auth)
        
        try assertWindowDisplaysErrorAlert(window: window)
    }
    
    func test_onFetchError_displaysErrorAlert() throws {
        let auth = AuthSpy()
        let repo = IPCRepositorySpy()
        let (sut, window) = makeSUT(auth: auth, repo: repo)
        let _ = try launchIPCFeedViewController(sut: sut, window: window, auth: auth)

        repo.complete(with: makeAnyError(), at: 0)
        
        try assertWindowDisplaysErrorAlert(window: window)
    }
    
    //MARK: - Helpers
    
    func makeSUT(auth: BiometryAuthType = AuthSpy(), repo: IPCRepositoryType = IPCRepositorySpy()) -> (sut: Coordinator, window: WindowSpy) {
        let window = WindowSpy()
        let sut = Coordinator(auth: auth, repo: repo, animated: false)
        return (sut, window)
    }
    
    func simulateSuccessfulAuth(on loginVC: LoginViewController, auth: AuthSpy) {
        loginVC.simulateLoginBtnTap()
        auth.completeSuccessfully()
    }
    
    func simulateFailingAuth(on loginVC: LoginViewController, auth: AuthSpy) {
        loginVC.simulateLoginBtnTap()
        auth.complete(with: makeAnyError())
    }
    
    func launchLoginViewController(sut: Coordinator, window: WindowSpy) throws -> LoginViewController {
        
        sut.configureWindow(window)
        
        let root = window.rootViewController
        let rootNavigation = try XCTUnwrap(root as? UINavigationController, "Expected a navigation controller as root, got \(String(describing: root)) instead")
        
        let topController = rootNavigation.topViewController
        let loginVC = try XCTUnwrap(topController as? LoginViewController, "Expected a login controller as top view controller, got \(String(describing: topController)) instead")
        loginVC.loadViewIfNeeded()
        
        return loginVC
    }
    
    func launchIPCFeedViewController(sut: Coordinator, window: WindowSpy, auth: AuthSpy) throws -> IPCFeedViewController {
        let loginVC = try launchLoginViewController(sut: sut, window: window)
        simulateSuccessfulAuth(on: loginVC, auth: auth)


        let root = window.rootViewController
        let rootNavigation = try XCTUnwrap(root as? UINavigationController, "Expected a navigation controller as root, got \(String(describing: root)) instead")

        let topController = rootNavigation.topViewController
        let ipcFeedVC = try XCTUnwrap(topController as? IPCFeedViewController, "Expected IPCFeed controller as top view controller, got \(String(describing: topController)) instead")
        ipcFeedVC.loadViewIfNeeded()

        return ipcFeedVC
    }
    
    func assertWindowDisplaysErrorAlert(window: UIWindow, file: StaticString = #filePath, line: UInt = #line) throws {
        let root = window.rootViewController
        let rootNavigation = try XCTUnwrap(root as? UINavigationController, "Expected a navigation controller as root, got \(String(describing: root)) instead")
        
        let alert = try XCTUnwrap(rootNavigation.visibleViewController as? UIAlertController, "Expected alert controller")
        
        XCTAssertEqual(alert.title, "Error", file: file, line: line)
    }
    
    class WindowSpy: UIWindow {
        
        private(set) var makeKeyAndVisibleCallCount = 0
        
        override func makeKeyAndVisible() {
            super.makeKeyAndVisible()
            makeKeyAndVisibleCallCount += 1
        }
        
    }
    
}
