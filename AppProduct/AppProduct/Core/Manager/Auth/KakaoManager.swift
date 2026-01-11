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
    func fetchAccessToken(completion: @escaping (Result<String, Error>) -> Void) {
        if UserApi.isKakaoTalkLoginAvailable() {
            UserApi.shared.loginWithKakaoTalk { oauthToken, error in
                if let error = error {
                    completion(.failure(error))
                } else if let oauthToken = oauthToken {
                    completion(.success(oauthToken.accessToken))
                }
            }
        } else {
            UserApi.shared.loginWithKakaoAccount { oauthToken, error in
                if let error = error {
                    completion(.failure(error))
                } else if let oauthToken = oauthToken {
                    completion(.success(oauthToken.accessToken))
                }
            }
        }
    }

    func getUserEmail(accessToken: String, completion: @escaping (Result<String, Error>) -> Void) {
        UserApi.shared.me { user, error in
            if let error = error {
                completion(.failure(error))
            } else if let user = user, let email = user.kakaoAccount?.email {
                completion(.success(email))
            }
        }
    }

    func getUserName(completion: @escaping (Result<String, Error>) -> Void) {
        UserApi.shared.me { user, error in
            if let error = error {
                completion(.failure(error))
            } else if let user = user, let nickname = user.kakaoAccount?.profile?.nickname {
                completion(.success(nickname))
            }
        }
    }
}
