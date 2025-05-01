import Combine

public extension Publisher {
    static func just(_ output: Output) -> AnyPublisher<Output, Failure> {
        Just(output).setFailureType(to: Failure.self).eraseToAnyPublisher()
    }

    static func empty() -> AnyPublisher<Output, Failure> {
        Empty(outputType: Output.self, failureType: Failure.self).eraseToAnyPublisher()
    }

    static func fail(_ error: Failure) -> AnyPublisher<Output, Failure> {
        Fail(error: error).eraseToAnyPublisher()
    }

    func mapToVoid() -> AnyPublisher<Void, Failure> {
        map { _ in () }.eraseToAnyPublisher()
    }

    func mapTo(_ output: Output) -> AnyPublisher<Output, Failure> {
        map { _ in output }.eraseToAnyPublisher()
    }
}
