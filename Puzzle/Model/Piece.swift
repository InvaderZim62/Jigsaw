//
//  Piece.swift
//  Puzzle
//
//  Created by Phil Stern on 4/21/23.
//

import Foundation

// IDable replicates the Identifiable protocol (available on iOS 13+) for older devices
protocol IDable {
    var id: UUID { get set }
}

struct Piece: IDable {  // IDable for index(matching:) in extension Collection
    var sides: [Side]
    var id = UUID()
    var rotation = 0.0  // +/- 180 degrees, zero is up, pos is clockwise
    var isConnected = false  // true if connected to edge, directly or through a series of pieces
    
    var edgeIndices: [Int] {  // 0: sides[0], 1: sides[1], ...
        sides.indices.filter { sides[$0].type == .edge }
    }
    
    var edgePositions: [Int] {  // 0: up, 1: right, 2: down, 3: left
        edgeIndices.map { ($0 + Int(round((rotation + 360) / 90))) % sides.count }  // +360, to avoid mod of negative index
    }
}

extension Piece: Hashable {  // Hashable to use as dictionary key
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Piece, rhs: Piece) -> Bool {
        lhs.id == rhs.id
    }
}

extension Piece: CustomStringConvertible {
    var description: String {
        var string = "isConnected: \(isConnected)\n"
        for (index, side) in sides.enumerated() {
            string += "\(index): \(side)\n"
        }
        return string
    }
}
