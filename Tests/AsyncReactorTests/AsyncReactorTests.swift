import Testing
@testable import AsyncReactor

@Suite("Class Type AsyncReatorTests")
struct ClassTypeAsyncReactorTestCases {
    @Test func sendInputShouldUpdateState() async throws {
        let reactor = TestTargetAsyncReactor_Class()
        let stub = Stub(reactor: reactor)
        
        let inputNumber = 5
        
        let state = await stub.test(input: .add(number: inputNumber))
        
        #expect(state.number == inputNumber)
    }

    @Test func multiInputReactorStateShouldPreserveResult() async throws {
        let reactor = TestTargetAsyncReactor_Class()
        let stub = Stub(reactor: reactor)

        let addNumber = 5
        let substractNumber = 3

        let firstState = await stub.test(input: .add(number: addNumber))
        let secondState = await stub.test(input: .substract(number: substractNumber))
        let thirdState = await stub.test(input: .add(number: addNumber))
        let forthState = await stub.test(input: .substract(number: substractNumber))
        #expect(firstState.number == addNumber)
        #expect(secondState.number == addNumber - substractNumber)
        #expect(thirdState.number == addNumber * 2 - substractNumber)
        #expect(forthState.number == addNumber * 2 - substractNumber * 2)
    }
}

@Suite("Actor Type AsyncReactorTests")
struct ActorTypeAsyncReactorTestCases {
    @Test func sendInputShouldUpdateState() async throws {
        let reactor = TestTargetAsyncReactor_Actor()
        let stub = Stub(reactor: reactor)

        let inputNumber = 5

        let state = await stub.test(input: .add(number: inputNumber))

        #expect(state.number == inputNumber)
    }

    @Test func multiInputReactorStateShouldPreserveResult() async throws {
        let reactor = TestTargetAsyncReactor_Actor()
        let stub = Stub(reactor: reactor)

        let addNumber = 5
        let substractNumber = 3

        let firstState = await stub.test(input: .add(number: addNumber))
        let secondState = await stub.test(input: .substract(number: substractNumber))
        let thirdState = await stub.test(input: .add(number: addNumber))
        let forthState = await stub.test(input: .substract(number: substractNumber))
        #expect(firstState.number == addNumber)
        #expect(secondState.number == addNumber - substractNumber)
        #expect(thirdState.number == addNumber * 2 - substractNumber)
        #expect(forthState.number == addNumber * 2 - substractNumber * 2)
    }
}
