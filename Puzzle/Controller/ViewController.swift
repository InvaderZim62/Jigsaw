//
//  ViewController.swift
//  Puzzle
//
//  Created by Phil Stern on 4/21/23.
//

import UIKit

struct PuzzleConst {
    static let outerSize: CGFloat = 200  // size of puzzle piece, including tabs
    static let innerRatio: CGFloat = 0.56
    static let innerSize = innerRatio * PuzzleConst.outerSize  // excluding tabs
    static let inset = (PuzzleConst.outerSize - PuzzleConst.innerSize) / 2
}

class ViewController: UIViewController {
    
    let image = UIImage(named: "tree")!  // eventually, this will come from the user's Photo library
    var pieces = [Piece]()
    var pieceViews = [Piece: PieceView]()
    var pannedPieceInitialCenter = CGPoint.zero
    var pannedPieceMatchingSide: Int?
    var targetPieceMatchingSide: Int?

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

        let separation = 100.0

        pieceViews[pieces[0]]!.center = CGPoint(x: 100, y: 200)
        pieceViews[pieces[1]]!.center = pieceViews[pieces[0]]!.center.offsetBy(dx: PuzzleConst.innerSize + separation, dy: 0)
        pieceViews[pieces[2]]!.center = pieceViews[pieces[0]]!.center.offsetBy(dx: 0, dy: PuzzleConst.innerSize + separation)
        pieceViews[pieces[3]]!.center = pieceViews[pieces[0]]!.center.offsetBy(dx: PuzzleConst.innerSize + separation, dy: PuzzleConst.innerSize + separation)
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
            let pannedPiece = pieceFor(pannedPieceView)  // copy of piece (don't manipulate)
            switch recognizer.state {
            case .began:
                pannedPieceInitialCenter = pannedPieceView.center
                view.bringSubviewToFront(pannedPieceView)
                fallthrough
            case .changed:
                // move panned piece, limited to edges of screen
                let translation = recognizer.translation(in: playView)
                let edgeInset = PuzzleConst.innerSize / 2
                pannedPieceView.center = (pannedPieceInitialCenter + translation)
                    .limitedToView(playView, withHorizontalInset: edgeInset, andVerticalInset: edgeInset)
                
                let targetPieceViews = pieceViews.filter { $0.value != pannedPieceView }
                for targetPieceView in targetPieceViews.values {
                    let targetPiece = pieceFor(targetPieceView)
                    let distanceToTarget = pannedPieceView.center.distance(from: targetPieceView.center)
                    if distanceToTarget < 1.1 * PuzzleConst.innerSize &&
                        distanceToTarget > 0.9 * PuzzleConst.innerSize {  // may be more than one (will use first)
                        // panned piece is near outer edge of potential target
                        let bearingToPannedPiece = targetPieceView.center.bearing(to: pannedPieceView.center)
                        let bearingInTargetFrame = (bearingToPannedPiece - targetPieceView.rotation).wrap360
                        let bearingInPannedPieceFrame = (bearingToPannedPiece + 180 - pannedPieceView.rotation).wrap360
                        if let targetSideIndex = sideIndexFor(bearing: bearingInTargetFrame),
                           let pannedPieceSideIndex = sideIndexFor(bearing: bearingInPannedPieceFrame) {
                            // panned piece is aligned horizontally or vertically to potential target
                            if targetPiece.sides[targetSideIndex].mate == pannedPiece.sides[pannedPieceSideIndex] {
                                // panned piece and target have complementary sides facing each other
                                pannedPieceView.center = targetPieceView.center + CGPoint(x: PuzzleConst.innerSize * sin(bearingToPannedPiece.round90.rads),
                                                                                          y: -PuzzleConst.innerSize * cos(bearingToPannedPiece.round90.rads))
                            }
                        }
                    }
                }
                
            case .ended:
                print("pan ended")
            default:
                break
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
            pieces[pieceIndexFor(tappedPieceView)].rotation = tappedPieceView.rotation
        }
    }
    
    // MARK: - Utilities
    
    func pieceFor(_ pieceView: PieceView) -> Piece {
        pieceViews.someKey(forValue: pieceView)!  // copy of piece (don't manipulate)
    }
    
    func pieceIndexFor(_ pieceView: PieceView) -> Int {
        let piece = pieceFor(pieceView)
        return pieces.index(matching: piece)!
    }
    
    func sideIndexFor(bearing: Double) -> Int? {  // assumes bearing from 0 to 360 degrees
        let threshold = 5.0
        if bearing < threshold || bearing > 360 - threshold {
            return 0
        } else if abs(bearing - 90) < threshold {
            return 1
        } else if abs(bearing - 180) < threshold {
            return 2
        } else if abs(bearing - 270) < threshold {
            return 3
        } else {
            return nil
        }
    }
}
