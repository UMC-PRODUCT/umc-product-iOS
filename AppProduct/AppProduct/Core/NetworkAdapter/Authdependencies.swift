//
//  Authdependencies.swift
//  AppProduct
//
//  Created by euijjang97 on 1/10/26.
//

import Foundation
import Moya

enum AuthSystemFactory {
    static func makeNetworkClient(
        baseURL: URL,
        session: URLSession = .shared
    ) -> NetworkClient {
        let tokenStore = KeychainTokenStore()
        let refreshService = TokenRefreshServiceImpl(baseURL: baseURL, session: session)
        
        return NetworkClient(
            session: session,
            tokenStore: tokenStore,
            refreshService: refreshService
        )
    }
    
    static func makeTestNetworkClient(
        tokenStore: TokenStore,
        refreshService: TokenRefreshService
    ) -> NetworkClient {
        NetworkClient(
            session: .shared,
            tokenStore: tokenStore,
            refreshService: refreshService
        )
    }
}
