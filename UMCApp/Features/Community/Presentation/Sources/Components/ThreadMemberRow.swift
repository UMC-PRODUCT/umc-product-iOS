//
//  ThreadMemberRow.swift
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
    static let avatarSize = CGSize(width: 40, height: 40)
    static let meSuffix = " (나)"
}

/// 참여자 목록 한 행 — 아바타 · 이름 · 파트 · 역할 배지.
///
/// ⋯ 메뉴는 관리 권한이 있을 때만 붙는다. 항목별 노출은 상위가 정하고 여기서는 받은 대로만 그린다.
struct ThreadMemberRow: View {

    // MARK: - Property

    let member: ThreadMember
    let isMe: Bool
    let canTransferOwnership: Bool
    let canKick: Bool
    let onTransferOwnership: () -> Void
    let onKick: () -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: DefaultSpacing.spacing12) {
            RemoteImage(
                urlString: member.profileImageURL ?? "",
                size: Constants.avatarSize
            )

            VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
                Text(isMe ? member.name + Constants.meSuffix : member.name)
                    .appFont(.subheadline, weight: .semibold, color: .grey900)
                    .lineLimit(1)

                if let part = member.part, !part.isEmpty {
                    Text(part)
                        .appFont(.caption1, color: .grey600)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: DefaultSpacing.spacing8)

            roleBadge

            if canTransferOwnership || canKick {
                manageMenu
            }
        }
        .padding(.vertical, DefaultSpacing.spacing4)
    }

    // MARK: - View Component

    /// 개설자만 강조색을 쓴다. 관리자는 문구로만 구분한다.
    private var roleBadge: some View {
        InfoBadge(
            member.role.displayName,
            textColor: member.role == .owner ? .indigo500 : .grey600,
            tintColor: member.role == .owner ? .indigo500 : nil
        )
    }

    private var manageMenu: some View {
        Menu {
            if canTransferOwnership {
                Button("개설자 위임", systemImage: "crown", action: onTransferOwnership)
            }
            if canKick {
                Button(
                    "내보내기",
                    systemImage: "person.fill.xmark",
                    role: .destructive,
                    action: onKick
                )
            }
        } label: {
            Image(systemName: "ellipsis")
                .foregroundStyle(Color.grey600)
                // 아이콘은 작아도 누를 곳은 44pt 를 채운다 (명세 접근성).
                .frame(
                    width: DefaultConstant.minimumTouchTarget,
                    height: DefaultConstant.minimumTouchTarget
                )
                .contentShape(.rect)
        }
        .accessibilityLabel("\(member.name) 님 관리")
    }
}
