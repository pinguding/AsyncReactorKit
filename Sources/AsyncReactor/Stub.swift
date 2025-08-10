/**
 *  Stub.swift
 *  AsyncReactor
 *
 *  Created by 박종우 on 8/2/25.
 */

import Foundation

/**
 * A testing utility that provides controlled access to reactor functionality for unit tests.
 *
 * `Stub` allows you to test your reactors in isolation by providing direct access to the
 * reactor's data flow without the complexity of setting up a full UI stack. It's designed
 * to make unit testing of business logic straightforward and reliable.
 *
 * ## Overview
 *
 * The Stub class wraps an AsyncReactor instance and provides testing-focused methods
 * that allow you to:
 * - Get the initial state of a reactor
 * - Send inputs directly and get the resulting state
 * - Test the complete data flow in isolation
 *
 * ## Usage Example
 *
 * ```swift
 * import XCTest
 * @testable import MyApp
 *
 * final class CounterReactorTests: XCTestCase {
 *     
 *     func testIncrement() async {
 *         // Given
 *         let reactor = CounterReactor()
 *         let stub = Stub(reactor: reactor)
 *         
 *         // When
 *         let newState = await stub.test(input: .increment)
 *         
 *         // Then
 *         XCTAssertEqual(newState.count, 1)
 *     }
 *     
 *     func testMultipleIncrements() async {
 *         // Given
 *         let reactor = CounterReactor()
 *         let stub = Stub(reactor: reactor)
 *         
 *         // When
 *         let state1 = await stub.test(input: .increment)
 *         let state2 = await stub.test(input: .increment)
 *         let state3 = await stub.test(input: .increment)
 *         
 *         // Then
 *         XCTAssertEqual(state1.count, 1)
 *         XCTAssertEqual(state2.count, 2)
 *         XCTAssertEqual(state3.count, 3)
 *     }
 *     
 *     func testInitialState() {
 *         // Given
 *         let reactor = CounterReactor()
 *         let stub = Stub(reactor: reactor)
 *         
 *         // When
 *         let initialState = stub.initialState()
 *         
 *         // Then
 *         XCTAssertEqual(initialState.count, 0)
 *     }
 * }
 * ```
 *
 * ## Testing Async Operations
 *
 * ```swift
 * final class UserReactorTests: XCTestCase {
 *     
 *     func testLoadUser() async {
 *         // Given
 *         let mockService = MockUserService()
 *         let reactor = UserReactor(userService: mockService)
 *         let stub = Stub(reactor: reactor)
 *         
 *         mockService.users["123"] = User(id: "123", name: "John Doe")
 *         
 *         // When
 *         let newState = await stub.test(input: .loadUser(id: "123"))
 *         
 *         // Then
 *         XCTAssertEqual(newState.user?.name, "John Doe")
 *         XCTAssertFalse(newState.isLoading)
 *         XCTAssertNil(newState.error)
 *     }
 *     
 *     func testLoadUserError() async {
 *         // Given
 *         let mockService = MockUserService()
 *         let reactor = UserReactor(userService: mockService)
 *         let stub = Stub(reactor: reactor)
 *         
 *         mockService.shouldThrowError = true
 *         
 *         // When
 *         let newState = await stub.test(input: .loadUser(id: "123"))
 *         
 *         // Then
 *         XCTAssertNil(newState.user)
 *         XCTAssertFalse(newState.isLoading)
 *         XCTAssertNotNil(newState.error)
 *     }
 * }
 * ```
 *
 * ## Testing Benefits
 *
 * - **Isolation**: Test business logic without UI dependencies
 * - **Speed**: Direct testing without view hierarchy setup
 * - **Predictability**: Control all inputs and verify exact outputs
 * - **Debugging**: Easy to step through the exact flow being tested
 */
public final class Stub<Reactor: AsyncReactor> {

    /// The reactor instance being tested
    private let reactor: Reactor

    /// Creates a new stub for testing the specified reactor.
    ///
    /// - Parameter reactor: The reactor to wrap for testing.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let reactor = MyReactor()
    /// let stub = Stub(reactor: reactor)
    /// ```
    public init(reactor: Reactor) {
        self.reactor = reactor
    }

    /// Returns the initial state of the wrapped reactor.
    ///
    /// This method provides access to the reactor's initial state for testing purposes.
    /// It's useful for verifying that your reactor starts with the correct default values.
    ///
    /// - Returns: The initial state of the reactor.
    ///
    /// ## Example
    ///
    /// ```swift
    /// func testInitialState() {
    ///     let stub = Stub(reactor: MyReactor())
    ///     let initialState = stub.initialState()
    ///     
    ///     XCTAssertEqual(initialState.count, 0)
    ///     XCTAssertFalse(initialState.isLoading)
    ///     XCTAssertNil(initialState.error)
    /// }
    /// ```
    public func initialState() -> Reactor.State {
        return self.reactor.initialState()
    }

    /// Sends an input to the reactor and returns the resulting state.
    ///
    /// This method executes the complete reactive flow:
    /// 1. Calls `reduce()` with the input
    /// 2. Calls `mutate()` with the resulting mutation
    /// 3. Updates the reactor's current state
    /// 4. Returns the new state
    ///
    /// - Parameter input: The input to send to the reactor.
    /// - Returns: The new state after processing the input.
    ///
    /// ## Example
    ///
    /// ```swift
    /// func testUserInput() async {
    ///     let stub = Stub(reactor: MyReactor())
    ///     
    ///     let newState = await stub.test(input: .buttonTapped)
    ///     
    ///     XCTAssertTrue(newState.buttonWasTapped)
    /// }
    /// ```
    ///
    /// ## Testing Sequential Operations
    ///
    /// ```swift
    /// func testSequentialInputs() async {
    ///     let stub = Stub(reactor: CounterReactor())
    ///     
    ///     let state1 = await stub.test(input: .increment)
    ///     XCTAssertEqual(state1.count, 1)
    ///     
    ///     let state2 = await stub.test(input: .increment)
    ///     XCTAssertEqual(state2.count, 2)
    ///     
    ///     let state3 = await stub.test(input: .decrement)
    ///     XCTAssertEqual(state3.count, 1)
    /// }
    /// ```
    @MainActor
    public func test(input: Reactor.Input) async -> Reactor.State {
        var resultState = self.initialState()
        for await state in await self.reactor.flow(input: input) {
            resultState = state
        }
        return resultState
    }
}
