//
//  ActorCacheStore.swift
//  RateConverter
//
//  Created by 黃昭銘 on 2025/7/7.
//

import Foundation

public protocol ActorCacheStore {
    func delete(with id: String) async throws
    func insert(with id: String, json: Any) async throws
    func retrieve(with id: String) async -> RetriveCacheResult
    func saveCache() async throws
    func loadCache() async throws
}
