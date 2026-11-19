//
//  ProfileLinkEditSection.swift
//  MyPagePresentation
//
//  Created by euijjang97 on 8/10/26.
//

import CoreDesignSystem
import CoreUIComponents
import MyPageDomain
import SwiftUI

/// 외부 프로필 링크(`SocialLinkType` 전 종류)를 TextField로 직접 편집하는 섹션.
///
/// 링크를 열기만 하는 ``ProfileLinkSection``과 달리 프로필 수정 화면 전용이다.
/// 줄 순서가 명함 뒷면 우선순위다 (#1679). 설정 앱 「선호하는 언어」 목록처럼 줄 오른쪽 손잡이가
/// 늘 보이고 바로 끌어서 옮긴다. 맨 위에서부터 값 있는 첫 링크가 명함에 보인다.
struct ProfileLinkEditSection: View, Equatable {

    // MARK: - Property

    @Binding private var profileLink: [ProfileLink]
    private let linkPriority: [SocialLinkType]
    private let header: String
    private let onMove: (IndexSet, Int) -> Void

    private enum Constants {
        /// 시안 아이콘 틀 (`Figma item/MypageModify/link` 실측 32×32, 라운드 8).
        static let iconSize: CGFloat = 32
        static let iconRadius: CGFloat = 8
        static let footer = """
            명함 뒷면에는 이 목록에서 링크가 입력된 첫 번째 항목이 보여요. \
            오른쪽 손잡이를 끌어 순서를 바꿀 수 있어요.
            """
    }

    // MARK: - Init

    init(
        profileLink: Binding<[ProfileLink]>,
        linkPriority: [SocialLinkType],
        header: String,
        onMove: @escaping (IndexSet, Int) -> Void
    ) {
        self._profileLink = profileLink
        self.linkPriority = linkPriority
        self.header = header
        self.onMove = onMove
    }

    // MARK: - Equatable

    /// 클로저는 비교하지 않는다 — 화면이 매번 같은 동작을 넘긴다.
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.header == rhs.header
            && lhs.profileLink == rhs.profileLink
            && lhs.linkPriority == rhs.linkPriority
    }

    // MARK: - Body

    var body: some View {
        Section(content: {
            ForEach(linkPriority, id: \.rawValue) { type in
                linkField(type)
            }
            .onMove(perform: onMove)
        }, header: {
            SectionHeaderView(title: header, weight: .semibold)
        }, footer: {
            Text(Constants.footer)
        })
    }

    // MARK: - Function

    private func linkField(_ type: SocialLinkType) -> some View {
        HStack(spacing: DefaultSpacing.spacing8) {
            // 시안(12804:30609)은 SF Symbol 틴트가 아니라 서비스 브랜드 이미지를 쓴다 —
            // 설정 화면 외부 링크 행(ProfileLinkSection)과 같은 에셋.
            type.brandIcon
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: Constants.iconSize, height: Constants.iconSize)
                .clipShape(.rect(cornerRadius: Constants.iconRadius))
                // 장식 — 입력 필드 placeholder 가 이미 어떤 링크인지 말한다.
                .accessibilityHidden(true)

            TextField("", text: binding(for: type), prompt: Text(type.placeholder))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
        }
    }

    /// 서버가 모든 링크 타입을 항상 내려주지는 않으므로, 없는 타입은 입력 시점에 추가한다.
    private func binding(for type: SocialLinkType) -> Binding<String> {
        Binding(
            get: { profileLink.first(where: { $0.type == type })?.url ?? "" },
            set: { newValue in
                if let index = profileLink.firstIndex(where: { $0.type == type }) {
                    profileLink[index].url = newValue
                } else {
                    profileLink.append(ProfileLink(type: type, url: newValue))
                }
            }
        )
    }
}
