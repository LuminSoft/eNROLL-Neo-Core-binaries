//
//  DetectionOperations.swift
//  VerIDCredentials
//
//  Created by Bahi Elfeky on 10/11/2024.


import UIKit
import Vision

@available(iOS 11.0, *)
public class PerspectiveCorrectionParamsOperation: Operation {
    
    let orientation: CGImagePropertyOrientation
    let pixelBuffer: CVImageBuffer
    let rect: VNRectangleObservation
    /// card detected corners as vector with cgPoints
    var perspectiveCorrectionParams: [String:CIVector]?
    /// card detected corners
    var corners: (topLeft: CGPoint, topRight: CGPoint, bottomRight: CGPoint, bottomLeft: CGPoint)?
    /// full image of detected card
    var cgImage: CGImage?
    var sharpness: Float?
    
    public init(pixelBuffer: CVImageBuffer, orientation: CGImagePropertyOrientation, rect: VNRectangleObservation) {
        self.pixelBuffer = pixelBuffer
        self.orientation = orientation
        self.rect = rect
    }
    
    public override func main() {
        if #available(iOS 13.0, *) {
            self.sharpness = pixelBuffer.sharpness()
        }
        /// this is the image containing rectangle
        guard let cgImage = pixelBuffer.cgImage(withOrientation: orientation) else {
            return
        }
        /// image size
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        /// image transform scale
        let transform = CGAffineTransform(scaleX: imageSize.width, y: imageSize.height)
        
        let corners: (topLeft: CGPoint, topRight: CGPoint, bottomRight: CGPoint, bottomLeft: CGPoint)
        let flipTransform: CGAffineTransform
        switch orientation {
        case .left, .right:
            corners = (topLeft: rect.topLeft.applying(transform), topRight: rect.topRight.applying(transform), bottomRight: rect.bottomRight.applying(transform), bottomLeft: rect.bottomLeft.applying(transform))
            flipTransform = CGAffineTransform(scaleX: 1, y: -1).concatenating(CGAffineTransform(translationX: 0, y: imageSize.height))
        default:
            corners = (topLeft: rect.bottomRight.applying(transform), topRight: rect.bottomLeft.applying(transform), bottomRight: rect.topLeft.applying(transform), bottomLeft: rect.topRight.applying(transform))
            flipTransform = CGAffineTransform(scaleX: -1, y: 1).concatenating(CGAffineTransform(translationX: imageSize.width, y: 0))
        }
        let params = [
            "inputTopLeft": CIVector(cgPoint: corners.topLeft),
            "inputTopRight": CIVector(cgPoint: corners.topRight),
            "inputBottomRight": CIVector(cgPoint: corners.bottomRight),
            "inputBottomLeft": CIVector(cgPoint: corners.bottomLeft)
        ]
        
        self.cgImage = cgImage
        self.corners = (topLeft: corners.topLeft.applying(flipTransform), topRight: corners.topRight.applying(flipTransform), bottomRight: corners.bottomRight.applying(flipTransform), bottomLeft: corners.bottomLeft.applying(flipTransform))
        self.perspectiveCorrectionParams = params
    }
}
