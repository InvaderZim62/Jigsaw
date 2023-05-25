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
    
    static func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    
    static func +=(lhs: inout CGPoint, rhs: CGPoint) {
        lhs = lhs + rhs
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

extension UIImage {
    // create rectangular image of given color and size
    // usage: let redImage = UIImage(color: .red, size: CGSize(width: 200, height: 200))
    // from: https://stackoverflow.com/questions/26542035
    convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage, scale: image!.scale, orientation: image!.imageOrientation)
    }
    
    // compute size of rectangle with aspect ratio of image that fits in container
    // for example, if image is 1000 x 500, and container is 100 x 100, return 100 x 50
    func sizeToFit(_ containerSize: CGSize) -> CGSize {
        let imageAspectRatio = size.width / size.height
        let containerAspectRatio = containerSize.width / containerSize.height
        if imageAspectRatio > containerAspectRatio {
            // width-limited
            return CGSize(width: containerSize.width, height: containerSize.width / imageAspectRatio)
        } else {
            // height-limited
            return CGSize(width: containerSize.height * imageAspectRatio, height: containerSize.height)
        }
    }

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
    func clipImageTo(_ path: UIBezierPath, isOutlined: Bool, isHighlighted: Bool) -> UIImage {
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        
        context?.addPath(path.cgPath)
        context?.clip()
        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        if isHighlighted {
            context?.addPath(path.cgPath)
            context?.setStrokeColor(UIColor.green.cgColor)
            context?.setLineWidth(2)
            context?.strokePath()
        } else if isOutlined {
            context?.addPath(path.cgPath)
            context?.setStrokeColor(UIColor.black.cgColor)
            context?.setLineWidth(1.2)
            context?.strokePath()
        }

        let maskedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return maskedImage
    }
    
    // break image into 2D array of tiles of given size
    // note: integer number of tiles will not cover entire image, so some cropping will occur around the edges (image centered)
    // from: https://stackoverflow.com/questions/42076184
    func extractTiles(with tileSize: CGSize, overlap: CGFloat) -> [[UIImage]]? {  // tile[row][col]
        let cols = Int(size.width / (tileSize.width - overlap))
        let rows = Int(size.height / (tileSize.height - overlap))
        let croppedWidth = size.width - CGFloat(cols) * (tileSize.width - overlap)
        let croppedHeight = size.height - CGFloat(rows) * (tileSize.height - overlap)

        var tiles = [[UIImage]]()

        for row in 0...rows - 1 {
            var tileRow = [UIImage]()
            for col in 0...cols - 1 {
                let imagePoint = CGPoint(x: -croppedWidth / 2 + overlap / 2 - CGFloat(col) * (tileSize.width - overlap),
                                         y: -croppedHeight / 2 + overlap / 2 - CGFloat(row) * (tileSize.height - overlap))
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
