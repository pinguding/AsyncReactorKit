/**
 *  AsyncReactor.swift
 *  AsyncReactor
 *
 *  Created by 박종우 on 8/2/25.
 */

import DynamicTypeDictionary

/**
 * A protocol that defines the core reactive architecture pattern using Swift Concurrency.
 *
 * `AsyncReactor` provides a unidirectional data flow pattern where:
 * 1. **Input** represents user actions or external events
 * 2. **Mutation** represents atomic state changes
 * 3. **State** represents the current state of the reactor
 *
 * ## Overview
 *
 * The `AsyncReactor` protocol is the heart of the AsyncReactor architecture.
 * It defines a clear separation between side effects (`reduce`) and state mutations (`mutate`),
 * making your code more predictable and testable.
 *
 * ## Data Flow
 *
 * ```
 * Input → reduce() → Mutation → mutate() → State
 * ```
 *
 * 1. An **Input** is sent to the reactor
 * 2. The `reduce()` method processes the input and returns a **Mutation**
 * 3. The `mutate()` method applies the mutation to the current state
 * 4. The new **State** is stored and can be observed by UI components
 *
 * ## Usage Example
 *
 * ```swift
 * final class UserProfileReactor: AsyncReactor {
 *     enum Input {
 *         case loadProfile(userID: String)
 *         case updateName(String)
 *         case refresh
 *     }
 *     
 *     enum Mutation {
 *         case setLoading(Bool)
 *         case setProfile(User)
 *         case setError(Error)
 *     }
 *     
 *     struct State: Sendable {
 *         var isLoading = false
 *         var user: User?
 *         var error: Error?
 *     }
 *     
 *     private let userService: UserServiceProtocol
 *     
 *     init(userService: UserServiceProtocol) {
 *         self.userService = userService
 *     }
 *     
 *     nonisolated func initialState() -> State {
 *         State()
 *     }
 *     
 *     func reduce(_ input: Input) async -> Mutation {
 *         switch input {
 *         case .loadProfile(let userID):
 *             do {
 *                 let user = try await userService.fetchUser(id: userID)
 *                 return .setProfile(user)
 *             } catch {
 *                 return .setError(error)
 *             }
 *         case .updateName(let name):
 *             // Handle name update...
 *             return .setProfile(updatedUser)
 *         case .refresh:
 *             return .setLoading(true)
 *         }
 *     }
 *     
 *     func mutate(_ state: State, mutation: Mutation) async -> State {
 *         var newState = state
 *         switch mutation {
 *         case .setLoading(let loading):
 *             newState.isLoading = loading
 *         case .setProfile(let user):
 *             newState.user = user
 *             newState.isLoading = false
 *             newState.error = nil
 *         case .setError(let error):
 *             newState.error = error
 *             newState.isLoading = false
 *         }
 *         return newState
 *     }
 * }
 * ```
 *
 * ## Thread Safety
 *
 * The reactor automatically handles thread safety for state access using internal locking mechanisms.
 * All associated types must conform to `Sendable` to ensure safe concurrent access.
 *
 * - Note: The `initialState()` method is marked as `nonisolated` because it should return
 *   a constant initial state without any side effects.
 */
public protocol AsyncReactor: AnyObject {

    /// The type representing user actions or external events that can be sent to the reactor.
    ///
    /// Input should be an enum that represents all possible actions that can trigger state changes.
    /// Each case can carry associated values containing the data needed for the action.
    ///
    /// - Important: Must conform to `Sendable` for thread safety.
    associatedtype Input: Sendable

    /// The type representing atomic state changes.
    ///
    /// Mutations represent the smallest possible changes to the state.
    /// They are typically produced by the `reduce()` method and consumed by the `mutate()` method.
    ///
    /// - Important: Must conform to `Sendable` for thread safety.
    associatedtype Mutation: Sendable

    /// The type representing the current state of the reactor.
    ///
    /// State should contain all the data needed to render the UI.
    /// It should be a struct with immutable properties for better predictability.
    ///
    /// - Important: Must conform to `Sendable` for thread safety.
    associatedtype State: Sendable

    /// Returns the initial state of the reactor.
    ///
    /// This method is called once when the reactor is first accessed.
    /// It should return a constant initial state without any side effects.
    ///
    /// - Returns: The initial state of the reactor.
    ///
    /// - Note: This method is `nonisolated` because it should be pure and stateless.
    nonisolated func initialState() -> State

