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

struct Piece: IDable, Hashable {  // IDable for index(matching:) in extension Collection, Hashable to use as dictionary key
    let sides: [Side]
    var id = UUID()
    var rotation = 0.0  // +/- pi, zero is up, pos is clockwise

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Piece, rhs: Piece) -> Bool {
        lhs.id == rhs.id
    }
}
