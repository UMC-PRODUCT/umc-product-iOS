//
//  OperatorMemberDetailSheetView.swift
//  AppProduct
//
//  Created by 이예지 on 2/16/26.
//

import SwiftUI

struct OperatorMemberDetailSheetView: View {
    
    // MARK: - Property
    
    @Environment(\.dismiss) private var dismiss
    var member: MemberManagementItem
    @State private var showPenalty: Bool = false
    @State private var showEditHistory: Bool = false
    @State private var penaltyReason: String = ""
    @State private var penaltyHistory: [OperatorMemberPenaltyHistory] = []
    @State private var totalPenalty: Double = 0
    @State private var selectedPenaltyScore: Double = 1.0
    
    // MARK: - Constant
    
    private enum Constants {
        static let tagPadding: EdgeInsets = .init(top: 4, leading: 8, bottom: 4, trailing: 8)
        static let boxPadding: EdgeInsets = .init(top: 12, leading: 0, bottom: 12, trailing: 0)
        static let listPadding: EdgeInsets = .init(top: 12, leading: 12, bottom: 12, trailing: 12)
        static let profileSize: CGSize = .init(width: 60, height: 60)
        
        static let baseHeight: CGFloat = 340  // 기본 정보 영역
        static let emptyHistoryHeight: CGFloat = 150 // 빈 상태 뷰 높이
        static let historyRowHeight: CGFloat = 50  // 각 출석 기록 행의 높이
        static let maxVisibleHistory: Int = 5  // 스크롤 없이 보이는 최대 기록 수
        static let minSheetHeight: CGFloat = 420  // 최소 시트 높이
        static let maxSheetHeight: CGFloat = 700  // 최대 시트 높이
        static let badgePadding: EdgeInsets = .init(top: 6, leading: 8, bottom: 6, trailing: 8)
        static let bgOpacity: Double = 0.2
        static let textfieldPadding: CGFloat = 12
    }
    
    // MARK: - Computed Properties
    
    /// 사유 입력 유효성 검사
     private var isReasonValid: Bool {
         !penaltyReason.trimmingCharacters(in: .whitespaces).isEmpty
     }
    
    /// 아웃 기록 개수에 따른 동적 시트 높이
    private var dynamicSheetHeight: CGFloat {
        let historyCount = penaltyHistory.count
        
        // 기본 높이 계산
        var calculatedHeight: CGFloat = Constants.baseHeight
        
        // 히스토리 영역 높이
        if historyCount == 0 {
            calculatedHeight += Constants.emptyHistoryHeight
        } else {
            let visibleHistory = min(historyCount, Constants.maxVisibleHistory)
            let historyHeight = (CGFloat(visibleHistory) * Constants.historyRowHeight)
            + (CGFloat(max(0, visibleHistory - 1)) * DefaultSpacing.spacing8)
            calculatedHeight += historyHeight
        }
        
        // 아웃 부여 TextField + 버튼 높이 추가
        if showPenalty {
            calculatedHeight += 120  // TextField(~50) + Button(~50) + spacing(~20)
        }
        
        // 기록 수정 안내 메시지 높이 추가
        if showEditHistory {
            calculatedHeight += 40  // Label 높이
        }
        
        // 최소/최대 높이 제한
        return max(Constants.minSheetHeight, min(calculatedHeight, Constants.maxSheetHeight))
    }
    
    /// 스크롤뷰 높이 (기록 개수에 따라 동적)
    private var scrollViewHeight: CGFloat {
        let recordCount = penaltyHistory.count
        
        if recordCount == 0 {
            return Constants.emptyHistoryHeight
        }
        
        let visibleHistory = min(recordCount, Constants.maxVisibleHistory)
        let historyHeight = (CGFloat(visibleHistory) * Constants.historyRowHeight)
        + (CGFloat(max(0, visibleHistory - 1)) * DefaultSpacing.spacing8)
        
        return historyHeight
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: DefaultSpacing.spacing32) {
                memberInfoView
                
                btnView
                
                historyView
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
        .onChange(of: member) { oldValue, newValue in
            penaltyHistory = newValue.penaltyHistory
            totalPenalty = newValue.penalty
        }
        .task {
            // 초기 로드
            penaltyHistory = member.penaltyHistory
            totalPenalty = member.penalty
        }
    }
    
    // MARK: - SubView
    
