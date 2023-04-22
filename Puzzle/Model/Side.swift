//
//  Side.swift
//  Puzzle
//
//  Created by Phil Stern on 4/21/23.
//

import Foundation

struct Side {
    let shape: Shape
    let tabPosition: CGFloat  // percentage from edge for tab or hole
    
    init(shape: Shape, tabPosition: CGFloat = 0.5) {
        self.shape = shape
        self.tabPosition = tabPosition
    }
}

enum Shape: CaseIterable {
    case tab
    case hole
    case flat
    
    static func random() -> Shape {
        Shape.allCases.randomElement()!
    }
}
