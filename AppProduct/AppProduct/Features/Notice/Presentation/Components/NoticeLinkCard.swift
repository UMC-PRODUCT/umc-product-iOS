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
    
    // MARK: - Body
    
    var body: some View {
        HStack {
            LinkIconPresenter()
            
            LinkTextPresenter(url: noticeLinkItem.url)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .resizable()
                .frame(width: 4, height: 8)
                .foregroundStyle(Color.border)
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .foregroundStyle(Color.primary100)
        }
    }
}

// MARK: - LinkIconPresenter
struct LinkIconPresenter: View {
    var body: some View {
        Image(systemName: "link")
            .resizable()
            .frame(width: 20, height: 20)
            .foregroundStyle(Color.primary700)
            .padding(10)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .foregroundStyle(Color.primary200)
            }
    }
}

// MARK: - LinkTextPresenter
struct LinkTextPresenter: View {
    
    let url: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
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
