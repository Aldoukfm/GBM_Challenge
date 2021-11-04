
import XCTest
import TestHelpers
import LocalAuthentication
import Combine

import GBMChallengeKit

class BiometryAuthTests: XCTestCase {
    
    func test_init_callCanEvaluatePolicyOnNewContext() {
        var makeContextCallCount: Int = 0
        var context: LAContextSpy?
        let _ = makeSut {
            makeContextCallCount += 1
            let newContext = LAContextSpy(biometry: .faceID, stub: .success(()))
            context = newContext
            return newContext
        }
        
        XCTAssertEqual(makeContextCallCount, 1)
        XCTAssertEqual(context?.canEvaluatePolicyCallCount, 1)
    }
    
    func test_init_readBiometryFromContext() {
        
        let faceidSUT = makeSut(biometry: .faceID)
        XCTAssertEqual(faceidSUT.supportedBiometry, .faceid)
        
        let touchidSUT = makeSut(biometry: .touchID)
        XCTAssertEqual(touchidSUT.supportedBiometry, .touchid)
        
        let noneSUT = makeSut(biometry: .none)
        XCTAssertEqual(noneSUT.supportedBiometry, .none)
    }
    
    func test_authenticateUser_callEvaluatePolicyOnNewContext() throws {
        var makeContextCallCount: Int = 0
        var context: LAContextSpy?
        let sut = makeSut {
            makeContextCallCount += 1
            let newContext = LAContextSpy(biometry: .faceID, stub: .success(()))
            context = newContext
            return newContext
        }
        
        _ = try wait(sut.authenticateUser())
        
        XCTAssertEqual(makeContextCallCount, 2)
        XCTAssertEqual(context?.evaluatePolicyCallCount, 1)
    }
    
    func test_authenticateUser_completeSuccessfully() {
        let sut = makeSut(biometry: .faceID, stub: .success(()))
        
        XCTAssertNoThrow(try wait(sut.authenticateUser()).get())
    }
    
    func test_atuhenticateUser_failsWithError() throws {
        let expectedError = makeAnyError()
        let sut = makeSut(biometry: .faceID, stub: .failure(makeAnyError()))
        
        let error = try wait(sut.authenticateUser()).getError()
        
        XCTAssertEqual(error as NSError, expectedError)
    }
    
    //MARK: - Helpers
    
    func makeSut(biometry: LABiometryType, stub: Result<Void, Error> = .success(()), file: StaticString = #filePath, line: UInt = #line) -> BiometryAuth {
        let sut = BiometryAuth(makeContext: {
            LAContextSpy(biometry: biometry, stub: stub)
        })
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    func makeSut(makeContext: @escaping () -> (LAContextSpy), file: StaticString = #filePath, line: UInt = #line) -> BiometryAuth {
        let sut = BiometryAuth(makeContext: makeContext)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    class LAContextSpy: LAContext {
        
        private let biometry: LABiometryType
        private let stub: Result<Void, Error>
        
        private(set) var canEvaluatePolicyCallCount: Int = 0
        private(set) var evaluatePolicyCallCount: Int = 0
        
        init(biometry: LABiometryType, stub: Result<Void, Error>) {
            self.biometry = biometry
            self.stub = stub
        }
        
        override var biometryType: LABiometryType {
            biometry
        }
        
        override func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool {
            canEvaluatePolicyCallCount += 1
            switch stub {
            case .success:
                return true
            case .failure(let evaluationError):
                error?.pointee = evaluationError as NSError
                return false
            }
        }
        
        override func evaluatePolicy(_ policy: LAPolicy, localizedReason: String, reply: @escaping (Bool, Error?) -> Void) {
            evaluatePolicyCallCount += 1
            do {
                try stub.get()
                reply(true, nil)
            } catch {
                reply(false, error)
            }
        }
    }
}
