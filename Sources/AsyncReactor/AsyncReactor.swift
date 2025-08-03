//
//  AsyncReactor.swift
//  AsyncReactor
//
//  Created by 박종우 on 8/2/25.
//

import DynamicTypeDictionary

public protocol AsyncReactor: AnyObject {

    associatedtype Input: Sendable

    associatedtype Mutation: Sendable

    associatedtype State: Sendable

    nonisolated func initialState() -> State

    func reduce(_ input: Input) async -> Mutation

    func mutate(_ state: State, mutation: Mutation) async -> State
}

nonisolated(unsafe) private let locking: NSLocking = NSLock()

internal extension AsyncReactor {

    var currentState: State {
        get {
            locking.withLock {
                return Map.dictionary[self.currentStateKey]
            }
        } set {
            locking.withLock {
                Map.dictionary[self.currentStateKey] = newValue
            }
        }
    }

    nonisolated func flow(input: Input) async -> State {
        let mutation = await self.reduce(input)
        let newState = await self.mutate(self.currentState, mutation: mutation)
        self.currentState = newState
        return self.currentState
    }
}

private extension AsyncReactor {
    var currentStateKey: DynamicTypeDictionaryKey<State> {
        .init(keyId: ObjectIdentifier(self).hashValue.description + "currentStateKey", defaultValue: self.initialState())
    }
}

private struct Map {
    nonisolated(unsafe) static let dictionary: DynamicTypeDictionary = .init()
}
