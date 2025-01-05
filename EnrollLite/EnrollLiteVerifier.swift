//
//  EnrollLiteVerifier.swift
//  EnrollLite
//
//  Created by Bahi El Feky on 05/01/2025.
//

import Foundation

public class EnrollLiteVerifier{
    public static func verifyEnrollLiteLicense(resourceName: String, withExtension: String = "json", bundle: Bundle = .main) throws {
        try LicenseVerifier.readRawFile(resourceName: resourceName, withExtension: withExtension, bundle: bundle)
    }
}
