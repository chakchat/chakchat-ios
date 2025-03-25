//
//  ImageCacheManager.swift
//  chakchat
//
//  Created by Кирилл Исаев on 24.02.2025.
//

import UIKit
import Kingfisher

// MARK: - ImageCacheManager
final class ImageCacheManager: ImageCacheProtocol {
        
    static let shared = ImageCacheManager()
    
    private init() {}
    
    func getImage(for url: NSURL) -> UIImage? {
        guard let u = url.absoluteString else { return nil }
        return KingfisherManager.shared.cache.retrieveImageInMemoryCache(forKey: u)
    }
    
    func saveImage(_ image: UIImage, for url: NSURL) {
        guard let u = url.absoluteString else { return }
        KingfisherManager.shared.cache.store(image, forKey: u)
    }
    
    func clearCache() {
        KingfisherManager.shared.cache.clearMemoryCache()
        KingfisherManager.shared.cache.clearDiskCache()
        KingfisherManager.shared.cache.cleanExpiredDiskCache()
    }
    
    func getCacheSize(completion: @escaping (Result<Double, any Error>) -> Void) {
        KingfisherManager.shared.cache.calculateDiskStorageSize { result in
             switch result {
             case .success(let sizeInBytes):
                 let sizeInMB = Double(sizeInBytes) / 1024 / 1024
                 completion(.success(sizeInMB))
             case .failure(let error):
                 completion(.failure(error))
             }
         }
    }
    
    private func getCacheSizeInBytes(completion: @escaping (Result<UInt, Error>) -> Void) {
        KingfisherManager.shared.cache.calculateDiskStorageSize { result in
            switch result {
            case .success(let size):
                completion(.success(size))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getCacheSizePercentage(completion: @escaping (Result<Double, any Error>) -> Void) {
        guard let storageInfo = getDeviceStorageInfo() else {
            completion(.failure(NSError(domain: "Failed to get cache", code: -1)))
            return
        }
        getCacheSizeInBytes { result in
            switch result {
            case .success(let sizeInBytes):
                let sizeInGB = Double(sizeInBytes) / (1024 * 1024 * 1024)
                let percentage = (sizeInGB / storageInfo.total) * 100
                completion(.success(percentage))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func setCacheLimit(megabytes: Int) {
        let bytesLimit = megabytes * 1024 * 1024
        KingfisherManager.shared.cache.diskStorage.config.sizeLimit = UInt(bytesLimit)
        UserDefaults.standard.set(megabytes, forKey: "cache")
    }
    
    func getCurrentCacheLimit() -> Int {
        let defaultLimit = 100
        return UserDefaults.standard.integer(forKey: "cache") > 0
            ? UserDefaults.standard.integer(forKey: "cache")
            : defaultLimit
    }
    
    func getDeviceStorageInfo() -> (total: Double, free: Double)? {
        guard let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
              let totalSize = systemAttributes[.systemSize] as? NSNumber,
              let freeSize = systemAttributes[.systemFreeSize] as? NSNumber else {
            return nil
        }
        let totalGB = totalSize.doubleValue / (1024 * 1024 * 1024)
        let freeGB = freeSize.doubleValue / (1024 * 1024 * 1024)
        return (totalGB, freeGB)
    }
    
    func getCacheInfo(completion: @escaping (Result<(sizeMB: Double, percentage: Double), Error>) -> Void) {
        getCacheSize { [weak self] sizeResult in
            guard let self = self else { return }
            
            switch sizeResult {
            case .success(let sizeMB):
                self.getCacheSizePercentage { percentageResult in
                    switch percentageResult {
                    case .success(let percentage):
                        completion(.success((sizeMB, percentage)))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getFormattedCacheInfo(completion: @escaping (String) -> Void) {
        getCacheInfo { result in
            let info: String
            switch result {
            case .success(let data):
                info = String(format: "\(LocalizationManager.shared.localizedString(for: "cache_size")) %.2f MB (%.1f%% \(LocalizationManager.shared.localizedString(for: "device_storage"))", data.sizeMB, data.percentage)
            case .failure(let error):
                info = "Error: \(error.localizedDescription)"
            }
            completion(info)
        }
    }
}
