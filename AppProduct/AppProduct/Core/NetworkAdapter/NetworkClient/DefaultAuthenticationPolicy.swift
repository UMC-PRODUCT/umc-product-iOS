//
//  DefaultAuthenticationPolicy.swift
//  AppProduct
//
//  Created by euijjang97 on 1/9/26.
//

import Foundation

struct DefaultAuthenticationPolicy: AuthenticationPolicy, Sendable {
    nonisolated init() {}
    
    nonisolated func requireAuthentication(_ request: URLRequest) -> Bool {
        true
    }
    
    nonisolated func isUnauthorizedResponse(_ response: HTTPURLResponse) -> Bool {
        response.statusCode == 401
    }
}
