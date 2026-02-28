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
    @Environment(\.openURL) private var openURL
    @Environment(ErrorHandler.self) private var errorHandler
    let sectionType: MyPageSectionType

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
    
    /// 약관 타입에 해당하는 Row를 생성합니다.
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
    private func sectionAction(_ law: LawsType) {
        Task {
            do {
                let provider = di.resolve(MyPageUseCaseProviding.self)
                let terms = try await provider.fetchTermsUseCase.execute(
                    termsType: law.apiType
                )

                guard let url = URL(string: terms.link) else {
                    throw AppError.validation(
                        .invalidFormat(
                            field: "termsLink",
                            expected: "https://..."
                        )
                    )
                }
                openURL(url)
            } catch {
                errorHandler.handle(
                    error,
                    context: .init(
                        feature: "MyPage",
                        action: "openTerms(\(law.apiType))"
                    )
                )
            }
        }
    }
}
