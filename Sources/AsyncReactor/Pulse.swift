//
//  Pulse.swift
//  AsyncReactor
//
//  Created by 박종우 on 8/3/25.
//

import Foundation

@propertyWrapper
public class Pulse<Value> {

    private var _value: Value

    private let lock: NSLocking = NSLock()

    private var assignedCount: UInt64 = .zero {
        didSet {
            if oldValue != self.assignedCount {
                self.updateHandler?(self._value)
            }
        }
    }

    private var updateHandler: ((Value) -> Void)? = nil

    public func updated(_ handler: @escaping (Value) -> Void) {
        self.updateHandler = handler
    }

    public var wrappedValue: Value {
        get {
            self.lock.withLock {
                return self._value
            }
        }
        set {
            self.lock.withLock {
                self._value = newValue
                self.assignedCount &+= 1
            }
        }
    }

    public var projectedValue: Pulse<Value> {
        self
    }

    public init(wrappedValue: Value) {
        self._value = wrappedValue
    }
}
