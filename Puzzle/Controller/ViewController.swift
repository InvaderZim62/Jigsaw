//
//  ViewController.swift
//  Puzzle
//
//  Created by Phil Stern on 4/21/23.
//

import UIKit

struct PuzzleConst {
    static let targetPieceSize: CGFloat = 200  // size of puzzle piece, including tabs
    static let innerRatio: CGFloat = 0.56
}

class ViewController: UIViewController {
    
//    let image = UIImage(named: "tree")!  // eventually, this will come from the user's Photo library
    let image = UIImage(named: "game")!
    let globalData = GlobalData.sharedInstance
    var pieces = [Piece]()
    var pieceViews = [Piece: PieceView]()
    var pannedPieceInitialCenter = CGPoint.zero
    var pannedPieceMatchingSide: Int?
    var targetPieceMatchingSide: Int?

    @IBOutlet weak var boardView: UIView!
    
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

        let overlap = globalData.outerSize - globalData.innerSize
        let tiles = image.extractTiles(with: CGSize(width: globalData.outerSize, height: globalData.outerSize), overlap: overlap)!

        let row = Int(0.58 * Double(tiles.count))  // branching part of tree
        let col = Int(0.54 * Double(tiles[0].count))
        
        pieceViews[pieces[0]] = createPieceView(sides: pieces[0].sides, image: tiles[row][col])
        pieceViews[pieces[1]] = createPieceView(sides: pieces[1].sides, image: tiles[row][col+1])
        pieceViews[pieces[2]] = createPieceView(sides: pieces[2].sides, image: tiles[row+1][col])
        pieceViews[pieces[3]] = createPieceView(sides: pieces[3].sides, image: tiles[row+1][col+1])

        let separation = 100.0

        pieceViews[pieces[0]]!.center = CGPoint(x: 100, y: 200)
        pieceViews[pieces[1]]!.center = pieceViews[pieces[0]]!.center.offsetBy(dx: globalData.innerSize + separation, dy: 0)
        pieceViews[pieces[2]]!.center = pieceViews[pieces[0]]!.center.offsetBy(dx: 0, dy: globalData.innerSize + separation)
        pieceViews[pieces[3]]!.center = pieceViews[pieces[0]]!.center.offsetBy(dx: globalData.innerSize + separation, dy: globalData.innerSize + separation)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        // resize image to fit boardView, without changing aspect ratio
        let fitSize = sizeToFit(image, in: boardView)
        
        let tileCols = fitSize.width / PuzzleConst.targetPieceSize
        let tileRows = fitSize.height / PuzzleConst.targetPieceSize

        let resizedImage = image.resizedTo(fitSize)
        
