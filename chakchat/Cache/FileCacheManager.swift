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
    
    func saveFile(_ url: URL, completion: @escaping (URL?) -> Void) {
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let fileName = url.lastPathComponent
        let localURL = cacheDirectory.appendingPathComponent(fileName)
        
        if FileManager.default.fileExists(atPath: localURL.path) {
            completion(localURL)
            return
        }
        
        URLSession.shared.downloadTask(with: url) { tempURL, _ , error in
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
}
