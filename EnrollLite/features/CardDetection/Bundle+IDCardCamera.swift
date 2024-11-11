//
//  Bundle+IDCardCamera.swift
//  IDCardCamera
//
//  Created by Bahi Elfeky on 10/11/2024.

import Foundation

extension Bundle {
    static let module: Bundle? = {
        guard let url = Bundle(for: BaseCardDetectionViewController.self).url(forResource: "IDCardCameraResources", withExtension: "bundle"), let idCamBundle = Bundle(url: url) else {
            return nil
        }
        return idCamBundle
    }()
}
