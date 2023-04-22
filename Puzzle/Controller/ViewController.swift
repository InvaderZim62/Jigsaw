//
//  ViewController.swift
//  Puzzle
//
//  Created by Phil Stern on 4/21/23.
//

import UIKit

struct PuzzleConst {
    static let width: CGFloat = 100
}

class ViewController: UIViewController {
    
    let image = UIImage(named: "tree")!
//    let image = UIImage(named: "game")!

    override func viewDidLoad() {
        super.viewDidLoad()

        // bottom right corner
        let sides1: [Side] = [
            .init(type: .knob, tabPosition: 0.4),
            .init(type: .hole, tabPosition: 0.4),
            .init(type: .hole, tabPosition: 0.6),
            .init(type: .knob, tabPosition: 0.4),
        ]
        
        let sides2: [Side] = [
            .init(type: .hole, tabPosition: 0.4),
            .init(type: .edge),
            .init(type: .knob, tabPosition: 0.5),
            .init(type: .knob, tabPosition: (1 - sides1[1].tabPosition)),
        ]
        
        let sides3: [Side] = [
            .init(type: .knob, tabPosition: (1 - sides1[2].tabPosition)),
            .init(type: .hole, tabPosition: 0.4),
            .init(type: .edge),
            .init(type: .hole, tabPosition: 0.5),
        ]
        
        let sides4: [Side] = [
            .init(type: .hole, tabPosition: (1 - sides2[2].tabPosition)),
            .init(type: .edge),
            .init(type: .edge),
            .init(type: .knob, tabPosition: (1 - sides3[1].tabPosition)),
        ]
        
//        // top left corner
//        let sides1: [Side] = [
//            .init(type: .edge),
//            .init(type: .hole, tabPosition: 0.4),
//            .init(type: .hole, tabPosition: 0.6),
//            .init(type: .edge),
//        ]
//
//        let sides2: [Side] = [
//            .init(type: .edge),
//            .init(type: .hole, tabPosition: 0.4),
//            .init(type: .knob, tabPosition: 0.5),
//            .init(type: .knob, tabPosition: (1 - sides1[1].tabPosition)),
//        ]
//
//        let sides3: [Side] = [
//            .init(type: .knob, tabPosition: (1 - sides1[2].tabPosition)),
//            .init(type: .hole, tabPosition: 0.4),
//            .init(type: .hole, tabPosition: 0.4),
//            .init(type: .edge),
//        ]
//
//        let sides4: [Side] = [
//            .init(type: .hole, tabPosition: (1 - sides2[2].tabPosition)),
//            .init(type: .hole, tabPosition: 0.4),
//            .init(type: .knob, tabPosition: 0.5),
//            .init(type: .knob, tabPosition: (1 - sides3[1].tabPosition)),
//        ]
        
        let overlap = 2 * PieceConst.insetFactor * PuzzleConst.width
        let tiles = image.extractTiles(with: CGSize(width: PuzzleConst.width, height: PuzzleConst.width), overlap: overlap)!

        // bottom right corner
        let row = tiles.count - 2
        let col = tiles[0].count - 2
//        // top left corner
//        let row = 0
//        let col = 0
        let pieceView1 = createPieceView(sides: sides1, image: tiles[row][col])
        let pieceView2 = createPieceView(sides: sides2, image: tiles[row][col+1])
        let pieceView3 = createPieceView(sides: sides3, image: tiles[row+1][col])
        let pieceView4 = createPieceView(sides: sides4, image: tiles[row+1][col+1])

        let offset = (1 - 2 * PieceConst.insetFactor) * PuzzleConst.width
        pieceView1.center = CGPoint(x: 150, y: 200)
        pieceView2.center = pieceView1.center.offsetBy(dx: offset, dy: 0)
        pieceView3.center = pieceView1.center.offsetBy(dx: 0, dy: offset)
        pieceView4.center = pieceView1.center.offsetBy(dx: offset, dy: offset)

        let imageView1 = UIImageView(image: tiles[row][col])
        imageView1.frame = CGRect(x: 0, y: 450, width: PuzzleConst.width, height: PuzzleConst.width)
        imageView1.backgroundColor = .red
        view.addSubview(imageView1)
        
        let imageView2 = UIImageView(image: tiles[row][col+1])
        imageView2.frame = CGRect(x: 0 + PuzzleConst.width, y: 450, width: PuzzleConst.width, height: PuzzleConst.width)
        imageView2.backgroundColor = .red
        view.addSubview(imageView2)
        
        let imageView3 = UIImageView(image: tiles[row+1][col])
        imageView3.frame = CGRect(x: 0, y: 450 + PuzzleConst.width, width: PuzzleConst.width, height: PuzzleConst.width)
        imageView3.backgroundColor = .red
        view.addSubview(imageView3)
        
        let imageView4 = UIImageView(image: tiles[row+1][col+1])
        imageView4.frame = CGRect(x: 0 + PuzzleConst.width, y: 450 + PuzzleConst.width, width: PuzzleConst.width, height: PuzzleConst.width)
        imageView4.backgroundColor = .red
        view.addSubview(imageView4)
    }
    
    func createPieceView(sides: [Side], image: UIImage) -> PieceView {
        let pieceView = PieceView(sides: sides, image: image)
        pieceView.frame = CGRect(x: 0, y: 0, width: PuzzleConst.width, height: PuzzleConst.width)
        view.addSubview(pieceView)
        return pieceView
    }
}
