//
//  StudyGroupCard.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/9/26.
//

import SwiftUI

// MARK: - StudyGroupDetailCard

struct StudyGroupCard: View, Equatable {

    // MARK: - Property

    private let detail: StudyGroupInfo
    private var onEdit: (() -> Void)?
    private var onDelete: (() -> Void)?
    private var onManageMembers: (() -> Void)?
    private var onAddMember: (() -> Void)?
    private var onSchedule: (() -> Void)?

    // MARK: - Initializer

    init(
        detail: StudyGroupInfo,
        onEdit: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil,
        onManageMembers: (() -> Void)? = nil,
        onAddMember: (() -> Void)? = nil,
        onSchedule: (() -> Void)? = nil
    ) {
        self.detail = detail
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.onManageMembers = onManageMembers
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
            scheduleButton
        }
        .padding(DefaultConstant.defaultCardPadding)
        .background(
            ConcentricRectangle(
                corners: .concentric(minimum: DefaultConstant.concentricRadius)
            )
            .fill(.white)
            .glass()
        )
    }

    // MARK: - View Components

    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
            HStack(spacing: DefaultSpacing.spacing8) {
                Text(detail.name)
                    .appFont(.calloutEmphasis, color: .black)

                InfoBadge(detail.part.name)

                Spacer()

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

            Button("멤버 관리", systemImage: "person.badge.plus") {
                onManageMembers?()
            }

            Divider()

            Button("그룹 삭제", systemImage: "trash", role: .destructive) {
                onDelete?()
            }
        } label: {
            Image(systemName: "gearshape")
                .font(.system(size: 20))
                .foregroundStyle(.grey500)
        }
    }

    private var metadataRow: some View {
        Text("생성일: \(detail.formattedCreatedDate) | 멤버 \(detail.memberCount)명")
            .appFont(.footnote, color: .grey500)
    }

    @ViewBuilder
    private var leaderSection: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing8) {
            SectionHeaderView(title: "담당 파트장")
            StudyGroupLeaderRow(leader: detail.leader)
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
                    StudyGroupMemberChip(member: member)
                        .equatable()
                }
            }
        }
    }

    private var addMemberButton: some View {
        Button {
            onAddMember?()
        } label: {
            Image(systemName: "plus")
                .padding(DefaultConstant.defaultBtnPadding)
                .foregroundStyle(.gray)
        }
        .glassEffect()
    }

    private var scheduleButton: some View {
        Button {
            onSchedule?()
        } label: {
            HStack(spacing: DefaultSpacing.spacing8) {
                Image(systemName: "calendar.badge.plus")
                Text("스터디 일정 등록하기")
            }
            .appFont(.subheadline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DefaultSpacing.spacing12)
        }
        .buttonStyle(.glass)
    }
}

// MARK: - Preview

#if DEBUG
#Preview(traits: .sizeThatFitsLayout) {
    StudyGroupCard(
        detail: .preview,
        onEdit: { print("Edit") },
        onDelete: { print("Delete") },
        onManageMembers: { print("Manage") },
        onAddMember: { print("Add") },
        onSchedule: { print("Schedule") }
    )
    .padding(DefaultConstant.defaultSafeHorizon)
}
#endif
