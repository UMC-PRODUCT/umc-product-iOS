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
    static let cardTitle = "카테고리 분류"
    static let engineLabel = "Apple Intelligence"
    /// 배지를 뺀 자리를 대신한다 — 입력한 특징이 기기 밖으로 나가지 않는다는 사실은 남겨야 한다.
    static let headerAccessibilityLabel = "카테고리 분류. Apple Intelligence 가 온디바이스로 처리합니다."
    static let idleHint = "AI가 카테고리와 아이콘을 정해 드릴게요."
    static let idleDisabledHint = """
    쓰레드 특징을 입력하면
    AI가 카테고리•아이콘을 정해줘요
    """
    static let classifyTitle = "AI로 분류하기"
    static let reclassifyTitle = "다시 분류하기"
    static let changeIconTitle = "이모지 변경하기"
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
    static let categoryLabel = "카테고리"
    static let categoryHint = "탭하면 카테고리를 고를 수 있어요."

    static let engineImage = "apple.intelligence"
    static let failureImage = "exclamationmark.circle"
    static let categoryImage = "chevron.up.chevron.down"

    static let engineIconSize: CGFloat = 13
    static let hintIconSize: CGFloat = 20
    static let resultIconSize: CGFloat = 34
    static let cardPadding: EdgeInsets = .init(
        top: DefaultSpacing.spacing16,
        leading: DefaultConstant.defaultSafeHorizon,
        bottom: DefaultSpacing.spacing16,
        trailing: DefaultConstant.defaultSafeHorizon
    )
    /// 줄마다 오른쪽을 다르게 비워 실제 문단처럼 보이게 한다.
    static let shimmerBarInsets: [CGFloat] = [0, DefaultSpacing.spacing48]
    static let aiBorderWidth: CGFloat = 1
    static let categoryIconSize: CGFloat = 22
    static let minimumTouchHeight: CGFloat = 44
    static let valueSpringDuration: TimeInterval = 0.35
    static let valueFadeDuration: TimeInterval = 0.2
}

/// 생성·편집 폼 안의 온디바이스 분류 카드.
///
/// 아이콘·카테고리·근거를 한 카드에 묶는다. 분류 결과를 폼 필드에만 반영하고 카드를 두지
/// 않으면, 카테고리가 왜 바뀌었는지 알 수 없는 채로 값만 바뀌어 있다.
///
/// 미지원 기기에서도 카드를 감추지 않는다 — 안내를 띄워야 사용자가 직접 고르러 간다.
struct ThreadClassificationCard: View {

    // MARK: - Property

    /// 편집 화면이 넘기는 현재 값. 있으면 카드가 값 행을 품고, 결과·버튼을 보조 톤으로 줄인다.
    struct Editing {
        let icon: String
        let category: CommunityThreadCategory
        let isReclassifySuggested: Bool
        let onSelectCategory: () -> Void
    }

    let viewModel: any ThreadClassificationPresenting

    var editing: Editing? = nil

    /// 이모지 칸으로 포커스를 옮긴다. 포커스는 폼이 들고 있어 화면이 넘겨 준다.
    var onChangeIcon: () -> Void = {}

