//
//  ThreadClassificationCard.swift
//  CommunityPresentation
//
//  Created by euijjang97 on 8/13/26.
//

import SwiftUI
import CommunityDomain
import CoreDesignSystem
import CoreUIComponents

// MARK: - Constants

fileprivate enum Constants {
    static let engineLabel = "Apple Intelligence"
    /// 화면에는 엔진 이름만 보이지만, 입력한 특징이 기기 밖으로 나가지 않는다는 사실은 읽혀야 한다.
    static let headerAccessibilityLabel = "Apple Intelligence 가 온디바이스로 처리합니다."
    static let idleHint = "AI가 카테고리와 아이콘을 정해 드릴게요."
    static let idleDisabledHint = "특징을 입력하면 카테고리와 아이콘을 추천해 드려요."
    static let classifyTitle = "AI로 분류하기"
    static let reclassifyTitle = "다시 분류하기"
    static let loadingTitle = "스레드를 살펴보고 있어요"
    static let resultTitle = "이렇게 분류했어요"
    static let failureTitle = "분류하지 못했어요"
    static let unavailableTitle = "자동 분류를 쓸 수 없어요"
    static let unavailableMessage = """
    이 기기에서는 Apple Intelligence 를 사용할 수 없어요. \
    카테고리와 이모지를 직접 골라 주세요.
    """
    static let manualHint = "마음에 들지 않으면 카테고리와 이모지를 직접 바꿀 수 있어요."
    static let reclassifyNudge = "특징이 바뀌었어요. 다시 분류하면 카테고리와 아이콘을 새로 정해 드려요."

    static let engineImage = "apple.intelligence"
    static let failureImage = "exclamationmark.circle"

    static let engineIconSize: CGFloat = 13
    static let resultIconSize: CGFloat = 34
    /// 줄마다 오른쪽을 다르게 비워 실제 문단처럼 보이게 한다.
    static let shimmerBarInsets: [CGFloat] = [0, DefaultSpacing.spacing48]
}

/// 생성·편집 폼(``ThreadForm``)의 `카테고리 분류` 섹션 셀에 들어가는 온디바이스 분류 카드.
///
/// 아이콘·카테고리·근거를 한 카드에 묶는다. 분류 결과를 폼 필드에만 반영하고 카드를 두지
/// 않으면, 카테고리가 왜 바뀌었는지 알 수 없는 채로 값만 바뀌어 있다.
///
/// 미지원 기기에서도 카드를 감추지 않는다 — 안내를 띄워야 사용자가 직접 고르러 간다.
///
/// 표면(여백·배경)은 Form 셀이 맡는다. 카드가 따로 그리면 셀 안에 회색 카드가 한 겹 더 생긴다.
struct ThreadClassificationCard: View {

    // MARK: - Property

    /// 어느 화면의 카드인지. 편집이면 결과·버튼을 보조 톤으로 줄인다 — 거기서는 저장이 주 액션이다.
    enum Mode {
        case create
        /// 특징을 고친 뒤 아직 재분류하지 않았으면 안내 자리에 재분류 넛지를 띄운다.
        case edit(isReclassifySuggested: Bool)
    }

    let viewModel: any ThreadClassificationPresenting

