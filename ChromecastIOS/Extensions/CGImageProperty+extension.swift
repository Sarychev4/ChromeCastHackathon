//
//  CGImageProperty+extension.swift
//  ScreenMirroring
//
//  Created by Vital on 12.11.21.
//

import Foundation
import CoreImage

extension CGImagePropertyOrientation {
    var fixedOrientation: CGImagePropertyOrientation {
        switch self {
        case .up:
            return .up
        case .upMirrored:
            return .upMirrored
        case .down:
            return .down
        case .downMirrored:
            return .downMirrored
        case .left:
            return .right
        case .leftMirrored:
            return .rightMirrored
        case .right:
            return .left
        case .rightMirrored:
            return .leftMirrored
        }
    }
    
    var fixedAngle: CGFloat {
        switch self {
        case .up, .upMirrored, .down, .downMirrored:
            return 0
        case .left, .leftMirrored:
            return -(CGFloat.pi / 2)
        case .right, .rightMirrored:
            return CGFloat.pi / 2
        }
    }
    
    var fixedAngleFFMPEG: String? {
        switch self {
        case .up, .upMirrored, .down, .downMirrored:
            return "0"
        case .left, .leftMirrored:
            return "3*PI/2"
        case .right, .rightMirrored:
            return "PI/2"
        }
    }
        
    var stringValue: String {
        switch self {
        case .up:
            return "up"
        case .upMirrored:
            return "upMirrored"
        case .down:
            return "down"
        case .downMirrored:
            return "downMirrored"
        case .leftMirrored:
            return "leftMirrored"
        case .right:
            return "right"
        case .rightMirrored:
            return "rightMirrored"
        case .left:
            return "left"
        }
    }
}
