//
//  FaceDetectionManager.swift
//  EnrollLite
//
//  Created by Mac on 12/11/2024.
//

import Foundation
import UIKit

public class FaceDetectionManager: NSObject {
    
    private var delegate: FaceDetectionDelegate?
    private var withSmileLiveness: Bool
    
    public init(delegate: FaceDetectionDelegate? = nil, withSmileLiveness: Bool = false) throws {
        guard LicenseVerifier.checkLicense() else {
            throw EnrollLiteLicenseError()
        }
        guard Globals.shared.isFaceEnabled else {
            throw EnrollLiteFaceScannerError()
        }
        self.delegate = delegate
        self.withSmileLiveness = withSmileLiveness
    }
    
    public func startFaceDetection()-> UIViewController{
        let vc = FaceDetectionViewController()
        vc.delegate = delegate
        vc.withSmileLiveness = withSmileLiveness
        return vc
        //viewController.present(vc, animated: true)
    }
}
