//
//  FaceDetectionDelegate.swift
//  EnrollLite
//
//  Created by Mac on 12/11/2024.
//

import Foundation
import UIKit

public protocol FaceDetectionDelegate{
    func faceDectionSucceed(with model: FaceDetectionSuccessModel)
    func faceDetectionFail(withError error: FaceDetectionErrorModel)
}