    /// Processes an input and returns a mutation asynchronously.
    ///
    /// This method is where side effects should be performed, such as:
    /// - API calls
    /// - Database operations
    /// - File I/O
    /// - Any other asynchronous operations
    ///
    /// - Parameter input: The input to process.
    /// - Returns: A mutation representing the state change to apply.
    ///
    /// ## Example
    ///
    /// ```swift
    /// func reduce(_ input: Input) async -> Mutation {
    ///     switch input {
    ///     case .loadData:
    ///         do {
    ///             let data = try await apiService.fetchData()
    ///             return .setData(data)
    ///         } catch {
    ///             return .setError(error)
    ///         }
    ///     case .reset:
    ///         return .clearData
    ///     }
    /// }
    /// ```
    func reduce(_ input: Input) async -> Mutation

    /// Applies a mutation to the current state and returns the new state.
    ///
    /// This method should be pure and only modify the state based on the given mutation.
    /// No side effects should be performed here.
    ///
    /// - Parameters:
    ///   - state: The current state.
    ///   - mutation: The mutation to apply.
    /// - Returns: The new state after applying the mutation.
    ///
    /// ## Example
    ///
    /// ```swift
    /// func mutate(_ state: State, mutation: Mutation) async -> State {
    ///     var newState = state
    ///     switch mutation {
    ///     case .setData(let data):
    ///         newState.data = data
    ///         newState.isLoading = false
    ///     case .setError(let error):
    ///         newState.error = error
    ///         newState.isLoading = false
    ///     case .clearData:
    ///         newState.data = nil
    ///         newState.error = nil
    ///     }
    ///     return newState
    /// }
    /// ```
    func mutate(_ state: State, mutation: Mutation) async -> State
}

/// Internal lock for thread-safe state access
nonisolated(unsafe) private let locking: NSLocking = NSLock()

/// Internal extension providing state management and data flow coordination
internal extension AsyncReactor {

    /// Thread-safe access to the current state of the reactor.
    ///
    /// This computed property provides synchronized access to the reactor's state
    /// using the internal `DynamicTypeDictionary` for type-safe storage.
    ///
    /// - Note: State access is automatically synchronized using an internal lock.
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

    /// Executes the complete data flow from input to state.
    ///
    /// This method orchestrates the entire reactive flow:
    /// 1. Calls `reduce()` to process the input and get a mutation
    /// 2. Calls `mutate()` to apply the mutation to the current state
    /// 3. Updates the current state with the new state
    /// 4. Returns the new state
    ///
    /// - Parameter input: The input to process through the reactive flow.
    /// - Returns: The new state after processing the input.
    ///
    /// - Note: This method is `nonisolated` because it coordinates async operations
    ///   but doesn't directly access actor-isolated state.
    nonisolated func flow(input: Input) async -> State {
        let mutation = await self.reduce(input)
        let newState = await self.mutate(self.currentState, mutation: mutation)
        self.currentState = newState
        return self.currentState
    }
}

/// Private extension for internal state key generation
private extension AsyncReactor {
    /// Generates a unique key for storing this reactor's state in the global dictionary.
    ///
    /// The key is created using the reactor instance's `ObjectIdentifier` to ensure
    /// each reactor instance has its own isolated state storage.
    ///
    /// - Returns: A unique `DynamicTypeDictionaryKey` for this reactor's state.
    var currentStateKey: DynamicTypeDictionaryKey<State> {
        .init(keyId: ObjectIdentifier(self).hashValue.description + "currentStateKey", defaultValue: self.initialState())
    }
}

/// Internal storage mechanism for reactor states.
///
/// This struct provides a global, thread-safe storage solution for all reactor states
/// using `DynamicTypeDictionary` which replaces ReactorKit's `WeakMapTable`.
private struct Map {
    /// Global dictionary for storing all reactor states with type safety.
    ///
    /// Each reactor instance stores its state using a unique key generated from its
    /// `ObjectIdentifier`, ensuring complete isolation between different reactor instances.
    ///
    /// - Note: Marked as `nonisolated(unsafe)` because thread safety is handled
    ///   by the external locking mechanism in the `currentState` property.
    nonisolated(unsafe) static let dictionary: DynamicTypeDictionary = .init()
}
