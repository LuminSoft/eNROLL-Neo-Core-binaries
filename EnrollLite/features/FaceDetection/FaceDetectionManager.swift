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
    
    public init(delegate: FaceDetectionDelegate? = nil, withSmileLiveness: Bool = false) {
        self.delegate = delegate
        self.withSmileLiveness = withSmileLiveness
    }
    
    public func startFaceDetection(from viewController: UIViewController){
        let vc = FaceDetectionViewController()
        vc.delegate = delegate
        vc.withSmileLiveness = withSmileLiveness
        viewController.present(vc, animated: true)
    }
}
