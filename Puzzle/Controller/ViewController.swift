//
//  ViewController.swift
//  Puzzle
//
//  Created by Phil Stern on 4/21/23.
//
//  Useful equations...
//    piece from pieceView:       puzzle.pieces[pieceIndexFor(pieceView).1].rotation = 90.0
//
//  To do...
//  - maybe have taps rotate groups of connected pieces
//  - alert user that changing settings will re-shuffle puzzle pieces
//  - check if piece connected to anything after it's rotated
//  - when a group is panned and snapped, only the pannedPiece's connections are updated (may not be a big problem)
//

import UIKit

struct PuzzleConst {
    static let innerRatio: CGFloat = 0.60  // bigger ratio => bigger inner size (less distance tab cuts into neighboring piece)
    static let snapDistance = 0.1  // percent innerSize
    static let connectEpsilon = 1.0  // closeness to be considered connected
    static let examplePuzzleWidth = 350.0  // matches hard-wired size in storyboard
    static let debugging = false
}

// UIImagePickerControllerDelegate & UINavigationControllerDelegate required for UIImagePickerController
// UIGestureRecognizerDelegate required for gestureRecognizer(gestureRecognizer:shouldRecognizeSimultaneouslyWith:)
class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate {
    var outerSize: CGFloat = 150
    var innerSize: CGFloat = 150 * PuzzleConst.innerRatio
    var image = UIImage(named: "tree")!  // default image
    var boardView = UIView()
    var puzzle = Puzzle()
    var pieceViews = [UUID: PieceView]()  // [Piece.id: PieceView]
    var pannedPieceMatchingSide: Int?
    var targetPieceMatchingSide: Int?
    var pastSafeAreaBounds = CGRect.zero
    var pastBoardViewOrigin = CGPoint.zero
    var nextGroupNumber = 1
    var panningPieceViews = [PieceView]()  // pieceViews grouped with panned piece if highlighted, or panned pieceView by itself if not highlighted
    var initialCenters = [CGPoint]()
    var targetPieceIndices = [Int]()
    var once = false

    // settings
    var allowsRotation = true
    var isOutlined = true
    var pieceSizeSML = PieceSizeSML.small

    @IBOutlet weak var safeArea: UIView!
    @IBOutlet weak var autosizedBoardView: UIView!
    
    // MARK: - Start of code
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Jigsaw Puzzle"
        if #available(iOS 14.0, *) {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "photo"), style: .plain, target: self, action: #selector(importPicture))
            navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "gearshape"), style: .plain, target: self, action: #selector(showSettings))
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Pick Photo", style: .plain, target: self, action: #selector(importPicture))
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Settings", style: .plain, target: self, action: #selector(showSettings))
        }
        getUserDefaults()
    
        outerSize = PuzzleConst.examplePuzzleWidth / CGFloat(5 - pieceSizeSML.rawValue) / PuzzleConst.innerRatio
        innerSize = outerSize * PuzzleConst.innerRatio
