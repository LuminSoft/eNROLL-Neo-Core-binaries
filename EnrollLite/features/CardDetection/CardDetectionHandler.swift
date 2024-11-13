//
//  CardDetectionHandler.swift
//  EnrollLite
//
//  Created by Mac on 12/11/2024.
//

import Foundation
import UIKit


internal class CardDetectionHandler: CardDetectionViewControllerDelegate{
    
    var manager: CardDetectionManager?
    
    func cardDetectionViewController(_ viewController: CardDetectionViewController, didDetectCard image: CGImage, withSettings settings: CardDetectionSettings) {
        let uiImage = UIImage(cgImage: image)
        manager?.delegate?.cardDetectionSuccess(with: CardDetectionSuccessModel(image: uiImage))
    }
}
