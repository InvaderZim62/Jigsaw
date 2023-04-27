//
//  Extensions.swift
//  Puzzle
//
//  Created by Phil Stern on 4/21/23.
//

import UIKit

extension Double {
    var rads: CGFloat {
        CGFloat(self) * CGFloat.pi / 180.0
    }
    
    var CGrads: CGFloat {
        CGFloat(self * .pi / 180)
    }
    
    // converts angle to 0 - 360
    var wrap360: Double {
        var wrappedAngle = self
        if self >= 360.0 {
            wrappedAngle -= 360.0
        } else if self < 0 {
            wrappedAngle += 360.0
        }
        return wrappedAngle
    }
    
    // rounds to nearest 90 degrees (assumes self is 0 to 360 deg)
    var round90: Double {
        if self < 45 {
            return 0
        } else if self < 135 {
            return 90
        } else if self < 225 {
            return 180
        } else if self < 315 {
            return 270
        } else {
            return 0
        }
    }
}

extension CGFloat {
    var degs: Double {
        Double(self) * 180 / Double.pi
    }
}

extension Dictionary where Value: Equatable {
    func getKey(forValue val: Value) -> Key? {  // usage: let key = dict.getKey(forValue: val)
        first(where: { $1 == val })?.key
    }
}

extension CGPoint {
    static func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    func distance(from point: CGPoint) -> Double {
        sqrt(pow((self.x - point.x), 2) + pow((self.y - point.y), 2))
    }

    func offsetBy(dx: CGFloat, dy: CGFloat) -> CGPoint {
        CGPoint(x: x + dx, y: y + dy)
    }
    
    // return bearing from 0 to 360, where 0 is up, positive is clockwise
    func bearing(to point: CGPoint) -> Double {
        (atan2(Double(point.x - self.x), Double(-point.y + self.y)) * 180 / Double.pi).wrap360
    }

    func limitedToView(_ view: UIView) -> CGPoint {
        let limitedX = min(view.bounds.maxX, max(view.bounds.minX, x))  // use bounds, since pieceViews are subviews of the view passed in (safeArea)
        let limitedY = min(view.bounds.maxY, max(view.bounds.minY, y))  // use frame, if pieceViews are subviews of ViewController.view
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
    // resize image to fit container, without changing aspect ratio
    // from: https://stackoverflow.com/questions/44715322
    func resizedTo(_ newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContext(newSize)
        
        draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return resizedImage
    }

    // from: https://stackoverflow.com/questions/49853122
    func clipImageTo(_ path: UIBezierPath) -> UIImage {
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        
        context?.addPath(path.cgPath)
        context?.clip()
        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        // add outline
        context?.addPath(path.cgPath)
        context?.setStrokeColor(UIColor.black.cgColor)
        context?.setLineWidth(2)
        context?.strokePath()

        let maskedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return maskedImage
    }
    
    // break image into 2D array of tiles of given size
    // from: https://stackoverflow.com/questions/42076184
    func extractTiles(with tileSize: CGSize, overlap: CGFloat) -> [[UIImage]]? {  // tile[row][col]
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
