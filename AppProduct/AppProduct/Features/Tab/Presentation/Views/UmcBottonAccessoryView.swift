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
    @Environment(ErrorHandler.self) var errorHandler
    
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
    
    private var router: NavigationRouter {
        di.resolve(NavigationRouter.self)
    }
    
    var body: some View {
        Button(action: {
            router.push(to: .home(.registrationSchedule))
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
    @Environment(\.di) private var di
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement

    private var userSession: UserSessionManager {
        di.resolve(UserSessionManager.self)
    }

    var body: some View {
        if userSession.canToggleAdminMode {
            adminToggleButton
        } else {
            EmptyView()
        }
    }

    private var adminToggleButton: some View {
        Button {
            withAnimation(.snappy) {
                userSession.toggleAdminMode()
            }
        } label: {
            HStack(spacing: DefaultSpacing.spacing8) {
                Image(systemName: userSession.isAdminModeEnabled
                    ? "gearshape.fill" : "gearshape")
                    .foregroundStyle(userSession.isAdminModeEnabled ? .indigo500 : .grey600)

                // 축소/확장 상태 모두 텍스트 표시
                Text(userSession.isAdminModeEnabled ? "운영진 모드" : "챌린저 모드")
                    .appFont(placement == .expanded ? .subheadline : .subheadline)
                    .foregroundStyle(.black)

                if placement == .expanded {
                    Spacer()

                    // 현재 역할 배지
                    Text(userSession.currentRole.displayName)
                        .appFont(.subheadline)
                }
            }
            .padding(.horizontal, placement == .expanded ? DefaultConstant.defaultSafeHorizon : 0)
        }
    }
}

// MARK: - Community
fileprivate struct CommunityAccessoryView: View {
    @Environment(\.di) private var di
    
    private var router: NavigationRouter {
        di.resolve(NavigationRouter.self)
    }
    
    var body: some View {
        Button(action: {
            router.push(to: .community(.post))
        }) {
            HStack(spacing: DefaultSpacing.spacing8) {
                Spacer()
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(.indigo500)
                
                Text("게시글 작성")
                    .fontWeight(.semibold)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundStyle(.grey900)
        }
    }
}
// MARK: - MyPage
fileprivate struct MyPageAccessoryView: View {
    var body: some View {
        Text("11")
    }
}
