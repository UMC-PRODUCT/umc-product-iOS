//
//  MoyaNetworkAdapter.swift
//  CoreNetwork
//
//  Created by euijjang97 on 4/25/26.
//

import AquilaMoya
import Foundation
import Moya

public struct MoyaNetworkAdapter {
    // MARK: - Property

    private let adapter: AquilaMoya.MoyaNetworkAdapter

    // MARK: - Init

    public init(networkClient: NetworkClient, baseURL: URL) {
        adapter = AquilaMoya.MoyaNetworkAdapter(networkClient: networkClient.aquilaClient)
    }

    // MARK: - Function

    public func request<T: TargetType>(_ target: T) async throws -> Response {
        do {
            return try await adapter.request(target)
        } catch {
            throw NetworkClient.appError(from: error)
        }
    }

    public func requestWithoutAuth<T: TargetType>(_ target: T) async throws -> Response {
        do {
            return try await adapter.requestWithoutAuth(target)
        } catch {
            throw NetworkClient.appError(from: error)
        }
    }
}
