//
//  KakaoManager.swift
//  AppProduct
//
//  Created by euijjang97 on 1/11/26.
//

import Foundation
import KakaoSDKAuth
import KakaoSDKUser

class KakaoLoginManager { 
    enum KakaoLoginError: Error {
        case tokenNotFound
        case userInfoNotFound
        case emailNotFound
        case nicknameNotFound
    }
    
    func fetchAccessToken() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            if UserApi.isKakaoTalkLoginAvailable() {
                UserApi.shared.loginWithKakaoTalk { oauthToken, error in 
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let oauthToken = oauthToken {
                        continuation.resume(returning: oauthToken.accessToken)
                    } else {
                        continuation.resume(throwing: KakaoLoginError.tokenNotFound)
                    }
                }
            } else {
                UserApi.shared.loginWithKakaoAccount { oauthToken, error in 
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let oauthToken = oauthToken {
                        continuation.resume(returning: oauthToken.accessToken)
                    } else {
                        continuation.resume(throwing: KakaoLoginError.tokenNotFound)
                    }
                }
            }
        }
    }
    
    func getUserEmail() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            UserApi.shared.me { user , error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let email = user?.kakaoAccount?.email {
                    continuation.resume(returning: email)
                } else {
                    continuation.resume(throwing: KakaoLoginError.emailNotFound)
                }
            }
        }
    }
    
    func login() async throws -> (accessToken: String, email: String) {
        let accessToken = try await fetchAccessToken()
        
        async let email = getUserEmail()
        
        return try await (accessToken, email)
    }
}
