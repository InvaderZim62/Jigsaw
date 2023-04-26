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
    var rotation = 0.0  // degrees, zero is up, pos is clockwise
    
    var isConnected: Bool {
        sides.filter { $0.isConnected }.count > 0
    }
    
    var edgeIndices: [Int] {
        sides.indices.filter { sides[$0].type == .edge }
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
