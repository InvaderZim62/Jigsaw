//
//  Puzzle.swift
//  Puzzle
//
//  Created by Phil Stern on 5/3/23.
//

import UIKit

struct Puzzle {
    
    var rows = 0
    var cols = 0
    var pieces = [Piece]()  // index = col + row * cols

    // resize image and split into overlapping squares
    mutating func createTiles(from image: UIImage, fitting container: UIView) -> [[UIImage]] {
        let globalData = GlobalData.sharedInstance

        // compute maximum size that fits in container, while maintaining image aspect ratio
        let fitSize = sizeToFit(image, in: container)

        let resizedImage = image.resizedTo(fitSize)

        let tiles = resizedImage.extractTiles(with: CGSize(width: globalData.outerSize, height: globalData.outerSize),
                                              overlap: globalData.outerSize - globalData.innerSize)!
        rows = tiles.count
        cols = tiles[0].count
        
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
    
    // create randomly fitting pieces in an array of end-to-end rows
    mutating func createPieces() {
        pieces.removeAll()
        
        for row in 0..<rows {
            for col in 0..<cols {
                let index = col + row * cols
                // move from left to right, top to bottom; top side must mate to piece above (unless first row edge);
                // left side must mate to previous piece (unless first col edge); remaining sides are random or edges
                var sides: [Side] = [
                    row == 0 ? Side(type: .edge) : pieces[index - cols].sides[2].mate,  // top side
                    col == cols - 1 ? Side(type: .edge) : Side.random(),                // right side
                    row == rows - 1 ? Side(type: .edge) : Side.random(),                // bottom side
                    col == 0 ? Side(type: .edge) : pieces[index - 1].sides[1].mate,     // left side
                ]
                // move right-side hole to avoid overlapping top-side hole
                if sides[1].type == .hole && sides[0].type == .hole {
                    sides[1].tabPosition = max(sides[1].tabPosition, sides[0].tabPosition - 0.05)
                }
                // move bottom-side hole to avoid overlapping right-side hole
                if sides[2].type == .hole && sides[1].type == .hole {
                    sides[2].tabPosition = max(sides[2].tabPosition, sides[1].tabPosition - 0.05)
                }
                // move bottom-side hole to avoid overlapping left-side hole
                if sides[2].type == .hole && sides[3].type == .hole {
                    if sides[1].type == .hole && sides[1].tabPosition >= 0.5 && sides[3].tabPosition <= 0.5 {
                        // bottom-side hole sandwiched between left- and right-side holes
                        sides[2].tabPosition = 0.5
                    } else {
                        sides[2].tabPosition = min(sides[2].tabPosition, sides[3].tabPosition + 0.05)
                    }
                }
                // move right-side tab, to avoid overlapping left- and top-side holes on piece to the right
                if row > 0 && col < cols - 1 && sides[1].type == .tab && pieces[index - cols + 1].sides[2].type == .tab {
                    sides[1].tabPosition = max(sides[1].tabPosition, pieces[index - cols + 1].sides[2].tabPosition - 0.05)
                }
                let piece = Piece(sides: sides)
                pieces.append(piece)
            }
        }
    }
}
