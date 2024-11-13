//
//  PassportDetectionDelegate.swift
//  EnrollLite
//
//  Created by Mac on 12/11/2024.
//

import Foundation

public protocol PassportDetectionDelegate: AnyObject {
    func passportDetectionDidSucceed(with model: PassportDetectionSuccessModel)
    func passportDetectionDidFail(withError error: PassportDetectionErrorModel)
    func passportDetectionDidCancel()
}
