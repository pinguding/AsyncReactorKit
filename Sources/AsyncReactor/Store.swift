/**
 *  Store.swift
 *  AsyncReactor
 *
 *  Created by 박종우 on 8/2/25.
 */

import DynamicTypeDictionary

/**
 * A protocol that connects UI components to AsyncReactor instances.
 *
 * `Store` acts as a bridge between your UI (views, view controllers, etc.) and your business logic
 * (reactors). It provides a clean interface for sending inputs to reactors and receiving state updates.
 *
 * ## Overview
 *
 * The Store protocol follows a simple pattern:
 * 1. Hold a reference to a reactor
 * 2. Send inputs to the reactor
 * 3. Receive state updates from the reactor
 * 4. Update the UI based on the new state
 *
 * This creates a unidirectional data flow: UI → Input → Reactor → State → UI
 *
 * ## Usage Example
 *
 * ```swift
 * class CounterViewController: UIViewController, Store {
 *     typealias Reactor = CounterReactor
 *     
 *     @IBOutlet weak var countLabel: UILabel!
 *     @IBOutlet weak var incrementButton: UIButton!
 *     @IBOutlet weak var decrementButton: UIButton!
 *     
 *     var reactor: CounterReactor?
 *
 *     override func viewDidLoad() {
 *         super.viewDidLoad()
 *         setupReactor()
 *         bindActions()
 *     }
 *     
 *     private func setupReactor() {
 *         reactor = CounterReactor()
 *     }
 *     
 *     private func bindActions() {
 *         incrementButton.addTarget(self, action: #selector(incrementTapped), for: .touchUpInside)
 *         decrementButton.addTarget(self, action: #selector(decrementTapped), for: .touchUpInside)
 *     }
 *     
 *     @objc private func incrementTapped() {
 *         send(.increment)
 *     }
 *     
 *     @objc private func decrementTapped() {
 *         send(.decrement)
 *     }
 *     
 *     // Store protocol implementation
 *     func state(_ state: CounterReactor.State) {
 *         state.$count.updated { [weak self] count in
 *             self?.countLabel.text = "\(state.count)"
 *         }
 *     }
 * }
 * ```
 */
public protocol Store: AnyObject {

    /// The type of reactor this store works with.
    ///
    /// This associated type ensures type safety between the store and its reactor,
    /// making sure that inputs and states are correctly typed.
    associatedtype Reactor: AsyncReactor

    /// The reactor instance that handles business logic.
    ///
    /// This property holds the reactor that will process inputs and produce state updates.
    /// It's optional to allow for scenarios where the reactor might not be immediately available
    /// or might be conditionally set.
    ///
    /// ## Example
    ///
    /// ```swift
    /// class MyStore: Store {
    ///     var reactor: MyReactor?
    ///
    ///     init(reactor: MyReactor) {
    ///         self.reactor = reactor
    ///         // Set initial state
    ///         state(reactor.currentState)
    ///     }
    /// }
    /// ```
    @MainActor
    var reactor: Reactor? { get set }

    /// Called whenever the reactor produces a new state.
    ///
    /// This method is where you should update your UI or any other components
    /// that depend on the reactor's state. It will be called after every input
    /// is processed by the reactor.
    ///
    /// - Parameter state: The new state produced by the reactor.
    ///
    /// ## Implementation Guidelines
    ///
    /// - Update UI elements based on the new state
    /// - Ensure UI updates happen on the main thread
    /// - Keep this method focused on presentation logic only
    /// - Avoid performing side effects or business logic here
    ///
    /// ## Example
    ///
    /// ```swift
    ///     func state(_ state: CounterReactor.State) {
    ///         state.$count.updated { [weak self] count in
    ///             self?.countLabel.text = "\(state.count)"
    ///         }
    ///     }
    /// ```
    @MainActor
    func state(_ state: Reactor.State)
}

/// Default implementation providing the core store functionality
public extension Store {

    /// Sends an input to the reactor and updates the store with the resulting state.
    ///
    /// This method orchestrates the complete flow from input to UI update:
    /// 1. Sends the input to the reactor
    /// 2. Waits for the reactor to process the input and return a new state
    /// 3. Calls the `state(_:)` method with the new state
    ///
    /// The method uses `UnCheckedSendable` to safely pass non-Sendable objects
    /// across concurrency boundaries, ensuring thread safety in the async context.
    ///
    /// - Parameter input: The input to send to the reactor.
    ///
    /// ## Usage Example
    ///
    /// ```swift
    /// // In a view controller - direct synchronous call
    /// @IBAction func refreshButtonTapped() {
    ///     send(.refresh)
    /// }
    /// 
    /// // In SwiftUI - direct synchronous call
    /// Button("Load Data") {
    ///     store.send(.loadData)
    /// }
    /// 
    /// // For custom async operations
    /// func performComplexOperation() {
    ///     send(.startLoading)
    ///     // The reactor will handle the async work internally
    /// }
    /// ```
    ///
    /// ## Concurrency Safety
    ///
    /// This method automatically handles concurrency safety by:
    /// - Using `UnCheckedSendable` to wrap objects for safe Task usage
    /// - Executing reactor operations in a background Task
    /// - Calling the `state(_:)` method directly without explicit main thread dispatch
    ///
    /// ## Error Handling
    ///
    /// If you need to handle errors from the reactor, you should do so within
    /// the reactor's `reduce` method and represent errors as part of the state:
    ///
    /// ```swift
    /// struct State {
    ///     var data: [Item] = []
    ///     var error: Error?
    ///     var isLoading = false
    /// }
    /// ```
    ///
    /// - Note: This method does nothing if `reactor` is `nil`.
    /// - Note: The method is non-async but internally uses `Task` for concurrency.
    @MainActor
    var reactor: Reactor? {
        get {
            Map[self.reactorMapKey]
        } set {
            if let newValue {
                Map[self.reactorMapKey] = newValue
                self.state(newValue.initialState())
            }
        }
    }

    @MainActor
    func send(_ input: Reactor.Input) {
        guard let reactor else { return }
        Task {
            for await state in reactor.flow(input: input) {
                self.state(state)
            }
        }
    }
}

private extension Store {

    var reactorMapKey: DynamicTypeDictionaryKey<Optional<Self.Reactor>> {
        .init(keyId: ObjectIdentifier(self).hashValue.description + "reactorMapKey", defaultValue: nil)
    }
}

nonisolated(unsafe) private let Map = DynamicTypeDictionary()
