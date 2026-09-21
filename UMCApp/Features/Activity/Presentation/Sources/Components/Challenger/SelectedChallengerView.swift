//
//  SelectedChallengerView.swift
//  ActivityPresentation
//
//  Created by jaewon Lee on 7/15/26.
//

import ActivityDomain
import CoreDesignSystem
import CoreDI
import CoreDomain
import CoreUIComponents
import SwiftUI
import UMCFoundation

/// 선택된 챌린저(멘토/스터디원) 목록을 확인·삭제하고, 검색으로 새 인원을 추가하는 화면.
///
/// 스터디 그룹 생성 폼과 그룹 관리 화면, 홈 일정 등록 화면이 시트로 띄우므로 자체
/// `NavigationStack` 을 가집니다.
public struct SelectedChallengerView: View {

    // MARK: - Property

    @Environment(\.dismiss) private var dismiss

    @Environment(\.di) private var container

    /// 상위 뷰와 공유하는 선택된 챌린저 목록
    @Binding var challenger: [ChallengerInfo]

    /// 검색 화면 push 여부
    @State private var showsSearch = false

    /// 검색 UseCase 주입 지점 — 프리뷰/테스트용. 미지정 시 DI 컨테이너에서 해석합니다.
    private let searchUseCase: SearchChallengersUseCaseProtocol?

    /// 검색으로 추가할 수 있는 memberId. `nil` 이면 제한하지 않습니다.
    private let selectableMemberIds: Set<String>?
    private let preferredGeneration: String?
    private let preferredPart: UMCPartType?
    private let requiresStudyContext: Bool

    /// 현재 사용자의 memberId (본인은 삭제 방지)
    private var myMemberIdSet: Set<String> {
        guard let id = AppStorageKey.memberIdString() else { return [] }
        return [id]
    }

    // MARK: - Init

    /// - Parameters:
    ///   - challenger: 상위 화면의 선택 목록 바인딩
    ///   - searchUseCase: 검색 UseCase (기본값 `nil` — DI 컨테이너에서 해석)
    ///   - selectableMemberIds: 검색 결과 중 고를 수 있는 memberId (기본값 `nil` — 제한 없음)
    public init(
        challenger: Binding<[ChallengerInfo]>,
        searchUseCase: SearchChallengersUseCaseProtocol? = nil,
        selectableMemberIds: Set<String>? = nil,
        preferredGeneration: String? = nil,
        preferredPart: UMCPartType? = nil,
        requiresStudyContext: Bool = false
    ) {
        self._challenger = challenger
        self.searchUseCase = searchUseCase
        self.selectableMemberIds = selectableMemberIds
        self.preferredGeneration = preferredGeneration
        self.preferredPart = preferredPart
        self.requiresStudyContext = requiresStudyContext
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            content
                .navigationTitle(NavigationTitle.Activity.participant.rawValue)
                .navigationBarTitleDisplayMode(.inline)
                .navigationSubtitle("총 \(challenger.count)명")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                    }

                    ToolBarCollection.AddBtn(action: {
                        showsSearch = true
                    }, disable: !canSearch)
                }
                .navigationDestination(isPresented: $showsSearch) {
                    SearchChallengerView(
                        useCase: resolvedSearchUseCase,
                        selectedChallengers: $challenger,
                        selectableMemberIds: selectableMemberIds,
                        preferredGeneration: preferredGeneration,
                        preferredPart: preferredPart
                    )
                }
        }
        .onAppear {
            guard canSearch else { return }
            let selection = SearchChallengerViewModel(
                searchChallengersUseCase: resolvedSearchUseCase,
                preferredGeneration: preferredGeneration,
                preferredPart: preferredPart
            )
            selection.initializeSelection(with: challenger)
            challenger = selection.confirmedSelection(previousSelection: challenger)
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if challenger.isEmpty {
            ContentUnavailableView(
                "선택된 챌린저가 없습니다",
                systemImage: "person.3.fill",
                description: Text("새로운 챌린저를 초대하여 함께 도전해보세요.")
            )
        } else {
            List {
                if !canSearch {
                    Text("그룹 기수·파트를 확인하지 못했습니다. 목록을 새로고침해 주세요.")
                        .appFont(.footnote, color: .grey500)
                }
                ForEach(challenger) { info in
                    challengerRow(info)
                }
            }
        }
    }

    private func challengerRow(_ info: ChallengerInfo) -> some View {
        HStack(spacing: DefaultSpacing.spacing12) {
            RemoteImage(
                urlString: info.profileImage ?? "",
                size: CGSize(width: 40, height: 40),
                cornerRadius: 0
            )
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
                Text("\(info.nickname)/\(info.name)")
                    .appFont(.subheadline, weight: .semibold, color: .grey900)
                Text(info.schoolName)
                    .appFont(.footnote, color: .grey500)
            }

            Spacer()

            if !myMemberIdSet.contains(info.memberId) {
                Button(role: .destructive) {
                    removeChallenger(info)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Function

    private var canSearch: Bool {
        !requiresStudyContext || (preferredGeneration != nil && preferredPart != nil)
    }

    private var resolvedSearchUseCase: SearchChallengersUseCaseProtocol {
        searchUseCase ?? container.resolve(SearchChallengersUseCaseProtocol.self)
    }

    private func removeChallenger(_ info: ChallengerInfo) {
        challenger.removeAll { $0.memberId == info.memberId }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("SelectedChallengerView") {
    @Previewable @State var challengers = OperatorStudyPreviewData.challengers
    SelectedChallengerView(
        challenger: $challengers,
        searchUseCase: PreviewSearchChallengersUseCase()
    )
}

#Preview("SelectedChallengerView · 빈 목록") {
    @Previewable @State var challengers: [ChallengerInfo] = []
    SelectedChallengerView(
        challenger: $challengers,
        searchUseCase: PreviewSearchChallengersUseCase()
    )
}
#endif
