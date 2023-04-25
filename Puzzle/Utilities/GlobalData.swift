//
//  GlobalData.swift
//  Puzzle
//
//  Created by Phil Stern on 4/24/23.
//

import UIKit

class GlobalData: NSObject {
    static let sharedInstance = GlobalData()
    private override init() { }
    
    var outerSize: CGFloat = PuzzleConst.targetPieceSize
    var innerSize: CGFloat = PuzzleConst.targetPieceSize * PuzzleConst.innerRatio
    var inset: CGFloat = PuzzleConst.targetPieceSize * (1 - PuzzleConst.innerRatio) / 2
}
