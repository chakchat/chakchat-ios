//
//  FileCacheManager.swift
//  chakchat
//
//  Created by Кирилл Исаев on 20.04.2025.
//

import Foundation

final class FileCacheManager: FileCacheProtocol {
    
    static let shared = FileCacheManager()
    
    private init() {}
    
    func saveFile(
        _ url: URL,
        _ fileName: String,
        _ mimeType: String,
        completion: @escaping (URL?) -> Void
    ) {
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let baseName = (fileName as NSString).deletingPathExtension
        let finalFileName = "\(baseName).\(mimeType)"
        let localURL = cacheDirectory.appendingPathComponent(finalFileName)
        
        if FileManager.default.fileExists(atPath: localURL.path) {
            do {
                try FileManager.default.removeItem(at: localURL)
            } catch {
                debugPrint("Failed to remove existing file: \(error)")
                completion(nil)
                return
            }
        }
        
        URLSession.shared.downloadTask(with: url) { tempURL, _, error in
            guard let tempURL = tempURL, error == nil else {
                completion(nil)
                return
            }
            
            do {
                try FileManager.default.moveItem(at: tempURL, to: localURL)
                completion(localURL)
            } catch {
                debugPrint("Failed to save file: \(error)")
                completion(nil)
            }
        }.resume()
    }
    
    func getFile(_ url: URL) -> URL? {
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let fileName = url.lastPathComponent
        let localURL = cacheDirectory.appendingPathComponent(fileName)
        
        return FileManager.default.fileExists(atPath: localURL.path) ? localURL : nil
    }
    
    private func mimeTypeToExtension(_ mimeType: String) -> String? {
        let mimeTypes = [
            "image/jpeg": "jpg",
            "image/png": "png",
            "application/pdf": "pdf",
            "text/plain": "txt",
            "application/json": "json",
            "audio/mpeg": "mp3",
            "video/mp4": "mp4",
        ]
        return mimeTypes[mimeType.lowercased()]
    }
}
