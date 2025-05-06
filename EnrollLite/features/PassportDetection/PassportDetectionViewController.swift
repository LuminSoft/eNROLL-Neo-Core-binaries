//
//  PassportDetectionViewController.swift
//  EnrollLite
//
//  Created by Bahi El Feky on 10/11/2024.
//

import UIKit
import VisionKit


public class PassportDetectionManager: NSObject {
    
    public weak var delegate: PassportDetectionDelegate?
    
    // Create a private instance of the delegate handler
    private var delegateHandler = PassportDetectionDelegateHandler()
    
    public init(delegate: PassportDetectionDelegate? = nil) throws {
        super.init()
        // Set self as a handler in the delegate handler
        guard LicenseVerifier.checkLicense() else {
            throw EnrollLiteLicenseError()
        }
        guard Globals.shared.isDocumentEnabled else {
            throw EnrollLiteDocumentScannerError()
        }
        delegateHandler.manager = self
        self.delegate = delegate
    }
    
    // Public method to start the scanning process
    public func startPassportDetection()-> UIViewController? {
        
        guard VNDocumentCameraViewController.isSupported else {
            self.delegate?.passportDetectionDidFail(withError: PassportDetectionErrorModel(error: NSError(
                domain: "com.sdk.passportdetection",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Document scanning is not supported on this device."]
            )))
            return  nil
        }
        let documentCameraViewController = VNDocumentCameraViewController()
        documentCameraViewController.delegate = delegateHandler 
        return documentCameraViewController
        // Set the handler as the delegate
//        viewController.present(documentCameraViewController, animated: true, completion: nil)
    }
    
    // Internal methods to handle results, called by the delegate handler
    internal func handleDetectionSuccess(scan: VNDocumentCameraScan) {
        if scan.pageCount > 0 {
            // Extract the last page as UIImage
            let image = scan.imageOfPage(at: scan.pageCount - 1)
            delegate?.passportDetectionDidSucceed(with: PassportDetectionSuccessModel(image: image))
        } else {
            // If no pages were scanned, call failure
            let error = NSError(
                domain: "com.sdk.passportdetection",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No pages found in scan."]
            )
            delegate?.passportDetectionDidFail(withError: PassportDetectionErrorModel(error: error))
        }
    }
    
    internal func handleDetectionFailure(error: Error) {
        delegate?.passportDetectionDidFail(withError: PassportDetectionErrorModel(error: error))
    }
    
    internal func handleDetectionCancel() {
        delegate?.passportDetectionDidCancel()
    }
}
