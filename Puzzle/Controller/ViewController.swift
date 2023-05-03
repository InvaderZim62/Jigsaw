//
//  ViewController.swift
//  Puzzle
//
//  Created by Phil Stern on 4/21/23.
//
//  To do...
//  - put white border around picture, so integer number of rows and columns don't truncate image
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
    var pastSafeAreaBounds = CGRect.zero
    var pastBoardViewOrigin = CGPoint.zero
    var once = false

    @IBOutlet weak var safeArea: UIView!
    @IBOutlet weak var autosizedBoardView: UIView!
    
    // MARK: - Start of code
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Jigsaw Puzzle"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Pick Photo", style: .plain, target: self, action: #selector(importPicture))
    }
    
    // Note: viewDidAppear gets called again when dismissing image picker on iPad running iOS 12.4
    override func viewDidAppear(_ animated: Bool) {
        guard once == false else { return }
        super.viewDidAppear(animated)
        createPuzzle(from: image)  // call after bounds set (don't put in viewDidLayoutSubviews, or it will re-create the puzzle when orientation changes)
        once = true
    }
    
    override func viewDidLayoutSubviews() {
        if safeArea.bounds != pastSafeAreaBounds {
            super.viewDidLayoutSubviews()
            safeArea.setNeedsLayout()  // force boardView bounds to update now, since it normally occurs after viewDidLayoutSubviews
            safeArea.layoutIfNeeded()
            for piece in pieces {
                let pieceView = pieceViews[piece]!
                if piece.isConnected {
                    // if connected, keep in same position on boardView (move with boardView origin)
                    pieceView.center = pieceView.center + boardView.frame.origin - pastBoardViewOrigin
                } else {
                    // if not connected, move to same relative position in safeArea
                    pieceView.center = CGPoint(x: pieceView.center.x * safeArea.bounds.width / pastSafeAreaBounds.width,
                                               y: pieceView.center.y * safeArea.bounds.height / pastSafeAreaBounds.height)
                    safeArea.bringSubviewToFront(pieceView)
                }
            }
            pastSafeAreaBounds = safeArea.bounds
            pastBoardViewOrigin = boardView.frame.origin
        }
    }
    
    func createPuzzle(from image: UIImage) {
        let tiles = createTiles(from: image)  // 2D array of overlapping images
        let tileRows = tiles.count
        let tileCols = tiles[0].count

        pieceViews.values.forEach { $0.removeFromSuperview() }  // in case choosing a new photo
        
        (pieces, pieceViews) = createPiecesAndViews(from: tiles)  // turn images into puzzle pieces
        
        // size boardView to fit completed puzzle size
        boardView.removeFromSuperview()  // easiest way to remove all constraints, before reseting them
        boardView = UIView()
        safeArea.insertSubview(boardView, aboveSubview: autosizedBoardView)
        boardView.translatesAutoresizingMaskIntoConstraints = false
        boardView.widthAnchor.constraint(equalToConstant: globalData.innerSize * CGFloat(tileCols)).isActive = true
        boardView.heightAnchor.constraint(equalToConstant: globalData.innerSize * CGFloat(tileRows)).isActive = true
        boardView.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor).isActive = true
        boardView.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor).isActive = true
        boardView.backgroundColor = .lightGray
        safeArea.setNeedsLayout()
        safeArea.layoutIfNeeded()
        pastBoardViewOrigin = boardView.frame.origin

        randomlyPlacePiecesInSafeArea()
