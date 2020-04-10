//
//  Copyright © 2020 Lukas Kukacka. All rights reserved.
//

import SwiftUI

struct ExampleSwiftUIView: View {

    @ObservedObject var viewModel: AnyViewModel<ExampleViewModel>

    var body: some View {
        self.content
            .onAppear {
                if self.viewModel.state == .empty {
                    self.viewModel.receive(.reload)
                }
        }
        .navigationBarTitle("SwiftUI Example", displayMode: .inline)
        .navigationBarItems(trailing:
            HStack {
                Button(action: self.reload) {
                    Image(systemName: "arrow.clockwise").imageScale(.large)
                }
                .disabled(!self.viewModel.rawValue.canReload)
                .padding(.trailing)

                Button(action: self.reset) {
                    Image(systemName: "trash").imageScale(.large)
                }
                .disabled(!self.viewModel.rawValue.canReset)
            }
        )
    }

    private var content: AnyView {
        switch self.viewModel.state {
        case .empty:
            return AnyView(self.emptyView)
        case .loading:
            return AnyView(self.loadingContent)
        case .error(let error):
            return AnyView(self.makeEmptyView(error: error))
        case .loaded(let values):
            return AnyView(self.makeList(values: values))
        }
    }

    private var emptyView: some View {
        Text("No content\nUse the Reload ↻ button")
            .multilineTextAlignment(.center)
    }

    private var loadingContent: some View {
        VStack() {
            ActivityIndicator(style: .large, isAnimating: .constant(true))
            Text("Loading...")
        }
    }

    private func makeEmptyView(error: Error) -> some View {
        Text("Something went wrong\n\((error as NSError).localizedDescription)")
            .foregroundColor(.red)
    }

    private func makeList(values: [String]) -> some View {
        List(values, id: \.self) {
            Text($0)
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: User actions

extension ExampleSwiftUIView {

    func reload() {
        self.viewModel.receive(.reload)
    }

    func reset() {
        self.viewModel.receive(.reset)
    }
}

extension ExampleSwiftUIView {

    init(wrappingViewModel viewModel: ExampleViewModel) {
        self.init(viewModel: viewModel.eraseToAnyViewModel())
    }
}
