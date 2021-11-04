
import UIKit
import Combine
import CombineHelpers
import GBMChallengeKit

public class LoginViewModel {
    
    private let auth: BiometryAuthType
    
    @Published private var authMessage: String?
    @Published private var authImage: UIImage?
    
    public init(auth: BiometryAuthType) {
        self.auth = auth
        
        switch auth.supportedBiometry {
        case .faceid:
            authMessage = "Usa FaceID para iniciar sesión"
            let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .regular)
            authImage = UIImage(systemName: "faceid", withConfiguration: config)
            authImage?.accessibilityIdentifier = "faceid"
        case .touchid:
            authMessage = "Usa TouchID para iniciar sesión"
            let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .regular)
            authImage = UIImage(systemName: "touchid", withConfiguration: config)
            authImage?.accessibilityIdentifier = "touchid"
        case .none:
            authMessage = nil
            authImage = nil
        }
    }
    
    func loginUser() -> AnyPublisher<Void, Error> {
        auth.authenticateUser().dispatchOnMainQueue()
    }
    
    var authMessagePublisher: AnyPublisher<String?, Never> {
        $authMessage.eraseToAnyPublisher()
    }
    
    var authImagePublisher: AnyPublisher<UIImage?, Never> {
        $authImage.eraseToAnyPublisher()
    }
}
