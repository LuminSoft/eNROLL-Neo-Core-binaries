//
//  PassportDetectionViewController.swift
//  EnrollLite
//
//  Created by Bahi El Feky on 10/11/2024.
//

import UIKit
import VisionKit

public protocol PassportDetectionDelegate: AnyObject {
    func passportDetectionDidSucceed(image: UIImage)
    func passportDetectionDidFail(withError error: Error)
    func passportDetectionDidCancel()
}

public class PassportDetectionManager: NSObject {
    
    public weak var delegate: PassportDetectionDelegate?
    
    // Create a private instance of the delegate handler
    private var delegateHandler = PassportDetectionDelegateHandler()
    
    public init(delegate: PassportDetectionDelegate?) {
        super.init()
        // Set self as a handler in the delegate handler
        delegateHandler.manager = self
        self.delegate = delegate
    }
    
    // Public method to start the scanning process
    public func startPassportScanning(from viewController: UIViewController) {
        
        guard VNDocumentCameraViewController.isSupported else {
            self.delegate?.passportDetectionDidFail(withError: NSError(
                domain: "com.sdk.passportdetection",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Document scanning is not supported on this device."]
            ))
            return
        }
        let documentCameraViewController = VNDocumentCameraViewController()
        documentCameraViewController.delegate = delegateHandler  // Set the handler as the delegate
        viewController.present(documentCameraViewController, animated: true, completion: nil)
    }
    
    // Internal methods to handle results, called by the delegate handler
    internal func handleDetectionSuccess(scan: VNDocumentCameraScan) {
        if scan.pageCount > 0 {
            // Extract the first page as UIImage
            let image = scan.imageOfPage(at: 0)
            delegate?.passportDetectionDidSucceed(image: image)
        } else {
            // If no pages were scanned, call failure
            let error = NSError(
                domain: "com.sdk.passportdetection",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No pages found in scan."]
            )
            delegate?.passportDetectionDidFail(withError: error)
        }
    }
    
    internal func handleDetectionFailure(error: Error) {
        delegate?.passportDetectionDidFail(withError: error)
    }
    
    internal func handleDetectionCancel() {
        delegate?.passportDetectionDidCancel()
    }
}

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
