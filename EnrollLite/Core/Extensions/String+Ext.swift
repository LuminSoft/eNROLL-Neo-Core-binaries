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



public class LocalizationManager {
    public static var provider: Dictionary<String, String>?
    

     static func localizedString(forKey key: String) -> String {
         return provider?[key] ?? key
    }
}
