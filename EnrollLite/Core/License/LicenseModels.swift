//
//  LicenseModels.swift
//  EnrollLite
//
//  Created by Bahi El Feky on 01/01/2025.
//

import Foundation

struct Contract: Codable {
    let customer: String
    let expiration: Expiration
    let id: String
    let enroll: ENROLL // Adjusted property name
    
    enum CodingKeys: String, CodingKey {
        case customer, expiration, id
        case enroll = "eNROLL" // Maps "eNROLL" from JSON to "enroll" property
    }
}

struct Expiration: Codable {
    let day: Int
    let month: Int
    let year: Int
}

struct ENROLL: Codable {
    let mobile: Mobile
    
    enum CodingKeys: String, CodingKey {
        case mobile
    }
}

struct Mobile: Codable {
    let face: Feature
    let document: Feature
}

struct Feature: Codable {
    let enabled: Bool
}

struct ContractModel: Codable {
    let contract: Contract
    let contractSignature: String
}
