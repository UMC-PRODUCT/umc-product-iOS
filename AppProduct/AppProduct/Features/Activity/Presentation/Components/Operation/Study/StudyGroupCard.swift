//
//  StudyGroupCard.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/9/26.
//

import SwiftUI

// MARK: - StudyGroupDetailCard

/// 스터디 그룹 상세 카드
///
/// 그룹명, 파트, 파트장, 멤버 목록과 관리 액션을 표시합니다.
struct StudyGroupCard: View, Equatable {

    // MARK: - Property

    @State private var deleteAlertPrompt: AlertPrompt?

    private let detail: StudyGroupInfo
    private var onEdit: (() -> Void)?
    private var onDelete: (() -> Void)?
    private var onAddMember: (() -> Void)?
    private var onSchedule: (() -> Void)?

    // MARK: - Initializer

    /// - Parameters:
    ///   - detail: 그룹 상세 정보
    ///   - onEdit: 편집 버튼 탭 콜백
    ///   - onDelete: 삭제 버튼 탭 콜백
    ///   - onAddMember: 멤버 추가 버튼 탭 콜백
    ///   - onSchedule: 일정 등록 버튼 탭 콜백
    init(
        detail: StudyGroupInfo,
        onEdit: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil,
        onAddMember: (() -> Void)? = nil,
        onSchedule: (() -> Void)? = nil
    ) {
        self.detail = detail
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.onAddMember = onAddMember
        self.onSchedule = onSchedule
    }

    
    // MARK: - Equatable

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.detail == rhs.detail
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing16) {
            headerSection
            leaderSection
            membersSection
        }
        .padding(DefaultConstant.defaultCardPadding)
        .background(
            ConcentricRectangle(
                corners: .concentric(minimum: DefaultConstant.concentricRadius)
            )
            .fill(.white)
            .glass()
        )
        .alertPrompt(item: $deleteAlertPrompt)
    }

    // MARK: - View Components

    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
            HStack(spacing: DefaultSpacing.spacing8) {
                Text(detail.name)
                    .appFont(.calloutEmphasis, color: .black)

                InfoBadge(
                    detail.part.name,
                    textColor: detail.part.color,
                    tintColor: detail.part.color
                )

                Spacer()

                scheduleActionButton
                settingsMenu
            }

            metadataRow
        }
    }

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
            Image(systemName: "gearshape")
                .font(.system(size: 20))
                .foregroundStyle(.black)
                .padding(DefaultConstant.iconPadding)
                .glassEffect()
        }
    }

    private var scheduleActionButton: some View {
        Button {
            onSchedule?()
        } label: {
            HStack(spacing: DefaultSpacing.spacing4) {
                Image(systemName: "calendar.badge.plus")
                Text("일정 등록")
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .appFont(.footnoteEmphasis, color: .indigo600)
            .padding(.horizontal, DefaultSpacing.spacing4)
            .padding(.vertical, DefaultSpacing.spacing4)
        }
        .buttonStyle(.glass)
    }

    private var metadataRow: some View {
        Text("생성일: \(detail.formattedCreatedDate) | 멤버 \(detail.memberCount)명")
            .appFont(.footnote, color: .grey500)
    }

    @ViewBuilder
    private var leaderSection: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing8) {
            SectionHeaderView(title: "담당 파트장")
            StudyGroupLeaderRow(
                leader: detail.leader,
                partTintColor: detail.part.color
            )
        }
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
                        showsBestWorkbookBadge: topBestWorkbookMemberServerIDs.contains(member.serverID)
                    )
                        .equatable()
                }
            }
        }
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
                .foregroundStyle(.black)
        }
        .glassEffect()
    }

}

// MARK: - Preview

#if DEBUG
#Preview(traits: .sizeThatFitsLayout) {
    StudyGroupCard(
        detail: .preview,
        onEdit: { print("Edit") },
        onDelete: { print("Delete") },
        onAddMember: { print("Add") },
        onSchedule: { print("Schedule") }
    )
    .padding(DefaultConstant.defaultSafeHorizon)
}
#endif
