//
//  Copyright © 2020 Lukas Kukacka. All rights reserved.
//

import SwiftUI

struct MainView: View {

    var body: some View {
        NavigationView {
            List {
                Section(header:
                    Text("""
                        This demo shows how the very same type / implementation of ViewModel can be used by both UIKit UIViewController and SwiftUI.

                        The main advange of this approach is that you can be building modern View Models which will work well with SwiftUI in future.

                        If you cannot drop iOS 12 support yet to use only SwiftUI, you can still keep using UIViewControllers with modern View Model implementation. When migrating to SwiftUI in future, View Model can stay untouched and you only need migrate UIViewController to SwiftUI, which should be quite simple and straighforward.
                        """).padding([.top, .bottom])
                ) {
                    NavigationLink(destination:
                        StoryboardViewControllerWrapper<ExampleUIViewControllerFromStoryboard>(
                            viewControllerIdentifier: "ExampleUIViewControllerFromStoryboard",
                            configurator: { $0.viewModel = ExampleViewModel() })
                    ) {
                        Row(title: "UIViewController example",
                            desctription: "Demo of using view model inside UIViewController")
                    }
                    // There is well know problem casuing a crash on some simualtors when going back. Ignoring for the sake of the demo
                    // See https://forums.developer.apple.com/thread/124757
                    NavigationLink(destination: ExampleSwiftUIView(wrappingViewModel: ExampleViewModel())) {
                        Row(title: "SwiftUI View example",
                            desctription: "Demo of using view model in SwiftUI View")
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitle("ReducerViewModel Demo", displayMode: .inline)
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}

private struct Row: View {
    let title: String
    let desctription: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(self.title)
                .font(.headline)
            Text(self.desctription)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
