//
//  CardContactEditSection.swift
//  MyPagePresentation
//
//  Created by euijjang97 on 11/19/26.
//

import CoreDesignSystem
import CoreUIComponents
import MyPageDomain
import SwiftUI
import UMCFoundation

/// 명함 이메일·외부 링크의 공개 여부를 고르고 링크를 입력·정렬하는 섹션 (#1678 · #1679).
///
/// 이메일은 따로 입력받지 않고 계정 이메일을 보여 주기만 한다 — 공개 여부만 고른다.
/// 링크 줄 순서가 명함 뒷면 우선순위다. 설정 앱 「선호하는 언어」처럼 손잡이가 늘 보이고
/// 바로 끌어서 옮긴다. 공개한 링크 중 맨 위에서부터 값 있는 첫 링크가 명함에 보인다.
///
/// 공개 여부는 서버에서 읽은 뒤에야 알 수 있어, 읽기 전에는 입력칸 대신 진행·실패 행을 둔다 —
/// 빈 칸을 먼저 보여 주면 입력한 값이 조회 결과에 덮인다.
struct CardContactEditSection: View {

    // MARK: - Property

    @Binding private var settings: CardContactSettings
    private let loadState: Loadable<CardContactSettings>
    private let email: String
    private let linkPriority: [SocialLinkType]
    private let header: String
    private let onMove: (IndexSet, Int) -> Void
    private let onRetry: () -> Void

    private enum Constants {
        /// 시안 아이콘 틀 (`Figma item/MypageModify/link` 실측 32×32, 라운드 8).
        static let iconSize: CGFloat = 32
        static let iconRadius: CGFloat = 8
        static let emailTitle = "이메일"
        static let emailIcon = "envelope.fill"
        static let noEmail = "등록된 이메일이 없어요"
        static let publicTitle = "공개"
        static let privateTitle = "비공개"
        static let publicIcon = "lock.open"
        static let privateIcon = "lock.fill"
        static let visibilitySpacing: CGFloat = 4
        static let visibilityIconWidth: CGFloat = 16
        static let visibilityMinWidth: CGFloat = 60
        static let visibilityLabelSuffix = " 공개 여부"
        static let visibilityHint = "두 번 탭하면 공개 여부를 바꿉니다."
        static let loadingTitle = "연락처·링크를 불러오는 중"
        static let failureTitle = "연락처·링크를 불러오지 못했어요."
        static let retryTitle = "다시 시도"
        static let footer = """
            명함 뒷면에는 공개한 링크 중 이 목록에서 링크가 입력된 첫 번째 항목이 보여요. \
            오른쪽 손잡이를 끌어 순서를 바꿀 수 있어요. \
            공개한 정보는 다른 회원이 스레드에서 내 프로필을 볼 때도 표시돼요.
            """
    }

    // MARK: - Init

    init(
        settings: Binding<CardContactSettings>,
        loadState: Loadable<CardContactSettings>,
        email: String,
        linkPriority: [SocialLinkType],
        header: String,
        onMove: @escaping (IndexSet, Int) -> Void,
        onRetry: @escaping () -> Void
    ) {
        self._settings = settings
        self.loadState = loadState
        self.email = email
        self.linkPriority = linkPriority
        self.header = header
        self.onMove = onMove
        self.onRetry = onRetry
    }

    // MARK: - Body

    var body: some View {
        Section(content: {
            switch loadState {
            case .idle, .loading:
                ProgressView(Constants.loadingTitle)
                    .frame(maxWidth: .infinity)
            case .failed:
                failureRow
            case .loaded:
                emailRow
                ForEach(linkPriority, id: \.rawValue) { type in
                    linkRow(type)
                }
                .onMove(perform: onMove)
            }
        }, header: {
            SectionHeaderView(title: header, weight: .semibold)
        }, footer: {
            if case .loaded = loadState {
                Text(Constants.footer)
            }
        })
    }

    // MARK: - View Component

    private var failureRow: some View {
        HStack {
            Text(Constants.failureTitle)
                .foregroundStyle(.secondary)
            Spacer()
            Button(Constants.retryTitle, action: onRetry)
                .buttonStyle(.borderless)
        }
    }

