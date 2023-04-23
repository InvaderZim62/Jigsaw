//
//  Side.swift
//  Puzzle
//
//  Created by Phil Stern on 4/21/23.
//

import Foundation

struct Side {
    let type: Type
    let tabPosition: CGFloat  // percentage from edge for tab or hole
    
    init(type: Type, tabPosition: CGFloat = 0.5) {
        self.type = type
        self.tabPosition = tabPosition
    }
}

enum Type: CaseIterable {
    case tab
    case hole
    case edge
    
    static func random() -> Type {
        Type.allCases.randomElement()!
    }
}
