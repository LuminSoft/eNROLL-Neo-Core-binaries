//
//  CardDetectionManager.swift
//  EnrollLite
//
//  Created by Mac on 12/11/2024.
//

import Foundation
import UIKit

public class CardDetectionManager: NSObject{
    
    private var cardDetectionHandler: CardDetectionHandler = CardDetectionHandler()
    public weak var delegate: CardDetectionDelegate?
    
    public init(delegate: CardDetectionDelegate? = nil) throws {
        super.init()
        guard LicenseVerifier.checkLicense() else {
            throw EnrollLiteLicenseError()
        }
        guard Globals.shared.isDocumentEnabled else {
            throw EnrollLiteDocumentScannerError()
        }
        cardDetectionHandler.manager = self
        self.delegate = delegate
        
    }
    
    public func startCardDetection()->UIViewController{
        let cardDetectorVC = CardDetectionViewController()
        cardDetectorVC.delegate = cardDetectionHandler
        return  cardDetectorVC
        //viewController.present(cardDetectorVC, animated: true)
    }
}






