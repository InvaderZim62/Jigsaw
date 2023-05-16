//
//  Puzzle.swift
//  Puzzle
//
//  Created by Phil Stern on 5/3/23.
//

import Foundation

struct Puzzle {
    
    var rows: Int
    var cols: Int
    var pieces: [Piece]  // index = col + row * cols
    
    init(rows: Int = 0, cols: Int = 0) {
        self.rows = rows
        self.cols = cols
        pieces = Puzzle.createPieces(rows: rows, cols: cols)
    }
    
    // return all pieces for a given group number
    func piecesInGroup(_ groupNumber: Int) -> [Piece] {
        return pieces.filter { $0.groupNumber == groupNumber }
    }
    
    func piecesNotInGroup(_ groupNumber: Int) -> [Piece] {
        return pieces.filter { $0.groupNumber != groupNumber }
    }

    // return all piece indices for a given group number
    func pieceIndicesInGroup(_ groupNumber: Int) -> [Int] {
        return pieces.indices.filter { pieces[$0].groupNumber == groupNumber }
    }
    
    // remove all connections from piece (index) and remove piece from all other pieces' connections
    mutating func removeConnectionsTo(_ index: Int) {
        pieces[index].connectedIndices = []
        pieces.indices.forEach { pieces[$0].connectedIndices.remove(index) }
    }
    
    // create randomly fitting pieces in an array of end-to-end rows
    // note: images are applied in PieceView
    static func createPieces(rows: Int, cols: Int) -> [Piece] {
        var pieces = [Piece]()
        
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
        
        return pieces
    }
}
