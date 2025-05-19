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

public protocol LocalizationProvider {
    func localizedString(forKey key: String) -> String
}

public class LocalizationManager {
    public static var provider: LocalizationProvider?

    public static func localizedString(forKey key: String) -> String {
        return provider?.localizedString(forKey: key) ?? key
    }
}
