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
    
    private enum Constants {
        static let tagPadding: EdgeInsets = .init(top: 4, leading: 8, bottom: 4, trailing: 8)
        static let boxPadding: EdgeInsets = .init(top: 12, leading: 0, bottom: 12, trailing: 0)
        static let listPadding: EdgeInsets = .init(top: 12, leading: 12, bottom: 12, trailing: 12)
        static let profileSize: CGSize = .init(width: 60, height: 60)
        
        static let baseHeight: CGFloat = 340  // 기본 정보 영역
        static let emptyRecordHeight: CGFloat = 150 // 빈 상태 뷰 높이
        static let recordRowHeight: CGFloat = 50  // 각 출석 기록 행의 높이
        static let maxVisibleRecords: Int = 5  // 스크롤 없이 보이는 최대 기록 수
        static let minSheetHeight: CGFloat = 420  // 최소 시트 높이
        static let maxSheetHeight: CGFloat = 700  // 최대 시트 높이
    }
    
    private enum InfoType {
        case generation
        case penalty
        
        var title: String {
            switch self {
            case .generation: return "활동 기수"
            case .penalty: return "누적 경고"
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// 출석 기록 개수에 따른 동적 시트 높이
    private var dynamicSheetHeight: CGFloat {
        let recordCount = member.attendanceRecords.count
        
        if recordCount == 0 {
            // 기록 없을 때: 기본 높이 + 빈 상태 뷰 높이 (150)
            return Constants.baseHeight + Constants.emptyRecordHeight
        }
        
        // 표시할 기록 수 (최대 개수까지만 높이 증가, 그 이상은 스크롤)
        let visibleRecords = min(recordCount, Constants.maxVisibleRecords)
        let recordsHeight = (CGFloat(visibleRecords) * Constants.recordRowHeight)
        + (CGFloat(max(0, visibleRecords - 1)) * DefaultSpacing.spacing8)

        let calculatedHeight = Constants.baseHeight + recordsHeight

        // 최소/최대 높이 제한
        return max(Constants.minSheetHeight, min(calculatedHeight, Constants.maxSheetHeight))
    }

    /// 스크롤뷰 높이 (기록 개수에 따라 동적)
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
                    generationPenaltyView(type: .generation)
                    generationPenaltyView(type: .penalty)
                }
                
                recordView
            }
            .toolbar {
                ToolBarCollection.CancelBtn(action: {
                    dismiss()
                })
            }
            .padding()
            .scrollContentBackground(.hidden)
            .presentationDetents([.height(dynamicSheetHeight)])
            .interactiveDismissDisabled()
        }
    }
    
    // MARK: - SubView
    
    /// 멤버 기본 정보
    private var memberInfoView: some View {
        HStack(spacing: DefaultSpacing.spacing12) {
            RemoteImage(urlString: member.profile ?? "", size: Constants.profileSize)
            
            HStack (spacing: DefaultSpacing.spacing8) {
                Text(member.name)
                    .appFont(.title2Emphasis)
                Text(member.part.name)
                    .appFont(.callout, color: .gray)
                    .padding(Constants.tagPadding)
                    .background(.white, in: Capsule())
                if member.managementTeam != .challenger {
                    Text(member.managementTeam.korean)
                        .appFont(.callout, color: member.managementTeam.textColor)
                        .padding(Constants.tagPadding)
                        .background(member.managementTeam.backgroundColor, in: Capsule())
                }
            }
        }
    }
    
    /// 활동 기수 및 누적 경고
    private func generationPenaltyView(type: InfoType) -> some View {
        VStack(spacing: DefaultSpacing.spacing8) {
            Text(type.title)
                .appFont(.callout, color: .grey700)
            Text(type == .generation ? member.generation : member.penalty.description)
                .appFont(.title3Emphasis, color: type == .generation ? .black : .red)
        }
        .padding(Constants.boxPadding)
        .frame(maxWidth: .infinity)
        .background(.white, in: RoundedRectangle(cornerRadius: DefaultConstant.cornerRadius))
        .glass()
    }
    
    /// 출석/활동 기록
    private var recordView: some View {
        VStack(alignment: .leading) {
            Label("출석/활동 기록", systemImage: "exclamationmark.arrow.trianglehead.2.clockwise.rotate.90")
                .appFont(.title3Emphasis)
            
            if member.attendanceRecords.isEmpty {
                // 기록 없음
                emptyRecordView
            } else {
                // 기록 리스트
                recordListView
            }
        }
    }
    
    /// 기록 없음 뷰
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
    
    /// 기록 리스트 뷰
    private var recordListView: some View {
        List(member.attendanceRecords, rowContent:  { record in
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
    
    /// 출석 기록 행
    private func attendanceRecordRow(_ record: MemberAttendanceRecord) -> some View {
        HStack(spacing: DefaultSpacing.spacing16) {
            // 출석 상태
            Text(record.status.displayText)
                .appFont(.subheadlineEmphasis, color: record.status.fontColor)
                .padding(Constants.tagPadding)
                .background(record.status.backgroundColor, in: Capsule())
            
            // 세션 제목
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
                    generation: "9기",
                    position: "Challenger",
                    part: .front(type: .ios),
                    penalty: 2,
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
                        MemberAttendanceRecord(
                            sessionTitle: "API 통신 & 네트워킹",
                            week: 4,
                            status: .present
                        ),
                        MemberAttendanceRecord(
                            sessionTitle: "상태 관리 & MVVM 패턴",
                            week: 5,
                            status: .present
                        ),
                        MemberAttendanceRecord(
                            sessionTitle: "클린 아키텍처 & DI",
                            week: 6,
                            status: .present
                        ),
                        MemberAttendanceRecord(
                            sessionTitle: "프로젝트 중간 발표",
                            week: 7,
                            status: .present
                        ),
                    ]
                ))
            })
}
