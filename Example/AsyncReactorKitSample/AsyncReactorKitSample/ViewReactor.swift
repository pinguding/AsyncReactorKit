//
//  ViewReactor.swift
//  AsyncReactor
//
//  Created by 박종우 on 8/3/25.
//

import Foundation
import AsyncReactor

final class ViewReactor: AsyncReactor, Sendable {

    enum Input {
        case increase
        case decrease
        case reset
    }

    enum Mutation {
        case addNumber(num: Int)
        case substract(num: Int)
        case getData(data: Data?, error: Error?)
        case reset
    }

    struct State : Sendable {
        @Pulse var number: Int = 0
        @Pulse var dataString: String = ""
        @Pulse var error: Error? = nil
        @Pulse var string: String = "This string should not changed"
    }

    nonisolated func initialState() -> State {
        return State()
    }

    func reduce(_ input: Input) -> [Task<Mutation, Never>] {
        switch input {
            case .increase:
            return [
                Task { return .addNumber(num: 1) },
                Task {
                    return await self.requestAPI()
                }
            ]
        case .decrease:
            return [
                Task { return .substract(num: 1) }
            ]
        case .reset:
            return [Task{ return .reset }]
        }
    }

    func mutate(_ state: State, mutation: Mutation) -> State {
        let newState = state
        switch mutation {
        case let .addNumber(num):
            newState.number += num
        case let .getData(data, error):
            if let data, let dataString = String(data: data, encoding: .utf8) {
                newState.dataString = dataString
            } else if let error {
                newState.error = error
            }
        case let .substract(num):
            newState.number -= num
        case .reset:
            newState.number = .zero
        }

        return newState
    }

    private func requestAPI() async -> Mutation {
        let response = try? await URLSession.shared.data(from: URL(string: "https://www.thecocktaildb.com/api/json/v1/1/search.php?s=margarita")!)
        guard let data = response?.0 else { return .getData(data: nil, error: URLError(.badServerResponse)) }
        return .getData(data: data, error: nil)
    }
}
