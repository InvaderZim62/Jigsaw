//
//  Side.swift
//  Puzzle
//
//  Created by Phil Stern on 4/21/23.
//

import Foundation

struct Side {
    let shape: Shape
    let tabOffsetFactor: CGFloat  // percentage from edge for tab or blank
    
    init(shape: Shape, centerFactor: CGFloat = 0.5) {
        self.shape = shape
        self.tabOffsetFactor = centerFactor
    }
}

enum Shape: CaseIterable {
    case tab
    case blank
    case edge
    
    static func random() -> Shape {
        Shape.allCases.randomElement()!
    }
}
