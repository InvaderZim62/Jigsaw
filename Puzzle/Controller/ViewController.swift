//
//  ViewController.swift
//  Puzzle
//
//  Created by Phil Stern on 4/21/23.
//

import UIKit

struct PuzzleConst {
    static let pieceSize: CGFloat = 200
    static let offset = (1 - 2 * PieceConst.insetFactor) * PuzzleConst.pieceSize
}

class ViewController: UIViewController {
    
    let image = UIImage(named: "tree")!
    var pannedPieceStartingPoint = CGPoint.zero

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let sides1: [Side] = [
            .init(type: .edge),
            .init(type: .hole, tabPosition: 0.4),
            .init(type: .hole, tabPosition: 0.6),
            .init(type: .edge),
        ]
        
        let sides2: [Side] = [
            .init(type: .edge),
            .init(type: .knob, tabPosition: 0.4),
            .init(type: .knob, tabPosition: 0.5),
            .init(type: .knob, tabPosition: (1 - sides1[1].tabPosition)),
        ]
        
        let sides3: [Side] = [
            .init(type: .knob, tabPosition: (1 - sides1[2].tabPosition)),
            .init(type: .hole, tabPosition: 0.4),
            .init(type: .hole, tabPosition: 0.4),
            .init(type: .edge),
        ]
        
        let sides4: [Side] = [
            .init(type: .hole, tabPosition: (1 - sides2[2].tabPosition)),
            .init(type: .hole, tabPosition: 0.6),
            .init(type: .knob, tabPosition: 0.5),
            .init(type: .knob, tabPosition: (1 - sides3[1].tabPosition)),
        ]
        
        let overlap = 2 * PieceConst.insetFactor * PuzzleConst.pieceSize
        let tiles = image.extractTiles(with: CGSize(width: PuzzleConst.pieceSize, height: PuzzleConst.pieceSize), overlap: overlap)!

        let row = 12
        let col = 15
        let pieceView1 = createPieceView(sides: sides1, image: tiles[row][col])
        let pieceView2 = createPieceView(sides: sides2, image: tiles[row][col+1])
        let pieceView3 = createPieceView(sides: sides3, image: tiles[row+1][col])
        let pieceView4 = createPieceView(sides: sides4, image: tiles[row+1][col+1])

        // to access sides, use: (pieceView1.subviews[0] as? PieceView).sides
        pieceView1.center = CGPoint(x: 150, y: 300)
        pieceView2.center = pieceView1.center.offsetBy(dx: PuzzleConst.offset, dy: 0)
        pieceView3.center = pieceView1.center.offsetBy(dx: 0, dy: PuzzleConst.offset)
        pieceView4.center = pieceView1.center.offsetBy(dx: PuzzleConst.offset, dy: PuzzleConst.offset)
    }
    
    func createPieceView(sides: [Side], image: UIImage) -> UIView {
        let pannableView = UIView(frame: CGRect(x: 0, y: 0, width: PuzzleConst.offset, height: PuzzleConst.offset))
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        pannableView.isUserInteractionEnabled = true
        pannableView.addGestureRecognizer(panGesture)
        
        let pieceView = PieceView(sides: sides, image: image)
        pieceView.frame = CGRect(x: 0, y: 0, width: PuzzleConst.pieceSize, height: PuzzleConst.pieceSize)
        pieceView.center = CGPoint(x: PuzzleConst.offset / 2, y: PuzzleConst.offset / 2)

        pannableView.addSubview(pieceView)
        view.addSubview(pannableView)

        return pannableView
    }

    @objc private func handlePan(panRecognizer: UIPanGestureRecognizer) {
        if let pannedPieceView = panRecognizer.view {
            if panRecognizer.state == .began {
                pannedPieceStartingPoint = pannedPieceView.center
                view.bringSubviewToFront(pannedPieceView)
            }
            
            // move panned piece, limited to edges of screen (otherwise you won't be able to pan it back)
            let translation = panRecognizer.translation(in: view)
            let edgeInset = (0.5 - PieceConst.insetFactor) * PuzzleConst.pieceSize  // up to shoulder
            pannedPieceView.center = (pannedPieceStartingPoint + translation)
                .limitedToView(view, withHorizontalInset: edgeInset, andVerticalInset: edgeInset)
            
            if panRecognizer.state == .ended {
            }
        }
    }
}
