//
//  MIT License
//
//  Copyright (c) 2020 Lukas Kukacka
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation

// MARK: ViewModel definitions

/// Feedback provides a way to react to changes in state of a View Model
/// It can start async loading from network, write to disk, etc.
public struct Feedback<VM: ViewModel, State> where VM.State == State {

    /// Handler executed automatically by `ViewModel` when `viewModel.state`
    /// changes to a new value.
    ///
    /// The handler is executed synchronously when state changes.
    ///
    /// - Warning: Handler is called for any state. Each `Feedback` must decide which state changes reacts to (i.e. something like `guard state == someExpectedState else { return }`
    public let handler: ((VM, State) -> Void)
}


/// Basic definition of a View Model based on `State`, `Event` and `reduce()` function for transitioning from one state to another.
///
/// ### Information flow diagram
/// ```
///  +--------------------+     +--------------+
///  |        View        |     |              |
///  |  UIViewController  |     |  View Model  |
///  |  SwiftUI View      |     |              |
///  +-----+--------------+     +------+-------+
///        |                           |
///        +----- receive(event) ------>
///        |                           +----+
///        |                           |    | 1. execute Feedbacks
///        |                           <----+
///        |                           |
///        |                           +----+
///        |                           |    | 2. self.stateChanged()
///        |                           |    |   1. update self.state
///        <-- stateChanged(old,new) --+    |   2. notify state change
///        |                           <----+
///        +----+                      |
///        |    | update UI            |
///        <----+                      |
///        |                           |
/// ```
public protocol ViewModel: class {

    /// Enum is a perfect representation for `State`.
    /// View Model is always in exactly one state at any given time.
    associatedtype State: Equatable

    /// Enum works really well for `Event` because only one event (action)
    /// at a time can be received (handled).
    associatedtype Event

    /// Prototype of closure callback for state changes.
    /// Arguments: (old state, new state)
    typealias StateChangeHandler = (State, State) -> Void

    /// Current state of a view model
    var state: State { get }

    /// Callback executed when a value of `self.state` changes.
    /// This being a callback instead of some reactive type (i.e. from Combine)
    /// is to keep the backwards compatibility for pre-Combine codebase
    /// and keep everything simple.
    var onStateChanged: StateChangeHandler? { get set }

    /// `Feedback`s associated with this type of view model.
    var feedbacks: [Feedback<Self, State>] { get }

    /// Decides how View Model's state changes in response to an `Event` (action) performed.
    ///
    /// This is `static` function so it becomes pure and has no way to perform
    /// side effects on View Model instance itself. This guarantees clean
    /// unidirectional flow of data by eliminating any changes for hidden
    /// side-effects.
    ///
    /// It is common to just return passed in `state` if given `event`
    /// does not have any impact in given `state`.
    ///
    /// - Parameters:
    ///   - state: Current state of a view model
    ///   - event: Action performed on view model
    /// - Returns: State in which a View Model should be after the `event` is performed while View Model is in given `state`.
    static func reduce(state: State, event: Event) -> State

    /// Method to receive (apply) `event` (action) to a View Model instance.
    ///
    /// This is the only entrance point for any modification of View Model's
    /// `state`. Any modification of state must go through unidirectional
    /// flow  of `receive(someEvent) -> `
    ///
    /// There is a default implementation which already does everything needed:
    /// uses `reduce(state:event:)` to get new state and if it means state change,
    /// it executes feedbacks and calls `self.stateChanged(from:to:)`
    func receive(_ event: Event)

    /// Method to update `state` and notify using `onStateChanged`.
    ///
    /// This has to be implemented by each concrete `ViewModel`.
    /// This is a compromise to keep View Model truly immutable from the outside.
    ///
    /// This is automatically called by default implementation of `receive(_:)`
    /// every receiving event produces new state according to `reduce(state:event:)`
    ///
    /// Each View Model must define `state {get}` and it is recommended to use
    /// `private(set) var state...` so the state can only be modified from
    /// inside of the View Model implementation. There is no better simple way
    /// to do this at the moment.
    ///
    /// This code can be idiomatic boilerplate like this:
    /// ```
    /// private(set) var state: State = .empty // any default value
    /// ...
    /// func stateChanged(from oldState: State, to newState: State) {
    ///    self.state = newState
    ///    self.onStateChanged?(oldState, newState)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - oldState: Old state
    ///   - newState: New state
    func stateChanged(from oldState: State, to newState: State)
}

// MARK: Default implementations

extension ViewModel {

    func receive(_ event: Event) {
        let oldState = self.state
        let newState = Self.reduce(state: oldState, event: event)

        guard oldState != newState else { return }

        self.feedbacks.forEach {
            $0.handler(self, newState)
        }

        self.stateChanged(from: oldState, to: newState)
    }
}

// MARK: - SwiftUI support

#if canImport(Combine)

/// Type-erasure wrapper for `ViewModel` which can be used as state `@ObservedObject` on SwiftUI Views.
@available(iOS 13.0, *)
final class AnyViewModel<VM: ViewModel>: ViewModel, RawRepresentable, ObservableObject {

    let rawValue: VM

    init(rawValue viewModel: VM) {
        self.rawValue = viewModel
        self.observableState = viewModel.state

        viewModel.onStateChanged = { [weak self] (_, newState) in
            self?.observableState = newState
        }
    }

    deinit {
        self.rawValue.onStateChanged = nil
    }

    // MARK: ViewModelProtocol erasure

    typealias State = VM.State
    typealias Event = VM.Event

    var state: State { self.rawValue.state }

    var onStateChanged: StateChangeHandler? {
        get { self.rawValue.onStateChanged }
        set { self.rawValue.onStateChanged = newValue }
    }

    var feedbacks: [Feedback<AnyViewModel<VM>, VM.State>] {
        /// This not very elegant, but it is a price for simpler API of `Feedback`
        self.rawValue.feedbacks.map { $0.eraseToAnyViewModel() }
    }

    static func reduce(state: State, event: Event) -> State {
        return VM.reduce(state: state, event: event)
    }

    func stateChanged(from oldState: State, to newState: State) {
        self.rawValue.stateChanged(from: oldState, to: newState)
    }

    // MARK: SwiftUI support

    @Published private(set) var observableState: State
}

// MARK: Type erasure

@available(iOS 13.0, *)
extension ViewModel {

    func eraseToAnyViewModel() -> AnyViewModel<Self> {
        return AnyViewModel(rawValue: self)
    }
}

@available(iOS 13.0, *)
extension Feedback {

    func eraseToAnyViewModel() -> Feedback<AnyViewModel<VM>, State> {
        return Feedback<AnyViewModel<VM>, State> { anyViewModel, state in
            self.handler(anyViewModel.rawValue, state)
        }
    }
}

#endif
