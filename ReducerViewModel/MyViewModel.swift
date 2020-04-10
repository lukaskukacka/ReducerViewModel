//
//  Created by Lukáš Kukačka on 10/04/2020.
//  Copyright © 2020 Lukas Kukacka. All rights reserved.
//

import UIKit

struct Feedback<State, Event> {
    typealias Builder = () -> Feedback<State, Event>

    // typealias Handler = (Event) -> Void
    typealias Completion = (Event) -> Void
    typealias Handler = (@escaping Completion) -> Void

    ////    let run: (State) -> Handler
    //    let state: State
    //    let handler: Handler

    let handler: (State) -> Handler?

    //    func run(state: State, handler: (Event?) -> Void) {
    //
    //    }
}

protocol ViewModel: class {
    associatedtype State
    associatedtype Event

    var state: Observable<State> { get }

    var feedbacks: [Feedback<State, Event>] { get }
    static func reduce(state: State, event: Event) -> State

    func receive(_ event: Event)
}

extension ViewModel {

    func receive(_ event: Event) {
        let newState = Self.reduce(state: self.state.value, event: event)

        for feedback in self.feedbacks {
            //            let handler = feedback.handler
            //            feedback.run(state: newState) { [weak self] (event) in
            //                if let event = event {
            //                    self?.receive(event)
            //                }
            //            }
            //            if let handler = feedback.handler(newState) {
            //                handler({ event in
            //                    self.receive(event)
            //                })
            //            }
            if let handler = feedback.handler(newState) {
                handler({ event in
                    self.receive(event)
                })
            }
        }

        self.state.value = newState
    }
}

class MyViewModel: ViewModel {

    enum State {
        case empty
        case loading
        case loaded([String])
        case error(Error)
    }

    enum Event {
        case add
        case failedToAdd(Error)
        case newValueLoaded(String)
        case refresh
    }

    let state = Observable<State>(value: .empty)

    lazy var feedbacks: [Feedback<State, Event>] = [
        self.onAdd()
    ]

    static func reduce(state: State, event: Event) -> State {
        switch state {
        case .empty, .loaded:
            switch event {
            case .add:
                return .loading
            case .refresh:
                return .empty
            case .failedToAdd, .newValueLoaded:
                return state
            }
        case .loading:
            switch event {
            case .newValueLoaded(let newValue):
                return .loaded([newValue])
            case .failedToAdd(let error):
                return .error(error)
            case .add, .refresh:
                return state
            }
        case .error:
            switch event {
            case .refresh:
                return .empty
            case .add, .failedToAdd, .newValueLoaded:
                return state
            }
        }
    }

    var onAdd: Feedback<State, Event>.Builder {
        return {
            Feedback { state in
                guard case State.loading = state else { return nil }

                return { completion in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        completion(.newValueLoaded(Date().description))
                    }
                }
            }
        }
    }
}
