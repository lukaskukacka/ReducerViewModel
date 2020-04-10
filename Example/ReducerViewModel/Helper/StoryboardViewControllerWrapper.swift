//
//  Copyright © 2020 Lukas Kukacka. All rights reserved.
//

import SwiftUI
import UIKit

/// Simple wrapper to initializer view controller from Storyboard and wrap it for SwiftUI
struct StoryboardViewControllerWrapper<ViewController: UIViewController>: UIViewControllerRepresentable {

    typealias UIViewControllerType = ViewController
    typealias Configurator = (ViewController) -> Void

    let storyboard: UIStoryboard
    let configurator: Configurator?
    let viewControllerIdentifier: String

    init(viewControllerIdentifier: String, configurator: Configurator?, storyboard: UIStoryboard = .init(name: "Main", bundle: nil)) {
        self.viewControllerIdentifier = viewControllerIdentifier
        self.configurator = configurator
        self.storyboard = storyboard
    }

    func makeUIViewController(context: Context) -> ViewController {
        let viewController = self.storyboard.instantiateViewController(identifier: self.viewControllerIdentifier)
        assert(viewController as? ViewController != nil,
               "Loaded wrong type of View Controller using Storyboard ID '\(self.viewControllerIdentifier)'. Expected: \(type(of: ViewController.self)), Got: \(type(of: viewController))")

        let typedViewController =  viewController as! ViewController
        self.configurator?(typedViewController)
        return typedViewController
    }

    func updateUIViewController(_ uiViewController: ViewController, context: Context) {
        // Not supported by simple wrapper
    }
}
