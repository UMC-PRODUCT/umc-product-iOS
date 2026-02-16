//
//  NoticeLinkCard.swift
//  AppProduct
//
//  Created by 이예지 on 1/10/26.
//

import SwiftUI

// MARK: - NoticeLinkCard
/// 공지 상세에서 첨부 링크를 표시하는 카드 컴포넌트
struct NoticeLinkCard: View {
    
    // MARK: - Property
    let url: String
    @Environment(\.openURL) var openURL
    
    // MARK: - Constants
    fileprivate enum Constants {
        static let innerPadding: CGFloat = 12
    }
    
    // MARK: - Body
    var body: some View {
        Button(action: {
            openURL(URL(string: url)!)
        }) {
            HStack {
                LinkIconPresenter()
                
                LinkTextPresenter(url: url)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.grey400)
            }
            .padding(Constants.innerPadding)
            .background {
                ConcentricRectangle(corners: .concentric(minimum: DefaultConstant.concentricRadius), isUniform: true)
                    .foregroundStyle(Color(.systemGroupedBackground))
            }
        }
        .glassEffect(.clear, in: .rect(corners: .concentric(minimum: DefaultConstant.concentricRadius), isUniform: true))
    }
}


// MARK: - LinkIconPresenter
/// 링크 아이콘
struct LinkIconPresenter: View {
    
    // MARK: - Constants
    fileprivate enum Constants {
        static let linkIconSize: CGSize = .init(width: 20, height: 20)
        static let iconPadding: CGFloat = 10
    }
    
    // MARK: - Body
    var body: some View {
        Image(systemName: "link")
            .resizable()
            .frame(width: Constants.linkIconSize.width, height: Constants.linkIconSize.height)
            .foregroundStyle(Color.grey100)
            .padding(Constants.iconPadding)
            .background {
                RoundedRectangle(cornerRadius: DefaultConstant.defaultCornerRadius)
                    .foregroundStyle(Color(.systemGray2))
            }
    }
}


// MARK: - LinkTextPresenter
/// 링크 텍스트
struct LinkTextPresenter: View {
    
    // MARK: - Property
    let url: String
    
    // MARK: Constants
    fileprivate enum Constants {
        static let vstackSpacing: CGFloat = 3
    }
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.vstackSpacing) {
            Text("관련 링크 바로가기")
                .font(.app(.calloutEmphasis))
                .foregroundStyle(Color.black)
            
            Text(url)
                .font(.app(.footnote, weight: .regular))
                .foregroundStyle(Color.grey700)
        }
    }
}


// MARK: - Preview
// url을 https:// 까지 입력해야 정상작동!
#Preview(traits: .sizeThatFitsLayout) {
    NoticeLinkCard(url: "https://www.naver.com")
}