    var mode: Mode = .create

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing16) {
            header

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Computed Property

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var isReclassifySuggested: Bool {
        if case .edit(let isReclassifySuggested) = mode { return isReclassifySuggested }
        return false
    }

    // MARK: - View Component

    /// 이 값을 무엇이 정하는지. 자리 이름은 섹션 헤더가 맡는다.
    ///
    /// 처리 중에는 심볼의 Apple Intelligence 색 애니메이션이 돈다 — 진행바 하나만으로는 일반
    /// 로딩과 구분되지 않는다.
    private var header: some View {
        HStack(spacing: DefaultSpacing.spacing4) {
            Image(systemName: Constants.engineImage)
                .font(.system(size: Constants.engineIconSize))
                .symbolEffect(
                    .variableColor.iterative.reversing,
                    isActive: viewModel.classification.isLoading
                )

            Text(Constants.engineLabel)
                .appFont(.caption1)
        }
        .foregroundStyle(.appleIntelligence)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Constants.headerAccessibilityLabel)
    }

    @ViewBuilder
    private var content: some View {
        if !viewModel.isClassificationAvailable {
            unavailableContent
        } else {
            switch viewModel.classification {
            case .idle:
                if isEditing {
                    editingGuidance(
                        viewModel.canClassify ? Constants.idleHint : Constants.idleDisabledHint
                    )
                } else {
                    idleContent
                }
            case .loading:
                loadingContent
            case .loaded(let classification):
                if isEditing {
                    editingGuidance(classification.reason)
                } else {
                    resultContent(classification)
                }
            case .failed:
                failureContent
            }
        }
    }

    /// 분류 버튼은 누를 수 있을 때만 나타난다. 특징이 비어 있는 첫 화면에서 잠긴 버튼을 띄우면
    /// 무엇을 해야 버튼이 열리는지 안내 문구와 버튼이 서로 경쟁한다.
    @ViewBuilder
    private var idleContent: some View {
        if viewModel.canClassify {
            VStack(alignment: .leading, spacing: DefaultSpacing.spacing16) {
                hintText(Constants.idleHint)

                MainButton(Constants.classifyTitle) { classify() }
                    .buttonStyle(.glassProminent)
            }
        } else {
            hintText(Constants.idleDisabledHint)
        }
    }

    /// 누를 수 없는 안내라 링크로 읽히는 틴트 대신 보조 텍스트 색을 쓴다. AI 아이콘은 헤더에만 둔다.
    private func hintText(_ text: String) -> some View {
        Text(text)
            .appFont(.subheadline, color: .grey600)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var loadingContent: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing12) {
            Text(Constants.loadingTitle)
                .appFont(.footnote, weight: .semibold, color: .grey700)

            ProgressView()
                .progressViewStyle(.linear)
                .tint(Color.indigo500)

            ForEach(Constants.shimmerBarInsets, id: \.self) { inset in
                ShimmerBar(trailingInset: inset)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Constants.loadingTitle)
    }

    /// 아이콘·카테고리·근거 3요소.
    ///
    /// 근거를 빼면 사용자가 결과를 검토할 근거가 없어 그대로 통과시키게 된다.
    private func resultContent(_ classification: ThreadClassification) -> some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing12) {
            HStack(spacing: DefaultSpacing.spacing12) {
                Text(classification.icon)
                    .font(.system(size: Constants.resultIconSize))

                VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
                    Text(Constants.resultTitle)
                        .appFont(.caption1, color: .grey500)

                    Text(classification.category.displayName)
                        .appFont(.body, weight: .semibold, color: .grey900)
                }

                Spacer(minLength: 0)
            }

            Text(classification.reason)
                .appFont(.footnote, color: .grey700)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(Constants.manualHint)
                .appFont(.caption2, color: .grey500)
                .frame(maxWidth: .infinity, alignment: .leading)

            actions
        }
        .accessibilityElement(children: .contain)
    }

    private var failureContent: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing12) {
            Label {
                Text(Constants.failureTitle)
                    .appFont(.footnote, weight: .semibold, color: .grey700)
            } icon: {
                Image(systemName: Constants.failureImage)
                    .foregroundStyle(Color.grey400)
            }

            if let message = viewModel.classificationErrorMessage {
                Text(message)
                    .appFont(.footnote, color: .grey500)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Text(Constants.manualHint)
                .appFont(.caption2, color: .grey500)
                .frame(maxWidth: .infinity, alignment: .leading)

            actions
        }
    }

    /// 미지원 기기. 분류만 잠기고, 카테고리·이모지를 손으로 고르는 길은 폼에 그대로 남는다.
    ///
    /// 여기서는 `canClassify` 가 늘 `false` 라 분류 버튼을 두지 않는다 — 영영 열리지 않는 버튼은
    /// 안내 문구와 경쟁만 한다.
    private var unavailableContent: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing12) {
            Text(Constants.unavailableTitle)
                .appFont(.footnote, weight: .semibold, color: .grey700)

            Text(Constants.unavailableMessage)
                .appFont(.footnote, color: .grey500)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// "다시 분류하기" 는 특징 미입력·처리 중에 잠긴다. 이모지는 폼의 아이콘 섹션이 맡는다.
    ///
    /// 편집 화면에서는 저장이 주 액션이라 재분류는 보조 버튼이고, 누를 수 있을 때만 둔다.
    @ViewBuilder
    private var actions: some View {
        if isEditing {
            if viewModel.canClassify {
                MainButton(Constants.reclassifyTitle) { classify() }
                    .buttonStyle(.glass)
            }
        } else {
            MainButton(Constants.reclassifyTitle) { classify() }
                .buttonStyle(.glassProminent)
                .disabled(!viewModel.canClassify)
        }
    }

    // MARK: - Editing Component

    /// 편집 화면의 안내 자리. 특징을 고쳤으면 원래 문구 대신 재분류 넛지를 띄운다.
    ///
    /// 분류 결과(아이콘·카테고리)는 폼의 미리보기·카테고리 행이 이미 보여 주므로 여기서는 근거만 둔다.
    private func editingGuidance(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing16) {
            Text(isReclassifySuggested ? Constants.reclassifyNudge : text)
                .appFont(.subheadline, color: .grey700)
                .frame(maxWidth: .infinity, alignment: .leading)

            actions
        }
    }

    // MARK: - Function

    private func classify() {
        Task { await viewModel.classify() }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("입력 전") {
    Form {
        Section {
            ThreadClassificationCard(viewModel: previewViewModel(description: ""))
        }
    }
}

#Preview("특징 입력됨") {
    Form {
        Section {
            ThreadClassificationCard(
                viewModel: previewViewModel(description: "매주 화요일 8시에 모여서 iOS 공부해요")
            )
        }
    }
}

