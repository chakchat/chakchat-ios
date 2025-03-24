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
}
