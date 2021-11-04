
import XCTest
import TestHelpers
import Combine
import GBMChallengeKit
import GBMChallengeiOS


class LoginUIIntegrationTests: XCTestCase {
    
    func test_init_doesNotRequestFromAuth() {
        let (sut, auth) = makeSut()
        sut.loadViewIfNeeded()
        XCTAssertEqual(auth.authenticateUserCallCount, 0)
    }
    
    func test_init_rendersUIForBiometryType() {
        
        assert(
            sut: makeSut(biometry: .faceid).sut,
            rendersUIForBiometry: .faceid)
        
        assert(
            sut: makeSut(biometry: .touchid).sut,
            rendersUIForBiometry: .touchid)
        
        assert(
            sut: makeSut(biometry: .none).sut,
            rendersUIForBiometry: .none)
        
    }
    
    func test_loginButton_requestFromAuth() {
        let (sut, auth) = makeSut()
        sut.loadViewIfNeeded()
        
        sut.loginBtn.simulate(event: .touchUpInside)
        
        XCTAssertEqual(auth.authenticateUserCallCount, 1)
    }
    
    func test_loginActions_sendMessagesToDelegate() {
        let (sut, auth) = makeSut()
        let delegateSpy = DelegateSpy()
        sut.delegate = delegateSpy
        sut.loadViewIfNeeded()
        
        sut.simulateLoginBtnTap()
        let error = makeAnyError()
        auth.complete(with: error, at: 0)
        XCTAssertEqual(delegateSpy.messages, [.error(error)])
        
        sut.simulateLoginBtnTap()
        auth.completeSuccessfully(at: 1)
        XCTAssertEqual(delegateSpy.messages, [.error(error), .didLogin])
    }
    
    func test_authenticationCompletion_dispatchesFromBackgroundToMainThread() {
        let (sut, auth) = makeSut()
        sut.loadViewIfNeeded()
        
        sut.simulateLoginBtnTap()
        
        let exp = expectation(description: "Wait for background queue")
        DispatchQueue.global().async {
            auth.completeSuccessfully()
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    //MARK: - Helpers
    
    func makeSut(biometry: BiometryType = .faceid, file: StaticString = #filePath, line: UInt = #line) -> (sut: LoginViewController, auht: AuthSpy) {
        let auth = AuthSpy(biometry: biometry)
        let sut = LoginUIComposer.composeLoginViewController(auth: auth)
        
        trackForMemoryLeaks(auth)
        trackForMemoryLeaks(sut)
        
        return (sut, auth)
    }
    
    func assert(sut: LoginViewController, rendersUIForBiometry biometry: BiometryType, file: StaticString = #filePath, line: UInt = #line) {
        sut.loadViewIfNeeded()
        
        switch biometry {
        case .none:
            XCTAssertNil(sut.biometryImg.image, file: file, line: line)
            XCTAssertNil(sut.descriptionLbl.text, file: file, line: line)
        case .touchid:
            XCTAssertEqual(sut.biometryImg.image?.accessibilityIdentifier, "touchid", file: file, line: line)
            XCTAssertEqual(sut.descriptionLbl.text, "Usa TouchID para iniciar sesión", file: file, line: line)
        case .faceid:
            XCTAssertEqual(sut.biometryImg.image?.accessibilityIdentifier, "faceid", file: file, line: line)
            XCTAssertEqual(sut.descriptionLbl.text, "Usa FaceID para iniciar sesión", file: file, line: line)
        }
    }
    
    class DelegateSpy: LoginViewControllerDelegate {
        enum Message: Equatable {
            
            static func == (lhs: DelegateSpy.Message, rhs: DelegateSpy.Message) -> Bool {
                switch (lhs, rhs) {
                case (.error, .error):
                    return true
                case (.didLogin, .didLogin):
                    return true
                default:
                    return false
                }
            }
            
            case error(Error)
            case didLogin
        }
        
        var messages: [Message] = []
        
        func loginViewControllerDidLoginUser(_ viewController: LoginViewController) {
            messages.append(.didLogin)
        }
        
        func loginViewController(_ viewController: LoginViewController, didReceiveLoginError error: Error) {
            messages.append(.error(error))
        }
    }
}