//        safeArea.backgroundColor = .blue
//        autosizedBoardView.backgroundColor = .yellow
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
            for piece in puzzle.pieces {
                let pieceView = pieceViews[piece.id]!
                if piece.isAnchored {
                    // if anchored, keep in same position on boardView (move with boardView origin)
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
    
    func getUserDefaults() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "allowsRotation") != nil {
            allowsRotation = defaults.bool(forKey: "allowsRotation")
            isOutlined = defaults.bool(forKey: "isOutlined")
            if let data = defaults.data(forKey: "pieceSizeSML") {
                pieceSizeSML = try! JSONDecoder().decode(PieceSizeSML.self, from: data)
            }
        }
    }
    
    func saveUserDefaults() {
        let defaults = UserDefaults.standard
        defaults.set(allowsRotation, forKey: "allowsRotation")
        defaults.set(isOutlined, forKey: "isOutlined")
        if let data = try? JSONEncoder().encode(pieceSizeSML) {
            defaults.setValue(data, forKey: "pieceSizeSML")
        }
    }
    
    func createPuzzle(from image: UIImage) {
        nextGroupNumber = 1
        let tiles = createTiles(from: image, fitting: autosizedBoardView)  // 2D array of overlapping images

        puzzle = Puzzle(rows: tiles.count, cols: tiles[0].count)

        pieceViews.values.forEach { $0.removeFromSuperview() }  // in case choosing a new photo
        pieceViews = createPieceViews(from: puzzle.pieces, and: tiles)  // create puzzle piece shapes overlaid with images
        
        createBoardView(puzzle.cols, puzzle.rows)
        
        randomlyPlacePiecesInSafeArea()
//        solvePuzzle(rows: puzzle.rows, cols: puzzle.cols)
    }

    // resize image and split into overlapping squares
    func createTiles(from image: UIImage, fitting container: UIView) -> [[UIImage]] {
        // compute maximum size that fits in container, while maintaining image aspect ratio
        let fitSize = sizeToFit(image, in: container)

        let resizedImage = image.resizedTo(fitSize)

        let tiles = resizedImage.extractTiles(with: CGSize(width: outerSize, height: outerSize),
                                              overlap: outerSize - innerSize)!
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

    func createPieceViews(from pieces: [Piece], and tiles: [[UIImage]]) -> [UUID: PieceView] {
        var pieceViews = [UUID: PieceView]()
        
        let tileRows = tiles.count
        let tileCols = tiles[0].count

        for row in 0..<tileRows {
            for col in 0..<tileCols {
                let index = col + row * tileCols
                let piece = pieces[index]
                let pieceView = createPieceView(sides: piece.sides, image: tiles[row][col], isOutlined: isOutlined)  // create piceView with overlayed image
                pieceViews[piece.id] = pieceView
            }
        }
        
        return pieceViews
    }

    // create pieceView with pan, double-tap, and single-tap gestures; add to playView
    func createPieceView(sides: [Side], image: UIImage, isOutlined: Bool) -> PieceView {
        let pieceView = PieceView(sides: sides, image: image, innerSize: innerSize, isOutlined: isOutlined)
        pieceView.frame = CGRect(x: 0, y: 0, width: innerSize, height: innerSize)
        pieceView.center = CGPoint(x: innerSize / 2, y: innerSize / 2)
        pieceView.isUserInteractionEnabled = true

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        pan.delegate = self
        pieceView.addGestureRecognizer(pan)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        pieceView.addGestureRecognizer(longPress)

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        doubleTap.numberOfTapsRequired = 2
        pieceView.addGestureRecognizer(doubleTap)

        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        singleTap.numberOfTapsRequired = 1
        pieceView.addGestureRecognizer(singleTap)
        singleTap.require(toFail: doubleTap)  // don't fire singleTap, unless doubleTap fails (this slows down singleTap response)

        safeArea.addSubview(pieceView)

        return pieceView
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherRecognizer: UIGestureRecognizer) -> Bool {
        gestureRecognizer is UIPanGestureRecognizer || gestureRecognizer is UILongPressGestureRecognizer
    }
    
    // size boardView to fit completed puzzle size and add constraints to center in safeArea
    func createBoardView(_ tileCols: Int, _ tileRows: Int) {
        boardView.removeFromSuperview()  // easiest way to remove all constraints, before reseting them
        boardView = UIView()
        safeArea.insertSubview(boardView, aboveSubview: autosizedBoardView)
        boardView.translatesAutoresizingMaskIntoConstraints = false
        boardView.widthAnchor.constraint(equalToConstant: innerSize * CGFloat(tileCols)).isActive = true
        boardView.heightAnchor.constraint(equalToConstant: innerSize * CGFloat(tileRows)).isActive = true
        boardView.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor).isActive = true
        boardView.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor).isActive = true
        boardView.backgroundColor = .lightGray
        safeArea.setNeedsLayout()
        safeArea.layoutIfNeeded()
        pastBoardViewOrigin = boardView.frame.origin
    }

    func randomlyPlacePiecesInSafeArea() {
        pieceViews.values.forEach {
            $0.center = CGPoint(x: Double.random(in: innerSize/2..<safeArea.bounds.width - innerSize/2),
                                y: Double.random(in: innerSize/2..<safeArea.bounds.height - innerSize/2))
            if allowsRotation {
                let rotation = [0, 1, 2, 3].randomElement()! * 90.0 - 90  // -90, 0, 90, 180
                puzzle.pieces[pieceIndexFor($0).1].rotation = rotation
                $0.transform = $0.transform.rotated(by: rotation.CGrads)
            }
        }
    }
    
    func solvePuzzle(rows: Int, cols: Int) {
        UIView.animate(withDuration: 0.6, animations: {
            for row in 0..<rows {
                for col in 0..<cols {
                    let index = col + row * cols
                    let piece = self.puzzle.pieces[index]
                    let pieceView = self.pieceViews[piece.id]!
                    pieceView.center = self.boardView.frame.origin + CGPoint(x: self.innerSize * (0.5 + CGFloat(col)),
                                                                             y: self.innerSize * (0.5 + CGFloat(row)))
                    pieceView.transform = .identity  // un-rotate
                    self.puzzle.pieces[index].rotation = 0
                    self.puzzle.pieces[index].isAnchored = true
                    self.puzzle.pieces[index].groupNumber = self.nextGroupNumber
                    if col > 0 {
                        self.puzzle.pieces[index].connectedIndices.insert(index - 1)
                    }
                    if col < cols - 1 {
                        self.puzzle.pieces[index].connectedIndices.insert(index + 1)
                    }
                    if row > 0 {
                        self.puzzle.pieces[index].connectedIndices.insert(index - cols)
                    }
                    if row < rows - 1 {
                        self.puzzle.pieces[index].connectedIndices.insert(index + cols)
                    }
                }
            }
            self.nextGroupNumber += 1
        })
    }

    // snap panned edge piece to nearby side of boardView
    func snapToEdge(_ pannedPiece: Piece, _ pannedPieceView: PieceView) -> Bool {
        var isAnchored = false
        let snapDistance = PuzzleConst.snapDistance * innerSize
        let edgePositions = pannedPiece.edgePositions
        let groupedPieces = pannedPieceView.isHighlighted ? puzzle.piecesInGroup(pannedPiece.groupNumber) : [pannedPiece]
        if edgePositions.count > 0 {
            for edgePosition in edgePositions {
                let pieceCenterInBoardCoords = safeArea.convert(pannedPieceView.center, to: boardView)
                
                switch edgePosition {
                case 0: // up
                    let distanceToTop = abs(pieceCenterInBoardCoords.y - innerSize / 2)
                    if distanceToTop < snapDistance && pieceCenterInBoardCoords.x > 0 && pieceCenterInBoardCoords.x < boardView.bounds.maxX {
                        let deltaSnapPosition = boardView.convert(CGPoint(x: pieceCenterInBoardCoords.x, y: innerSize / 2), to: safeArea) - pannedPieceView.center
                        groupedPieces.forEach { pieceViews[$0.id]?.center += deltaSnapPosition}
                        isAnchored = true
                    }
                case 1: // right
                    let distanceToRight = abs(boardView.bounds.maxX - pieceCenterInBoardCoords.x - innerSize / 2)
                    if distanceToRight < snapDistance && pieceCenterInBoardCoords.y > 0 && pieceCenterInBoardCoords.y < boardView.bounds.maxY {
                        let deltaSnapPosition = boardView.convert(CGPoint(x: boardView.bounds.maxX - innerSize / 2, y: pieceCenterInBoardCoords.y), to: safeArea) - pannedPieceView.center
                        groupedPieces.forEach { pieceViews[$0.id]?.center += deltaSnapPosition}
                        isAnchored = true
                    }
                case 2: // down
                    let distanceToBottom = abs(boardView.bounds.maxY - pieceCenterInBoardCoords.y - innerSize / 2)
                    if distanceToBottom < snapDistance && pieceCenterInBoardCoords.x > 0 && pieceCenterInBoardCoords.x < boardView.bounds.maxX {
                        let deltaSnapPosition = boardView.convert(CGPoint(x: pieceCenterInBoardCoords.x, y: boardView.bounds.maxY - innerSize / 2), to: safeArea) - pannedPieceView.center
                        groupedPieces.forEach { pieceViews[$0.id]?.center += deltaSnapPosition}
                        isAnchored = true
                    }
                case 3: // left
                    let distanceToLeft = abs(pieceCenterInBoardCoords.x - innerSize / 2)
                    if distanceToLeft < snapDistance && pieceCenterInBoardCoords.y > 0 && pieceCenterInBoardCoords.y < boardView.bounds.maxY {
                        let deltaSnapPosition = boardView.convert(CGPoint(x: innerSize / 2, y: pieceCenterInBoardCoords.y), to: safeArea) - pannedPieceView.center
                        groupedPieces.forEach { pieceViews[$0.id]?.center += deltaSnapPosition}
                        isAnchored = true
                    }
                default:
                    break
                }
            }
        }
        return isAnchored
    }

    // snap panned piece to nearby mating piece(s), if any (may not be the correct one)
    // if two targets are in snap distance, only snap to the first, then determine if the other target
    // is aligned and mating
    func snapToPieces(_ pannedPiece: Piece, _ pannedPieceView: PieceView) -> [Int] {
        var snapTargetIndices = [Int]()
        var isSnapped = false
        let snapDistance = PuzzleConst.snapDistance * innerSize
        let targetPieceViews = pieceViews.filter { $0.value != pannedPieceView }  // all pieces, excluding panned piece
        for targetPieceView in targetPieceViews.values {
            let (targetPiece, targetPieceIndex) = pieceIndexFor(targetPieceView)
            let distanceToTarget = pannedPieceView.center.distance(from: targetPieceView.center)
            let isSnapDistance = distanceToTarget < innerSize + snapDistance && distanceToTarget > innerSize - snapDistance
            let isConnectDistance = abs(distanceToTarget - innerSize) < PuzzleConst.connectEpsilon
            if (isSnapped && isConnectDistance) || (!isSnapped && isSnapDistance) {
                // panned piece is within within connectDistance or snapDistance of potential target
                let bearingToPannedPiece = targetPieceView.center.bearing(to: pannedPieceView.center)
                let bearingInTargetFrame = (bearingToPannedPiece - targetPieceView.rotation).wrap360
                let bearingInPannedPieceFrame = (bearingToPannedPiece + 180 - pannedPieceView.rotation).wrap360
                if let targetSideIndex = sideIndexFor(bearing: bearingInTargetFrame),
                   let pannedPieceSideIndex = sideIndexFor(bearing: bearingInPannedPieceFrame) {
                    // panned piece is aligned horizontally or vertically to potential target
                    // within threshold and indices of sides facing each other obtained
                    if targetPiece.sides[targetSideIndex].mate == pannedPiece.sides[pannedPieceSideIndex] {
                        // panned piece and target have mating sides facing each other (snap them together, if first one)
                        if !isSnapped {
                            let deltaSnapPosition = targetPieceView.center + CGPoint(x: innerSize * sin(bearingToPannedPiece.round90.rads), y: -innerSize * cos(bearingToPannedPiece.round90.rads)) - pannedPieceView.center
                            let groupedPieces = pannedPieceView.isHighlighted ? puzzle.piecesInGroup(pannedPiece.groupNumber) : [pannedPiece]
                            groupedPieces.forEach { pieceViews[$0.id]?.center += deltaSnapPosition}
                            isSnapped = true
                        }
                        snapTargetIndices.append(targetPieceIndex)
                    }
                }
            }
        }
        return snapTargetIndices
    }
    
    func disconnectPiece( _ piece: Piece, _ pieceIndex: Int) {
        puzzle.pieces[pieceIndex].groupNumber = 0
        puzzle.removeConnectionsTo(pieceIndex)
        // check if panning of piece split group into two or more separate groups (give each group a new group number)
        let originalGroupPieceIndices = puzzle.pieceIndicesInGroup(piece.groupNumber)
        var handledPieceIndices = [Int]()  // keep track of which pieces have already been taken care of
        for originalGroupPieceIndex in originalGroupPieceIndices {
            if !handledPieceIndices.contains(originalGroupPieceIndex) {
                let newGroupIndices = connectedList([], for: originalGroupPieceIndex)
                newGroupIndices.forEach { puzzle.pieces[$0].groupNumber = (newGroupIndices.count == 1 ? 0 : nextGroupNumber) }
                nextGroupNumber += 1
                handledPieceIndices += newGroupIndices
            }
        }
    }
    
    func connectedList(_ list: [Int], for pieceIndex: Int) -> [Int] {
        var newList = list + [pieceIndex]
        let connectedIndices = puzzle.pieces[pieceIndex].connectedIndices
        for index in connectedIndices {
            if !newList.contains(index) {
                newList = connectedList(newList, for: index)  // call recursively
            }
        }
        return newList
    }

    // MARK: - Gestures
    
    @objc private func handlePan(recognizer: UIPanGestureRecognizer) {
        if let pannedPieceView = recognizer.view as? PieceView {
            let (pannedPiece, pannedPieceIndex) = pieceIndexFor(pannedPieceView)  // copy of piece (don't manipulate)
            switch recognizer.state {
            case .began:
                safeArea.bringSubviewToFront(pannedPieceView)
                if pannedPieceView.isHighlighted {
                    if pannedPiece.groupNumber == 0 {
                        // panning a single highlighted piece
                        panningPieceViews = [pannedPieceView]
                        initialCenters = [pannedPieceView.center]
                    } else {
                        // panning a group of highlighted pieces
                        let panningPieces = puzzle.piecesInGroup(pannedPiece.groupNumber)
                        panningPieceViews = panningPieces.map { pieceViews[$0.id]! }
                        initialCenters = panningPieces.map { pieceViews[$0.id]!.center }
                    }
                } else {
                    // panning a single un-highlighted piece
                    pieceViews.values.forEach { $0.isHighlighted = false }
                    panningPieceViews = [pannedPieceView]
                    initialCenters = [pannedPieceView.center]
                }
                
            case .changed:
                // move panned pieces together
                let translation = recognizer.translation(in: safeArea)
                for (index, panningPieceView) in panningPieceViews.enumerated() {
                    panningPieceView.center = (initialCenters[index] + translation)
                }
                puzzle.pieces[pannedPieceIndex].isAnchored = snapToEdge(pannedPiece, pannedPieceView)
                targetPieceIndices = snapToPieces(pannedPiece, pannedPieceView)  // pannedPiece snapped to these targets (may be empty)
                
            case .ended, .cancelled:
                if targetPieceIndices.count > 0 {
                    // pannedPiece connected to targetPiece(s)
                    puzzle.removeConnectionsTo(pannedPieceIndex)
                    targetPieceIndices.forEach { puzzle.pieces[pannedPieceIndex].connectedIndices.insert($0) }  // add target pieces to panned piece's connection
                    targetPieceIndices.forEach { puzzle.pieces[$0].connectedIndices.insert(pannedPieceIndex) }  // add panned piece to target's connection
                    
                    pieceViews.values.forEach { $0.isHighlighted = false }
                    var newGroupIndices = [pannedPieceIndex]
                    for targetPieceIndex in targetPieceIndices {
                        let targetPiece = puzzle.pieces[targetPieceIndex]  // copy of piece (don't manipulate)
                        if targetPiece.groupNumber == 0 {
                            // target isn't in a group (add it to new pannedPiece group)
                            newGroupIndices.append(targetPieceIndex)
                        } else {
                            // target is in a group (add its group to new pannedPiece group)
                            newGroupIndices += puzzle.pieceIndicesInGroup(targetPiece.groupNumber)
                        }
                    }
                    
                    // give entire connected group a new group number
                    newGroupIndices.forEach { puzzle.pieces[$0].groupNumber = nextGroupNumber }
                    nextGroupNumber += 1
                    
                    // if any in new group is anchored, anchor all
                    let isAnyAnchored = newGroupIndices.filter { puzzle.pieces[$0].isAnchored }.count > 0
                    if isAnyAnchored {
                        newGroupIndices.forEach { puzzle.pieces[$0].isAnchored = true }
                    }
                } else {
                    // pannedPiece disconnected from or didn't connect to other pieces
                    disconnectPiece(pannedPiece, pannedPieceIndex)
                }
            default:
                break
            }
        }
    }

    // rotate piece +90 degrees for single-tap, -90 degrees for double-tap (animated)
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        pieceViews.values.forEach { $0.isHighlighted = false }
        guard allowsRotation else { return }
        if let tappedPieceView = recognizer.view as? PieceView {
            let (tappedPiece, tappedPieceIndex) = pieceIndexFor(tappedPieceView)  // copy of piece (don't manipulate)
            if PuzzleConst.debugging && recognizer.numberOfTapsRequired == 1 {
                print("index: \(tappedPieceIndex), group: \(tappedPiece.groupNumber), isAnchored: \(tappedPiece.isAnchored), connections: \(tappedPiece.connectedIndices)")
            } else {
                disconnectPiece(tappedPiece, tappedPieceIndex)  // assume disconnected and un-anchored after rotation (may want to re-evaluate)
                puzzle.pieces[tappedPieceIndex].isAnchored = false
                safeArea.bringSubviewToFront(tappedPieceView)
                UIView.animate(withDuration: 0.2, animations: {
                    tappedPieceView.transform = tappedPieceView.transform.rotated(by: recognizer.numberOfTapsRequired == 1 ? 90.CGrads : -90.CGrads)
                })
            }
            
            // update model
            puzzle.pieces[pieceIndexFor(tappedPieceView).1].rotation = tappedPieceView.rotation
        }
    }

    @objc private func handleLongPress(recognizer: UIPanGestureRecognizer) {
        if let pressedPieceView = recognizer.view as? PieceView {
            if !pressedPieceView.isHighlighted {
                // first remove all highlighting, if long-pressed piece is unhighlighted
                pieceViews.values.forEach { $0.isHighlighted = false }
            }
            switch recognizer.state {
            case .began:
                let (pressedPiece, _) = pieceIndexFor(pressedPieceView)
                if pressedPiece.groupNumber == 0 {
                    // pressed piece not in a group (just toggle its highlight)
                    pressedPieceView.isHighlighted.toggle()
                    safeArea.bringSubviewToFront(pressedPieceView)
                } else {
                    // pressed piece in a group (toggle highlight of whole group)
                    // pws: if highlighting turned off, might want to ensure pieces aren't off screen (limit to safeArea)
                    let groupedPieces = puzzle.piecesInGroup(pressedPiece.groupNumber)
                    for piece in groupedPieces {
                        let pieceView = pieceViews[piece.id]!
                        pieceView.isHighlighted.toggle()
                        safeArea.bringSubviewToFront(pieceView)
                    }
                }
            default:
                break
            }
        }
    }
    
    // MARK: - Button Bar Actions
    
    @objc func showSettings() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let svc = storyboard.instantiateViewController(withIdentifier: "Settings") as? SettingsViewController {
            svc.allowsRotation = allowsRotation
            svc.isOutlined = isOutlined
            svc.pieceSizeSML = pieceSizeSML
            svc.updateSettings = { [weak self] in
                self?.allowsRotation = svc.allowsRotation
                self?.isOutlined = svc.isOutlined
                self?.pieceSizeSML = svc.pieceSizeSML
                self?.outerSize = svc.outerSize
                self?.innerSize = svc.outerSize * PuzzleConst.innerRatio
                self?.createPuzzle(from: self!.image)
                self?.saveUserDefaults()
            }
            navigationController?.pushViewController(svc, animated: true)
        }
    }
    
    // open picker controller to browse through photo library
    @objc func importPicture() {
        let picker = UIImagePickerController()
        picker.allowsEditing = false  // matches use of .originalImage in imagePickerController, below
        picker.delegate = self
        present(picker, animated: true)
    }
    
    // MARK: - Utilities
    
    func pieceIndexFor(_ pieceView: PieceView) -> (Piece, Int) {
        let pieceID = pieceIDFor(pieceView)
        let pieceIndex = puzzle.pieces.firstIndex(where: { $0.id == pieceID })!
        return (puzzle.pieces[pieceIndex], pieceIndex)
    }
    
    func pieceIDFor(_ pieceView: PieceView) -> UUID {
        pieceViews.getKey(forValue: pieceView)!
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
    
    // get image from picker when it closes (use it to create new puzzle)
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // .editedImage allows user to zoom or crop image while selecting, but image picker forces cropping in some orientations
        // .originalImage is the only way to get whole image in all orientations
        guard let pickerImage = info[.originalImage] as? UIImage else { return }
        dismiss(animated: true)  // dismiss picker
        image = pickerImage  // for iPad, since it calls viewDidAppear again
        createPuzzle(from: image)
    }
}
