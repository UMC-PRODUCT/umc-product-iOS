//
//  UmcBottonAccessoryView.swift
//  AppProduct
//
//  Created by euijjang97 on 1/19/26.
//

import SwiftUI

struct UmcBottonAccessoryView: View {
    @Binding var tabCase: TabCase
    @Environment(\.di) var di
    
    var body: some View {
        switch tabCase {
        case .home:
            HomeBottonAccessoryView()
        case .notice:
            NoticeAccessoryView()
        case .activity:
            ActivityAccessoryView()
        case .community:
            CommunityAccessoryView()
        case .mypage:
            MyPageAccessoryView()
        }
    }
}

// MARK: - Home
fileprivate struct HomeBottonAccessoryView: View {
    @Environment(\.di) var di
    
    var body: some View {
        Button(action: {
            print("hello")
        }, label: {
            HStack(spacing: DefaultSpacing.spacing8) {
                Spacer()
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(.indigo500)
                
                Text("일정 생성")
                    .fontWeight(.semibold)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundStyle(.grey900)
        })
    }
}

// MARK: - Notice
fileprivate struct NoticeAccessoryView: View {
    var body: some View {
        Text("11")
    }
}

// MARK: - Activity
fileprivate struct ActivityAccessoryView: View {
    var body: some View {
        Text("11")
    }
}

// MARK: - Community
fileprivate struct CommunityAccessoryView: View {
    var body: some View {
        Text("11")
    }
}
// MARK: - MyPage
fileprivate struct MyPageAccessoryView: View {
    var body: some View {
        Text("11")
    }
}
