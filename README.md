# AsyncReactorKit

[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS%20%7C%20macCatalyst-blue.svg)](https://swift.org)
[![SPM](https://img.shields.io/badge/SPM-Compatible-brightgreen.svg)](https://swift.org/package-manager)

AsyncReactorKit is a modern reactive architecture library for Swift applications that brings unidirectional data flow to the async/await era. Inspired by [ReactorKit](https://github.com/ReactorKit/ReactorKit), it leverages Swift Concurrency instead of RxSwift to provide a more straightforward and type-safe reactive programming experience.

## Overview

AsyncReactorKit reimagines reactive architecture for modern Swift development:

- **Swift Concurrency First**: Built from the ground up with async/await patterns
- **Type Safety**: Full Swift 6 concurrency compliance with `Sendable` guarantees  
- **Unidirectional Data Flow**: Clear separation between inputs, mutations, and state
- **Zero Dependencies**: Uses custom `DynamicTypeDictionary` instead of external reactive frameworks
- **Easy Testing**: Built-in testing utilities with `Stub` for isolated unit tests

## Key Differences from ReactorKit

| Feature | ReactorKit | AsyncReactorKit |
|---------|------------|-----------------|
| **Concurrency** | RxSwift Observables | Swift async/await |
| **State Storage** | WeakMapTable | DynamicTypeDictionary |
| **Swift Version** | Swift 5+ | Swift 6+ |
| **Dependencies** | RxSwift, RxCocoa | None |
| **Thread Safety** | Manual synchronization | Built-in Sendable compliance |
| **Learning Curve** | RxSwift knowledge required | Native Swift Concurrency |

## Installation

### Swift Package Manager

Add AsyncReactorKit to your project using Xcode or by adding it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/AsyncReactorKit.git", from: "1.0.0")
]
```

### Requirements

- iOS 13.0+ / macOS 11.0+ / macCatalyst 13.0+
- Swift 6.0+
- Xcode 16.0+

## Quick Start

### 1. Define a Reactor

```swift
import AsyncReactor

class CounterReactor: AsyncReactor {
    enum Input {
        case increment
        case decrement
        case reset
    }
    
    enum Mutation {
        case setCount(Int)
    }
    
    struct State: Sendable {
        @Pulse var count: Int = 0
        @Pulse var message: String?
    }
    
    nonisolated func initialState() -> State {
        State()
    }
    
    func reduce(_ input: Input) async -> Mutation {
        switch input {
        case .increment:
            return .setCount(currentState.count + 1)
        case .decrement:
            return .setCount(currentState.count - 1)
        case .reset:
            return .setCount(0)
        }
    }
    
    func mutate(_ state: State, mutation: Mutation) async -> State {
        var newState = state
        switch mutation {
        case .setCount(let count):
            newState.count = count
            newState.message = "Count updated to \(count)"
        }
        return newState
    }
}
```

### 2. Create a Store (UIKit)

```swift
import UIKit
import AsyncReactor

class CounterViewController: UIViewController, Store {
    typealias Reactor = CounterReactor
    
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var incrementButton: UIButton!
    @IBOutlet weak var decrementButton: UIButton!
    
    var reactor: CounterReactor?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        reactor = CounterReactor()
        setupActions()
    }
    
    private func setupActions() {
        incrementButton.addTarget(self, action: #selector(incrementTapped), for: .touchUpInside)
        decrementButton.addTarget(self, action: #selector(decrementTapped), for: .touchUpInside)
    }
    
    @objc private func incrementTapped() {
        send(.increment)
    }
    
    @objc private func decrementTapped() {
        send(.decrement)
    }
    
    // Store protocol implementation
    func state(_ state: CounterReactor.State) {
        state.$count.updated { [weak self] count in
            self?.countLabel.text = "\(count)"
        }
        
        state.$message.updated { [weak self] message in
            guard let message = message else { return }
            self?.showAlert(message)
        }
    }
}
```

### 3. SwiftUI Integration

> ⚠️ **Note**: SwiftUI integration is currently experimental and not officially supported. The API will be improved in future updates for better SwiftUI compatibility. The following example demonstrates a temporary workaround pattern.

```swift
import SwiftUI
import AsyncReactor

@MainActor
class CounterStore: ObservableObject, Store {
    typealias Reactor = CounterReactor
    
    @Published private(set) var currentState = CounterReactor.State()
    var reactor: CounterReactor?
    
    init() {
        reactor = CounterReactor()
    }
    
    func state(_ state: CounterReactor.State) {
        currentState = state
    }
}

struct CounterView: View {
    @StateObject private var store = CounterStore()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("\(store.currentState.count)")
                .font(.largeTitle)
            
            HStack {
                Button("−") { store.send(.decrement) }
                Button("+") { store.send(.increment) }
                Button("Reset") { store.send(.reset) }
            }
        }
        .padding()
    }
}
```

## Core Components

### AsyncReactor

The heart of the architecture, defining the reactive data flow:

```swift
protocol AsyncReactor: AnyObject {
    associatedtype Input: Sendable
    associatedtype Mutation: Sendable  
    associatedtype State: Sendable
    
    nonisolated func initialState() -> State
    func reduce(_ input: Input) async -> Mutation
    func mutate(_ state: State, mutation: Mutation) async -> State
}
```

### Store

Connects UI components to reactors:

```swift
protocol Store: AnyObject {
    associatedtype Reactor: AsyncReactor
    var reactor: Reactor? { get }
    func state(_ state: Reactor.State)
}
```

### Pulse

A property wrapper for state properties that trigger updates on every assignment:

```swift
struct State {
    @Pulse var alertMessage: String?  // Triggers even with same value
    var userData: User?               // Regular property
}
```

### Testing with Stub

```swift
func testIncrement() async {
    let reactor = CounterReactor()
    let stub = Stub(reactor: reactor)
    
    let newState = await stub.test(input: .increment)
    
    XCTAssertEqual(newState.count, 1)
}
```

## Architecture Principles

### Unidirectional Data Flow

```
User Action → Input → reduce() → Mutation → mutate() → State → UI Update
```

1. **Input**: User actions or external events
2. **reduce()**: Process inputs and handle side effects (API calls, etc.)
3. **Mutation**: Atomic state changes
4. **mutate()**: Apply mutations to create new state
5. **State**: Single source of truth for UI

### Thread Safety

- All types must conform to `Sendable`
- Automatic concurrency safety with internal synchronization
- Main thread UI updates handled automatically

### Testing

- **Stub**: Test reactors in isolation
- **Predictable**: Pure functions make testing straightforward
- **Fast**: No UI dependencies required

## Example Project

Check out the complete example in the `Example/` directory:

- **CounterApp**: Basic counter with increment/decrement
- **Advanced Features**: Pulse usage, async operations, testing

```bash
cd Example/AsyncReactorKitSample
open AsyncReactorKitSample.xcodeproj
```

## Migration from ReactorKit

| ReactorKit | AsyncReactorKit |
|------------|-----------------|
| `Action` | `Input` |
| `reactor.action.onNext(.action)` | `store.send(.input)` |
| `reactor.state.map(\.property)` | `state.$property.updated { }` |
| `Observable<State>` | Direct state updates via Store |
| `DisposeBag` | Not needed (automatic cleanup) |

## Dependencies

AsyncReactorKit uses a minimal dependency:

- **[DynamicTypeDictionary](https://github.com/pinguding/DynamicTypeDictionary)**: Type-safe storage solution replacing WeakMapTable

## License

AsyncReactorKit is available under the MIT license.

## Related Projects

- **[ReactorKit](https://github.com/ReactorKit/ReactorKit)**: The original RxSwift-based reactive architecture
- **[DynamicTypeDictionary](https://github.com/pinguding/DynamicTypeDictionary)**: Type-safe dictionary for dynamic type storage

---

Made with ❤️ for the Swift community