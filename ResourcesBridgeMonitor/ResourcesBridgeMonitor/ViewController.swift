//
//  ViewController.swift
//  ResourcesBridgeMonitor
//
//  Created by Eugene Bokhan on 5/31/20.
//  Copyright © 2020 Eugene Bokhan. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    let monitor = try! ResourcesBridgeMonitor()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