    @ScaledMetric(relativeTo: .body) private var categoryIconSize = Constants.categoryIconSize

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing16) {
            header

            if let editing {
                categoryRow(editing)
            }

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Constants.cardPadding)
        .glassEffect(
            .regular,
            in: .rect(corners: .concentric(minimum: DefaultConstant.concentricRadius))
        )
        // 처리 중임을 색으로도 알린다. 진행바 하나만으로는 일반 로딩과 구분되지 않는다.
        .overlay {
            if viewModel.classification.isLoading {
                ConcentricRectangle(
                    corners: .concentric(minimum: DefaultConstant.concentricRadius),
                    isUniform: true
                )
                .stroke(.appleIntelligence, lineWidth: Constants.aiBorderWidth)
            }
        }
    }

    // MARK: - View Component

    /// 카드가 무엇을 하는 자리인지와, 그 값을 무엇이 정하는지.
    private var header: some View {
        HStack(spacing: DefaultSpacing.spacing8) {
            Text(Constants.cardTitle)
                .appFont(.body, weight: .semibold, color: .grey900)

            Spacer(minLength: 0)

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
        }
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
                if editing != nil {
                    editingGuidance(
                        viewModel.canClassify ? Constants.idleHint : Constants.idleDisabledHint
                    )
                } else {
                    idleContent
                }
            case .loading:
                loadingContent
            case .loaded(let classification):
                if editing != nil {
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
                hintRow(Constants.idleHint)

                MainButton(Constants.classifyTitle) { classify() }
                    .buttonStyle(.glassProminent)
            }
        } else {
            hintRow(Constants.idleDisabledHint)
        }
    }

    private func hintRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: DefaultSpacing.spacing8) {
            Image(systemName: Constants.engineImage)
                .font(.system(size: Constants.hintIconSize))
                .foregroundStyle(.appleIntelligence)

            Text(text)
                .appFont(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(Color.indigo500)
        .accessibilityElement(children: .combine)
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

    /// 미지원 기기. 분류는 잠기지만 이모지 변경은 남는다 — 손으로 고르는 길까지 막을 이유가 없다.
    private var unavailableContent: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing12) {
            Text(Constants.unavailableTitle)
                .appFont(.footnote, weight: .semibold, color: .grey700)

            Text(Constants.unavailableMessage)
                .appFont(.footnote, color: .grey500)
                .frame(maxWidth: .infinity, alignment: .leading)

            actions
        }
    }

    /// "다시 분류하기" 는 미지원·특징 미입력·처리 중에 잠긴다. "이모지 변경하기" 는 항상 열려 있다.
    ///
    /// 편집 화면에서는 저장이 주 액션이라 재분류는 보조 버튼이고, 누를 수 있을 때만 둔다.
    /// 이모지는 화면 위 아이콘 배지가 맡는다.
    @ViewBuilder
    private var actions: some View {
        if editing != nil {
            if viewModel.canClassify {
                MainButton(Constants.reclassifyTitle) { classify() }
                    .buttonStyle(.glass)
            }
        } else {
            HStack(spacing: DefaultSpacing.spacing12) {
                MainButton(Constants.reclassifyTitle) { classify() }
                    .buttonStyle(.glassProminent)
                    .disabled(!viewModel.canClassify)

                MainButton(Constants.changeIconTitle, action: onChangeIcon)
                    .buttonStyle(.glass)
            }
        }
    }

    // MARK: - Editing Component

    /// 지금 저장될 아이콘·카테고리. 분류 결과도 이 행으로 바뀌므로 결과 영역에서 반복하지 않는다.
    private func categoryRow(_ editing: Editing) -> some View {
        Button(action: editing.onSelectCategory) {
            HStack(spacing: DefaultSpacing.spacing8) {
                Text(editing.icon)
                    .font(.system(size: categoryIconSize))

                Text(editing.category.displayName)
                    .appFont(.body, weight: .semibold, color: .grey900)

                Spacer(minLength: 0)

                Image(systemName: Constants.categoryImage)
                    .foregroundStyle(Color.grey600)
            }
            .frame(minHeight: Constants.minimumTouchHeight)
            .contentShape(.rect)
            .contentTransition(reduceMotion ? .opacity : .interpolate)
            .animation(valueAnimation, value: editing.icon)
            .animation(valueAnimation, value: editing.category)
        }
        .buttonStyle(.plain)
        // 분류가 끝나면 결과가 카테고리를 덮어쓰므로, 그 사이에 고른 값은 사라진다.
        .disabled(viewModel.classification.isLoading)
        .accessibilityLabel(Constants.categoryLabel)
        .accessibilityValue(editing.category.displayName)
        .accessibilityHint(Constants.categoryHint)
    }

    /// 편집 화면의 안내 자리. 특징을 고쳤으면 원래 문구 대신 재분류 넛지를 띄운다.
    private func editingGuidance(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing16) {
            Text(editing?.isReclassifySuggested == true ? Constants.reclassifyNudge : text)
                .appFont(.subheadline, color: .grey700)
                .frame(maxWidth: .infinity, alignment: .leading)

            actions
        }
    }

    private var valueAnimation: Animation {
        reduceMotion
            ? .easeInOut(duration: Constants.valueFadeDuration)
            : .spring(duration: Constants.valueSpringDuration, bounce: 0)
    }

    // MARK: - Function

    private func classify() {
        Task { await viewModel.classify() }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("입력 전") {
    ThreadClassificationCard(
        viewModel: previewViewModel(description: ""),
        onChangeIcon: {}
    )
    .padding(DefaultSpacing.spacing16)
}

#Preview("특징 입력됨") {
    ThreadClassificationCard(
        viewModel: previewViewModel(description: "매주 화요일 8시에 모여서 iOS 공부해요"),
        onChangeIcon: {}
    )
    .padding(DefaultSpacing.spacing16)
}

#Preview("편집") {
    ThreadClassificationCard(
        viewModel: previewViewModel(description: "매주 화요일 8시에 모여서 iOS 공부해요"),
        editing: .init(
            icon: "📚",
            category: .study,
            isReclassifySuggested: true,
            onSelectCategory: {}
        )
    )
    .padding(DefaultSpacing.spacing16)
}

#Preview("미지원 기기") {
    ThreadClassificationCard(
        viewModel: previewViewModel(
            description: "매주 화요일 8시에 모여서 iOS 공부해요",
            isAvailable: false
        ),
        onChangeIcon: {}
    )
    .padding(DefaultSpacing.spacing16)
}

@MainActor
private func previewViewModel(
    description: String,
    isAvailable: Bool = true
) -> CommunityThreadCreateViewModel {
    let viewModel = CommunityThreadCreateViewModel(
        useCase: PreviewCreateUseCase(),
        classifier: PreviewClassifier(isAvailable: isAvailable)
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
