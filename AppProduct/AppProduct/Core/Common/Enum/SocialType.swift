//
//  SocialType.swift
//  AppProduct
//
//  Created by euijjang97 on 1/12/26.
//

import Foundation
import SwiftUI

enum SocialType: String, CaseIterable {
    case kakao = "Kakao"
    case apple = "Apple"
    
    var image: Image {
        switch self {
        case .kakao:
            return Image(.kakao)
        case .apple:
            return Image(.apple)
        }
    }
}
