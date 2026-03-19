//
//  ChallengerMemberDetailSheetView.swift
//  AppProduct
//
//  Created by 김미주 on 2/5/26.
//

import SwiftUI

struct ChallengerMemberDetailSheetView: View {
    // MARK: - Property

    @Environment(\.dismiss) private var dismiss
    var member: MemberManagementItem
    @State private var showGenerationPopover: Bool = false

    private enum Constants {
        static let tagPadding: EdgeInsets = .init(top: 4, leading: 8, bottom: 4, trailing: 8)
        static let boxPadding: EdgeInsets = .init(top: 12, leading: 0, bottom: 12, trailing: 0)
        static let listPadding: EdgeInsets = .init(top: 12, leading: 12, bottom: 12, trailing: 12)
        static let profileSize: CGSize = .init(width: 60, height: 60)

        static let baseHeight: CGFloat = 340
        static let emptyRecordHeight: CGFloat = 150
        static let recordRowHeight: CGFloat = 50
        static let maxVisibleRecords: Int = 5
        static let minSheetHeight: CGFloat = 420
        static let maxSheetHeight: CGFloat = 700
    }

    // MARK: - Computed Properties

    /// 현재 기수 (마지막 기수만 표시)
    private var currentGeneration: String {
        let gens = member.generation
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return gens.last ?? member.generation
    }

    /// 복수 기수 여부
    private var hasMultipleGenerations: Bool {
        member.generation.contains(",")
    }

    private var dynamicSheetHeight: CGFloat {
        let recordCount = member.attendanceRecords.count

        if recordCount == 0 {
            return Constants.baseHeight + Constants.emptyRecordHeight
        }

        let visibleRecords = min(recordCount, Constants.maxVisibleRecords)
        let recordsHeight = (CGFloat(visibleRecords) * Constants.recordRowHeight)
        + (CGFloat(max(0, visibleRecords - 1)) * DefaultSpacing.spacing8)

        let calculatedHeight = Constants.baseHeight + recordsHeight

        return max(Constants.minSheetHeight, min(calculatedHeight, Constants.maxSheetHeight))
    }

