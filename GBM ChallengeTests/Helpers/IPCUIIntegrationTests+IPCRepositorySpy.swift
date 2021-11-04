
import Foundation
import Combine
import GBMChallengeKit

class IPCRepositorySpy: IPCRepositoryType {
    
    var fetchValuesCallCount: Int {
        subjects.count
    }
    
    private var subjects: [PassthroughSubject<(IPCRepositorySource, [IPCValue]), Error>] = []
    
    func fetchValues() -> AnyPublisher<(IPCRepositorySource, [IPCValue]), Error> {
        let subject: PassthroughSubject<(IPCRepositorySource, [IPCValue]), Error> = PassthroughSubject()
        subjects.append(subject)
        return subject.eraseToAnyPublisher()
    }
    
    func send(_ input: (IPCRepositorySource, [IPCValue]), at index: Int = 0) {
        subjects[index].send(input)
    }
    
    func complete(with error: Error? = nil, at index: Int = 0) {
        if let error = error {
            subjects[index].send(completion: .failure(error))
        } else {
            subjects[index].send(completion: .finished)
        }
    }
    
}
