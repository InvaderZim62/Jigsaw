//
//  Side.swift
//  Puzzle
//
//  Created by Phil Stern on 4/21/23.
//

import Foundation

struct Side {
    let type: Type
    var tabPosition: CGFloat  // percentage from edge for tab or hole
    
    init(type: Type, tabPosition: CGFloat = 0.5) {
        self.type = type
        self.tabPosition = tabPosition
    }
    
    var mate: Side {
        Side(type: self.type.mate, tabPosition: 1 - self.tabPosition)
    }

    static func random() -> Side {
        Side(type: Type.randomTab(), tabPosition: round(10 * CGFloat.random(in: 0.4...0.6)) / 10)  // rounded to 1 decimal place
    }
    
    static func == (lhs: Side, rhs: Side) -> Bool {
        lhs.type == rhs.type && abs(lhs.tabPosition - rhs.tabPosition) < 0.01
    }
}

extension Side: CustomStringConvertible {
    var description: String {
        switch type {
        case .tab, .hole:
            return "\(type) \(tabPosition)"
        default:
            return "\(type)"
        }
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
