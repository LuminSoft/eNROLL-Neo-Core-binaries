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
    
    public init(delegate: FaceDetectionDelegate? = nil) {
        self.delegate = delegate
    }
    
    public func startFaceDetection(from viewController: UIViewController){
        let vc = FaceDetectionViewController()
        vc.delegate = delegate
        viewController.present(vc, animated: true)
    }
}