//        solvePuzzle(rows: tileRows, cols: tileCols)
    }
    
    // resize image and split into overlapping squares
    func createTiles(from image: UIImage) -> [[UIImage]] {
        // compute maximum size that fits in autosizedBoardView, while maintaining image aspect ratio
        let fitSize = sizeToFit(image, in: autosizedBoardView)
//        safeArea.backgroundColor = .blue
//        autosizedBoardView.backgroundColor = .yellow

        let resizedImage = image.resizedTo(fitSize)

        let tiles = resizedImage.extractTiles(with: CGSize(width: globalData.outerSize, height: globalData.outerSize),
                                              overlap: globalData.outerSize - globalData.innerSize)!
        return tiles
    }
    
    // compute size that maximizes space in container, while maintaining image aspect ration
    func sizeToFit(_ image: UIImage, in container: UIView) -> CGSize {
        let imageAspectRatio = image.size.width / image.size.height
        let containerAspectRatio = container.bounds.size.width / container.bounds.size.height
        if imageAspectRatio > containerAspectRatio {
            // width-limited
            return CGSize(width: container.bounds.size.width, height: container.bounds.size.width / imageAspectRatio)
        } else {
            // height-limited
            return CGSize(width: container.bounds.size.height * imageAspectRatio, height: container.bounds.size.height)
        }
    }
    
    func createPiecesAndViews(from tiles: [[UIImage]]) -> ([Piece], [Piece: PieceView]) {
        var pieces = [Piece]()
        var pieceViews = [Piece: PieceView]()
        
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
                let pieceView = createPieceView(sides: sides, image: tiles[row][col])  // create piceView with overlayed image
                pieceViews[piece] = pieceView
            }
        }
        
        return (pieces, pieceViews)
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
    
    func randomlyPlacePiecesInSafeArea() {
        pieceViews.values.forEach {
            $0.center = CGPoint(x: Double.random(in: globalData.innerSize/2..<safeArea.bounds.width - globalData.innerSize/2),
                                y: Double.random(in: globalData.innerSize/2..<safeArea.bounds.height - globalData.innerSize/2))
        }
    }
    
    func solvePuzzle(rows: Int, cols: Int) {
        for row in 0..<rows {
            for col in 0..<cols {
                let index = col + row * cols
                let piece = pieces[index]
                pieceViews[piece]!.center = boardView.frame.origin + CGPoint(x: globalData.innerSize * (0.5 + CGFloat(col)),
                                                                             y: globalData.innerSize * (0.5 + CGFloat(row)))
                pieces[index].isConnected = true
            }
        }
    }
    
    // open picker controller to browse through photo library
    @objc func importPicture() {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }

    // snap panned edge piece to nearby side of boardView
    func snapToEdge(_ pannedPiece: Piece, _ pannedPieceView: PieceView, _ pannedPieceIndex: Int) -> Bool {
        var isConnected = false
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
                        isConnected = true
                    }
                case 1: // right
                    let distanceToRight = abs(boardView.bounds.maxX - pieceCenterInBoardCoords.x - globalData.innerSize / 2)
                    if distanceToRight < snap && pieceCenterInBoardCoords.y > 0 && pieceCenterInBoardCoords.y < boardView.bounds.maxY {
                        pannedPieceView.center = boardView.convert(CGPoint(x: boardView.bounds.maxX - globalData.innerSize / 2, y: pieceCenterInBoardCoords.y), to: safeArea)
                        isConnected = true
                    }
                case 2: // bottom
                    let distanceToBottom = abs(boardView.bounds.maxY - pieceCenterInBoardCoords.y - globalData.innerSize / 2)
                    if distanceToBottom < snap && pieceCenterInBoardCoords.x > 0 && pieceCenterInBoardCoords.x < boardView.bounds.maxX {
                        pannedPieceView.center = boardView.convert(CGPoint(x: pieceCenterInBoardCoords.x, y: boardView.bounds.maxY - globalData.innerSize / 2), to: safeArea)
                        isConnected = true
                    }
                case 3: // left
                    let distanceToLeft = abs(pieceCenterInBoardCoords.x - globalData.innerSize / 2)
                    if distanceToLeft < snap && pieceCenterInBoardCoords.y > 0 && pieceCenterInBoardCoords.y < boardView.bounds.maxY {
                        pannedPieceView.center = boardView.convert(CGPoint(x: globalData.innerSize / 2, y: pieceCenterInBoardCoords.y), to: safeArea)
                        isConnected = true
                    }
                default:
                    break
                }
            }
        }
        return isConnected
    }

    // snap panned piece to nearby mating piece, if any (may not be the correct one)
    func snapToPiece(_ pannedPiece: Piece, _ pannedPieceView: PieceView) -> Bool {
        var isConnected = false
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
                        if pieces[targetPieceIndex].isConnected {
                            isConnected = true
                        }
                    }
                }
            }
        }
        return isConnected
    }
    
    // MARK: - Gestures

    @objc private func handlePan(recognizer: UIPanGestureRecognizer) {
        if let pannedPieceView = recognizer.view as? PieceView {
            let (pannedPiece, pannedPieceIndex) = pieceIndexFor(pannedPieceView)  // copy of piece (don't manipulate)
            switch recognizer.state {
            case .began:
                pannedPieceInitialCenter = pannedPieceView.center
                safeArea.bringSubviewToFront(pannedPieceView)
                fallthrough
            case .changed:
                // move panned piece, limited to edges of safeArea
                let translation = recognizer.translation(in: safeArea)
                let edgeInset = globalData.innerSize / 4
                pannedPieceView.center = (pannedPieceInitialCenter + translation)
                    .limitedToView(safeArea, withHorizontalInset: edgeInset, andVerticalInset: edgeInset)
                
                // can't do: isConnected = snapToEdge || snapToPiece, since "or" stops checking if first is true
                pieces[pannedPieceIndex].isConnected = snapToEdge(pannedPiece, pannedPieceView, pannedPieceIndex)
                pieces[pannedPieceIndex].isConnected = snapToPiece(pannedPiece, pannedPieceView) || pieces[pannedPieceIndex].isConnected
                
//            case .ended:
//                print("pan ended\n\(pieces[pannedPieceIndex])")
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
        guard let pickerImage = info[.editedImage] as? UIImage else { return }  // .editedImage, in case user cropped image during selection
        dismiss(animated: true)  // dismiss picker
        image = pickerImage  // for iPad, since it calls viewDidAppear again
        createPuzzle(from: pickerImage)
    }
}
