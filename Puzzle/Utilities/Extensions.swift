//
//  Extensions.swift
//  Puzzle
//
//  Created by Phil Stern on 4/21/23.
//

import UIKit

extension Double {
    var rads: CGFloat {
        return CGFloat(self) * CGFloat.pi / 180.0
    }
}

extension CGPoint {
    static func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    func offsetBy(dx: CGFloat, dy: CGFloat) -> CGPoint {
        return CGPoint(x: x + dx, y: y + dy)
    }
}
