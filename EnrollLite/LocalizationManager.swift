//
//  LocalizationManager.swift
//  EnrollLite
//
//  Created by Mariam Ismail on 19/05/2025.
//



public class LocalizationManager {
    
    public static var provider: Dictionary<String, String>?

     public static func localizedString(forKey key: String) -> String {
         return provider?[key] ?? key
    }
}
