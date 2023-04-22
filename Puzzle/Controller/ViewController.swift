//
//  ViewController.swift
//  Puzzle
//
//  Created by Phil Stern on 4/21/23.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let pieceView = PieceView(frame: CGRect(x: 100, y: 100, width: 100, height: 100))
        pieceView.backgroundColor = .lightGray
        view.addSubview(pieceView)
    }
}
