//
//  ThreadMemberProfileContent.swift
//  CommunityPresentation
//
//  Created by euijjang97 on 11/19/26.
//

import CommunityDomain
import CoreDesignSystem
import CoreDomain
import CoreUIComponents
import SwiftUI
import UMCFoundation

/// 스레드에서 연 다른 회원 프로필 시트의 내용 (#1681).
///
/// `MemberSafetyProfileView` 의 내용 자리에 들어가는 `Section` 묶음이다. 시안 「(스레드)프로필
/// 조회」(`80:20399`)처럼 사진·이름·학교·기수/파트·활동 이력·이메일·링크를 보여 준다.
/// 입력하지 않았거나 비공개인 항목은 자물쇠와 문구로 표시한다 — 서버가 둘을 똑같이 `null` 로
/// 줘서 구분하지 않는다. 이메일은 서버가 주지 않아 늘 비공개로 보인다.
struct ThreadMemberProfileContent: View {

    // MARK: - Property

    @State private var viewModel: ThreadMemberProfileViewModel
    /// 프로필을 읽기 전·실패했을 때 머리 행에 보일 이름. 메시지·참여자 행이 이미 들고 있다.
    private let name: String

    private enum Constants {
        static let avatarSize: CGFloat = 96
        static let iconSize: CGFloat = 28
        static let iconRadius: CGFloat = 7
        static let nameHeader = "이름/닉네임"
        static let schoolHeader = "학교"
        static let generationHeader = "기수/파트"
        static let activityHeader = "활동 이력"
        static let contactHeader = "연락처·외부 링크"
        static let loadingTitle = "프로필을 불러오는 중"
        static let failureTitle = "프로필을 불러오지 못했어요."
        static let retryTitle = "다시 시도"
        static let noActivity = "활동 이력이 없어요."
        static let privateTitle = "비공개 항목이에요."
        static let emptyValue = "-"
        static let emailTitle = "이메일"
        static let emailIcon = "envelope.fill"
        static let privateIcon = "lock.fill"
    }

    // MARK: - Init

    init(memberId: String, name: String, useCase: ThreadMemberProfileUseCaseProtocol) {
        self._viewModel = State(
            initialValue: ThreadMemberProfileViewModel(memberId: memberId, useCase: useCase)
        )
        self.name = name
    }

    // MARK: - Body

    var body: some View {
        // 첫 섹션에만 `.task` 를 단다 — 섹션 묶음 전체에 달면 섹션마다 한 번씩 읽는다.
        headerSection
            .task { await viewModel.load() }

        switch viewModel.state {
        case .idle, .loading:
            Section {
                ProgressView(Constants.loadingTitle)
                    .frame(maxWidth: .infinity)
            }
        case .failed:
            Section {
                HStack {
                    Text(Constants.failureTitle)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(Constants.retryTitle) { Task { await viewModel.load() } }
                        .buttonStyle(.borderless)
                }
            }
        case .loaded(let profile):
            Section(Constants.nameHeader) { Text(displayName(profile)) }
            Section(Constants.schoolHeader) { Text(valueOrDash(profile.schoolName)) }
            Section(Constants.generationHeader) { Text(generationAndPart(profile)) }
            activitySection(profile.activityLogs)
            contactSection(profile.links)
        }
    }

    // MARK: - View Component

