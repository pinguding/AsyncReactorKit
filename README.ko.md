# AsyncReactorKit

[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS%20%7C%20macCatalyst-blue.svg)](https://swift.org)
[![SPM](https://img.shields.io/badge/SPM-Compatible-brightgreen.svg)](https://swift.org/package-manager)

AsyncReactorKit은 단방향 데이터 플로우를 async/await 시대에 맞게 구현한 현대적인 반응형 아키텍처 라이브러리입니다. [ReactorKit](https://github.com/ReactorKit/ReactorKit)에서 영감을 받아 RxSwift 대신 Swift Concurrency를 활용하여 더욱 직관적이고 타입 안전한 반응형 프로그래밍 경험을 제공합니다.

## 개요

AsyncReactorKit은 현대적인 Swift 개발을 위한 반응형 아키텍처를 재정의합니다:

- **Swift Concurrency 우선**: async/await 패턴으로 처음부터 설계
- **타입 안전성**: Swift 6 동시성 준수 및 `Sendable` 보장
- **단방향 데이터 플로우**: 입력, 변이, 상태 간의 명확한 분리
- **의존성 제로**: 외부 반응형 프레임워크 대신 자체 `DynamicTypeDictionary` 사용
- **쉬운 테스팅**: 격리된 단위 테스트를 위한 `Stub` 내장

## ReactorKit과의 주요 차이점

| 기능 | ReactorKit | AsyncReactorKit |
|------|------------|-----------------|
| **동시성** | RxSwift Observable | Swift async/await |
| **상태 저장소** | WeakMapTable | DynamicTypeDictionary |
| **Swift 버전** | Swift 5+ | Swift 6+ |
| **의존성** | RxSwift, RxCocoa | 없음 |
| **스레드 안전성** | 수동 동기화 | 내장 Sendable 준수 |
| **학습 곡선** | RxSwift 지식 필요 | 네이티브 Swift Concurrency |

## 설치

### Swift Package Manager

Xcode를 사용하거나 `Package.swift`에 추가하여 AsyncReactorKit을 프로젝트에 추가하세요:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/AsyncReactorKit.git", from: "1.0.0")
]
```

### 요구사항

- iOS 13.0+ / macOS 11.0+ / macCatalyst 13.0+
- Swift 6.0+
- Xcode 16.0+

## 빠른 시작

### 1. Reactor 정의

```swift
import AsyncReactor

class CounterReactor: AsyncReactor {
    enum Input {
        case increment  // 증가
        case decrement  // 감소
        case reset      // 리셋
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
            newState.message = "카운트가 \(count)로 업데이트되었습니다"
        }
        return newState
    }
}
```

### 2. Store 생성 (UIKit)

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
    
    // Store 프로토콜 구현
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

### 3. SwiftUI 통합

> ⚠️ **참고**: SwiftUI 통합은 현재 실험적 기능으로 공식적으로 지원되지 않습니다. 향후 업데이트에서 더욱 편리한 SwiftUI 호환성을 위해 API가 개선될 예정입니다. 다음 예시는 임시 해결 방법 패턴을 보여줍니다.

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
                Button("리셋") { store.send(.reset) }
            }
        }
        .padding()
    }
}
```

## 핵심 컴포넌트

### AsyncReactor

아키텍처의 핵심으로, 반응형 데이터 플로우를 정의합니다:

```swift
protocol AsyncReactor: AnyObject {
    associatedtype Input: Sendable    // 입력
    associatedtype Mutation: Sendable // 변이
    associatedtype State: Sendable    // 상태
    
    nonisolated func initialState() -> State
    func reduce(_ input: Input) async -> Mutation
    func mutate(_ state: State, mutation: Mutation) async -> State
}
```

### Store

UI 컴포넌트를 reactor에 연결합니다:

```swift
protocol Store: AnyObject {
    associatedtype Reactor: AsyncReactor
    var reactor: Reactor? { get }
    func state(_ state: Reactor.State)
}
```

### Pulse

매번 할당될 때마다 업데이트를 트리거하는 상태 프로퍼티용 프로퍼티 래퍼:

```swift
struct State {
    @Pulse var alertMessage: String?  // 같은 값이어도 트리거
    var userData: User?               // 일반 프로퍼티
}
```

### Stub으로 테스팅

```swift
func testIncrement() async {
    let reactor = CounterReactor()
    let stub = Stub(reactor: reactor)
    
    let newState = await stub.test(input: .increment)
    
    XCTAssertEqual(newState.count, 1)
}
```

## 아키텍처 원칙

### 단방향 데이터 플로우

```
사용자 액션 → Input → reduce() → Mutation → mutate() → State → UI 업데이트
```

1. **Input**: 사용자 액션 또는 외부 이벤트
2. **reduce()**: 입력을 처리하고 사이드 이펙트 처리 (API 호출 등)
3. **Mutation**: 원자적 상태 변경
4. **mutate()**: 변이를 적용하여 새로운 상태 생성
5. **State**: UI를 위한 단일 정보원

### 스레드 안전성

- 모든 타입이 `Sendable`을 준수해야 함
- 내부 동기화를 통한 자동 동시성 안전성
- 메인 스레드 UI 업데이트 자동 처리

### 테스팅

- **Stub**: Reactor를 격리하여 테스트
- **예측 가능**: 순수 함수로 테스트가 간단함
- **빠름**: UI 의존성 불필요

## 예제 프로젝트

`Example/` 디렉터리에서 완전한 예제를 확인하세요:

- **CounterApp**: 증가/감소 기본 카운터
- **고급 기능**: Pulse 사용법, 비동기 작업, 테스팅

```bash
cd Example/AsyncReactorKitSample
open AsyncReactorKitSample.xcodeproj
```

## ReactorKit에서 마이그레이션

| ReactorKit | AsyncReactorKit |
|------------|-----------------|
| `Action` | `Input` |
| `reactor.action.onNext(.action)` | `store.send(.input)` |
| `reactor.state.map(\.property)` | `state.$property.updated { }` |
| `Observable<State>` | Store를 통한 직접 상태 업데이트 |
| `DisposeBag` | 불필요 (자동 정리) |

## 의존성

AsyncReactorKit은 최소한의 의존성을 사용합니다:

- **[DynamicTypeDictionary](https://github.com/pinguding/DynamicTypeDictionary)**: WeakMapTable을 대체하는 타입 안전 저장소 솔루션

## 라이선스

AsyncReactorKit은 MIT 라이선스 하에 제공됩니다.

## 관련 프로젝트

- **[ReactorKit](https://github.com/ReactorKit/ReactorKit)**: RxSwift 기반의 원본 반응형 아키텍처
- **[DynamicTypeDictionary](https://github.com/pinguding/DynamicTypeDictionary)**: 동적 타입 저장을 위한 타입 안전 딕셔너리

---

Swift 커뮤니티를 위해 ❤️로 제작했습니다