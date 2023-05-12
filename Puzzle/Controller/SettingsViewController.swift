//
//  SettingsViewController.swift
//  Puzzle
//
//  Created by Phil Stern on 5/3/23.
//
//  To do...
//  - handle boardView width better (use PuzzleConst.examplePuzzleWidth, make boardView.width constraint an outlet...)
//

import UIKit

enum PieceSizeSML: Int, Codable {
    case small, medium, large
}

class SettingsViewController: UIViewController {
    
    var allowsRotation: Bool!
    var isOutlined: Bool!
    var pieceSizeSML: PieceSizeSML!
    var updateSettings: (() -> Void)?  // callback
    var pieceViews = [PieceView]()

    private var outerSize: CGFloat!

    @IBOutlet weak var rotationSwitch: UISwitch!
    @IBOutlet weak var outlineSwitch: UISwitch!
    @IBOutlet weak var pieceSizeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var boardView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        rotationSwitch.isOn = allowsRotation
        outlineSwitch.isOn = isOutlined
        pieceSizeSegmentedControl.selectedSegmentIndex = pieceSizeSML.rawValue
        outerSize = boardView.bounds.width / CGFloat(5 - pieceSizeSML.rawValue) / PuzzleConst.innerRatio  // also in ViewController pieceSizeSML didSet
        createExamplePuzzle(outerSize)
    }
    
    override func willMove(toParent parent: UIViewController?) {
        updateSettings?()
    }
    
    func createExamplePuzzle(_ outerSize: CGFloat) {
        let innerSize = outerSize * PuzzleConst.innerRatio
        let dimension = Int(boardView.bounds.width / innerSize)
        let puzzle = Puzzle(rows: dimension, cols: dimension)
        
        pieceViews.forEach { $0.removeFromSuperview() }
        pieceViews.removeAll()

        for row in 0..<dimension {
            for col in 0..<dimension {
                let index = col + row * dimension
                let piece = puzzle.pieces[index]
                let colorImage = UIImage(color: .lightGray, size: CGSize(width: outerSize, height: outerSize))!
                let pieceView = PieceView(sides: piece.sides, image: colorImage, innerSize: innerSize, isOutlined: isOutlined)
                pieceView.frame = CGRect(x: 0, y: 0, width: innerSize, height: innerSize)
                pieceView.center = CGPoint(x: innerSize * (0.5 + CGFloat(col)),
                                           y: innerSize * (0.5 + CGFloat(row)))
                pieceViews.append(pieceView)
                boardView.addSubview(pieceView)
            }
        }
    }
    
    @IBAction func rotationSwitchChanged(_ sender: UISwitch) {
        allowsRotation = sender.isOn
    }
    
    @IBAction func outlineSwitchChanged(_ sender: UISwitch) {
        isOutlined = sender.isOn
        createExamplePuzzle(outerSize)
    }
    
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        pieceSizeSML = PieceSizeSML(rawValue: sender.selectedSegmentIndex)!
        outerSize = boardView.bounds.width / CGFloat(5 - pieceSizeSML.rawValue) / PuzzleConst.innerRatio
        createExamplePuzzle(outerSize)
    }
}