    /// 사진. 읽기 전·실패했을 때는 넘겨받은 이름을 사진 아래에 둔다 — 읽고 나면 「이름/닉네임」
    /// 섹션이 같은 값을 보여 주므로(시안) 겹치지 않게 뺀다.
    private var headerSection: some View {
        let profile = viewModel.state.value
        return Section {
            VStack(spacing: DefaultSpacing.spacing8) {
                RemoteImage(
                    urlString: profile?.profileImageURL ?? "",
                    size: CGSize(width: Constants.avatarSize, height: Constants.avatarSize),
                    cornerRadius: Constants.avatarSize / 2
                )
                .accessibilityHidden(true)

                if profile == nil {
                    Text(name)
                        .appFont(.title3, weight: .semibold)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
        }
    }

    @ViewBuilder
    private func activitySection(_ logs: [ActivityLog]) -> some View {
        Section(Constants.activityHeader) {
            if logs.isEmpty {
                Text(Constants.noActivity)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(logs) { log in
                    activityRow(log)
                }
            }
        }
    }

    /// 마이페이지 「활동 이력」 행과 같은 모양 — 기수 · 파트 · 운영진 역할.
    private func activityRow(_ log: ActivityLog) -> some View {
        let roles = log.roles.filter { $0 != .challenger }
        let partName = log.part == .admin ? "" : log.part.name
        let label = (["\(log.generation)기", partName] + roles.map(\.tagName))
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
        return HStack(spacing: DefaultSpacing.spacing8) {
            Text("\(log.generation)기")
                .appFont(.footnote)
            if !partName.isEmpty {
                MemberTag(part: log.part)
            }
            Spacer()
            ForEach(roles, id: \.self) { role in
                MemberTag(role: role)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
    }

    private func contactSection(_ links: [ThreadMemberProfile.Link]) -> some View {
        Section(Constants.contactHeader) {
            contactRow(
                icon: AnyView(
                    Color.accentColor.overlay {
                        Image(systemName: Constants.emailIcon)
                            .resizable()
                            .scaledToFit()
                            .padding(DefaultSpacing.spacing4)
                            .foregroundStyle(.white)
                    }
                ),
                title: Constants.emailTitle,
                value: nil
            )
            ForEach(links, id: \.kind) { link in
                contactRow(
                    icon: AnyView(brandIcon(link.kind).resizable().aspectRatio(contentMode: .fill)),
                    title: title(link.kind),
                    value: link.value
                )
            }
        }
    }

    /// 값이 있으면 주소를, 없으면 자물쇠와 「비공개 항목이에요.」를 보인다.
    private func contactRow(icon: AnyView, title: String, value: String?) -> some View {
        HStack(spacing: DefaultSpacing.spacing8) {
            icon
                .frame(width: Constants.iconSize, height: Constants.iconSize)
                .clipShape(.rect(cornerRadius: Constants.iconRadius))
                .accessibilityHidden(true)

            if let value {
                Text(value)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
            } else {
                Label(Constants.privateTitle, systemImage: Constants.privateIcon)
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(value ?? Constants.privateTitle)
    }

    // MARK: - Function

    private func displayName(_ profile: ThreadMemberProfile) -> String {
        let nickname = profile.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        return nickname.isEmpty ? profile.name : "\(profile.name)/\(nickname)"
    }

    private func generationAndPart(_ profile: ThreadMemberProfile) -> String {
        let generation = profile.generation.isEmpty ? "" : "\(profile.generation)기"
        let items = [generation, profile.part?.name ?? ""].filter { !$0.isEmpty }
        return items.isEmpty ? Constants.emptyValue : items.joined(separator: "/")
    }

    private func valueOrDash(_ value: String) -> String {
        value.isEmpty ? Constants.emptyValue : value
    }

    /// 설정·내 정보 편집 화면의 외부 링크 행과 같은 브랜드 이미지.
    private func brandIcon(_ kind: ThreadMemberProfile.Kind) -> Image {
        switch kind {
        case .github: .githubColor
        case .linkedIn: .linkedInColor
        case .blog: Image(systemName: "text.alignleft")
        case .instagram: .umcInstagram
        case .personal: .blogColor
        }
    }

    private func title(_ kind: ThreadMemberProfile.Kind) -> String {
        switch kind {
        case .github: "GitHub"
        case .linkedIn: "LinkedIn"
        case .blog: "Blog"
        case .instagram: "Instagram"
        case .personal: "개인 사이트"
        }
    }
}
