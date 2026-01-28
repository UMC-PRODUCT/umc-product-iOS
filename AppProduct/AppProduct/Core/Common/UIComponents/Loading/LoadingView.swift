//
//  LoadingView.swift
//  AppProduct
//
//  Created by euijjang97 on 1/21/26.
//

import Foundation
import SwiftUI

struct LoadingView: View {
    let type: LoadingType
    
    enum LoadingType {
        case home(Home)
        
        enum Home: String {
            case seasonLoading = "기수 정보를 가져오는 중입니다."
            case penaltyLoading = "패널티 정보를 가져오는 중입니다."
            case recentNoticeLoading = "최근 공지를 가져오는 중입니다."
        }
        
        var text: String {
            switch self {
            case .home(let homeType):
                return homeType.rawValue
            }
        }
    }
    
    init(_ type: LoadingType) {
        self.type = type
    }
    
    var body: some View {
        ProgressView(label: {
            Text(type.text)
                .appFont(.footnote, color: .grey400)
                .frame(maxWidth: .infinity)
        })
        .padding(20)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: DefaultConstant.defaultCornerRadius))
    }
}
