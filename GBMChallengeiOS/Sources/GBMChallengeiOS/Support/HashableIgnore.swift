
import Foundation

@propertyWrapper
struct EquatableIgnore<Value>: Equatable {
    
    var wrappedValue: Value
    
    static func ==(lhs: EquatableIgnore<Value>, rhs: EquatableIgnore<Value>) -> Bool {
        return true
    }
}

@propertyWrapper
struct HashableIgnore<Value>: Hashable {
    
    @EquatableIgnore
    var wrappedValue: Value
    
    func hash(into hasher: inout Hasher) { }
}
