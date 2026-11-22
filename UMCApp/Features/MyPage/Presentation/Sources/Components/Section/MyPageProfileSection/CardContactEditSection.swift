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

struct CardContactEditSection: View {

    // MARK: - Property

    @Binding private var settings: CardContactSettings
    private let loadState: Loadable<CardContactSettings>
    private let email: String
    private let linkPriority: [SocialLinkType]
    private let header: String
    private let onMove: (IndexSet, Int) -> Void
    private let onRetry: () -> Void

    @Environment(\.editMode) private var editMode
    @State private var editingLink: SocialLinkType?
    @FocusState private var focusedLink: SocialLinkType?

    private enum Constants {
        static let emailTitle = "이메일"
        static let noEmail = "등록된 이메일이 없어요"
        static let publicTitle = "공개"
        static let privateTitle = "비공개"
        static let loadingTitle = "연락처·링크를 불러오는 중"
        static let failureTitle = "연락처·링크를 불러오지 못했어요."
        static let retryTitle = "다시 시도"
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
                .onMove(perform: isReordering ? onMove : nil)
            }
        }, header: {
            HStack {
                SectionHeaderView(title: header, weight: .semibold)
                Spacer()
                if case .loaded = loadState {
                    Button {
                        endEditing()
                        editMode?.wrappedValue = isReordering ? .inactive : .active
                    } label: {
                        Text(isReordering ? "정렬 마침" : "순서 변경")
                            .appFont(.footnote, weight: .semibold, color: Color.teal600)
                            .frame(minHeight: DefaultConstant.minimumTouchTarget)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel(isReordering ? "링크 정렬 마침" : "링크 순서 변경")
                }
            }
        }, footer: {
            if case .loaded = loadState {
                VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
                    Text(cardLinkSummary)
                    Text("공개한 정보는 다른 회원이 스레드에서 내 프로필을 볼 때도 표시돼요.")
                }
            }
        })
        .onChange(of: focusedLink) { previous, current in
            if current == nil, editingLink == previous {
                editingLink = nil
            }
        }
    }

    private var isReordering: Bool {
        editMode?.wrappedValue.isEditing == true
    }

    private var cardLinkSummary: String {
        let firstLink = linkPriority.first { type in
            let item = settings.link(type)
            let address = item.value.trimmingCharacters(in: .whitespacesAndNewlines)
            return item.isPublic && !address.isEmpty
        }
        guard let firstLink else { return "명함 뒷면에 표시할 공개 링크가 없어요." }
        return "명함 뒷면에 표시되는 링크 · \(firstLink.title)"
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

    private var emailRow: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
            rowHeader(title: Constants.emailTitle, isPublic: $settings.isEmailPublic) {
                Color.accentColor.overlay {
                    Image(systemName: "envelope.fill")
                        .resizable()
                        .scaledToFit()
                        .padding(DefaultSpacing.spacing8)
                        .foregroundStyle(.white)
                }
            }

            Text(verbatim: email.isEmpty ? Constants.noEmail : email)
                .font(.app(.subheadline))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }
    }

    private func linkRow(_ type: SocialLinkType) -> some View {
        let item = linkBinding(type)
        return VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
            rowHeader(title: type.title, isPublic: item.isPublic) {
                type.brandIcon
                    .resizable()
                    .scaledToFit()
            }

            if editingLink == type {
                TextField(type.placeholder, text: item.value, axis: .vertical)
                    .font(.app(.subheadline))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                    .focused($focusedLink, equals: type)
                    .onAppear { focusedLink = type }
                    .accessibilityLabel("\(type.title) 주소")
            } else {
                Button {
                    editingLink = type
                } label: {
                    let rawValue = item.wrappedValue.value
                    let address = rawValue.isEmpty ? type.placeholder : rawValue
                    Text(verbatim: displayAddress(address))
                        .font(.app(.subheadline))
                        .foregroundStyle(rawValue.isEmpty ? .tertiary : .secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(
                            maxWidth: .infinity,
                            minHeight: DefaultConstant.minimumTouchTarget,
                            alignment: .leading
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(type.title) 주소 편집")
                .accessibilityValue(item.wrappedValue.value)
            }
        }
        .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }
    }

    private func rowHeader(
        title: String,
        isPublic: Binding<Bool>,
        @ViewBuilder icon: () -> some View
    ) -> some View {
        HStack(spacing: DefaultSpacing.spacing8) {
            icon()
                .frame(width: DefaultSpacing.spacing32, height: DefaultSpacing.spacing32)
                .clipShape(.rect(cornerRadius: DefaultSpacing.spacing8))
                .accessibilityHidden(true)

            Text(title)
                .appFont(.callout, weight: .semibold)
            Spacer(minLength: DefaultSpacing.spacing4)
            visibilityButton(isPublic: isPublic, title: title)
        }
    }

    private func visibilityButton(isPublic: Binding<Bool>, title: String) -> some View {
        let value = isPublic.wrappedValue
        return Button {
            endEditing()
            isPublic.wrappedValue.toggle()
        } label: {
            Label(
                value ? Constants.publicTitle : Constants.privateTitle,
                systemImage: value ? "lock.open" : "lock.fill"
            )
            .labelStyle(.titleAndIcon)
            .appFont(.footnote, weight: .semibold)
            .foregroundStyle(value ? Color.teal600 : Color.secondary)
            .frame(minHeight: DefaultConstant.minimumTouchTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .accessibilityLabel("\(title) 공개 여부")
        .accessibilityValue(value ? Constants.publicTitle : Constants.privateTitle)
        .accessibilityHint(value ? "비공개로 바꿉니다." : "공개로 바꿉니다.")
    }

    // MARK: - Function

    private func endEditing() {
        focusedLink = nil
        editingLink = nil
    }

    private func displayAddress(_ address: String) -> String {
        let prefix = "https://"
        guard address.lowercased().hasPrefix(prefix) else { return address }
        return String(address.dropFirst(prefix.count))
    }

    /// 서버가 링크를 늘 5개 주지만, 빠진 종류가 있어도 입력하는 순간 채운다.
    private func linkBinding(_ type: SocialLinkType) -> Binding<CardContactItem> {
        Binding(
            get: { settings.link(type) },
            set: { settings.links[type] = $0 }
        )
    }
}
