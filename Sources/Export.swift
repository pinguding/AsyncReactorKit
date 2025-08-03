/**
 *  Export.swift
 *  AsyncReactor
 *
 *  Created by 박종우 on 8/2/25.
 *
 * AsyncReactor is a reactive architecture library for Swift applications built on Swift Concurrency.
 * It provides a unidirectional data flow pattern similar to ReactorKit but leverages async/await
 * instead of RxSwift for handling asynchronous operations.
 *
 * ## Overview
 *
 * AsyncReactor reimagines the ReactorKit architecture for the modern Swift concurrency model.
 * Instead of relying on RxSwift's observables, it uses Swift's native async/await pattern
 * to provide a more straightforward and type-safe reactive programming experience.
 *
 * ## Key Components
 *
 * - ``AsyncReactor``: The core protocol that defines the reactive architecture pattern
 * - ``Store``: A protocol for connecting reactors to UI components
 * - ``Pulse``: A property wrapper for state properties that need to trigger updates
 * - ``Stub``: A testing utility for unit testing reactors
 *
 * ## Differences from ReactorKit
 *
 * - Uses Swift Concurrency (async/await) instead of RxSwift
 * - Leverages `DynamicTypeDictionary` for type-safe state storage instead of WeakMapTable
 * - Designed for Swift 6 with full concurrency safety
 * - Simplified API surface with fewer concepts to learn
 *
 * ## Usage Example
 *
 * ```swift
 * // Define a reactor
 * final class CounterReactor: AsyncReactor {
 *     enum Input {
 *         case increment
 *         case decrement
 *     }
 *     
 *     enum Mutation {
 *         case setCount(Int)
 *     }
 *     
 *     struct State: Sendable {
 *         var count: Int = 0
 *     }
 *     
 *     nonisolated func initialState() -> State {
 *         State()
 *     }
 *     
 *     func reduce(_ input: Input) async -> Mutation {
 *         switch input {
 *         case .increment:
 *             return .setCount(currentState.count + 1)
 *         case .decrement:
 *             return .setCount(currentState.count - 1)
 *         }
 *     }
 *     
 *     func mutate(_ state: State, mutation: Mutation) async -> State {
 *         var newState = state
 *         switch mutation {
 *         case .setCount(let count):
 *             newState.count = count
 *         }
 *         return newState
 *     }
 * }
 * ```
 */

@_exported import Foundation
@_exported import DynamicTypeDictionary
