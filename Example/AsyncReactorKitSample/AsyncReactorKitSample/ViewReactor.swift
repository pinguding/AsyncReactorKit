//
//  ViewReactor.swift
//  AsyncReactor
//
//  Created by 박종우 on 8/3/25.
//

import Foundation
import AsyncReactor

class ViewReactor: AsyncReactor {

    enum Input {
        case increase
        case decrease
        case reset
    }

    enum Mutation {
        case addNumber(num: Int)
        case substract(num: Int)
        case reset
    }

    struct State {
        @Pulse var number: Int = 0
        @Pulse var string: String = "This string should not changed"
    }

    nonisolated func initialState() -> State {
        return State()
    }

    func reduce(_ input: Input) async -> Mutation {
        switch input {
            case .increase:
            return .addNumber(num: 1)
        case .decrease:
            return .substract(num: 1)
        case .reset:
            return .reset
        }
    }

    func mutate(_ state: State, mutation: Mutation) async -> State {
        let newState = state
        switch mutation {
        case let .addNumber(num):
            newState.number += num
        case let .substract(num):
            newState.number -= num
        case .reset:
            newState.number = .zero
        }

        return newState
    }
}
