/**
 *  Pulse.swift
 *  AsyncReactor
 *
 *  Created by 박종우 on 8/3/25.
 */

import Foundation

/**
 * A property wrapper that triggers updates whenever a value is assigned, even if it's the same value.
 *
 * `Pulse` is designed for state properties that need to trigger side effects or UI updates
 * whenever they are assigned, regardless of whether the new value is different from the current value.
 * This is particularly useful for alert messages, notifications, or any event-driven properties.
 *
 * ## Overview
 *
 * Unlike regular properties that only trigger change notifications when the value actually changes,
 * `Pulse` tracks assignment operations and can notify observers every time a value is set.
 * This makes it perfect for scenarios where the act of assignment itself is meaningful.
 *
 * ## Common Use Cases
 *
 * - **Alert Messages**: Show an alert every time a message is set, even if it's the same message
 * - **Navigation Events**: Trigger navigation even when navigating to the same destination
 * - **Notifications**: Display notifications that should appear every time they're triggered
 * - **Analytics Events**: Track events that should fire on every assignment
 *
 * ## Usage Example
 *
 * ```swift
 * struct State {
 *     @Pulse var alertMessage: String?
 *     @Pulse var navigationDestination: Route?
 *     var userProfile: User?
 * }
 *
 * class ViewController: Store {
 *     var reactor: MyReactor!
 *
 *     func state(_ state: MyReactor.State) {
 *         // This will trigger every time alertMessage is assigned
 *         state.$alertMessage.updated { [weak self] message in
 *             guard let message = message else { return }
 *             self?.showAlert(message: message)
 *         }
 *         
 *         // This will trigger every time navigationDestination is assigned
 *         state.$navigationDestination.updated { [weak self] destination in
 *             guard let destination = destination else { return }
 *             self?.navigate(to: destination)
 *         }
 *     }
 * }
 * ```
 *
 * ## Behavior Example
 *
 * ```swift
 * @Pulse var message: String? = nil
 * 
 * $message.updated { value in
 *     print("Message updated: \(value)")
 * }
 * 
 * message = "Hello"     // Prints: "Message updated: Hello"
 * message = "Hello"     // Prints: "Message updated: Hello" (triggers again!)
 * message = "World"     // Prints: "Message updated: World"
 * message = "World"     // Prints: "Message updated: World" (triggers again!)
 * ```
 *
 * ## Thread Safety
 *
 * `Pulse` is thread-safe and can be safely accessed from multiple threads.
 * All property access is synchronized using an internal lock.
 */
@propertyWrapper
@MainActor
public class Pulse<Value> {

    /// The actual stored value
    private var _value: Value

    /// Internal lock for thread-safe access
    private let lock: NSLocking = NSLock()

    /// Counter tracking the number of assignments made to this pulse
    private var assignedCount: UInt64 = .zero {
        didSet {
            if oldValue != self.assignedCount {
                self.updateHandler?(self._value)
            }
        }
    }

    /// Handler called whenever the value is assigned (even if it's the same value)
    private var updateHandler: ((Value) -> Void)? = nil

    /// Sets a handler to be called whenever the pulse value is assigned.
    ///
    /// The handler will be called every time the `wrappedValue` is set,
    /// regardless of whether the new value is different from the current value.
    ///
    /// - Parameter handler: A closure that receives the assigned value.
    ///
    /// ## Example
    ///
    /// ```swift
    /// @Pulse var alertMessage: String?
    /// 
    /// $alertMessage.updated { message in
    ///     guard let message = message else { return }
    ///     showAlert(message)
    /// }
    /// 
    /// alertMessage = "Error occurred"  // Handler called
    /// alertMessage = "Error occurred"  // Handler called again
    /// ```
    public func updated(_ handler: @escaping (Value) -> Void) {
        self.updateHandler = handler
    }

    /// The wrapped value that triggers updates on every assignment.
    ///
    /// Getting this property returns the current value.
    /// Setting this property stores the new value and triggers the update handler,
    /// even if the new value is identical to the current value.
    ///
    /// - Note: All access is thread-safe and synchronized using an internal lock.
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

    /// The projected value providing access to the Pulse instance itself.
    ///
    /// This allows access to Pulse-specific methods like `updated(_:)` using the `$` syntax.
    ///
    /// ## Example
    ///
    /// ```swift
    /// @Pulse var message: String?
    /// 
    /// // $message gives you access to the Pulse instance
    /// $message.updated { value in
    ///     print("Message: \(value)")
    /// }
    /// ```
    public var projectedValue: Pulse<Value> {
        self
    }

    /// Creates a new Pulse with the specified initial value.
    ///
    /// - Parameter wrappedValue: The initial value for the pulse.
    ///
    /// ## Example
    ///
    /// ```swift
    /// @Pulse var counter: Int = 0
    /// @Pulse var message: String? = nil
    /// ```
    public init(wrappedValue: Value) {
        self._value = wrappedValue
    }
}
