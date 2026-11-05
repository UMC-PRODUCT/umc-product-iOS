//
//  StudyGroupCard.swift
//  ActivityPresentation
//
//  Created by jaewon Lee on 7/15/26.
//

import ActivityDomain
import CoreDesignSystem
import CoreUIComponents
import SwiftUI
import UMCFoundation

// MARK: - StudyGroupCard

/// 스터디 그룹 상세 카드
///
/// 그룹명, 파트, 멘토(담당 파트장) 목록, 멤버 목록과 관리 액션을 표시합니다.
struct StudyGroupCard: View, Equatable {

    // MARK: - Property

    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var deleteAlertPrompt: AlertPrompt?
    /// 멘토/스터디원 섹션 펼침 상태
    ///
    /// 멘토가 N명 가능 + 멤버 많을수록 카드 길이가 빠르게 늘어남.
    /// 기본 collapsed → 헤더만으로 빠른 스캔, 관심 카드만 펼침.
    @State private var isExpanded: Bool = false

    /// 펼침 콘텐츠(멘토+멤버 섹션)의 자연 높이.
    ///
    /// `fixedSize`로 클램프와 무관하게 측정한 natural height를 보관한다. `frame(height:)`를
    /// 이 값↔0 으로 애니메이션해 콘텐츠를 카드 안에 가둔 채(clip) 펼침/접힘을 표현한다.
    /// `if + .transition` 방식은 제거되는 뷰가 축소된 부모 밖으로 잔류 렌더되며 clip을 벗어나
    /// 잔상이 생기는데(이번 이슈 영상 검증), 이 방식은 콘텐츠가 항상 클램프 프레임 안에 있어
    /// 헤더 아래로 넘치지 않는다.
    @State private var expandedSectionsHeight: CGFloat = 0

    private let detail: StudyGroupInfo
    private var onEdit: (() -> Void)?
    private var onDelete: (() -> Void)?
    private var onAddMember: (() -> Void)?
    private var onAddMentor: (() -> Void)?
    private var onSchedule: (() -> Void)?
    private var onRemoveMember: ((StudyGroupMember) -> Void)?
    private var onRemoveMentor: ((StudyGroupMember) -> Void)?

    // MARK: - Initializer

    /// - Parameters:
    ///   - detail: 그룹 상세 정보
    ///   - onEdit: 편집 버튼 탭 콜백
    ///   - onDelete: 삭제 버튼 탭 콜백
    ///   - onAddMember: 멤버 추가 버튼 탭 콜백
    ///   - onAddMentor: 멘토 추가 버튼 탭 콜백
    ///   - onSchedule: 일정 등록 버튼 탭 콜백
    ///   - onRemoveMember: 멤버 칩 삭제 콜백
    ///   - onRemoveMentor: 멘토 칩 삭제 콜백
    init(
        detail: StudyGroupInfo,
        onEdit: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil,
        onAddMember: (() -> Void)? = nil,
        onAddMentor: (() -> Void)? = nil,
        onSchedule: (() -> Void)? = nil,
        onRemoveMember: ((StudyGroupMember) -> Void)? = nil,
        onRemoveMentor: ((StudyGroupMember) -> Void)? = nil
    ) {
        self.detail = detail
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.onAddMember = onAddMember
        self.onAddMentor = onAddMentor
        self.onSchedule = onSchedule
        self.onRemoveMember = onRemoveMember
        self.onRemoveMentor = onRemoveMentor
    }

