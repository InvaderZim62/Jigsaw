//
//  ViewController.swift
//  Puzzle
//
//  Created by Phil Stern on 4/21/23.
//

import UIKit

struct PuzzleConst {
    static let width: CGFloat = 200
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let sides1: [Side] = [
            .init(shape: .tab, tabPosition: 0.4),
            .init(shape: .hole, tabPosition: 0.4),
            .init(shape: .hole, tabPosition: 0.6),
            .init(shape: .tab, tabPosition: 0.4),
        ]
        
        let sides2: [Side] = [
            .init(shape: .hole, tabPosition: 0.4),
            .init(shape: .flat),
            .init(shape: .tab, tabPosition: 0.5),
            .init(shape: .tab, tabPosition: (1 - sides1[1].tabPosition)),
        ]
        
        let sides3: [Side] = [
            .init(shape: .tab, tabPosition: (1 - sides1[2].tabPosition)),
            .init(shape: .hole, tabPosition: 0.4),
            .init(shape: .flat),
            .init(shape: .hole, tabPosition: 0.5),
        ]
        
        let sides4: [Side] = [
            .init(shape: .hole, tabPosition: (1 - sides2[2].tabPosition)),
            .init(shape: .flat),
            .init(shape: .flat),
            .init(shape: .tab, tabPosition: (1 - sides3[1].tabPosition)),
        ]
        
        let offset = (1 - 2 * PieceConst.insetFactor) * PuzzleConst.width
        let piece1Center = CGPoint(x: 150, y: 400)
        let piece2Center = piece1Center.offsetBy(dx: offset, dy: 0)
        let piece3Center = piece1Center.offsetBy(dx: 0, dy: offset)
        let piece4Center = piece1Center.offsetBy(dx: offset, dy: offset)

        createPieceView(sides: sides1, position: piece1Center, color: .blue)
        createPieceView(sides: sides2, position: piece2Center, color: .yellow)
        createPieceView(sides: sides3, position: piece3Center, color: .green)
        createPieceView(sides: sides4, position: piece4Center, color: .red)
    }
    
    func createPieceView(sides: [Side], position: CGPoint, color: UIColor) {
        let pieceView = PieceView()
        pieceView.piece = Piece(sides: sides)
        pieceView.frame = CGRect(x: 0, y: 0, width: PuzzleConst.width, height: PuzzleConst.width)
        pieceView.center = position
        pieceView.backgroundColor = .clear
        pieceView.color = color
        view.addSubview(pieceView)
    }
}
