//
//  Copyright © 2020 Lukas Kukacka. All rights reserved.
//

import Foundation

final class ExampleViewModel: ViewModel {

    // MARK: State & Event

    enum State: Equatable {
        case empty
        case loading
        case loaded([String])
        case error(Error)

        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.empty, .empty),
                 (.loading, .loading):
                return true
            case (.loaded(let lhsContent), .loaded(let rhsContent)):
                return lhsContent == rhsContent
            case (.error(let lhsError), .error(let rhsError)):
                return (lhsError as NSError == rhsError as NSError)
            case (_, _):
                return false
            }
        }
    }

    enum Event {
        case reload
        case reset
        case failed(Error)
        case finishedLoading([String])
    }

    // MARK: ViewModelProtocol

    private(set) var state: State = .empty
    var onStateChanged: StateChangeHandler?

    func stateChanged(from oldState: State, to newState: State) {
        self.state = newState
        self.onStateChanged?(oldState, newState)
    }

    lazy var feedbacks: [Feedback<ExampleViewModel, State>] = [
        self.onLoading
    ]

    static func reduce(state: State, event: Event) -> State {
        switch (state, event) {
        case (_, .reload):
            return .loading
        case (_, .reset):
            return .empty
        case (_, .finishedLoading(let newValue)):
                return .loaded(newValue)
        case (_, .failed(let error)):
            return .error(error)
        }
    }

    // MARK: Feedbacks

    let onLoading = Feedback<ExampleViewModel, State> { viewModel, state in
        // Start loading on transition to Loading state
        guard case State.loading = state else { return }

        // Mock some delay like if there was a network call. Actual network call is out of scope of the demo.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak viewModel] in
            guard let viewModel = viewModel else { return }
            // State changed meanwhile (i.e. clean while loading, ignore fetched data
            guard viewModel.state == state else { return }
            let dateString = Date().description
            let values: [String] = (0..<10).map { String("\($0): \(dateString)") }
            viewModel.receive(.finishedLoading(values))
        }
    }
}

extension ExampleViewModel {

    var canReload: Bool {
        switch self.state {
        case .empty, .error, .loaded: return true
        case .loading: return false
        }
    }

    var canReset: Bool {
        switch self.state {
        case .loaded: return true
        case .empty, .error, .loading: return false
        }
    }
}

extension ExampleViewModel.State {

    var values: [String]? {
        switch self {
        case .loaded(let values): return values
        default: return nil
        }
    }
}
