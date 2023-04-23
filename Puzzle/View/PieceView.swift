//
//  PieceView.swift
//  Puzzle
//
//  Created by Phil Stern on 4/21/23.
//
//  Note: PieceView must be square.
//

import UIKit

struct PieceConst {
    static let insetFactor: CGFloat = 0.22  // start corner inset from frame corner, percent width
    static let radiusFactor: CGFloat = 0.08
    static let neckWidthFactor: CGFloat = 0.11
    static let controlPointLengthFactor: CGFloat = 0.05
    static let lineWidthFactor: CGFloat = 0.015
}

class PieceView: UIImageView {
    
    var sides: [Side]
    
    init(sides: [Side], image: UIImage) {
        self.sides = sides
        super.init(image: image)
        self.image = image.shapeImageTo(pathForSides(sides))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var first = true

    private lazy var frameCenter = CGPoint(x: frame.width / 2.0, y: frame.height / 2.0)
    private lazy var inset = PieceConst.insetFactor * bounds.width
    private lazy var radius = PieceConst.radiusFactor * bounds.width
    private lazy var neckWidth = PieceConst.neckWidthFactor * bounds.width
    private lazy var cpLength = PieceConst.controlPointLengthFactor * bounds.width
    private lazy var lineWidth = PieceConst.lineWidthFactor * bounds.width
    
    // rotate about point by translating (from 0,0) to point, rotating, and translating back
    private func transformToRotate(angle: Double, about point: CGPoint) -> CGAffineTransform {
        CGAffineTransform(translationX: point.x, y: point.y).rotated(by: CGFloat(angle)).translatedBy(x: -point.x, y: -point.y)
    }

    // create path for one edge at a time, rotating the path 90 deg between each;
    // path will pick up where the previous left off, but the coordinates will be
    // relative to the new orientation (PieceView must be square).
    func pathForSides(_ sides: [Side]) -> UIBezierPath {
        var outline = UIBezierPath()
        for index in 0..<4 {
            outline = addSide(sides[index], to: outline)
            outline.apply(transformToRotate(angle: -90.rads, about: frameCenter))
        }
        outline.close()
        return outline
    }

    private func addSide(_ side: Side, to path: UIBezierPath) -> UIBezierPath {
        let leftShoulder = CGPoint(x: inset, y: inset)
        let rightShoulder = CGPoint(x: bounds.width - inset, y: inset)

        if first {
            first = false
            path.move(to: leftShoulder)
        }

        if side.type == .edge {
            path.addLine(to: rightShoulder)
        } else {
            let sign: CGFloat = side.type == .knob ? 1 : -1
            let tabCenter = leftShoulder + CGPoint(x: side.tabPosition * (rightShoulder.x - leftShoulder.x),
                                                   y: -sign * (leftShoulder.y - radius - lineWidth / 2))
            
            let leftNeck = tabCenter.offsetBy(dx: -neckWidth / 2, dy: sign * 1.1 * radius)
            let leftNeckCP1 = leftShoulder.offsetBy(dx: cpLength, dy: 0)
            let leftNeckCP2 = leftNeck.offsetBy(dx: 0, dy: sign * cpLength)
            
            let leftEar = tabCenter.offsetBy(dx: -radius, dy: 0)
            let leftEarCP1 = leftNeck.offsetBy(dx: 0, dy: -sign * cpLength)
            let leftEarCP2 = leftEar.offsetBy(dx: 0, dy: sign * cpLength)
            
            let rightEar = tabCenter.offsetBy(dx: radius, dy: 0)
            let rightNeck = leftNeck.offsetBy(dx: neckWidth, dy: 0)
            let rightNeckCP1 = rightEar.offsetBy(dx: 0, dy: sign * cpLength)
            let rightNeckCP2 = rightNeck.offsetBy(dx: 0, dy: -sign * cpLength)
            
            let endCP1 = rightNeck.offsetBy(dx: 0, dy: sign * cpLength)
            let endCP2 = rightShoulder.offsetBy(dx: -cpLength, dy: 0)
            
            path.addCurve(to: leftNeck, controlPoint1: leftNeckCP1, controlPoint2: leftNeckCP2)
            path.addCurve(to: leftEar, controlPoint1: leftEarCP1, controlPoint2: leftEarCP2)
            path.addArc(withCenter: tabCenter, radius: radius, startAngle: CGFloat.pi, endAngle: 0, clockwise: side.type == .knob)
            path.addCurve(to: rightNeck, controlPoint1: rightNeckCP1, controlPoint2: rightNeckCP2)
            path.addCurve(to: rightShoulder, controlPoint1: endCP1, controlPoint2: endCP2)
        }
        
        return path
    }
}
