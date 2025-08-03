//
//  Stub.swift
//  AsyncReactor
//
//  Created by 박종우 on 8/2/25.
//

import Foundation

public final class Stub<Reactor: AsyncReactor> {

    private let reactor: Reactor

    public init(reactor: Reactor) {
        self.reactor = reactor
    }

    public func initialState() -> Reactor.State {
        return self.reactor.initialState()
    }

    public func test(input: Reactor.Input) async -> Reactor.State {
        return await self.reactor.flow(input: input)
    }
}
