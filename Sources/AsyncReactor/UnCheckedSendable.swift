/**
 *  UnCheckedSendable.swift
 *  AsyncReactor
 *
 *  Created by 박종우 on 8/3/25.
 */

import Foundation

/**
 * A wrapper that makes non-Sendable objects safely passable across concurrency boundaries.
 *
 * `UnCheckedSendable` provides a way to work with objects that don't conform to `Sendable`
 * in Swift Concurrency contexts when you can guarantee thread safety through other means.
 * It uses `@unchecked Sendable` to bypass Swift's compile-time safety checks.
 *
 * ## Overview
 *
 * Swift Concurrency requires types to be `Sendable` when passed between different
 * concurrency contexts (actors, tasks, etc.). However, some objects like UI components
 * or legacy classes may not conform to `Sendable` but are still safe to use in specific
 * patterns with proper synchronization.
 *
 * ## When to Use
 *
 * Use `UnCheckedSendable` when:
 * - You need to pass non-Sendable objects across concurrency boundaries
 * - You can guarantee thread safety through external synchronization
 * - The object is only accessed from the main thread (like UI components)
 * - You're working with legacy code that can't be made Sendable
 *
 * ## Safety Considerations
 *
 * ⚠️ **Important**: Using `UnCheckedSendable` bypasses Swift's safety checks.
 * You must ensure thread safety manually:
 * - Only access the wrapped object from appropriate contexts
 * - Use proper synchronization when needed
 * - Be aware that the object may become `nil` if it's deallocated
 *
 * ## Usage Example
 *
 * ```swift
 * class MyViewController: UIViewController, Store {
 *     var reactor: MyReactor?
 *     
 *     func setupReactor() {
 *         reactor = MyReactor()
 *     }
 *     
 *     @IBAction func buttonTapped() {
 *         // Wrap self to pass it safely to Task
 *         let wrappedSelf = UnCheckedSendable(self)
 *         
 *         Task {
 *             let state = await reactor?.flow(input: .buttonTapped)
 *             
 *             // Access the wrapped object safely on main thread
 *             await MainActor.run {
 *                 wrappedSelf.object?.updateUI(with: state)
 *             }
 *         }
 *     }
 *     
 *     func updateUI(with state: MyReactor.State?) {
 *         // Update UI elements here
 *     }
 * }
 * ```
 *
 * ## Store Protocol Integration
 *
 * ```swift
 * public extension Store {
 *     func send(_ input: Reactor.Input) {
 *         guard let reactor = self.reactor else { return }
 *         let wrappedSelf = UnCheckedSendable(self)
 *         
 *         Task {
 *             let state = await reactor.flow(input: input)
 *             await MainActor.run {
 *                 wrappedSelf.object?.state(state)
 *             }
 *         }
 *     }
 * }
 * ```
 *
 * ## Memory Management
 *
 * The wrapped object is held with a `weak` reference, which means:
 * - No retain cycles are created
 * - The object can be deallocated normally
 * - Always check if `object` is `nil` before use
 *
 * ## Thread Safety Pattern
 *
 * ```swift
 * func processAsync() {
 *     let wrappedDelegate = UnCheckedSendable(self.delegate)
 *     
 *     Task {
 *         let result = await performAsyncWork()
 *         
 *         // Always access on main thread for UI objects
 *         await MainActor.run {
 *             wrappedDelegate.object?.handleResult(result)
 *         }
 *     }
 * }
 * ```
 *
 * - Warning: This class bypasses Swift's concurrency safety checks.
 *   Use only when you can guarantee thread safety through other means.
 */
public class UnCheckedSendable<Object: AnyObject>: @unchecked Sendable {

    /// The wrapped object, held with a weak reference to prevent retain cycles.
    ///
    /// This property may be `nil` if the original object has been deallocated.
    /// Always check for `nil` before accessing the object.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let wrapper = UnCheckedSendable(myObject)
    /// 
    /// // Later, in an async context...
    /// if let object = wrapper.object {
    ///     object.doSomething()
    /// }
    /// ```
    public weak var object: Object?

    /// Creates a new wrapper for the specified object.
    ///
    /// The object is stored with a weak reference to prevent retain cycles
    /// and allow normal memory management.
    ///
    /// - Parameter object: The object to wrap for safe concurrency usage.
    ///
    /// ## Example
    ///
    /// ```swift
    /// class MyClass {
    ///     func performAsyncOperation() {
    ///         let wrappedSelf = UnCheckedSendable(self)
    ///         
    ///         Task {
    ///             // Use wrappedSelf.object safely in async context
    ///             await MainActor.run {
    ///                 wrappedSelf.object?.updateState()
    ///             }
    ///         }
    ///     }
    /// }
    /// ```
    public init(_ object: Object) {
        self.object = object
    }
}
