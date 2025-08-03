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
 *         self.send(.increment)
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
@preconcurrency public protocol Store: AnyObject {

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
    var reactor: Reactor? { get }

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
    /// - Parameter input: The input to send to the reactor.
    ///
    /// ## Usage Example
    ///
    /// ```swift
    /// // In a view controller
    /// @IBAction func refreshButtonTapped() {
    ///     self.send(.refresh)
    /// }
    /// 
    /// // In SwiftUI
    /// Button("Load Data") {
    ///     self.send(.loadData)
    /// }
    /// ```
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
    /// - Note: This method does nothing if `reducer` is `nil`.
    func sendStore(_ input: Reactor.Input) {
        guard let reactor else { return }
        let unCheckableReactor = UnCheckedSendable(reactor)
        let unCheckableSelf = UnCheckedSendable(self)
        Task {
            guard let state = await unCheckableReactor.object?.flow(input: input) else { return }
            await MainActor.run {
                unCheckableSelf.object?.state(state)
            }
        }
    }
}

