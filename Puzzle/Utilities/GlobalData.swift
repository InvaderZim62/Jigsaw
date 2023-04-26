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
    
    var outerSize: CGFloat = PuzzleConst.pieceSize
    var innerSize: CGFloat = PuzzleConst.pieceSize * PuzzleConst.innerRatio
    var inset: CGFloat = PuzzleConst.pieceSize * (1 - PuzzleConst.innerRatio) / 2
}