        let wholeImageView = UIImageView(image: resizedImage)
        wholeImageView.frame = CGRect(origin: CGPoint.zero, size: resizedImage.size)
        wholeImageView.center = CGPoint(x: boardView.bounds.midX, y: boardView.bounds.midY)
        wholeImageView.sizeToFit()
        boardView.addSubview(wholeImageView)
        
    }
    
    func sizeToFit(_ image: UIImage, in container: UIView) -> CGSize {
        let imageAspectRatio = image.size.width / image.size.height
        let containerAspectRatio = container.bounds.size.width / container.bounds.size.height
        if imageAspectRatio > containerAspectRatio {
            return CGSize(width: container.bounds.size.width, height: container.bounds.size.width / imageAspectRatio)
        } else {
            return CGSize(width: container.bounds.size.height * imageAspectRatio, height: container.bounds.size.height)
        }
    }

    // create pieceView with pan, double-tap, and single-tap gestures; add to playView
    func createPieceView(sides: [Side], image: UIImage) -> PieceView {
        let pieceView = PieceView(sides: sides, image: image)
        pieceView.frame = CGRect(x: 0, y: 0, width: globalData.innerSize, height: globalData.innerSize)
        pieceView.center = CGPoint(x: globalData.innerSize / 2, y: globalData.innerSize / 2)

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

        boardView.addSubview(pieceView)

        return pieceView
    }

    // MARK: - Gestures
    
    @objc private func handlePan(recognizer: UIPanGestureRecognizer) {
        if let pannedPieceView = recognizer.view as? PieceView {
            let (pannedPiece, pannedPieceIndex) = pieceIndexFor(pannedPieceView)  // copy of piece (don't manipulate)
            switch recognizer.state {
            case .began:
                pannedPieceInitialCenter = pannedPieceView.center
                boardView.bringSubviewToFront(pannedPieceView)
                fallthrough
            case .changed:
                // move panned piece, limited to edges of screen
                let translation = recognizer.translation(in: boardView)
                let edgeInset = globalData.innerSize / 2
                pannedPieceView.center = (pannedPieceInitialCenter + translation)
                    .limitedToView(boardView, withHorizontalInset: edgeInset, andVerticalInset: edgeInset)
                
                let targetPieceViews = pieceViews.filter { $0.value != pannedPieceView }
                for targetPieceView in targetPieceViews.values {
                    let (targetPiece, targetPieceIndex) = pieceIndexFor(targetPieceView)
                    let distanceToTarget = pannedPieceView.center.distance(from: targetPieceView.center)
                    if distanceToTarget < 1.1 * globalData.innerSize &&
                        distanceToTarget > 0.9 * globalData.innerSize {  // may be more than one (will use first)
                        // panned piece is aligned horizontally or vertically to potential target within threshold
                        let bearingToPannedPiece = targetPieceView.center.bearing(to: pannedPieceView.center)
                        let bearingInTargetFrame = (bearingToPannedPiece - targetPieceView.rotation).wrap360
                        let bearingInPannedPieceFrame = (bearingToPannedPiece + 180 - pannedPieceView.rotation).wrap360
                        if let targetSideIndex = sideIndexFor(bearing: bearingInTargetFrame),
                           let pannedPieceSideIndex = sideIndexFor(bearing: bearingInPannedPieceFrame) {
                            // panned piece is aligned horizontally or vertically to potential target
                            if targetPiece.sides[targetSideIndex].mate == pannedPiece.sides[pannedPieceSideIndex] {
                                // panned piece and target have complementary sides facing each other (snap them together)
                                print("panned piece side: \(pannedPieceSideIndex), target side: \(targetSideIndex)")
                                pannedPieceView.center = targetPieceView.center + CGPoint(x: globalData.innerSize * sin(bearingToPannedPiece.round90.rads),
                                                                                          y: -globalData.innerSize * cos(bearingToPannedPiece.round90.rads))
                                pieces[targetPieceIndex].sides[targetSideIndex].isConnected = true
                                pieces[pannedPieceIndex].sides[pannedPieceSideIndex].isConnected = true
                            }
                        }
                    }
                }
                
            case .ended:
                print("pan ended")  // check if puzzle is complete?
            default:
                break
            }
        }
    }
    
    // rotate piece +90 degrees for single-tap, -90 degrees for double-tap (animated)
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        if let tappedPieceView = recognizer.view as? PieceView {
            boardView.bringSubviewToFront(tappedPieceView)
            UIView.animate(withDuration: 0.2, animations: {
                tappedPieceView.transform = tappedPieceView.transform.rotated(by: recognizer.numberOfTapsRequired == 1 ? 90.CGrads : -90.CGrads)
            })
            // update model
            pieces[pieceIndexFor(tappedPieceView).1].rotation = tappedPieceView.rotation
        }
    }
    
    // MARK: - Utilities
    
    func pieceFor(_ pieceView: PieceView) -> Piece {
        pieceViews.someKey(forValue: pieceView)!  // copy of piece (don't manipulate)
    }
    
    func pieceIndexFor(_ pieceView: PieceView) -> (Piece, Int) {
        let piece = pieceFor(pieceView)
        let pieceIndex = pieces.index(matching: piece)!
        return (piece, pieceIndex)
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
