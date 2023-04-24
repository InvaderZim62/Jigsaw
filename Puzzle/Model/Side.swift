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
    var isConnected = false
    
    init(type: Type, tabPosition: CGFloat = 0.5) {
        self.type = type
        self.tabPosition = tabPosition
    }
    
    var mate: Side {
        Side(type: self.type.mate, tabPosition: 1 - self.tabPosition)
    }

    static func random() -> Side {
        Side(type: Type.randomTab(), tabPosition: Double.random(in: 0.4...0.6))  // pws: may want to truncate tabPosition to two decimal places
    }
}

enum Type: CaseIterable {
    case tab
    case hole
    case edge
    
    var mate: Type {
        switch self {
        case .tab:
            return .hole
        case .hole:
            return .tab
        case .edge:
            return .edge
        }
    }
    
    static func random() -> Type {
        Type.allCases.randomElement()!
    }
    
    static func randomTab() -> Type {
        Bool.random() ? .tab : .hole
    }
}
