//
//  Piece.swift
//  Puzzle
//
//  Created by Phil Stern on 4/21/23.
//

import Foundation

struct Piece {
    var sides: [Side] = [
        .init(shape: Shape.random()),
        .init(shape: Shape.random()),
        .init(shape: Shape.random()),
        .init(shape: Shape.random()),
    ]
}