#Preview("편집") {
    Form {
        Section {
            ThreadClassificationCard(
                viewModel: previewViewModel(description: "매주 화요일 8시에 모여서 iOS 공부해요"),
                mode: .edit(isReclassifySuggested: true)
            )
        }
    }
}

#Preview("미지원 기기") {
    Form {
        Section {
            ThreadClassificationCard(
                viewModel: previewViewModel(
                    description: "매주 화요일 8시에 모여서 iOS 공부해요",
                    isAvailable: false
                )
            )
        }
    }
}

@MainActor
private func previewViewModel(
    description: String,
    isAvailable: Bool = true
) -> CommunityThreadCreateViewModel {
    let viewModel = CommunityThreadCreateViewModel(
        useCase: PreviewCreateUseCase(),
        classifier: PreviewClassifier(isAvailable: isAvailable),
        descriptionRefiner: PreviewDescriptionRefiner(isAvailable: isAvailable)
    )
    viewModel.title = "iOS 스터디"
    viewModel.threadDescription = description
    return viewModel
}

private struct PreviewClassifier: ThreadClassifying {
    let isAvailable: Bool

    func classify(title: String, description: String) async throws -> ThreadClassification {
        ThreadClassification(
            category: .study,
            icon: "📚",
            reason: "매주 정해진 시간에 모여 공부한다는 내용이 있어 스터디로 봤어요."
        )
    }
}

private struct PreviewDescriptionRefiner: ThreadDescriptionRefining {
    let isAvailable: Bool

    func refine(title: String, description: String) async throws -> String {
        "매주 화요일 저녁 8시에 모여 함께 iOS 를 공부해요."
    }
}

private struct PreviewCreateUseCase: CommunityThreadCreateUseCaseProtocol {
    func create(
        title: String,
        description: String,
        category: CommunityThreadCategory,
        icon: String,
        memberIds: [String]
    ) async throws -> CommunityThread {
        throw ThreadClassificationError.unavailable
    }
}
#endif
