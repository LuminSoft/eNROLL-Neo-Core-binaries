//
//  String+Ext.swift
//  EnrollLite
//
//  Created by Bahi El Feky on 18/11/2024.
//

import Foundation


 extension String{
    
    func localizedString() -> String {
        
      return  LocalizationManager.localizedString(forKey: self)
//        return NSLocalizedString(self, bundle: Bundle.enrollBundle, comment: "")
    }
}


