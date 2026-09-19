//
//  AuthSection.swift
//  MyPage
//
//  Created by 김동민 on 7/4/26.
//

import CoreUIComponents
import Foundation
import SwiftUI
import UMCFoundation

/// 마이페이지의 인증 관련 섹션 (이메일 변경, 비밀번호 변경, 로그아웃, 회원탈퇴)
///
/// 사용자 인증 관련 작업을 처리하는 섹션으로, AlertPrompt를 통해 확인 다이얼로그를 표시합니다.
/// 실제 화면 이동·세션 종료·탈퇴 수행은 상위(``MyPageView``)가 주입한 액션이 담당합니다.
public struct AuthSection: View {

    // MARK: - Property

    private let sectionType: MyPageSectionType
    @Binding private var alertPrompt: AlertPrompt?
    private let hasLocalCredential: Bool?
    private let onChangePassword: () -> Void
    private let onLogout: () -> Void
    private let onDeleteAccount: () -> Void
    private let onChangeEmail: () -> Void

    // MARK: - Constant

    fileprivate enum Constants {
        static let registerPasswordTitle: String = "비밀번호 등록"
    }

    // MARK: - Init

    /// - Parameter hasLocalCredential: 로컬 비밀번호 보유 여부. `false`면 비밀번호 행이
    ///   「비밀번호 등록」이 되고, `nil`(아직 모름)이면 행을 숨긴다.
    public init(
        sectionType: MyPageSectionType = .auth,
        alertPrompt: Binding<AlertPrompt?>,
        hasLocalCredential: Bool?,
        onChangePassword: @escaping () -> Void,
        onLogout: @escaping () -> Void,
        onDeleteAccount: @escaping () -> Void,
        onChangeEmail: @escaping () -> Void
    ) {
        self.sectionType = sectionType
        self._alertPrompt = alertPrompt
        self.hasLocalCredential = hasLocalCredential
        self.onChangePassword = onChangePassword
        self.onLogout = onLogout
        self.onDeleteAccount = onDeleteAccount
        self.onChangeEmail = onChangeEmail
    }

    // MARK: - Body

    public var body: some View {
        Section(content: {
            sectionContent
        }, header: {
            SectionHeaderView(title: sectionType.rawValue, weight: .semibold)
        })
    }

    // MARK: - Function

    private var sectionContent: some View {
        ForEach(AuthType.allCases, id: \.rawValue) { auth in
            if auth != .changePassword || hasLocalCredential != nil {
                content(auth)
            }
        }
    }

    private func content(_ auth: AuthType) -> some View {
        Button(action: {
            typeAction(auth)
        }, label: {
            // 회원 탈퇴는 빨간색으로 표시
            MyPageSectionRow(
                systemIcon: auth.icon,
                title: title(for: auth),
                rightText: "",
                iconBackgroundColor: auth.color,
                titleColor: auth == .accountDelete ? .red : .black
            )
        })
        .buttonStyle(.borderless)
    }

    private func title(for auth: AuthType) -> String {
        guard auth == .changePassword, hasLocalCredential == false else { return auth.rawValue }
        return Constants.registerPasswordTitle
    }

    /// 인증 타입에 따른 액션을 처리하고, 파괴적 작업은 AlertPrompt로 확인받는다.
    ///
    /// - Parameter auth: 처리할 인증 타입 (이메일 변경, 비밀번호 변경, 로그아웃 또는 회원탈퇴)
    private func typeAction(_ auth: AuthType) {
        switch auth {
        case .changeEmail:
            onChangeEmail()
        case .changePassword:
            onChangePassword()
        case .logout:
            alertPrompt = .init(
                title: "로그아웃",
                message: "정말 로그아웃을 하시겠습니까?",
                positiveBtnTitle: "로그아웃",
                positiveBtnAction: onLogout,
                negativeBtnTitle: "취소",
                isPositiveBtnDestructive: true
            )
        case .accountDelete:
            alertPrompt = .init(
                title: "계정 삭제",
                message: "계정을 삭제하면 모든 데이터가 영구적으로 삭제됩니다. 정말 삭제하시겠습니까?",
                positiveBtnTitle: "삭제",
                positiveBtnAction: onDeleteAccount,
                negativeBtnTitle: "취소",
                isPositiveBtnDestructive: true
            )
        }
    }
}
