//
//  PieceView.swift
//  Puzzle
//
//  Created by Phil Stern on 4/21/23.
//
//  PieceView is the inner portion of the puzzle piece.  It includes a larger subview (imageView)
//  for drawing the complete piece.  It was done this way, so a pan gesture can be attached to the
//  inner portion of the piece, yet still move the whole picture.  If a pan gesture is attached to
//  the complete puzzle piece, the pan gestures would overlap, since the puzzle pieces overlap when
//  connected.
//
//  Note: PieceView must be square, for the drawing and clipping of the image to work.
//

import UIKit

struct PieceConst {
    static let tabRadiusFactor: CGFloat = 0.08  // use PuzzleConst.innerRatio to change how far tabs cut into neighboring pieces (not radius)
    static let neckWidthFactor: CGFloat = 0.11
    static let controlPointLengthFactor: CGFloat = 0.05  // bigger cp => bigger radius splines
    static let lineWidthFactor: CGFloat = 0.015
}

class PieceView: UIView {
    
    var sides: [Side]
    var image: UIImage
    var outerSize: CGFloat
    var isOutlined: Bool {  // black outline
        didSet {
            imageView.image = image.clipImageTo(pathForSides(sides), isOutlined: isOutlined, isHighlighted: isHighlighted)
        }
    }
    
    var isHighlighted = false {  // green outline
        didSet {
            imageView.image = image.clipImageTo(pathForSides(sides), isOutlined: isOutlined, isHighlighted: isHighlighted)
        }
    }

    var rotation: CGFloat {
        atan2(self.transform.b, self.transform.a).degs  // +/-180 degrees, zero is up, pos is clockwise
    }
    
    private var first = true
    private var imageView = UIImageView()  // larger view to hold image
    
    init(sides: [Side], image: UIImage, innerSize: CGFloat, isOutlined: Bool) {
        self.sides = sides
        self.image = image
        self.isOutlined = isOutlined
        outerSize = innerSize / PuzzleConst.innerRatio
        super.init(frame: CGRect.zero)  // compiler complains if this isn't here
        imageView.frame = CGRect(x: 0, y: 0, width: outerSize, height: outerSize)
        imageView.center = CGPoint(x: innerSize / 2, y: innerSize / 2)
        imageView.image = image.clipImageTo(pathForSides(sides), isOutlined: isOutlined, isHighlighted: false)
        addSubview(imageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // lazy, since they use bounds (ok to use during init, since not using constraints)
    private lazy var frameCenter = CGPoint(x: imageView.frame.width / 2.0, y: imageView.frame.height / 2.0)
    private lazy var tabRadius = PieceConst.tabRadiusFactor * imageView.bounds.width
    private lazy var neckWidth = PieceConst.neckWidthFactor * imageView.bounds.width
    private lazy var cpLength = PieceConst.controlPointLengthFactor * imageView.bounds.width
    private lazy var lineWidth = PieceConst.lineWidthFactor * imageView.bounds.width
    
    // rotate about point by translating (from 0,0) to point, rotating, and translating back
    private func transformToRotate(angle: Double, about point: CGPoint) -> CGAffineTransform {
        CGAffineTransform(translationX: point.x, y: point.y).rotated(by: CGFloat(angle)).translatedBy(x: -point.x, y: -point.y)
    }

    // create path for one edge at a time, rotating the path 90 deg between each; path will pick up where the
    // previous left off, but the coordinates will be relative to the new orientation (PieceView must be square).
    // Note: outline is applied in extension UIImage.clipImageTo(path:isOutlined:)
    func pathForSides(_ sides: [Side]) -> UIBezierPath {
        first = true
        var path = UIBezierPath()
        for index in 0..<4 {
            path = addSide(sides[index], to: path)
            path.apply(transformToRotate(angle: -90.rads, about: frameCenter))
        }
        path.close()
        return path
    }

    private func addSide(_ side: Side, to path: UIBezierPath) -> UIBezierPath {
        let inset = outerSize * (1 - PuzzleConst.innerRatio) / 2
        let leftShoulder = CGPoint(x: inset, y: inset)
        let rightShoulder = CGPoint(x: imageView.bounds.width - inset, y: inset)

        if first {
            first = false
            path.move(to: leftShoulder)
        }

        if side.type == .edge {
            path.addLine(to: rightShoulder)
        } else {
            let sign: CGFloat = side.type == .tab ? 1 : -1
            let tabCenter = leftShoulder + CGPoint(x: side.tabPosition * (rightShoulder.x - leftShoulder.x),
                                                   y: -sign * (leftShoulder.y - tabRadius - lineWidth / 2))  // ie. tabRadius from top, for tab
            
            let leftNeck = tabCenter.offsetBy(dx: -neckWidth / 2, dy: sign * leftShoulder.y / 2)  // midway between bottom of tab circle and shoulder
            let leftNeckCP1 = leftShoulder.offsetBy(dx: cpLength, dy: 0)
            let leftNeckCP2 = leftNeck.offsetBy(dx: 0, dy: sign * cpLength)
            
            let leftEar = tabCenter.offsetBy(dx: -tabRadius, dy: 0)
            let leftEarCP1 = leftNeck.offsetBy(dx: 0, dy: -sign * cpLength)
            let leftEarCP2 = leftEar.offsetBy(dx: 0, dy: sign * cpLength)
            
            let rightEar = tabCenter.offsetBy(dx: tabRadius, dy: 0)
            let rightNeck = leftNeck.offsetBy(dx: neckWidth, dy: 0)
            let rightNeckCP1 = rightEar.offsetBy(dx: 0, dy: sign * cpLength)
            let rightNeckCP2 = rightNeck.offsetBy(dx: 0, dy: -sign * cpLength)
            
            let endCP1 = rightNeck.offsetBy(dx: 0, dy: sign * cpLength)
            let endCP2 = rightShoulder.offsetBy(dx: -cpLength, dy: 0)
            
            path.addCurve(to: leftNeck, controlPoint1: leftNeckCP1, controlPoint2: leftNeckCP2)
            path.addCurve(to: leftEar, controlPoint1: leftEarCP1, controlPoint2: leftEarCP2)
            path.addArc(withCenter: tabCenter, radius: tabRadius, startAngle: CGFloat.pi, endAngle: 0, clockwise: side.type == .tab)
            path.addCurve(to: rightNeck, controlPoint1: rightNeckCP1, controlPoint2: rightNeckCP2)
            path.addCurve(to: rightShoulder, controlPoint1: endCP1, controlPoint2: endCP2)
        }
        
        return path
    }
}
