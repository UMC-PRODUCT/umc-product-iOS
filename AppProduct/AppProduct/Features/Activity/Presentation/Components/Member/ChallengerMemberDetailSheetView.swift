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
        static let partPadding: EdgeInsets = .init(top: 4, leading: 8, bottom: 4, trailing: 8)
        static let boxPadding: EdgeInsets = .init(top: 12, leading: 0, bottom: 12, trailing: 0)
        static let defaultSheetFraction: CGFloat = 500

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
            .scrollDisabled(true)
            .presentationDetents([.height(Constants.defaultSheetFraction)])
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled()
        }
    }
    
    // MARK: - SubView
    
    /// 멤버 기본 정보
    private var memberInfoView: some View {
        HStack(spacing: DefaultSpacing.spacing12) {
            Circle().fill(.white).frame(width: 60)
            
            HStack (spacing: DefaultSpacing.spacing8) {
                Text(member.name)
                    .appFont(.title2Emphasis)
                Text(member.part.name)
                    .appFont(.callout, color: .gray)
                    .padding(Constants.partPadding)
                    .background(.white, in: Capsule())
                if member.managementTeam != .challenger {
                    Text(member.managementTeam.rawValue)
                        .appFont(.callout, color: member.managementTeam.textColor)
                        .padding(Constants.partPadding)
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
            
            ScrollView {
                // TODO: 챌린저 출석/활동 기록
            }
            .background(.white, in: RoundedRectangle(cornerRadius: DefaultConstant.cornerRadius))
            .glass()
        }
    }
}

#Preview {
    Text("Preview")
        .sheet(isPresented: .constant(true), content: {
            ChallengerMemberDetailSheetView(member: .init(profile: nil, name: "김미주", generation: "9기", position: "Challenger", part: .front(type: .ios), penalty: 2, badge: false, managementTeam: .campusPartLeader))
        })
}
