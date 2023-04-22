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