    /// 이메일은 고칠 수 없는 값이라 입력칸이 아니라 글자로 둔다. 순서에도 끼지 않는다 —
    /// 명함 뒷면에서 이메일은 늘 링크 위다.
    private var emailRow: some View {
        HStack(spacing: DefaultSpacing.spacing8) {
            // 브랜드 아이콘처럼 틀을 꽉 채운 색 바탕에 흰 기호를 얹는다. 바탕을 기호 크기에
            // 맞추면 가로로 긴 봉투 모양을 따라 틀이 납작해진다.
            iconFrame(
                Color.accentColor.overlay {
                    Image(systemName: Constants.emailIcon)
                        .resizable()
                        .scaledToFit()
                        .padding(DefaultSpacing.spacing8)
                        .foregroundStyle(.white)
                }
            )

            Text(email.isEmpty ? Constants.noEmail : email)
                .foregroundStyle(email.isEmpty ? .secondary : .primary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel(Constants.emailTitle)
                .accessibilityValue(email.isEmpty ? Constants.noEmail : email)
                .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }

            visibilityButton(isPublic: $settings.isEmailPublic, title: Constants.emailTitle)
        }
    }

    private func linkRow(_ type: SocialLinkType) -> some View {
        HStack(spacing: DefaultSpacing.spacing8) {
            // 시안(12804:30609)은 SF Symbol 틴트가 아니라 서비스 브랜드 이미지를 쓴다 —
            // 설정 화면 외부 링크 행(ProfileLinkSection)과 같은 에셋.
            iconFrame(
                type.brandIcon
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            )

            TextField("", text: linkBinding(type).value, prompt: Text(type.placeholder))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
                .accessibilityLabel(type.title)
                // 구분선은 행의 첫 글자에 맞춰 그려지는데, 입력칸은 글자로 치지 않아 공개 버튼
                // 문구에 붙는다. 입력칸 앞에서 시작하도록 맞춘다.
                .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }

            visibilityButton(isPublic: linkBinding(type).isPublic, title: type.title)
        }
    }

    /// 장식 — 입력칸 라벨이 이미 어떤 항목인지 말한다.
    private func iconFrame(_ icon: some View) -> some View {
        icon
            .frame(width: Constants.iconSize, height: Constants.iconSize)
            .clipShape(.rect(cornerRadius: Constants.iconRadius))
            .accessibilityHidden(true)
    }

    /// 자물쇠 모양으로 공개·비공개를 바꾸는 버튼 (Android와 같은 위치·문구).
    ///
    /// 폭은 더 긴 「비공개」에 맞춰 고정한다. 문구 길이대로 두면 누를 때마다 입력칸 폭이
    /// 바뀌고, 리스트 행 안의 `Label` 은 문구를 숨기고 아이콘만 남긴다.
    private func visibilityButton(isPublic: Binding<Bool>, title: String) -> some View {
        Button {
            isPublic.wrappedValue.toggle()
        } label: {
            let icon = isPublic.wrappedValue ? Constants.publicIcon : Constants.privateIcon
            HStack(spacing: Constants.visibilitySpacing) {
                Image(systemName: icon)
                    .frame(width: Constants.visibilityIconWidth)
                Text(isPublic.wrappedValue ? Constants.publicTitle : Constants.privateTitle)
            }
            .appFont(.footnote, weight: .semibold)
            .foregroundStyle(isPublic.wrappedValue ? Color.accentColor : Color.secondary)
            .frame(minWidth: Constants.visibilityMinWidth, alignment: .leading)
            .fixedSize()
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(title + Constants.visibilityLabelSuffix)
        .accessibilityValue(isPublic.wrappedValue ? Constants.publicTitle : Constants.privateTitle)
        .accessibilityHint(Constants.visibilityHint)
    }

    // MARK: - Function

    /// 서버가 링크를 늘 5개 주지만, 빠진 종류가 있어도 입력하는 순간 채운다.
    private func linkBinding(_ type: SocialLinkType) -> Binding<CardContactItem> {
        Binding(
            get: { settings.link(type) },
            set: { settings.links[type] = $0 }
        )
    }
}
