//
//  LawSection.swift
//  AppProduct
//
//  Created by euijjang97 on 1/29/26.
//

import SwiftUI

/// 마이페이지 약관 섹션
///
/// 개인정보처리방침, 이용약관 등 법적 문서로 이동하는 버튼들을 표시합니다.
struct LawSection: View {
    // MARK: - Property

    @Environment(\.di) var di
    let sectionType: MyPageSectionType

    private var router: NavigationRouter {
        di.resolve(NavigationRouter.self)
    }

    // MARK: - Body

    var body: some View {
        Section(content: {
            sectionRow
        }, header: {
            SectionHeaderView(title: sectionType.rawValue)
        })
    }

    // MARK: - Function

    @ViewBuilder
    private var sectionRow: some View {
        ForEach(LawsType.allCases, id: \.rawValue) { law in
            sectionContent(law)
        }
    }
    
    private func sectionContent(_ law: LawsType) -> some View {
        Button(action: {
            sectionAction(law)
        }, label: {
            MyPageSectionRow(systemIcon: law.icon, title: law.rawValue, rightImage: "chevron.right", iconBackgroundColor: law.color)
        })
    }
    
    /// 약관 타입에 따라 적절한 화면으로 이동
    ///
    /// - Parameter law: 이동할 약관 타입 (개인정보처리방침/이용약관)
    ///
    /// - Note: 현재는 개발 중이며, 추후 WebView 또는 PDF 뷰어로 연결 예정
    private func sectionAction(_ law: LawsType) {
        switch law {
        case .policy:
            // TODO: 개인정보처리방침 화면으로 이동
            print("개인정보처리 방침")
        case .terms:
            // TODO: 이용약관 화면으로 이동
            print("이용약관")
        }
    }
}
