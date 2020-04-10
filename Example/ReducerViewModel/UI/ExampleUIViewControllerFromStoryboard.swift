//
//  Copyright © 2020 Lukas Kukacka. All rights reserved.
//

import UIKit

class ExampleUIViewControllerFromStoryboard: UIViewController {

    /// Storyboard does not allow better dependency injection.
    /// Without using Storybpard, this should be `let` injected in `init`
    var viewModel: ExampleViewModel!

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var acitivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var label: UILabel!

    @IBOutlet weak var reloadNavigationItem: UIBarButtonItem!
    @IBOutlet weak var resetNavigationItem: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "UIViewController example"

        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.tableView.dataSource = self

        self.setUpObservers()

        // Start loading view model immediatelly
        if self.viewModel.state == .empty {
            self.viewModel.receive(.reload)
        }

        self.setUpViews(forState: self.viewModel.state)
    }

    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)

        /// Bit of hack for `UIViewControllerRepresentable`
        /// See https://stackoverflow.com/a/59317657
        /// There is some glitch in the animation, but that is not concern of this demo
        parent?.navigationItem.title = self.title
        parent?.navigationItem.rightBarButtonItems = self.navigationItem.rightBarButtonItems
    }
}

// MARK: Observers

extension ExampleUIViewControllerFromStoryboard {

    func setUpObservers() {
        // React to state changes.
        // Here similarly to SwiftUI, we configure view according to state
        self.viewModel.onStateChanged = { [weak self] _, newState in
            self?.setUpViews(forState: newState)
        }
    }
}

// MARK: User actions

extension ExampleUIViewControllerFromStoryboard {

    @IBAction func reload(_ sender: Any) {
        self.viewModel.receive(.reload)
    }

    @IBAction func reset(_ sender: Any) {
        self.viewModel.receive(.reset)
    }
}

// MARK: UITableViewDataSource

extension ExampleUIViewControllerFromStoryboard: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.state.values?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        let value = self.viewModel.state.values![indexPath.row]
        cell.textLabel?.text = value
        return cell
    }
}

// MARK: Private

private extension ExampleUIViewControllerFromStoryboard {

    func setUpViews(forState state: ExampleViewModel.State) {
        self.resetViews()

        switch state {
        case .empty:
            self.label.text = "No content\nUse the Reload ↻ button"
        case .loading:
            self.label.text = "Loading..."
            self.acitivityIndicator.startAnimating()
        case .error(let error):
            let errorDescription = (error as NSError).localizedDescription
            self.label.text = "Something went wrong\n\(errorDescription)"
        case .loaded:
            self.tableView.reloadData()
            self.tableView.isHidden = false
        }

        self.label.isHidden = (self.label.text == nil)
        self.reloadNavigationItem.isEnabled = self.viewModel.canReload
        self.resetNavigationItem.isEnabled = self.viewModel.canReset
    }

    func resetViews() {
        self.tableView.isHidden = true
        self.acitivityIndicator.stopAnimating()
        self.label.isHidden = true
        self.label.text = nil
    }

}
