//
//  Config.swift
//  AppProduct
//
//  Created by euijjang97 on 1/29/26.
//

import Foundation

enum Config {
    private static let infoDictionary: [String: Any] = {
        guard let dict = Bundle.main.infoDictionary else {
            fatalError("Plist cannot be fount")
        }
        return dict
    }()
    
    static let baseURL: String = {
        guard let baseURL = Config.infoDictionary["BASE_URL"] as? String else {
            fatalError("BaseURL not found")
        }
        return baseURL
    }()
    
    static let kakaoAppKey: String = {
        guard let key = Config.infoDictionary["KAKAO_KEY"] as? String else {
            fatalError("KakakoKey not found")
        }
        return key
    }()

    static let tmapSecretKey: String = {
        guard let key = Config.infoDictionary["TMAP_SECRET_KEY"] as? String else {
            fatalError("TMAP_SECRET_KEY not found")
        }
        return key
    }()
}
