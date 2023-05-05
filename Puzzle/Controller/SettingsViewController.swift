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
    @IBOutlet weak var boardView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pieceSizeSegmentedControl.selectedSegmentIndex = pieceSizeSML.rawValue
        createExamplePuzzle(outerSize: 150)
    }
    
    func createExamplePuzzle(outerSize: CGFloat) {
        let puzzle = Puzzle(rows: 3, cols: 3)
        let innerSize = outerSize * PuzzleConst.innerRatio

        for row in 0..<3 {
            for col in 0..<3 {
                let index = col + row * 3
                let piece = puzzle.pieces[index]
                let whiteImage = UIImage(color: .white, size: CGSize(width: outerSize, height: outerSize))!
                let pieceView = PieceView(sides: piece.sides, image: whiteImage, innerSize: innerSize)
                pieceView.frame = CGRect(x: 0, y: 0, width: innerSize, height: innerSize)
                pieceView.center = CGPoint(x: innerSize * (0.5 + CGFloat(col)),
                                           y: innerSize * (0.5 + CGFloat(row)))
                boardView.addSubview(pieceView)
            }
        }
    }
    
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        pieceSizeSML = PieceSizeSML(rawValue: sender.selectedSegmentIndex)!
        updateSettings?()
    }
}
