//
//  SettingsViewController.swift
//  Puzzle
//
//  Created by Phil Stern on 5/3/23.
//
//  To do...
//  - create a mini-puzzle to demonstrate the selected piece size.
//

import UIKit

enum PieceSizeSML: Int {
    case small, medium, large
}

class SettingsViewController: UIViewController {
    
    var pieceSizeSML: PieceSizeSML!
    var updateSettings: (() -> Void)?

    @IBOutlet weak var pieceSizeSegmentedControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pieceSizeSegmentedControl.selectedSegmentIndex = pieceSizeSML.rawValue
    }
    
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        pieceSizeSML = PieceSizeSML(rawValue: sender.selectedSegmentIndex)!
        updateSettings?()
    }
}
