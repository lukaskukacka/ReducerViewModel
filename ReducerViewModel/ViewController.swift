//
//  ViewController.swift
//  ReducerViewModel
//
//  Created by Lukáš Kukačka on 10/04/2020.
//  Copyright © 2020 Lukas Kukacka. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var label: UILabel!

    lazy var viewModel = MyViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.viewModel.state.setAndStartObserving { state in
            self.label.text = String(describing: state)
        }
    }

    @IBAction func refresh(_ sender: Any) {
        self.viewModel.receive(.refresh)
    }

    @IBAction func add(_ sender: Any) {
        self.viewModel.receive(.add)
    }
}

