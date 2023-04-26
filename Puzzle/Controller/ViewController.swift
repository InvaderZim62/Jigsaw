//
//  ViewController.swift
//  Puzzle
//
//  Created by Phil Stern on 4/21/23.
//

import UIKit

struct PuzzleConst {
    static let pieceSize: CGFloat = 150  // size of puzzle piece, including tabs
    static let innerRatio: CGFloat = 0.56
}

class ViewController: UIViewController {
    
    let image = UIImage(named: "tree")!  // eventually, this will come from the user's Photo library
//    let image = UIImage(named: "game")!
    var boardView = UIView()
    let globalData = GlobalData.sharedInstance
    var pieces = [Piece]()
    var pieceViews = [Piece: PieceView]()
    var pannedPieceInitialCenter = CGPoint.zero
    var pannedPieceMatchingSide: Int?
    var targetPieceMatchingSide: Int?

    @IBOutlet weak var safeView: UIView!
    @IBOutlet weak var autosizedBoardView: UIView!
    
    // MARK: - Start of code

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // resize image to fit autosizedBoardView, without changing image aspect ratio
        let fitSize = sizeToFit(image, in: autosizedBoardView)
        autosizedBoardView.removeFromSuperview()  // no longer needed, replace with boardView

        let resizedImage = image.resizedTo(fitSize)

        let tiles = resizedImage.extractTiles(with: CGSize(width: globalData.outerSize, height: globalData.outerSize),
                                              overlap: globalData.outerSize - globalData.innerSize)!
        let tileRows = tiles.count
        let tileCols = tiles[0].count
        
        // size boardView to fit completed puzzle size
        boardView.bounds.size = CGSize(width: globalData.innerSize * CGFloat(tileCols),
                                       height: globalData.innerSize * CGFloat(tileRows))
        boardView.center = safeView.center
        boardView.backgroundColor = .lightGray
        safeView.addSubview(boardView)

        for row in 0..<tileRows {
            for col in 0..<tileCols {
                let index = col + row * tileCols
                let sides: [Side] = [
                    row == 0 ? Side(type: .edge) : pieces[index - tileCols].sides[2].mate,
                    col == tileCols - 1 ? Side(type: .edge) : Side.random(),
                    row == tileRows - 1 ? Side(type: .edge) : Side.random(),
                    col == 0 ? Side(type: .edge) : pieces[index - 1].sides[1].mate,
                ]
                let piece = Piece(sides: sides)
                pieces.append(piece)
                let pieceView = createPieceView(sides: sides, image: tiles[row][col])
                // randomly place piece in safe area
                pieceView.center = CGPoint(x: Double.random(in: globalData.innerSize/2..<safeView.bounds.width - globalData.innerSize/2),
                                           y: Double.random(in: globalData.innerSize/2..<safeView.bounds.height - globalData.innerSize/2))
                // place in order with some space between pieces
//                let spaceFactor = 1.0
//                pieceView.center = boardView.frame.origin + CGPoint(x: globalData.innerSize * (0.5 + spaceFactor * CGFloat(col)),
//                                                                    y: globalData.innerSize * (0.5 + spaceFactor * CGFloat(row)))
                pieceViews[piece] = pieceView
            }
        }
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

//        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
//        doubleTap.numberOfTapsRequired = 2
//        pieceView.addGestureRecognizer(doubleTap)
//
//        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
//        singleTap.numberOfTapsRequired = 1
//        pieceView.addGestureRecognizer(singleTap)
//        singleTap.require(toFail: doubleTap)  // don't fire singleTap, unless doubleTap fails (this slows down singleTap response)

        safeView.addSubview(pieceView)