    // MARK: - Equatable

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.detail == rhs.detail
    }

    // MARK: - Constants

    fileprivate enum Constants {
        static let cardCornerRadius = DefaultConstant.cornerRadius
        /// sub-section(멘토/멤버) 내부 패딩
        static let subSectionPadding: CGFloat = 12
        /// sub-section 배경 라운드
        static let subSectionCornerRadius: CGFloat = 14
        /// HIG 권장 최소 터치 타겟
        static let minTouchTarget = DefaultConstant.minimumTouchTarget
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection

            // 펼침 콘텐츠는 항상 트리에 존재하고 `fixedSize`로 자연 높이를 측정한다.
            // 표시 높이는 `frame(height:)`로 0↔측정값을 애니메이션하고 `clipped()`로 잘라,
            // 콘텐츠가 헤더 아래로 빠져나오는 잔상 없이 카드 안에서만 열리고 닫힌다.
            expandableSections
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.height
                } action: { newHeight in
                    expandedSectionsHeight = newHeight
                }
                .frame(
                    height: isExpanded ? expandedSectionsHeight : 0,
                    alignment: .top
                )
                .opacity(isExpanded ? 1 : 0)
                .accessibilityHidden(!isExpanded)
                .clipped()
        }
        .padding(DefaultSpacing.spacing16)
        .background(
            Color.Surface.content,
            in: .rect(cornerRadius: Constants.cardCornerRadius)
        )
        // 카드 외곽 라운드로 콘텐츠를 한 번 더 clip — 내부 섹션 clip과 더불어 어떤 자식도
        // 카드 모서리를 넘지 않도록 보장한다.
        .clipShape(.rect(cornerRadius: Constants.cardCornerRadius))
        // 카드 전체를 펼침/접힘 탭 영역으로 만든다. 내부 Button/Menu(일정 등록·설정·추가)는
        // 자체적으로 탭을 소비하므로 토글되지 않고, 빈 영역·타이틀·메타·파트장/멤버 행을
        // 탭하면 펼침/접힘이 토글된다.
        .contentShape(.rect(cornerRadius: Constants.cardCornerRadius))
        .onTapGesture { toggleExpansion() }
        .alertPrompt(item: $deleteAlertPrompt)
    }

    /// 펼침/접힘 토글 — 헤더 버튼과 카드 전체 탭이 공유하는 단일 진입점.
    private func toggleExpansion() {
        withAnimation(reduceMotion ? nil : .smooth(duration: 0.3)) {
            isExpanded.toggle()
        }
    }

    /// 펼침 시 노출되는 멘토/멤버 섹션 묶음.
    ///
    /// 헤더와의 간격(spacing16)을 이 블록 상단 패딩으로 흡수해, 접힘 시 `frame(height: 0)`로
    /// 갭까지 함께 사라지게 한다(외곽 VStack spacing은 0).
    private var expandableSections: some View {
        AdaptiveContentLayout(
            minimumColumnWidth: 280,
            maximumColumns: dynamicTypeSize.isAccessibilitySize ? 1 : 2,
            spacing: DefaultSpacing.spacing16,
            layoutDirection: layoutDirection
        ) {
            mentorSection
            membersSection
        }
        .padding(.top, DefaultSpacing.spacing16)
    }

    // MARK: - View Components

    /// 식별·구성원 펼침과 관리 액션을 구분한다. 큰 글자에서는 가로 정보를 세로로 배치한다.
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing8) {
            Button(action: toggleExpansion) {
                VStack(alignment: .leading, spacing: DefaultSpacing.spacing8) {
                    let identityLayout = dynamicTypeSize.isAccessibilitySize
                        ? AnyLayout(VStackLayout(alignment: .leading, spacing: DefaultSpacing.spacing8))
                        : AnyLayout(HStackLayout(alignment: .firstTextBaseline,
                                                spacing: DefaultSpacing.spacing8))
                    identityLayout {
                        Text(detail.name)
                            .appFont(.body, weight: .semibold, color: .grey900)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        MemberTag(part: detail.part)
                            .fixedSize()
                        if isMeetingToday {
                            todayMeetingBadge
                        }
                    }
                    metadataRow
                }
                .frame(maxWidth: .infinity, minHeight: Constants.minTouchTarget,
                       alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityValue(isExpanded ? "펼쳐짐" : "접힘")
            .accessibilityHint("멘토와 스터디원 목록 펼치기 또는 접기")

            Divider()

            let actionLayout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: DefaultSpacing.spacing4))
                : AnyLayout(HStackLayout(spacing: DefaultSpacing.spacing16))
            actionLayout {
                scheduleActionButton
                settingsMenu
            }
        }
    }

    /// 그룹 편집·삭제 메뉴 — HIG 44×44 터치 타겟 보장.
    ///
    /// 인접한 expand 토글(`metadataRow`) 영역과 오탭을 피하기 위해 명시 frame을 사용한다.
    private var settingsMenu: some View {
        Menu {
            Button("그룹 편집", systemImage: "pencil") {
                onEdit?()
            }

            Divider()

            Button("그룹 삭제", systemImage: "trash", role: .destructive) {
                deleteAlertPrompt = AlertPrompt(
                    title: "그룹 삭제",
                    message: "'\(detail.name)' 그룹을 삭제하시겠습니까?",
                    positiveBtnTitle: "삭제",
                    positiveBtnAction: {
                        onDelete?()
                    },
                    negativeBtnTitle: "취소",
                    isPositiveBtnDestructive: true
                )
            }
        } label: {
            Label("그룹 설정", systemImage: "gearshape")
                .labelStyle(.titleAndIcon)
                .appFont(.footnote, weight: .medium, color: .grey700)
                .frame(maxWidth: .infinity, minHeight: Constants.minTouchTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("그룹 설정")
    }

    /// 접힘 여부와 관계없이 동작 이름을 보여 주는 일정 등록 진입점.
    private var scheduleActionButton: some View {
        Button {
            onSchedule?()
        } label: {
            Label("일정 등록", systemImage: "calendar.badge.plus")
                .labelStyle(.titleAndIcon)
                .appFont(.footnote, weight: .semibold, color: .teal600)
                .frame(maxWidth: .infinity, minHeight: Constants.minTouchTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("일정 등록")
    }

    /// "오늘 미팅" active 상태 뱃지 (UI hook)
    /// 산정 로직은 별도 이슈에서 추가하고, 여기서는 `isMeetingToday` false 고정으로 hidden 상태.
    private var todayMeetingBadge: some View {
        InfoBadge(
            "오늘 미팅",
            textColor: detail.part.color,
            tintColor: detail.part.color
        )
        .tint(detail.part.color)
    }

    /// 오늘 미팅 여부 — 산정 로직은 후속 이슈에서 도입. 현 시점에서는 hidden.
    private var isMeetingToday: Bool { false }

    /// 구성원 수와 펼침 상태는 하나의 헤더 버튼 안에서 함께 읽힌다.
    private var metadataRow: some View {
        HStack(spacing: DefaultSpacing.spacing8) {
            Text("멘토 \(detail.mentors.count)명 · 멤버 \(detail.members.count)명")
                .appFont(.footnote, color: .grey600)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: DefaultSpacing.spacing8)
            Image(systemName: "chevron.down")
                .font(.app(.caption1))
                .foregroundStyle(Color.grey500)
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private var mentorSection: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing8) {
            HStack {
                SectionHeaderView(title: "담당 파트장")
                Spacer()
                addMentorButton
            }

            ForEach(detail.mentors) { mentor in
                StudyGroupLeaderRow(
                    leader: mentor,
                    partTintColor: detail.part.color
                )
                .equatable()
                .contextMenu {
                    Button(role: .destructive) {
                        onRemoveMentor?(mentor)
                    } label: {
                        Label("멘토 삭제", systemImage: "trash")
                    }
                }
            }
        }
        .padding(Constants.subSectionPadding)
        .background(
            Color.Surface.inset,
            in: .rect(cornerRadius: Constants.subSectionCornerRadius)
        )
    }

    @ViewBuilder
    private var membersSection: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing8) {
            HStack {
                SectionHeaderView(title: "스터디원")
                Spacer()
                addMemberButton
            }

            FlowLayout(spacing: DefaultSpacing.spacing8) {
                ForEach(detail.members) { member in
                    StudyGroupMemberChip(
                        member: member,
                        showsBestWorkbookBadge: topBestWorkbookMemberServerIDs
                            .contains(member.serverID)
                    )
                    .equatable()
                    .contextMenu {
                        Button(role: .destructive) {
                            onRemoveMember?(member)
                        } label: {
                            Label("멤버 삭제", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .padding(Constants.subSectionPadding)
        .background(
            Color.Surface.inset,
            in: .rect(cornerRadius: Constants.subSectionCornerRadius)
        )
    }

    private var topBestWorkbookMemberServerIDs: Set<String> {
        guard let topScore = detail.members
            .map(\.bestWorkbookPoint)
            .max(),
              topScore > 0 else {
            return []
        }

        return Set(
            detail.members
                .filter { $0.bestWorkbookPoint == topScore }
                .map(\.serverID)
        )
    }

    private var addMemberButton: some View {
        Button {
            onAddMember?()
        } label: {
            Image(systemName: "plus")
                .padding(DefaultConstant.defaultBtnPadding)
        }
        .glassEffect(.regular.interactive())
        .accessibilityLabel("스터디원 추가")
    }

    private var addMentorButton: some View {
        Button {
            onAddMentor?()
        } label: {
            Image(systemName: "plus")
                .padding(DefaultConstant.defaultBtnPadding)
        }
        .glassEffect(.regular.interactive())
        .accessibilityLabel("멘토 추가")
    }
}

// MARK: - Preview

#if DEBUG
#Preview("StudyGroupCard") {
    ScrollView {
        StudyGroupCard(
            detail: OperatorStudyPreviewData.groups[0],
            onEdit: {},
            onDelete: {},
            onAddMember: {},
            onAddMentor: {},
            onSchedule: {},
            onRemoveMember: { _ in },
            onRemoveMentor: { _ in }
        )
        .padding()
    }
}
#endif