    private var scrollViewHeight: CGFloat {
        let recordCount = member.attendanceRecords.count

        if recordCount == 0 {
            return Constants.emptyRecordHeight
        }

        let visibleRecords = min(recordCount, Constants.maxVisibleRecords)
        let recordsHeight = (CGFloat(visibleRecords) * Constants.recordRowHeight)
        + (CGFloat(max(0, visibleRecords - 1)) * DefaultSpacing.spacing8)

        return recordsHeight
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: DefaultSpacing.spacing32) {
                memberInfoView

                HStack(spacing: DefaultSpacing.spacing16) {
                    generationView
                    infoBox(title: "상점", value: String(format: "%.0f", member.rewardPoints), color: .green)
                    infoBox(title: "벌점", value: String(format: "%.0f", member.penalty), color: .red)
                }

                recordView
            }
            .safeAreaPadding(.horizontal, DefaultConstant.defaultSafeHorizon)
            .scrollContentBackground(.hidden)
            .presentationDetents([.height(dynamicSheetHeight)])
        }
    }

    // MARK: - SubView

    private var memberInfoView: some View {
        HStack(spacing: DefaultSpacing.spacing12) {
            RemoteImage(urlString: member.profile ?? "", size: Constants.profileSize)

            VStack(alignment: .leading, spacing: DefaultSpacing.spacing8) {
                Text("\(member.nickname)/\(member.name)")
                    .appFont(.bodyEmphasis)
                HStack(spacing: DefaultSpacing.spacing8) {
                    Text(member.part.name)
                        .appFont(.callout, color: member.part.color)
                        .padding(Constants.tagPadding)
                        .background(member.part.color.opacity(0.14), in: Capsule())
                        .overlay {
                            Capsule()
                                .stroke(member.part.color.opacity(0.4), lineWidth: 1)
                        }
                    Text(member.school)
                        .appFont(.callout, color: .black)
                        .padding(Constants.tagPadding)
                        .background(.white, in: Capsule())
                    if member.managementTeam != .challenger {
                        ManagementTeamBadgePresenter(managementTeam: member.managementTeam)
                    }
                }
            }
        }
    }

    /// 활동 기수 박스 — 탭하면 전체 기수 팝오버
    private var generationView: some View {
        VStack(spacing: DefaultSpacing.spacing8) {
            Text("활동 기수")
                .appFont(.callout, color: .grey700)
            HStack(spacing: 2) {
                Text(currentGeneration)
                    .appFont(.title3Emphasis)
                if hasMultipleGenerations {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.grey500)
                }
            }
        }
        .padding(Constants.boxPadding)
        .frame(maxWidth: .infinity)
        .background(.white, in: RoundedRectangle(cornerRadius: DefaultConstant.cornerRadius))
        .glass()
        .onTapGesture {
            if hasMultipleGenerations {
                showGenerationPopover = true
            }
        }
        .popover(isPresented: $showGenerationPopover, arrowEdge: .bottom) {
            Text(member.generation)
                .appFont(.subheadline)
                .padding()
                .presentationCompactAdaptation(.popover)
        }
    }

    private func infoBox(title: String, value: String, color: Color) -> some View {
        VStack(spacing: DefaultSpacing.spacing8) {
            Text(title)
                .appFont(.callout, color: .grey700)
            Text(value)
                .appFont(.title3Emphasis, color: color)
        }
        .padding(Constants.boxPadding)
        .frame(maxWidth: .infinity)
        .background(.white, in: RoundedRectangle(cornerRadius: DefaultConstant.cornerRadius))
        .glass()
    }

    private var recordView: some View {
        VStack(alignment: .leading) {
            Label("출석/활동 기록", systemImage: "exclamationmark.arrow.trianglehead.2.clockwise.rotate.90")
                .appFont(.title3Emphasis)

            if member.attendanceRecords.isEmpty {
                emptyRecordView
            } else {
                recordListView
            }
        }
    }

    private var emptyRecordView: some View {
        VStack(spacing: DefaultSpacing.spacing8) {
            Image(systemName: "calendar.badge.exclamationmark")
                .appFont(.title1, color: .grey500)
            Text("아직 출석 기록이 없습니다")
                .appFont(.subheadline, color: .grey500)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Constants.emptyRecordHeight)
        .background(.white, in: RoundedRectangle(cornerRadius: DefaultConstant.cornerRadius))
        .glass()
    }

    private var recordListView: some View {
        List(member.attendanceRecords, rowContent: { record in
            attendanceRecordRow(record)
                .listRowBackground(Color.clear)
        })
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .frame(height: scrollViewHeight)
        .background(.white, in: RoundedRectangle(cornerRadius: DefaultConstant.cornerRadius))
        .glass()
    }

    private func attendanceRecordRow(_ record: MemberAttendanceRecord) -> some View {
        HStack(spacing: DefaultSpacing.spacing16) {
            Text(record.status.displayText)
                .appFont(.subheadlineEmphasis, color: record.status.fontColor)
                .padding(Constants.tagPadding)
                .background(record.status.backgroundColor, in: Capsule())

            Text(record.sessionTitle)
                .appFont(.subheadline)
                .lineLimit(1)

            Spacer()
        }
    }
}

#Preview {
    Text("Preview")
        .sheet(isPresented: .constant(true), content: {
            ChallengerMemberDetailSheetView(
                member: .init(
                    profile: nil,
                    name: "김미주",
                    nickname: "마티",
                    generation: "7기, 8기, 9기",
                    school: "덕성여자대학교",
                    position: "Challenger",
                    part: .front(type: .ios),
                    penalty: 2,
                    rewardPoints: 3,
                    badge: false,
                    managementTeam: .schoolPartLeader,
                    attendanceRecords: [
                        MemberAttendanceRecord(
                            sessionTitle: "OT 및 Git 기초",
                            week: 1,
                            status: .present
                        ),
                        MemberAttendanceRecord(
                            sessionTitle: "iOS SwiftUI 기초",
                            week: 2,
                            status: .absent
                        ),
                        MemberAttendanceRecord(
                            sessionTitle: "네비게이션 & 데이터 플로우",
                            week: 3,
                            status: .late
                        ),
                    ],
                    penaltyHistory: []
                ))
            })
}
