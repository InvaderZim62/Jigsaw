//
//  PieceView.swift
//  Puzzle
//
//  Created by Phil Stern on 4/21/23.
//

import UIKit

struct PieceConst {
    static let insetFactor: CGFloat = 0.22  // start corner inset from frame corner, percent width
    static let radiusFactor: CGFloat = 0.08
    static let neckWidthFactor: CGFloat = 0.11
    static let controlPointLengthFactor: CGFloat = 0.05
    static let lineWidthFactor: CGFloat = 0.02
}

class PieceView: UIView {
    
    var sides: [Side] = [
        .init(shape: .tab, centerFactor: 0.4),
        .init(shape: .blank, centerFactor: 0.4),
        .init(shape: .edge),
        .init(shape: .blank, centerFactor: 0.5),
    ]
    
    lazy var frameCenter = CGPoint(x: frame.width / 2.0, y: frame.height / 2.0)
    lazy var inset = PieceConst.insetFactor * bounds.width
    lazy var radius = PieceConst.radiusFactor * bounds.width
    lazy var neckWidth = PieceConst.neckWidthFactor * bounds.width
    lazy var cpLength = PieceConst.controlPointLengthFactor * bounds.width
    lazy var lineWidth = PieceConst.lineWidthFactor * bounds.width
    
    var first = true
    
    // rotate about point by translating (from 0,0) to point, rotating, and translating back
    private func transformToRotate(angle: Double, about point: CGPoint) -> CGAffineTransform {
        CGAffineTransform(translationX: point.x, y: point.y).rotated(by: CGFloat(angle)).translatedBy(x: -point.x, y: -point.y)
    }

    override func draw(_ rect: CGRect) {
        var edge = UIBezierPath()
        for index in 0..<4 {
            edge = addSide(sides[index], edge: edge)
            edge.apply(transformToRotate(angle: -90.rads, about: frameCenter))
        }
        edge.close()
        UIColor.black.setStroke()
        edge.lineWidth = lineWidth
        edge.stroke()
        UIColor.blue.setFill()
        edge.fill()
    }

    private func addSide(_ side: Side, edge: UIBezierPath) -> UIBezierPath {
        let start = CGPoint(x: inset, y: inset)
        let end = CGPoint(x: bounds.width - inset, y: inset)
        let tabOffset = side.tabOffsetFactor * (end.x - start.x)

        if first {
            first = false
            edge.move(to: start)
        }

        if side.shape == .edge {
            edge.addLine(to: end)
        } else {
            let shapeSign: CGFloat = side.shape == .tab ? 1.0 : -1.0
            let tabCenter = start + CGPoint(x: tabOffset, y: -shapeSign * (start.y - radius - lineWidth / 2))
            
            let leftNeck = tabCenter.offsetBy(dx: -neckWidth / 2, dy: shapeSign * 1.1 * radius)
            let leftNeckCP1 = start.offsetBy(dx: cpLength, dy: 0)
            let leftNeckCP2 = leftNeck.offsetBy(dx: 0, dy: shapeSign * cpLength)
            
            let leftEar = tabCenter.offsetBy(dx: -radius, dy: 0)
            let leftEarCP1 = leftNeck.offsetBy(dx: 0, dy: -shapeSign * cpLength)
            let leftEarCP2 = leftEar.offsetBy(dx: 0, dy: shapeSign * cpLength)
            
            let rightEar = tabCenter.offsetBy(dx: radius, dy: 0)
            let rightNeck = leftNeck.offsetBy(dx: neckWidth, dy: 0)
            let rightNeckCP1 = rightEar.offsetBy(dx: 0, dy: shapeSign * cpLength)
            let rightNeckCP2 = rightNeck.offsetBy(dx: 0, dy: -shapeSign * cpLength)
            
            let endCP1 = rightNeck.offsetBy(dx: 0, dy: shapeSign * cpLength)
            let endCP2 = end.offsetBy(dx: -cpLength, dy: 0)
            
            edge.addCurve(to: leftNeck, controlPoint1: leftNeckCP1, controlPoint2: leftNeckCP2)
            edge.addCurve(to: leftEar, controlPoint1: leftEarCP1, controlPoint2: leftEarCP2)
            edge.addArc(withCenter: tabCenter, radius: radius, startAngle: CGFloat.pi, endAngle: 0, clockwise: side.shape == .tab)
            edge.addCurve(to: rightNeck, controlPoint1: rightNeckCP1, controlPoint2: rightNeckCP2)
            edge.addCurve(to: end, controlPoint1: endCP1, controlPoint2: endCP2)
        }
        
        return edge
    }
}