    /// 멤버 기본 정보
    private var memberInfoView: some View {
        HStack(spacing: DefaultSpacing.spacing12) {
            RemoteImage(urlString: member.profile ?? "", size: Constants.profileSize)
            
            HStack (spacing: DefaultSpacing.spacing8) {
                Text("\(member.name)/\(member.nickname)")
                    .appFont(.title2Emphasis)
                Text(member.part.name)
                    .appFont(.callout, color: .gray)
                    .padding(Constants.tagPadding)
                    .background(.white, in: Capsule())
                Text(member.school)
                    .appFont(.callout, color: .black)
                    .padding(Constants.tagPadding)
                    .background(.white, in: Capsule())
            }
        }
    }
    
    /// 아웃 부여/기록 수정 버튼
    private var btnView: some View {
        VStack(spacing: DefaultSpacing.spacing16) {
            HStack(spacing: DefaultSpacing.spacing16) {
                penaltyBtn
                editHistory
            }
            if showPenalty {
                penaltyInputSection
            }
            if showEditHistory {
                Label(title: {
                    Text("삭제 버튼을 눌러 기록을 삭제할 수 있습니다.")
                        .foregroundStyle(.black)
                        .appFont(.callout)
                }, icon: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                        .appFont(.callout)
                })
            }
        }
    }
    
    /// 아웃 부여
    private var penaltyBtn: some View {
        VStack {
            Button(action: {
                showEditHistory = false
                showPenalty.toggle()
            }, label: {
                VStack(spacing: DefaultSpacing.spacing8) {
                    Image(systemName: "slash.circle")
                    Text("아웃 부여")
                }
                .appFont(.body, color: showPenalty ? .red : .grey500)
                .padding(Constants.boxPadding)
                .frame(maxWidth: .infinity)
                .background(showPenalty ? .red.opacity(Constants.bgOpacity) : .white, in: RoundedRectangle(cornerRadius: DefaultConstant.cornerRadius))
                .glass()
            })
        }
    }
    
    /// 아웃 사유/점수 입력
    private var penaltyInputSection: some View {
        VStack {
            HStack {
                // 아웃 사유 TextField
                TextField("", text: $penaltyReason, prompt: Text("아웃 사유를 입력하세요"))
                    .frame(maxWidth: .infinity)
                    .padding(Constants.textfieldPadding)
                    .background(.white, in: RoundedRectangle(cornerRadius: DefaultConstant.defaultCornerRadius))
                    .glass()
                
                // 아웃 점수 선택 메뉴
                Menu {
                    Button("0.5점") {
                        selectedPenaltyScore = 0.5
                    }
                    Button("1점") {
                        selectedPenaltyScore = 1.0
                    }
                    Button("2점") {
                        selectedPenaltyScore = 2.0
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("+\(String(format: "%.1f", selectedPenaltyScore))")
                            .appFont(.calloutEmphasis, color: .red)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundStyle(.red)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(.red.opacity(0.1), in: Capsule())
                }
            }
            
            // 아웃 확정하기 Btn
            Button(action: {
                addPenalty()
            }, label: {
                Text("아웃 확정하기")
                    .foregroundStyle(isReasonValid ? .red : .grey400)
                    .frame(maxWidth: .infinity)
                    .padding(Constants.textfieldPadding)
                    .background(
                        isReasonValid ? Color.red.opacity(Constants.bgOpacity) : Color.grey200,
                        in: RoundedRectangle(cornerRadius: DefaultConstant.defaultCornerRadius)
                    )
            })
            .disabled(!isReasonValid)
        }
    }
    
    /// 기록 수정
    private var editHistory: some View {
        VStack {
            Button(action: {
                showPenalty = false
                showEditHistory.toggle()
            }, label: {
                VStack(spacing: DefaultSpacing.spacing8) {
                    Image(systemName: "gearshape")
                    Text("기록 수정")
                }
                .appFont(.body, color: showEditHistory ? .blue : .grey500)
                .padding(Constants.boxPadding)
                .frame(maxWidth: .infinity)
                .background(showEditHistory ? .blue.opacity(Constants.bgOpacity) : .white, in: RoundedRectangle(cornerRadius: DefaultConstant.cornerRadius))
                .glass()
            })
        }
    }
    
    /// 히스토리
    private var historyView: some View {
        VStack(alignment: .leading) {
            HStack(spacing: DefaultSpacing.spacing8) {
                Label("히스토리", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                    .appFont(.title3Emphasis)
                
                if !penaltyHistory.isEmpty {
                    penaltyBadge
                }
            }
            
            if penaltyHistory.isEmpty {
                // 기록 없음
                emptyHistoryView
            } else {
                // 기록 리스트
                historyListView
            }
        }
    }
    
    /// 누적 경고 뱃지
    private var penaltyBadge: some View {
        Text("아웃 \(String(format: "%.1f", totalPenalty))")
            .font(.app(.footnote, weight: .regular))
            .foregroundStyle(.red)
            .padding(Constants.badgePadding)
            .background {
                RoundedRectangle(cornerRadius: DefaultConstant.cornerRadius)
                    .fill(.red.opacity(Constants.bgOpacity))
            }
    }
    
    /// 기록 없음 뷰
    private var emptyHistoryView: some View {
        
        VStack(spacing: DefaultSpacing.spacing8) {
            Image(systemName: "exclamationmark.bubble.fill")
                .appFont(.title1, color: .grey500)
            Text("아웃 기록이 없습니다")
                .appFont(.subheadline, color: .grey500)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Constants.emptyHistoryHeight)
        .background(.white, in: RoundedRectangle(cornerRadius: DefaultConstant.cornerRadius))
        .glass()
    }
    
    /// 히스토리 리스트 뷰
    private var historyListView: some View {
        List(penaltyHistory, rowContent:  { history in
            penaltyHistoryRow(history)
                .listRowBackground(Color.clear)
        })
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .frame(height: scrollViewHeight)
        .background(.white, in: RoundedRectangle(cornerRadius: DefaultConstant.cornerRadius))
        .glass()
    }
    
    /// 아웃 히스토리 행
    private func penaltyHistoryRow(_ history: OperatorMemberPenaltyHistory) -> some View {
        HStack(spacing: DefaultSpacing.spacing16) {
            // 날짜
            Text(history.date.toYearMonthDay())
                .appFont(.subheadlineEmphasis)
            
            // 아웃 사유
            Text(history.reason)
                .appFont(.subheadline)
                .lineLimit(1)
            
            Spacer()
            
            // 아웃 점수
            Text("아웃 +\(String(format: "%.1f", history.penaltyScore))")
                .appFont(.subheadline, color: .red)
            
            if showEditHistory {
                Button(action: {
                    deletePenalty(history)
                }, label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.grey500)
                })
            }
        }
    }
    
    // MARK: - Function
    
    /// 아웃 부여하기
    private func addPenalty() {
        guard !penaltyReason.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        
        let newPenalty = OperatorMemberPenaltyHistory(
            date: Date(),
            reason: penaltyReason,
            penaltyScore: selectedPenaltyScore
        )
        
        // 히스토리에 추가 후 날짜순 정렬 (최신순)
        penaltyHistory.append(newPenalty)
        penaltyHistory.sort { $0.date > $1.date }
        
        // 총 페널티 점수 업데이트
        totalPenalty += selectedPenaltyScore
        
        // 입력 필드 초기화 및 모드 종료
        penaltyReason = ""
        selectedPenaltyScore = 1.0
        showPenalty = false
    }
    
    /// 히스토리 삭제하기
    private func deletePenalty(_ history: OperatorMemberPenaltyHistory) {
        if let index = penaltyHistory.firstIndex(where: { $0.id == history.id }) {
            let deletedScore = penaltyHistory[index].penaltyScore
            penaltyHistory.remove(at: index)
            
            // 총 페널티 점수 업데이트
            totalPenalty -= deletedScore
        }
    }
}

#Preview {
    Text("Preview")
        .sheet(isPresented: .constant(true), content: {
            OperatorMemberDetailSheetView(
                member: .init(
                    profile: nil,
                    name: "김미주",
                    nickname: "마티",
                    generation: "9기",
                    school: "덕성여자대학교",
                    position: "Challenger",
                    part: .front(type: .ios),
                    penalty: 2,
                    badge: false,
                    managementTeam: .schoolPartLeader,
                    attendanceRecords: [],
                    penaltyHistory: [
                        OperatorMemberPenaltyHistory(
                            date: Date().addingTimeInterval(-14 * 24 * 60 * 60), // 2주 전
                            reason: "세션 지각",
                            penaltyScore: 1.0
                        ),
                        OperatorMemberPenaltyHistory(
                            date: Date().addingTimeInterval(-7 * 24 * 60 * 60), // 1주 전
                            reason: "세션 결석 (사유 없음)",
                            penaltyScore: 1.0
                        )
                    ]
                ))
            })
}
