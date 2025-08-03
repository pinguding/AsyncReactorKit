//
//  Store.swift
//  AsyncReactor
//
//  Created by 박종우 on 8/2/25.
//

import DynamicTypeDictionary

public protocol Store: AnyObject {

    associatedtype Reactor: AsyncReactor

    var reducer: Reactor? { get }

    func state(_ state: Reactor.State)
}

public extension Store {

    func send(_ input: Reactor.Input) async {
        guard let reducer = self.reducer else { return }
        let state = await reducer.flow(input: input)
        self.state(state)
    }
}

