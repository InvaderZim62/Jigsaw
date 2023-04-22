//
//  Piece.swift
//  Puzzle
//
//  Created by Phil Stern on 4/21/23.
//

import Foundation

struct Piece {
    var sides: [Side] = [
        .init(type: Type.random()),
        .init(type: Type.random()),
        .init(type: Type.random()),
        .init(type: Type.random()),
    ]
}
