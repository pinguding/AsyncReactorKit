//
//  TestTarget-class.swift
//  AsyncReactor
//
//  Created by 박종우 on 8/3/25.
//

import Foundation
import AsyncReactor

class TestTargetAsyncReactor_Class: AsyncReactor {

    enum Input {
        case add(number: Int)
        case substract(number: Int)
    }

    struct State {
        var number: Int
    }

    nonisolated func initialState() -> State {
        .init(number: .zero)
    }

    func reduce(_ input: Input) async -> Input {
        return input
    }

    func mutate(_ state: State, mutation: Input) async -> State {
        var newState = state
        switch mutation {
        case let .add(number):
            newState.number += number
        case let .substract(number):
            newState.number -= number
        }
        return newState
    }
}
