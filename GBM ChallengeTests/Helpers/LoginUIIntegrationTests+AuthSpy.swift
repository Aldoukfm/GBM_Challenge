
import Foundation
import Combine
import GBMChallengeKit

class AuthSpy: BiometryAuthType {
    
    let supportedBiometry: BiometryType
    
    private var subjects: [PassthroughSubject<Void, Error>] = []
    
    var authenticateUserCallCount: Int {
        subjects.count
    }
    
    init(biometry: BiometryType = .faceid) {
        self.supportedBiometry = biometry
    }
    
    func authenticateUser() -> AnyPublisher<Void, Error> {
        let subject = PassthroughSubject<Void, Error>()
        subjects.append(subject)
        return subject.eraseToAnyPublisher()
    }
    
    func complete(with error: Error, at index: Int = 0) {
        subjects[index].send(completion: .failure(error))
    }
    
    func completeSuccessfully(at index: Int = 0) {
        subjects[index].send(())
        subjects[index].send(completion: .finished)
    }
}
