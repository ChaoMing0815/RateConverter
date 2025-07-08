//
//  CacheStoreError.swift
//  RateConverter
//
//  Created by 黃昭銘 on 2025/7/5.
//

import Foundation

enum CacheStoreError: Error {
    case failureDeletion
    case failureInsertion
    case failureRetrival
    case failureSaveCache
    case failureLoadCache
    case corruptFile
}
