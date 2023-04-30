//
//  ViewController.swift
//  Puzzle
//
//  Created by Phil Stern on 4/21/23.
//

import UIKit

struct PuzzleConst {
    static let pieceSize: CGFloat = 150  // size of puzzle piece, including tabs
    static let innerRatio: CGFloat = 0.60  // bigger ratio => bigger inner size (less distance tab cuts into neighboring piece)
    static let snapDistance = 0.1  // percent innerSize
}

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var image = UIImage(named: "tree")!  // default image
    var boardView = UIView()
    let globalData = GlobalData.sharedInstance
    var pieces = [Piece]()
    var pieceViews = [Piece: PieceView]()
    var pannedPieceInitialCenter = CGPoint.zero
    var pannedPieceMatchingSide: Int?
    var targetPieceMatchingSide: Int?

    @IBOutlet weak var safeArea: UIView!
    @IBOutlet weak var autosizedBoardView: UIView!
    
    // MARK: - Start of code
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Jigsaw Puzzle"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Choose Photo", style: .plain, target: self, action: #selector(importPicture))

        safeArea.addSubview(boardView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        createPuzzle(from: image)  // must call after bounds set
    }
    
    func createPuzzle(from image: UIImage) {
        let tiles = createTiles(from: image)

        createPiecesAndViews(from: tiles)

        let tileRows = tiles.count
        let tileCols = tiles[0].count
        
        // size boardView to fit completed puzzle size
        boardView.bounds.size = CGSize(width: globalData.innerSize * CGFloat(tileCols),
                                       height: globalData.innerSize * CGFloat(tileRows))
        boardView.center = CGPoint(x: safeArea.bounds.midX, y: safeArea.bounds.midY)
        boardView.backgroundColor = .lightGray
    }
    
    func createTiles(from image: UIImage) -> [[UIImage]] {
        // resize image to fit autosizedBoardView, without changing image aspect ratio
        let fitSize = sizeToFit(image, in: autosizedBoardView)
//        autosizedBoardView.backgroundColor = .yellow
//        safeArea.backgroundColor = .blue

        let resizedImage = image.resizedTo(fitSize)

        let tiles = resizedImage.extractTiles(with: CGSize(width: globalData.outerSize, height: globalData.outerSize),
                                              overlap: globalData.outerSize - globalData.innerSize)!
        return tiles
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

    func createPiecesAndViews(from tiles: [[UIImage]]) {
        pieces.removeAll()
        pieceViews.values.forEach { $0.removeFromSuperview() }
        pieceViews.removeAll()
        
        let tileRows = tiles.count
        let tileCols = tiles[0].count

        for row in 0..<tileRows {
            for col in 0..<tileCols {
                let index = col + row * tileCols
                // move from left to right, top to bottom; top side must mate to piece above (unless first row edge);
                // left side must mate to previous piece (unless first col edge); remaining sides are random or edges
                var sides: [Side] = [
                    row == 0 ? Side(type: .edge) : pieces[index - tileCols].sides[2].mate,  // top side
                    col == tileCols - 1 ? Side(type: .edge) : Side.random(),                // right side
                    row == tileRows - 1 ? Side(type: .edge) : Side.random(),                // bottom side
                    col == 0 ? Side(type: .edge) : pieces[index - 1].sides[1].mate,         // left side
                ]
                // move right-side hole to avoid overlapping top-side hole
                if sides[1].type == .hole && sides[0].type == .hole {
                    sides[1].tabPosition = max(sides[1].tabPosition, sides[0].tabPosition - 0.05)
                }
                // move bottom-side hole to avoid overlapping right-side hole
                if sides[2].type == .hole && sides[1].type == .hole {
                    sides[2].tabPosition = max(sides[2].tabPosition, sides[1].tabPosition - 0.05)
                }
                // move bottom-side hole to avoid overlapping left-side hole
                if sides[2].type == .hole && sides[3].type == .hole {
                    if sides[1].type == .hole && sides[1].tabPosition >= 0.5 && sides[3].tabPosition <= 0.5 {
                        // bottom-side hole sandwiched between left- and right-side holes
                        sides[2].tabPosition = 0.5
                    } else {
                        sides[2].tabPosition = min(sides[2].tabPosition, sides[3].tabPosition + 0.05)
                    }
                }
                // move right-side tab, to avoid overlapping left- and top-side holes on piece to the right
                if row > 0 && col < tileCols - 1 && sides[1].type == .tab && pieces[index - tileCols + 1].sides[2].type == .tab {
                    sides[1].tabPosition = max(sides[1].tabPosition, pieces[index - tileCols + 1].sides[2].tabPosition - 0.05)
                }
                let piece = Piece(sides: sides)
                pieces.append(piece)
                let pieceView = createPieceView(sides: sides, image: tiles[row][col])
                // randomly place piece in safe area
                pieceView.center = CGPoint(x: Double.random(in: globalData.innerSize/2..<safeArea.bounds.width - globalData.innerSize/2),
                                           y: Double.random(in: globalData.innerSize/2..<safeArea.bounds.height - globalData.innerSize/2))
//                // place in order with some space between pieces
//                let spaceFactor = 1.0
//                pieceView.center = boardView.frame.origin + CGPoint(x: globalData.innerSize * (0.5 + spaceFactor * CGFloat(col)),
//                                                                    y: globalData.innerSize * (0.5 + spaceFactor * CGFloat(row)))
                pieceViews[piece] = pieceView
            }
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

        safeArea.addSubview(pieceView)

        return pieceView
    }
    
    // open picker controller to browse through photo library
    @objc func importPicture() {
        let picker = UIImagePickerController()
        picker.allowsEditing = true  // pws: needed?
        picker.delegate = self
        present(picker, animated: true)
    }

    // snap panned edge piece to nearby side of boardView
    func snapToEdge(_ pannedPiece: Piece, _ pannedPieceView: PieceView) {
        let snap = PuzzleConst.snapDistance * globalData.innerSize
        let edgeIndices = pannedPiece.edgeIndices
        if edgeIndices.count > 0 {
            for edgeIndex in edgeIndices {
                let pieceCenterInBoardCoords = safeArea.convert(pannedPieceView.center, to: boardView)
                
                switch edgeIndex {
                case 0: // top
                    let distanceToTop = abs(pieceCenterInBoardCoords.y - globalData.innerSize / 2)
                    if distanceToTop < snap && pieceCenterInBoardCoords.x > 0 && pieceCenterInBoardCoords.x < boardView.bounds.maxX {
                        pannedPieceView.center = boardView.convert(CGPoint(x: pieceCenterInBoardCoords.x, y: globalData.innerSize / 2), to: safeArea)
                    }
                case 1: // right
                    let distanceToRight = abs(boardView.bounds.maxX - pieceCenterInBoardCoords.x - globalData.innerSize / 2)
                    if distanceToRight < snap && pieceCenterInBoardCoords.y > 0 && pieceCenterInBoardCoords.y < boardView.bounds.maxY {
                        pannedPieceView.center = boardView.convert(CGPoint(x: boardView.bounds.maxX - globalData.innerSize / 2, y: pieceCenterInBoardCoords.y), to: safeArea)
                    }
                case 2: // bottom
                    let distanceToBottom = abs(boardView.bounds.maxY - pieceCenterInBoardCoords.y - globalData.innerSize / 2)
                    if distanceToBottom < snap && pieceCenterInBoardCoords.x > 0 && pieceCenterInBoardCoords.x < boardView.bounds.maxX {
                        pannedPieceView.center = boardView.convert(CGPoint(x: pieceCenterInBoardCoords.x, y: boardView.bounds.maxY - globalData.innerSize / 2), to: safeArea)
                    }
                case 3: // left
                    let distanceToLeft = abs(pieceCenterInBoardCoords.x - globalData.innerSize / 2)
                    if distanceToLeft < snap && pieceCenterInBoardCoords.y > 0 && pieceCenterInBoardCoords.y < boardView.bounds.maxY {
                        pannedPieceView.center = boardView.convert(CGPoint(x: globalData.innerSize / 2, y: pieceCenterInBoardCoords.y), to: safeArea)
                    }
                default:
                    break
                }
            }
        }
    }

    // snap panned piece to nearby mating piece, if any (may not be the correct one)
    func snapToPiece(_ pannedPiece: Piece, _ pannedPieceView: PieceView, _ pannedPieceIndex: Int) {
        let snap = PuzzleConst.snapDistance * globalData.innerSize
        let targetPieceViews = pieceViews.filter { $0.value != pannedPieceView }  // all pieces, excluding panned piece
        for targetPieceView in targetPieceViews.values {
            let (targetPiece, targetPieceIndex) = pieceIndexFor(targetPieceView)
            let distanceToTarget = pannedPieceView.center.distance(from: targetPieceView.center)
            if distanceToTarget < globalData.innerSize + snap && distanceToTarget > globalData.innerSize - snap {  // may be more than one (will use first)
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
                print(pannedPiece)
                pannedPieceInitialCenter = pannedPieceView.center
                safeArea.bringSubviewToFront(pannedPieceView)
                fallthrough
            case .changed:
                // move panned piece, limited to edges of safeArea
                let translation = recognizer.translation(in: safeArea)
                let edgeInset = globalData.innerSize / 2
                pannedPieceView.center = (pannedPieceInitialCenter + translation)
                    .limitedToView(safeArea, withHorizontalInset: edgeInset, andVerticalInset: edgeInset)
                
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
            safeArea.bringSubviewToFront(tappedPieceView)
            UIView.animate(withDuration: 0.2, animations: {
                tappedPieceView.transform = tappedPieceView.transform.rotated(by: recognizer.numberOfTapsRequired == 1 ? 90.CGrads : -90.CGrads)
            })
            // update model
            pieces[pieceIndexFor(tappedPieceView).1].rotation = tappedPieceView.rotation
        }
    }
    
    // MARK: - Utilities
    
    func pieceIndexFor(_ pieceView: PieceView) -> (Piece, Int) {
        let piece = pieceFor(pieceView)
        let pieceIndex = pieces.index(matching: piece)!
        return (piece, pieceIndex)
    }
    
    func pieceFor(_ pieceView: PieceView) -> Piece {
        pieceViews.getKey(forValue: pieceView)!  // copy of piece (don't manipulate)
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
    
    // MARK: - UIImagePickerControllerDelegate
    
    // get image from picker when it closes (assign it to currentImage)
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let pickerImage = info[.editedImage] as? UIImage else { return }
        dismiss(animated: true)  // dismiss picker
        
        createPuzzle(from: pickerImage)
    }
}
