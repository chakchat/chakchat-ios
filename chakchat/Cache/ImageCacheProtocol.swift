//
//  ImageCacheProtocol.swift
//  chakchat
//
//  Created by Кирилл Исаев on 24.02.2025.
//

import UIKit

// MARK: - ImageCacheProtocol
protocol ImageCacheProtocol {
    
    func getImage(for url: NSURL) -> UIImage?

    func saveImage(_ image: UIImage, for url: NSURL)
    
    func clearCache()
    func getCacheSize(completion: @escaping (Result<Double, Error>) -> Void)
    func getCacheSizePercentage(completion: @escaping (Result<Double, Error>) -> Void)
    func setCacheLimit(megabytes: Int)
    func getCurrentCacheLimit() -> Int
    func getDeviceStorageInfo() -> (total: Double, free: Double)?
    func getFormattedCacheInfo(completion: @escaping (String) -> Void)
}
