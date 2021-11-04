
import Foundation
import Combine

extension Publisher {
    
    public func optionalTry() -> Publishers.ReplaceError<Publishers.Map<Self, Optional<Self.Output>>> {
        self.map({ Optional($0) })
            .replaceError(with: nil)
    }
    
    public func optional() -> Publishers.Map<Self, Self.Output?> {
        self.map({ Optional($0) })
    }
    
    public func unwrap<T>() -> Publishers.CompactMap<Self, T> where Output == Optional<T> {
        compactMap { $0 }
    }
    
    public func voidOutput() -> Publishers.Map<Self, ()> {
        return map({ _ in })
    }
    
    public func sink(receiveResult: @escaping (Result<Output, Failure>) -> ()) -> AnyCancellable {
        return sink { (completion) in
            switch completion {
            case .finished:
                break
            case .failure(let error):
                receiveResult(.failure(error))
            }
        } receiveValue: { (value) in
            receiveResult(.success(value))
        }
        
    }
    
    @discardableResult
    public func wait(qos: DispatchQoS.QoSClass = .default) -> Result<Output, Failure> {
        var result: Result<Output, Failure>?
        
        let group = DispatchGroup()
        group.enter()
        
        let cancellable = self.sink(receiveResult: { _result in
            result = _result
            group.leave()
        })
        
        DispatchQueue.global(qos: qos).sync {
            group.wait()
            cancellable.cancel()
        }
        
        return result!
    }
}

extension Publisher {
    public func weakAssign<Root: AnyObject>(to keyPath: ReferenceWritableKeyPath<Root, Self.Output>, on root: Root) -> AnyCancellable where Self.Failure == Never {
        sink(receiveValue: {[weak root] in
            root?[keyPath: keyPath] = $0
        })
    }
}

extension Publisher where Output == URLSession.DataTaskPublisher.Output {
    public func decode<Item, Coder>(type: Item.Type, decoder: Coder) -> Publishers.TryMap<Self, Item> where Item: Decodable, Coder: TopLevelDecoder, Coder.Input == Data {
        return tryMap { try decoder.decode(type, from: $0.data) }
    }
}

extension Publisher where Output: Sequence {
    public func filterItems(_ isIncluded: @escaping (Output.Element) -> Bool) -> Publishers.Map<Self, [Self.Output.Element]> {
        map({ output in output.filter(isIncluded) })
    }
    
    public func compactMapItems<T>(_ transform: @escaping (Output.Element) -> T?) -> Publishers.Map<Self, [T]> {
        map({ output in output.compactMap(transform) })
    }
    
    public func mapItems<T>(_ transform: @escaping (Output.Element) -> T) -> Publishers.Map<Self, [T]> {
        map({ output in output.map(transform) })
    }
    
    public func sortItems(_ sort: @escaping (Output.Element, Output.Element) -> Bool) -> Publishers.Map<Self, [Output.Element]> {
        map({ output in output.sorted(by: sort) })
    }
}

extension Publisher where Failure == Never {
    public func failable() -> Publishers.SetFailureType<Self, Error> {
        setFailureType(to: Error.self)
    }
}


