//
//  CellAnimationMeasurement.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 22.04.2022.
//

import UIKit

protocol CellAnimationMeasurement {
    var animatedCellIndex: Int { get set}
    var originalInsetAndContentOffset: (CGFloat, CGFloat) { get set}
    var animatedCellType: AnimatedCellType { get set }
}
