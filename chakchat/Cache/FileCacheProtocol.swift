//
//  FileCacheProtocol.swift
//  chakchat
//
//  Created by Кирилл Исаев on 20.04.2025.
//

import Foundation

protocol FileCacheProtocol {
    func saveFile(_ url: URL, completion: @escaping (URL?) -> Void)
    func getFile(_ url: URL) -> URL?
}

