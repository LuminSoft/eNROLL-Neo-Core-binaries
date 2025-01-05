//
//  Globals.swift
//  EnrollLite
//
//  Created by Bahi El Feky on 05/01/2025.
//

import Foundation

class Globals {
    static let shared = Globals()
    
    var isLicenseValid: Bool = false
    var isFaceEnabled: Bool = false
    var isDocumentEnabled: Bool = false
    
    private init() {}
}
