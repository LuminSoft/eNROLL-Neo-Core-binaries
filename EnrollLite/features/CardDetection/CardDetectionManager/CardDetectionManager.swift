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
    
    public init(delegate: CardDetectionDelegate? = nil) {
        super.init()
        cardDetectionHandler.manager = self
        self.delegate = delegate
        
    }
    
    public func startCardDetection(from viewController: UIViewController){
        let cardDetectorVC = CardDetectionViewController()
        cardDetectorVC.delegate = cardDetectionHandler
        viewController.present(cardDetectorVC, animated: true)
    }
}






