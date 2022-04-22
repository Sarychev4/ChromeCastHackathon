//
//  CellPassiveMeasurement.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 22.04.2022.
//

import UIKit

protocol CellPassiveMeasurement {
    var puppetCellIndex: Int { get set }
    var puppetFractionComplete: CGFloat { get set }
    var unitStepOfPuppet: CGFloat { get }
}
