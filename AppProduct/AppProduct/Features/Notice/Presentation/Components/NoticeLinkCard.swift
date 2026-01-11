//
//  NoticeLinkCard.swift
//  AppProduct
//
//  Created by 이예지 on 1/10/26.
//

import SwiftUI

// MARK: - NoticeLinkCard
struct NoticeLinkCard: View {
    
    // MARK: - Property
    let noticeLinkItem: NoticeLinkItem
    
    // MARK: - Constants
    fileprivate enum Constants {
        static let chevronSize: CGSize = .init(width: 4, height: 8)
        static let innerPadding: CGFloat = 12
        static let radius: CGFloat = 14
    }
    
    // MARK: - Body
    var body: some View {
        HStack {
            LinkIconPresenter()
            
            LinkTextPresenter(url: noticeLinkItem.url)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .resizable()
                .frame(width: Constants.chevronSize.width, height: Constants.chevronSize.height)
                .foregroundStyle(Color.border)
        }
        .padding(Constants.innerPadding)
        .background {
            RoundedRectangle(cornerRadius: Constants.radius)
                .foregroundStyle(Color.primary100)
        }
    }
}


// MARK: - LinkIconPresenter
/// 링크 아이콘
struct LinkIconPresenter: View {
    
    // MARK: - Constants
    fileprivate enum Constants {
        static let linkIconSize: CGSize = .init(width: 20, height: 20)
        static let iconPadding: CGFloat = 10
        static let iconCornerRadius: CGFloat = 10
    }
    
    // MARK: - Body
    var body: some View {
        Image(systemName: "link")
            .resizable()
            .frame(width: Constants.linkIconSize.width, height: Constants.linkIconSize.height)
            .foregroundStyle(Color.primary700)
            .padding(Constants.iconPadding)
            .background {
                RoundedRectangle(cornerRadius: Constants.iconCornerRadius)
                    .foregroundStyle(Color.primary200)
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
                .font(.app(.subheadline, weight: .bold))
            
            Text(url)
                .font(.app(.caption1, weight: .regular))
                .foregroundStyle(Color.neutral700)
        }
    }
}


// MARK: - Preview
#Preview(traits: .sizeThatFitsLayout) {
    NoticeLinkCard(noticeLinkItem: NoticeLinkItem(url: "www.naver.com"))
}