        return pieceView
    }
    
    // snap panned edge piece to nearby side of boardView
    func snapToEdge(_ pannedPiece: Piece, _ pannedPieceView: PieceView) {
        let edgeIndices = pannedPiece.edgeIndices
        if edgeIndices.count > 0 {
            for edgeIndex in edgeIndices {
                let pieceCenterInBoardCoords = safeView.convert(pannedPieceView.center, to: boardView)
                
                switch edgeIndex {
                case 0: // top
                    let distanceToTop = abs(pieceCenterInBoardCoords.y - globalData.innerSize / 2)
                    if distanceToTop < 0.1 * globalData.innerSize && pieceCenterInBoardCoords.x > 0 && pieceCenterInBoardCoords.x < boardView.bounds.maxX {
                        pannedPieceView.center = boardView.convert(CGPoint(x: pieceCenterInBoardCoords.x, y: globalData.innerSize / 2), to: safeView)
                    }
                case 1: // right
                    let distanceToRight = abs(boardView.bounds.maxX - pieceCenterInBoardCoords.x - globalData.innerSize / 2)
                    if distanceToRight < 0.1 * globalData.innerSize && pieceCenterInBoardCoords.y > 0 && pieceCenterInBoardCoords.y < boardView.bounds.maxY {
                        pannedPieceView.center = boardView.convert(CGPoint(x: boardView.bounds.maxX - globalData.innerSize / 2, y: pieceCenterInBoardCoords.y), to: safeView)
                    }
                case 2: // bottom
                    let distanceToBottom = abs(boardView.bounds.maxY - pieceCenterInBoardCoords.y - globalData.innerSize / 2)
                    if distanceToBottom < 0.1 * globalData.innerSize && pieceCenterInBoardCoords.x > 0 && pieceCenterInBoardCoords.x < boardView.bounds.maxX {
                        pannedPieceView.center = boardView.convert(CGPoint(x: pieceCenterInBoardCoords.x, y: boardView.bounds.maxY - globalData.innerSize / 2), to: safeView)
                    }
                case 3: // left
                    let distanceToLeft = abs(pieceCenterInBoardCoords.x - globalData.innerSize / 2)
                    if distanceToLeft < 0.1 * globalData.innerSize && pieceCenterInBoardCoords.y > 0 && pieceCenterInBoardCoords.y < boardView.bounds.maxY {
                        pannedPieceView.center = boardView.convert(CGPoint(x: globalData.innerSize / 2, y: pieceCenterInBoardCoords.y), to: safeView)
                    }
                default:
                    break
                }
            }
        }
    }

    // snap panned piece to nearby mating piece, if any (may not be the correct one)
    func snapToPiece(_ pannedPiece: Piece, _ pannedPieceView: PieceView, _ pannedPieceIndex: Int) {
        let targetPieceViews = pieceViews.filter { $0.value != pannedPieceView }  // all pieces, excluding panned piece
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
                    // obtained indices of sides facing each other
                    if targetPiece.sides[targetSideIndex].mate == pannedPiece.sides[pannedPieceSideIndex] {
                        // panned piece and target have complementary sides facing each other (snap them together)
                        pannedPieceView.center = targetPieceView.center + CGPoint(x: globalData.innerSize * sin(bearingToPannedPiece.round90.rads),
                                                                                  y: -globalData.innerSize * cos(bearingToPannedPiece.round90.rads))
                        pieces[targetPieceIndex].sides[targetSideIndex].isConnected = true
                        pieces[pannedPieceIndex].sides[pannedPieceSideIndex].isConnected = true
                    }
                }
            }
        }
    }
    
    // MARK: - Gestures

    @objc private func handlePan(recognizer: UIPanGestureRecognizer) {
        if let pannedPieceView = recognizer.view as? PieceView {
            let (pannedPiece, pannedPieceIndex) = pieceIndexFor(pannedPieceView)  // copy of piece (don't manipulate)
            switch recognizer.state {
            case .began:
                pannedPieceInitialCenter = pannedPieceView.center
                safeView.bringSubviewToFront(pannedPieceView)
                fallthrough
            case .changed:
                // move panned piece, limited to edges of safeView
                let translation = recognizer.translation(in: safeView)
                let edgeInset = globalData.innerSize / 2
                pannedPieceView.center = (pannedPieceInitialCenter + translation)
                    .limitedToView(safeView, withHorizontalInset: edgeInset, andVerticalInset: edgeInset)
                
                snapToEdge(pannedPiece, pannedPieceView)
                snapToPiece(pannedPiece, pannedPieceView, pannedPieceIndex)
                
//            case .ended:
//                print("pan ended")  // check if puzzle is complete?
            default:
                break
            }
        }
    }
    
    // rotate piece +90 degrees for single-tap, -90 degrees for double-tap (animated)
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        if let tappedPieceView = recognizer.view as? PieceView {
            safeView.bringSubviewToFront(tappedPieceView)
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
