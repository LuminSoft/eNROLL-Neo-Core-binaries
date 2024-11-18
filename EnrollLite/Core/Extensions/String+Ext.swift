//
//  String+Ext.swift
//  EnrollLite
//
//  Created by Bahi El Feky on 18/11/2024.
//

import Foundation


extension String{
    
    func localizedString() -> String {
        return NSLocalizedString(self, bundle: Bundle.enrollBundle, comment: "")
    }
}
