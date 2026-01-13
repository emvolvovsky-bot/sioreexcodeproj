//
//  QRCodeService.swift
//  Sioree
//
//  Service for generating and validating QR codes for tickets
//

import Foundation
import CoreImage
import UIKit
import CommonCrypto

struct TicketQRData: Codable {
    let ticketId: String
    let eventId: String
    let userId: String
    let timestamp: Date
    let signature: String // For validation
    
    var qrString: String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(self),
              let string = String(data: data, encoding: .utf8) else {
            return ""
        }
        return string
    }
    
    static func fromQRString(_ string: String) -> TicketQRData? {
        guard let data = string.data(using: .utf8) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(TicketQRData.self, from: data)
    }
}

class QRCodeService {
    static let shared = QRCodeService()
    
    // MARK: - Generate QR Code Image
    func generateQRCode(from string: String, size: CGSize = CGSize(width: 200, height: 200)) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)
        
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }
        
        filter.setValue(data, forKey: "inputMessage")
        let transform = CGAffineTransform(scaleX: size.width / 200, y: size.height / 200)
        
        guard let outputImage = filter.outputImage?.transformed(by: transform) else {
            return nil
        }
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - Generate Ticket QR Code
    func generateTicketQRCode(ticketId: String, eventId: String, userId: String) -> UIImage? {
        // Create QR data with signature for validation
        let timestamp = Date()
        let signature = createSignature(ticketId: ticketId, eventId: eventId, userId: userId, timestamp: timestamp)
        
        let qrData = TicketQRData(
            ticketId: ticketId,
            eventId: eventId,
            userId: userId,
            timestamp: timestamp,
            signature: signature
        )
        
        return generateQRCode(from: qrData.qrString)
    }
    
    // MARK: - Validate QR Code
    func validateQRCode(_ qrString: String) -> (isValid: Bool, ticketData: TicketQRData?) {
        guard let ticketData = TicketQRData.fromQRString(qrString) else {
            return (false, nil)
        }
        
        // Verify signature
        let expectedSignature = createSignature(
            ticketId: ticketData.ticketId,
            eventId: ticketData.eventId,
            userId: ticketData.userId,
            timestamp: ticketData.timestamp
        )
        
        let isValid = ticketData.signature == expectedSignature
        
        return (isValid, ticketData)
    }
    
    // MARK: - Create Signature (simple hash for validation)
    private func createSignature(ticketId: String, eventId: String, userId: String, timestamp: Date) -> String {
        let combined = "\(ticketId)-\(eventId)-\(userId)-\(timestamp.timeIntervalSince1970)"
        return combined.sha256()
    }
}

extension String {
    func sha256() -> String {
        guard let data = self.data(using: .utf8) else { return "" }
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

