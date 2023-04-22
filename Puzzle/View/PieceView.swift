//
//  PieceView.swift
//  Puzzle
//
//  Created by Phil Stern on 4/21/23.
//
//  Making each quadrant a separate shape layer has drawbacks
//  - you can't outline the final piece; you don't want to outline the separate quadrants
//  - you can't easily close the path, without passing through a blank, or leaving gaps between the quadrants
//

import UIKit

struct PieceConst {
    static let lineWidthFactor: CGFloat = 0.002
    static let insetFactor: CGFloat = 0.22
    static let radiusFactor: CGFloat = 0.08
    static let neckWidthFactor: CGFloat = 0.1
}

class PieceView: UIView {
    
    var sides: [Side] = [
        .init(shape: .blank, centerFactor: 0.4),
        .init(shape: .tab, centerFactor: 0.4),
        .init(shape: .edge),
        .init(shape: .tab, centerFactor: 0.5),
    ]
    
    lazy var inset = PieceConst.insetFactor * bounds.width
    lazy var radius = PieceConst.radiusFactor * bounds.width
    lazy var neckWidth = PieceConst.neckWidthFactor * bounds.width

    override func draw(_ rect: CGRect) {
        for index in 0..<4 {
            let transform = CATransform3DMakeRotation(CGFloat(index) * 90.rads, 0, 0, 1)  // rotates about center of BoardView
            
            let side = makeSide(sides[index])
            addLayer(side, with: transform)
        }
    }
    
    private func addLayer(_ layer: CAShapeLayer, with transform: CATransform3D) {
        layer.transform = transform
        self.layer.addSublayer(layer)
    }
    
    private func createShapeLayer(from path: UIBezierPath) -> CAShapeLayer {
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
//        shapeLayer.strokeColor = UIColor.black.cgColor
//        shapeLayer.lineWidth = PieceConst.lineWidthFactor * bounds.width
        shapeLayer.fillColor = UIColor.blue.cgColor
        shapeLayer.bounds = bounds
        shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)  // place center of drawing at middle of board
        return shapeLayer
    }

    private func makeSide(_ side: Side) -> CAShapeLayer {
        let start = CGPoint(x: inset, y: inset)
        let end = CGPoint(x: bounds.width - inset, y: inset)

        let edge = UIBezierPath()
        edge.move(to: start)

        if side.shape == .edge {
            edge.addLine(to: end)
        } else {
            let shapeSign: CGFloat = side.shape == .tab ? 1.0 : -1.0
            let cpDistance: CGFloat = 6.0
            let tabCenter = start + CGPoint(x: side.shapeOffsetFactor * (end.x - start.x), y: -shapeSign * (start.y - radius))
            
            let leftNeck = tabCenter.offsetBy(dx: -neckWidth / 2, dy: shapeSign * (radius + neckWidth / 2))
            let leftNeckCP1 = start.offsetBy(dx: cpDistance, dy: 0)
            let leftNeckCP2 = leftNeck.offsetBy(dx: 0, dy: shapeSign * cpDistance)
            
            let leftEar = tabCenter.offsetBy(dx: -radius, dy: 0)
            let leftEarCP1 = leftNeck.offsetBy(dx: 0, dy: -shapeSign * cpDistance)
            let leftEarCP2 = leftEar.offsetBy(dx: 0, dy: shapeSign * cpDistance)
            
            let rightEar = tabCenter.offsetBy(dx: radius, dy: 0)
            let rightNeck = leftNeck.offsetBy(dx: neckWidth, dy: 0)
            let rightNeckCP1 = rightEar.offsetBy(dx: 0, dy: shapeSign * cpDistance)
            let rightNeckCP2 = rightNeck.offsetBy(dx: 0, dy: -shapeSign * cpDistance)
            
            let endCP1 = rightNeck.offsetBy(dx: 0, dy: shapeSign * cpDistance)
            let endCP2 = end.offsetBy(dx: -cpDistance, dy: 0)
            
            edge.addCurve(to: leftNeck, controlPoint1: leftNeckCP1, controlPoint2: leftNeckCP2)
            edge.addCurve(to: leftEar, controlPoint1: leftEarCP1, controlPoint2: leftEarCP2)
            edge.addArc(withCenter: tabCenter, radius: radius, startAngle: CGFloat.pi, endAngle: 0, clockwise: side.shape == .tab)
            edge.addCurve(to: rightNeck, controlPoint1: rightNeckCP1, controlPoint2: rightNeckCP2)
            edge.addCurve(to: end, controlPoint1: endCP1, controlPoint2: endCP2)
        }
        edge.addLine(to: CGPoint(x: bounds.width / 2, y: bounds.height / 2))
        edge.close()

        let shapeLayer = createShapeLayer(from: edge)  // add path to CAShapeLayer so it can be rotated
        
        return shapeLayer
    }
}
