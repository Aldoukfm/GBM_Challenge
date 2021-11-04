
import Foundation
import Combine
import LocalAuthentication

public enum BiometryType {
    case none
    case faceid
    case touchid
}

public protocol BiometryAuthType {
    var supportedBiometry: BiometryType { get }
    func authenticateUser() -> AnyPublisher<Void, Error>
}

public class BiometryAuth: BiometryAuthType {
    
    public let supportedBiometry: BiometryType
    private let makeContext: () -> (LAContext)
    
    public init(makeContext: @escaping () -> (LAContext) = LAContext.init) {
        self.makeContext = makeContext
        let context = makeContext()
        context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        switch context.biometryType {
        case .faceID:
            supportedBiometry = .faceid
        case .touchID:
            supportedBiometry = .touchid
        case .none:
            supportedBiometry = .none
        @unknown default:
            supportedBiometry = .none
        }
        
    }
    
    public func authenticateUser() -> AnyPublisher<Void, Error> {
        return Future {[unowned self] completion in
            
            let context = makeContext()
            var error: NSError?
            if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
                context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Acceder a la app") { success, error in
                    if success {
                        completion(.success(()))
                    } else {
                        completion(.failure(error ?? UnknownError()))
                    }
                }
            } else {
                completion(.failure(error ?? UnknownError()))
            }
        }
        .eraseToAnyPublisher()
    }
    
    struct UnknownError: Error { }
}

