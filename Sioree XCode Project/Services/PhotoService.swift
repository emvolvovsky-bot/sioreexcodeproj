//
//  PhotoService.swift
//  Sioree
//
//  Created by Sioree Team
//

import Foundation
import Combine
import Photos
import UIKit
import SwiftUI

enum PhotoPermissionStatus {
    case notDetermined
    case restricted
    case denied
    case authorized
    case limited
}

class PhotoService: ObservableObject {
    static let shared = PhotoService()
    @Published var permissionStatus: PhotoPermissionStatus = .notDetermined
    
    init() {
        checkPermissionStatus()
    }
    
    // MARK: - Check Permission Status
    func checkPermissionStatus() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .notDetermined:
            self.permissionStatus = .notDetermined
        case .restricted:
            self.permissionStatus = .restricted
        case .denied:
            self.permissionStatus = .denied
        case .authorized:
            self.permissionStatus = .authorized
        case .limited:
            self.permissionStatus = .limited
        @unknown default:
            self.permissionStatus = .notDetermined
        }
    }
    
    // MARK: - Request Permission
    func requestPermission() -> AnyPublisher<PhotoPermissionStatus, Never> {
        return Future { promise in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                DispatchQueue.main.async {
                    switch status {
                    case .notDetermined:
                        self.permissionStatus = .notDetermined
                    case .restricted:
                        self.permissionStatus = .restricted
                    case .denied:
                        self.permissionStatus = .denied
                    case .authorized:
                        self.permissionStatus = .authorized
                    case .limited:
                        self.permissionStatus = .limited
                    @unknown default:
                        self.permissionStatus = .notDetermined
                    }
                    promise(.success(self.permissionStatus))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Upload Image
    func uploadImage(_ image: UIImage) -> AnyPublisher<String, Error> {
        let networkService = NetworkService()
        
        // Resize & compress to avoid 413/decoding errors from oversized payloads
        guard let imageData = prepareImageData(image) else {
            return Fail(error: NSError(domain: "PhotoService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"]))
                .eraseToAnyPublisher()
        }
        
        // Create multipart form data
        let boundary = UUID().uuidString
        var body = Data()
        
        // Add image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        // Create request
        guard let url = URL(string: Constants.API.baseURL + "/api/media/upload") else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        if let token = StorageService.shared.getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = body
        
        struct UploadResponse: Codable {
            let url: String
            let thumbnailUrl: String?
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let http = response as? HTTPURLResponse else {
                    throw NSError(domain: "PhotoService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response from server"])
                }
                
                // Surface server-side errors with readable messages
                guard (200...299).contains(http.statusCode) else {
                    if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let message = json["error"] as? String {
                        throw NSError(domain: "PhotoService", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
                    }
                    
                    let bodyText = String(data: data, encoding: .utf8) ?? ""
                    let message = bodyText.isEmpty ? "Upload failed with status \(http.statusCode)" : bodyText
                    throw NSError(domain: "PhotoService", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
                }
                
                return data
            }
            .decode(type: UploadResponse.self, decoder: JSONDecoder())
            .map { $0.url }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Upload Multiple Images
    func uploadImages(_ images: [UIImage]) -> AnyPublisher<[String], Error> {
        let publishers = images.map { uploadImage($0) }
        return Publishers.Sequence(sequence: publishers)
            .flatMap { $0 }
            .collect()
            .eraseToAnyPublisher()
    }
    
    // MARK: - Helpers
    /// Resize and compress image to keep uploads under ~1.5MB and within sensible dimensions.
    private func prepareImageData(_ image: UIImage) -> Data? {
        // Cap longest side to 1600px to avoid enormous payloads
        let resized = image.resized(toMaxDimension: 1600)
        var quality: CGFloat = 0.8
        let maxSize = 1_500_000 // ~1.5MB
        var data = resized.jpegData(compressionQuality: quality)
        
        while let current = data, current.count > maxSize, quality > 0.2 {
            quality -= 0.1
            data = resized.jpegData(compressionQuality: quality)
        }
        
        return data
    }
}

