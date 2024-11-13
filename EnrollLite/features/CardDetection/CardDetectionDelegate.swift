//
//  CardDetectionDelegate.swift
//  EnrollLite
//
//  Created by Mac on 12/11/2024.
//

import Foundation


public protocol CardDetectionDelegate: AnyObject{
    func cardDetectionSuccess(with model: CardDetectionSuccessModel)
}
