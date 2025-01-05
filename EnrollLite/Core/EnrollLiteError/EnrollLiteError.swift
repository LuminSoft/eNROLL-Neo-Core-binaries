//
//  EnrollLiteError.swift
//  EnrollLite
//
//  Created by Bahi El Feky on 05/01/2025.
//

import Foundation

public protocol EnrollLiteError: Error{
    var message: String {get set}
    init(message: String)
}

class EnrollLiteDocumentScannerError: EnrollLiteError{
    var message: String
    
    required init(message: String = "Document Scanner is not enabled in your license") {
        self.message = message
    }
}

class EnrollLiteFaceScannerError: EnrollLiteError{
    var message: String
    
    required init(message: String = "Face Scanner is not enabled in your license") {
        self.message = message
    }
}

class EnrollLiteLicenseError: EnrollLiteError{
    var message: String
    
    required init(message: String = "Enroll Lite License Error") {
        self.message = message
    }
}
