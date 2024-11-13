//
//  PassportDetectionDelegateHandler.swift
//  EnrollLite
//
//  Created by Mac on 12/11/2024.
//

import Foundation
import VisionKit

// Internal delegate handler class to conform to VNDocumentCameraViewControllerDelegate
internal class PassportDetectionDelegateHandler: NSObject, VNDocumentCameraViewControllerDelegate {
    
    // Weak reference to the manager to prevent retain cycles
    var manager: PassportDetectionManager?
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        manager?.handleDetectionSuccess(scan: scan)
        controller.dismiss(animated: true){ [weak self] in
            self?.manager = nil
        }
    }
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        manager?.handleDetectionCancel()
        controller.dismiss(animated: true){ [weak self] in
            self?.manager = nil
        }
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        manager?.handleDetectionFailure(error: error)
        controller.dismiss(animated: true){ [weak self] in
            self?.manager = nil
        }
    }
}
