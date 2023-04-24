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
    
    var CGrads: CGFloat {
        return CGFloat(self * .pi / 180)
    }
}

//extension CGFloat {
//    var degs: CGFloat {
//        return self * 180.0 / CGFloat.pi
//    }
//}

extension Dictionary where Value: Equatable {
    func someKey(forValue val: Value) -> Key? {  // usage: let key = dict.someKey(forValue: val)
        first(where: { $1 == val })?.key
    }
}

extension CGPoint {
    static func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    func offsetBy(dx: CGFloat, dy: CGFloat) -> CGPoint {
        return CGPoint(x: x + dx, y: y + dy)
    }
    
    func limitedToView(_ view: UIView) -> CGPoint {
        let limitedX = min(view.bounds.maxX, max(view.bounds.minX, x))  // use bounds, since pawnViews are subviews of the view passed in (boardView)
        let limitedY = min(view.bounds.maxY, max(view.bounds.minY, y))  // use frame, if pawnViews are subviews of SorryViewController.view
        return CGPoint(x: limitedX, y: limitedY)
    }
    
    func limitedToView(_ view: UIView, withHorizontalInset horizontalInset: CGFloat, andVerticalInset verticalInset: CGFloat) -> CGPoint {
        let limitedX = min(view.bounds.maxX - horizontalInset, max(view.bounds.minX + horizontalInset, x))
        let limitedY = min(view.bounds.maxY - verticalInset, max(view.bounds.minY + verticalInset, y))
        return CGPoint(x: limitedX, y: limitedY)
    }
}

// IDable replicates the Identifiable protocol (available on iOS 13+) for older devices
extension Collection where Element: IDable {
    func index(matching element: Element) -> Self.Index? {
        firstIndex(where: { $0.id == element.id })
    }
}

extension UIImage {
    // from: https://stackoverflow.com/questions/49853122
    func shapeImageTo(_ path: UIBezierPath) -> UIImage {
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        
        context?.addPath(path.cgPath)
        context?.clip()
        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        let maskedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return maskedImage
    }
    
    // from: https://stackoverflow.com/questions/42076184
    func extractTiles(with tileSize: CGSize, overlap: CGFloat) -> [[UIImage]]? {
        let cols = Int(size.width / (tileSize.width - overlap))
        let rows = Int(size.height / (tileSize.height - overlap))

        var tiles = [[UIImage]]()

        for row in 0...rows - 1 {
            var tileRow = [UIImage]()
            for col in 0...cols - 1 {
                let imagePoint = CGPoint(x: overlap / 2 - CGFloat(col) * (tileSize.width - overlap),
                                         y: overlap / 2 - CGFloat(row) * (tileSize.height - overlap))
                UIGraphicsBeginImageContextWithOptions(tileSize, false, 0.0)
                draw(at: imagePoint)
                if let newImage = UIGraphicsGetImageFromCurrentImageContext() {
                    tileRow.append(newImage)
                }
                UIGraphicsEndImageContext()
            }
            tiles.append(tileRow)
        }

        return tiles
    }
}
