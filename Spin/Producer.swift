//
//  Producer.swift
//  Spin
//
//  Created by Thibault Wittemberg on 2019-08-15.
//  Copyright © 2019 WarpFactor. All rights reserved.
//

public protocol Producer: ReactiveStream where Value: Command {
    associatedtype Input: Producer where Input.Value == Value, Input.Executer == Executer, Input.Lifecycle == Lifecycle

    //    func merge(function: () -> Input) -> AnyProducer<Input, Value, Executer, Lifecycle>
    //    func merge(input: Input) -> AnyProducer<Input, Value, Executer, Lifecycle>
    func executeAndScan(initial value: Value.State, reducer: @escaping (Value.State, Value.Stream.Value) -> Value.State) -> AnyConsumable<Value.State, Executer, Lifecycle>
    //    func spy(function: @escaping (Value) -> Void) -> AnyProducer<Input, Value, Executer, Lifecycle>
    func toReactiveStream() -> Input
}

public extension Producer {
    func eraseToAnyProducer() -> AnyProducer<Input, Value, Executer, Lifecycle> {
        return AnyProducer(producer: self)
    }
}

public extension Producer {
    func executeAndScan(initial value: Value.State,
                        reducer: @escaping (Value.State, Value.Stream.Value) -> Value.State,
                        spies: (Value.State, Value.Stream.Value) -> Void...) -> AnyConsumable<Value.State, Executer, Lifecycle> {
        let spiesAndReducer: (Value.State, Value.Stream.Value) -> Value.State = { (result, value) -> Value.State in
            spies.forEach { $0(result, value) }
            return reducer(result, value)
        }
        return self.executeAndScan(initial: value, reducer: spiesAndReducer)
    }
}

public final class AnyProducer<AnyInput: Producer, AnyValue, AnyExecuter, AnyLifecycle>: Producer
where AnyInput.Value == AnyValue, AnyInput.Executer == AnyExecuter, AnyInput.Lifecycle == AnyLifecycle {
    public typealias Input = AnyInput
    public typealias Value = AnyValue
    public typealias Executer = AnyExecuter
    public typealias Lifecycle = AnyLifecycle

    //    private let mergeClosureWithFunction: (() -> Input) -> AnyProducer<Input, Value, Executer, Lifecycle>
    //    private let mergeClosureWithInput: (Input) -> AnyProducer<Input, Value, Executer, Lifecycle>
    private let feedbackClosure: (Value.State, @escaping (Value.State, Value.Stream.Value) -> Value.State) -> AnyConsumable<Value.State, Executer, Lifecycle>
    //    private let spyClosure: (@escaping (Value) -> Void) -> AnyProducer<Input, Value, Executer, Lifecycle>
    private let toReactiveStreamClosure: () -> Input
    
    init<ProducerType: Producer>(producer: ProducerType)
        where ProducerType.Input == Input, ProducerType.Value == Value, ProducerType.Executer == Executer, ProducerType.Lifecycle == Lifecycle {
//            self.mergeClosureWithFunction = producer.merge(function:)
//            self.mergeClosureWithInput = producer.merge(input:)
            self.feedbackClosure = producer.executeAndScan
            //                        self.spyClosure = producer.spy
            self.toReactiveStreamClosure = producer.toReactiveStream
    }

//    public func merge(function: () -> AnyInput) -> AnyProducer<Input, Value, Executer, Lifecycle> {
//        return self.mergeClosureWithFunction(function)
//    }
//
//    public func merge(input: Input) -> AnyProducer<Input, Value, Executer, Lifecycle> {
//        return self.mergeClosureWithInput(input)
//    }

    public func executeAndScan(initial value: Value.State, reducer: @escaping (Value.State, Value.Stream.Value) -> Value.State) -> AnyConsumable<Value.State, Executer, Lifecycle> {
        return self.feedbackClosure(value, reducer)
    }

    //        public func spy(function: @escaping (Value) -> Void) -> AnyProducer<Input, Value, Executer, Lifecycle> {
    //            return self.spyClosure(function)
    //        }
    
    public func toReactiveStream() -> Input {
        return self.toReactiveStreamClosure()
    }

    public static func from(producer: Input) -> AnyProducer<Input.Input, Value, Executer, Lifecycle> {
        return producer.eraseToAnyProducer()
    }

    public static func from(function: () -> Input) -> AnyProducer<Input.Input, Value, Executer, Lifecycle> {
        return function().eraseToAnyProducer()
    }
}

public typealias Spinner = AnyProducer
