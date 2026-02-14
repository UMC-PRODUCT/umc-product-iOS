//
//  AuthSection.swift
//  AppProduct
//
//  Created by euijjang97 on 1/31/26.
//

import SwiftUI

/// 마이페이지의 인증 관련 섹션 (로그아웃, 회원탈퇴)
///
/// 사용자 인증 관련 작업을 처리하는 섹션으로, AlertPrompt를 통해 확인 다이얼로그를 표시합니다.
struct AuthSection: View {
    // MARK: - Property

    let sectionType: MyPageSectionType
    @Binding var alertPrompt: AlertPrompt?
    @Environment(\.appFlow) private var appFlow

    init(sectionType: MyPageSectionType, alertPrompt: Binding<AlertPrompt?>) {
        self.sectionType = sectionType
        self._alertPrompt = alertPrompt
    }

    // MARK: - Body

    var body: some View {
        Section(content: {
            sectionContent
        })
    }

    // MARK: - Private Function

    private var sectionContent: some View {
        ForEach(AuthType.allCases, id: \.rawValue) { auth in
            content(auth)
        }
    }
    
    private func content(_ auth: AuthType) -> some View {
        Button(action: {
            typeAction(auth)
        }, label: {
            // 회원 탈퇴는 빨간색으로 표시
            MyPageSectionRow(systemIcon: auth.icon, title: auth.rawValue, rightText: "", iconBackgroundColor: auth.color, titleColor: auth == .accountDelete ? .red : .black)
        })
    }

    /// 인증 타입에 따른 액션을 처리하고 AlertPrompt를 표시
    ///
    /// - Parameter auth: 처리할 인증 타입 (로그아웃 또는 회원탈퇴)
    private func typeAction(_ auth: AuthType) {
        switch auth {
        case .logout:
            alertPrompt = .init(
                title: "로그아웃",
                message: "정말 로그아웃 하시겠습니까?",
                positiveBtnTitle: "로그아웃",
                positiveBtnAction: {
                    appFlow.logout()
                },
                negativeBtnTitle: "취소",
                isPositiveBtnDestructive: true
            )
        case .accountDelete:
            alertPrompt = .init(
                title: "계정 삭제",
                message: "계정을 삭제하면 모든 데이터가 영구적으로 삭제됩니다. 정말 삭제하시겠습니까",
                positiveBtnTitle: "삭제",
                positiveBtnAction: {
                    // TODO: - 계정 삭재 로직
                },
                negativeBtnTitle: "취소",
                isPositiveBtnDestructive: true
            )
        }
    }
    
}
