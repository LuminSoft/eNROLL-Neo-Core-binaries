//
//  Bundle+Ext.swift
//  EnrollLite
//
//  Created by Bahi El Feky on 18/11/2024.
//

import Foundation

extension Bundle {
    
    static var enrollBundle: Bundle {
         let bundleName = "EnrollLiteFrameworkResources"

         // The bundle this code is executing in (the Pod's module)
         let podBundle = Bundle(for: BaseCardDetectionViewController.self)

         // Locate the resource bundle inside the Pod bundle
         guard let url = podBundle.url(forResource: bundleName, withExtension: "bundle"),
               let resourceBundle = Bundle(url: url) else {
             fatalError("Cannot find EnrollFrameworkResources.bundle")
         }

         return resourceBundle
     }
   // static let enrollBundle = Bundle(identifier: "com.luminsoft.EnrollLite")!
}
