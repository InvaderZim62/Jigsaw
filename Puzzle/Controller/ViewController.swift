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
    var pieces = [Piece]()
    var pieceViews = [Piece: PieceView]()
    var pannedPieceInitialCenter = CGPoint.zero
    
    @IBOutlet weak var playView: UIView!
    
    // MARK: - Start of code

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
        
        pieces.append(Piece(sides: sides0))
        pieces.append(Piece(sides: sides1))
        pieces.append(Piece(sides: sides2))
        pieces.append(Piece(sides: sides3))

        let overlap = PuzzleConst.outerSize - PuzzleConst.innerSize
        let tiles = image.extractTiles(with: CGSize(width: PuzzleConst.outerSize, height: PuzzleConst.outerSize), overlap: overlap)!

        let row = Int(0.58 * Double(tiles.count))  // branching part of tree
        let col = Int(0.54 * Double(tiles[0].count))
        
        pieceViews[pieces[0]] = createPieceView(sides: pieces[0].sides, image: tiles[row][col])
        pieceViews[pieces[1]] = createPieceView(sides: pieces[1].sides, image: tiles[row][col+1])
        pieceViews[pieces[2]] = createPieceView(sides: pieces[2].sides, image: tiles[row+1][col])
        pieceViews[pieces[3]] = createPieceView(sides: pieces[3].sides, image: tiles[row+1][col+1])

        pieceViews[pieces[0]]!.center = CGPoint(x: 150, y: 300)
        pieceViews[pieces[1]]!.center = pieceViews[pieces[0]]!.center.offsetBy(dx: PuzzleConst.innerSize, dy: 0)
        pieceViews[pieces[2]]!.center = pieceViews[pieces[0]]!.center.offsetBy(dx: 0, dy: PuzzleConst.innerSize)
        pieceViews[pieces[3]]!.center = pieceViews[pieces[0]]!.center.offsetBy(dx: PuzzleConst.innerSize, dy: PuzzleConst.innerSize)
    }
    
    // create pieceView with pan, double-tap, and single-tap gestures; add to playView
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

        playView.addSubview(pieceView)

        return pieceView
    }

    // MARK: - Gestures

    @objc private func handlePan(recognizer: UIPanGestureRecognizer) {
        if let pannedPieceView = recognizer.view as? PieceView {
            if recognizer.state == .began {
                pannedPieceInitialCenter = pannedPieceView.center
                view.bringSubviewToFront(pannedPieceView)
            }
            
            // move panned piece, limited to edges of screen
            let translation = recognizer.translation(in: playView)
            let edgeInset = PuzzleConst.innerSize / 2
            pannedPieceView.center = (pannedPieceInitialCenter + translation)
                .limitedToView(playView, withHorizontalInset: edgeInset, andVerticalInset: edgeInset)
            
            if recognizer.state == .ended {
            }
        }
    }
    
    // rotate piece +90 degrees for single-tap, -90 degrees for double-tap (animated)
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        if let tappedPieceView = recognizer.view as? PieceView {
            view.bringSubviewToFront(tappedPieceView)
            UIView.animate(withDuration: 0.2, animations: {
                tappedPieceView.transform = tappedPieceView.transform.rotated(by: recognizer.numberOfTapsRequired == 1 ? 90.CGrads : -90.CGrads)
            })
            // update model
            pieces[pieceIndex(from: tappedPieceView)].rotation = tappedPieceView.rotation
        }
    }
    
    // MARK: - Utilities
    
    func pieceIndex(from pieceView: PieceView) -> Int {
        let piece = pieceViews.someKey(forValue: pieceView)!  // copy of struct (don't manipulate)
        return pieces.index(matching: piece)!
    }

    // return nearby piece and which side of nearby piece is the mate
//    func nearbyMateFor(_ pieceView: PieceView) -> (PieceView, Int) {
//
//    }
}
