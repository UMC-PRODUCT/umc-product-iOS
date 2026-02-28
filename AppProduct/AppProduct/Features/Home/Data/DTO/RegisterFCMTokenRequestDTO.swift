//
//  RegisterFCMTokenRequestDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/14/26.
//

import Foundation

/// FCM 토큰 등록 요청 DTO
struct RegisterFCMTokenRequestDTO: Encodable {
    let fcmToken: String
}
