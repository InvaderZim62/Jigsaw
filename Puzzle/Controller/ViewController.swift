//
//  ViewController.swift
//  Puzzle
//
//  Created by Phil Stern on 4/21/23.
//

import UIKit

struct PuzzleConst {
    static let outerSize: CGFloat = 200  // including tabs
    static let innerRatio: CGFloat = 0.56
    static let innerSize = innerRatio * PuzzleConst.outerSize  // excluding tabs
    static let inset = (PuzzleConst.outerSize - PuzzleConst.innerSize) / 2
}

class ViewController: UIViewController {
    
    let image = UIImage(named: "tree")!  // eventually, this will come from the user's Photo library
    var pieceViews = [PieceView]()
    var panStartingPoint = CGPoint.zero

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let sides0: [Side] = [
            Side(type: .edge),
            Side.random(),
            Side.random(),
            Side(type: .edge),
        ]
        
        let sides1: [Side] = [
            Side(type: .edge),
            Side.random(),
            Side.random(),
            sides0[1].mate,
        ]
        
        let sides2: [Side] = [
            sides0[2].mate,
            Side.random(),
            Side.random(),
            Side(type: .edge),
        ]
        
        let sides3: [Side] = [
            sides1[2].mate,
            Side.random(),
            Side.random(),
            sides2[1].mate,
        ]
        
        let overlap = PuzzleConst.outerSize - PuzzleConst.innerSize
        let tiles = image.extractTiles(with: CGSize(width: PuzzleConst.outerSize, height: PuzzleConst.outerSize), overlap: overlap)!

        let row = Int(0.58 * Double(tiles.count))
        let col = Int(0.54 * Double(tiles[0].count))
        pieceViews.append(createPieceView(sides: sides0, image: tiles[row][col]))
        pieceViews.append(createPieceView(sides: sides1, image: tiles[row][col+1]))
        pieceViews.append(createPieceView(sides: sides2, image: tiles[row+1][col]))
        pieceViews.append(createPieceView(sides: sides3, image: tiles[row+1][col+1]))

        pieceViews[0].center = CGPoint(x: 150, y: 300)
        pieceViews[1].center = pieceViews[0].center.offsetBy(dx: PuzzleConst.innerSize, dy: 0)
        pieceViews[2].center = pieceViews[0].center.offsetBy(dx: 0, dy: PuzzleConst.innerSize)
        pieceViews[3].center = pieceViews[0].center.offsetBy(dx: PuzzleConst.innerSize, dy: PuzzleConst.innerSize)
    }
    
    func createPieceView(sides: [Side], image: UIImage) -> PieceView {
        let pieceView = PieceView(sides: sides, image: image)
        pieceView.frame = CGRect(x: 0, y: 0, width: PuzzleConst.innerSize, height: PuzzleConst.innerSize)
        pieceView.center = CGPoint(x: PuzzleConst.innerSize / 2, y: PuzzleConst.innerSize / 2)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        pieceView.isUserInteractionEnabled = true
        pieceView.addGestureRecognizer(pan)

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        doubleTap.numberOfTapsRequired = 2
        pieceView.addGestureRecognizer(doubleTap)

        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        singleTap.numberOfTapsRequired = 1
        pieceView.addGestureRecognizer(singleTap)
        singleTap.require(toFail: doubleTap)  // don't fire singleTap, unless doubleTap fails (this slows down singleTap response)

        view.addSubview(pieceView)

        return pieceView
    }

    @objc private func handlePan(recognizer: UIPanGestureRecognizer) {
        if let pieceView = recognizer.view as? PieceView {
            if recognizer.state == .began {
                panStartingPoint = pieceView.center  // pws: is there a version that doesn't require "startingPoint"? (see Tantrix)
                view.bringSubviewToFront(pieceView)
            }
            
            // move panned piece, limited to edges of screen
            let translation = recognizer.translation(in: view)
            let edgeInset = PuzzleConst.innerSize / 2
            pieceView.center = (panStartingPoint + translation)
                .limitedToView(view, withHorizontalInset: edgeInset, andVerticalInset: edgeInset)
            
            if recognizer.state == .ended {
            }
        }
    }
    
    // rotate piece +90 degrees for single-tap, -90 degrees for double-tap
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        if let pieceView = recognizer.view as? PieceView {
            view.bringSubviewToFront(pieceView)
            UIView.animate(withDuration: 0.2, animations: {
                pieceView.transform = pieceView.transform.rotated(by: recognizer.numberOfTapsRequired == 1 ? 90.CGrads : -90.CGrads)
            })
        }
    }

    // return nearby piece and which side of nearby piece is the mate
//    func nearbyMateFor(_ pieceView: PieceView) -> (PieceView, Int) {
//
//    }
}
