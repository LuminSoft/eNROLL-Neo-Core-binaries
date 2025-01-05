//
//  LicenseVerifier.swift
//  EnrollLite
//
//  Created by Bahi El Feky on 01/01/2025.
//

import Foundation
import CommonCrypto

class LicenseVerifier {
    
    static func checkLicense() -> Bool {
        return Globals.shared.isLicenseValid
    }
    
    static func readRawFile(resourceName: String, withExtension: String = "json", bundle: Bundle = .main) throws {
        guard let url = bundle.url(forResource: resourceName, withExtension: withExtension),
              let data = try? String(contentsOf: url, encoding: .utf8) else {
            throw EnrollLiteLicenseError(message: "Failed to load resource: \(resourceName).\(withExtension)")
        }
        let isValid = try verifyLicense(licenseData: data)
        Globals.shared.isLicenseValid = isValid
    }
    
    private static func verifyLicense(licenseData: String) throws -> Bool {
        guard let contractModel = try parseJsonToModel(jsonString: licenseData) else {  return false }
        Globals.shared.isFaceEnabled = contractModel.contract.enroll.mobile.face.enabled
        Globals.shared.isDocumentEnabled = contractModel.contract.enroll.mobile.document.enabled
        
        if !checkExpiry(expiration: contractModel.contract.expiration) {
            throw EnrollLiteLicenseError(message: "verifyLicense: expiration")
        }
        
        if !checkId(id: contractModel.contract.id) {
            throw EnrollLiteLicenseError(message: "verifyLicense: id")
        }
        
        let createdHash = createDataToEncrypt(contractModel: contractModel)
        return checkHash(createdHash: createdHash, contractSignature: contractModel.contractSignature)
    }
    
    private static func parseJsonToModel(jsonString: String) throws -> ContractModel? {
        guard let data = jsonString.data(using: .utf8) else { return nil }
        do {
            return try JSONDecoder().decode(ContractModel.self, from: data)
        } catch {
            throw EnrollLiteLicenseError(message: "verifyLicense: License Format issue")
        }
        
    }
    
    private static func createDataToEncrypt(contractModel: ContractModel) -> String {
        var dataToEncrypt = "0xeN"
        
        // customer
        dataToEncrypt += String(contractModel.contract.customer.reversed())
        
        // expiration
        let expiration = contractModel.contract.expiration
        let calendar = Calendar(identifier: .gregorian)
        let dateComponents = DateComponents(
            year: expiration.year,
            month: expiration.month,
            day: expiration.day
        )
        guard let expirationDate = calendar.date(from: dateComponents) else { return "" }
        let expirationTimeStamp = expirationDate.timeIntervalSince1970 * 1000
        dataToEncrypt += "\(Int(expirationTimeStamp * 21)).suffix(7)"
        
        dataToEncrypt += "LU0x12"
        
        // id
        dataToEncrypt += contractModel.contract.id.replacingOccurrences(
            of: ".",
            with: String(contractModel.contract.customer.prefix(1))
        )
        
        // enroll
        dataToEncrypt += String(contractModel.contract.enroll.mobile.face.enabled.description.reversed().prefix(3))
        dataToEncrypt += String(contractModel.contract.enroll.mobile.document.enabled.description.reversed().prefix(2))
        
        dataToEncrypt += String(dataToEncrypt.reversed())
        return encryptWithSHA512(input: dataToEncrypt)
    }
    
    private static func encryptWithSHA512(input: String) -> String {
        guard let data = input.data(using: .utf8) else { return "" }
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA512($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    private static func checkExpiry(expiration: Expiration) -> Bool {
        let expiry = getExpirationTimeStamp(expiration: expiration)
        let currentTimestamp = Date().timeIntervalSince1970 * 1000
        return expiry >= currentTimestamp
    }
    
    private static func getExpirationTimeStamp(expiration: Expiration) -> TimeInterval {
        let calendar = Calendar(identifier: .gregorian)
        let dateComponents = DateComponents(
            year: expiration.year,
            month: expiration.month,
            day: expiration.day
        )
        guard let date = calendar.date(from: dateComponents) else { return 0 }
        return date.timeIntervalSince1970 * 1000
    }
    
    private static func checkId(id: String) -> Bool {
        return Bundle.main.bundleIdentifier == id
    }
    
    private static func checkHash(createdHash: String, contractSignature: String) -> Bool {
        return createdHash == contractSignature
    }
}
