//
//  NoticeReadStatusButton.swift
//  AppProduct
//
//  Created by 이예지 on 2/3/26.
//

import SwiftUI

/// 공지 열람 현황 하단 버튼
/// NoticeDetailView 하단에 표시되는 슬라이드 버튼
struct NoticeReadStatusButton: View {
    
    // MARK: - Properties
    
    let confirmedCount: Int
    let totalCount: Int
    let action: () -> Void
    
    // MARK: - Constants
    
    fileprivate enum Constants {
        static let iconSize: CGFloat = 16
        static let progressHeight: CGFloat = 6
        static let vSpacing: CGFloat = 8
    }
    
    // MARK: - Computed Properties
    
    private var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(confirmedCount) / Double(totalCount)
    }
    
    private var progressText: String {
        let percentage = Int(progress * 100)
        return "\(confirmedCount)/\(totalCount)명 (\(percentage)%)"
    }
    
    // MARK: - Body
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Constants.vSpacing) {
                // 상단: 제목 + 진행률 텍스트
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: Constants.iconSize))
                            .foregroundStyle(.white)
                        
                        Text("수신 확인 현황")
                            .appFont(.subheadlineEmphasis)
                    }
                    
                    Spacer()
                    
                    Text(progressText)
                        .appFont(.subheadlineEmphasis)
                        .foregroundStyle(.white)
                }
                .foregroundStyle(.grey000)
                
                // 중간: Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // 배경 (회색)
                        RoundedRectangle(cornerRadius: Constants.progressHeight / 2)
                            .fill(.grey300)
                        
                        // 진행 바 (검은색)
                        RoundedRectangle(cornerRadius: Constants.progressHeight / 2)
                            .fill(.white)
                            .frame(width: geometry.size.width * progress)
                    }
                }
                .frame(height: Constants.progressHeight)
                
                // 하단: 안내 텍스트
                Text("터치하여 미확인 인원 관리하기")
                    .appFont(.caption1, color: .grey300)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal, DefaultSpacing.spacing16)
            .padding(.vertical, DefaultSpacing.spacing12)
            .background {
                RoundedRectangle(cornerRadius: DefaultConstant.defaultCornerRadius)
                    .fill(.indigo500)
            }
        }
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: DefaultConstant.defaultCornerRadius))
    }
}


// MARK: - Preview
#Preview(traits: .sizeThatFitsLayout) {
    VStack(spacing: 20) {
        NoticeReadStatusButton(confirmedCount: 1100, totalCount: 1250) {
            print("Tapped")
        }
        
        NoticeReadStatusButton(confirmedCount: 3, totalCount: 8) {
            print("Tapped")
        }
        
        NoticeReadStatusButton(confirmedCount: 0, totalCount: 10) {
            print("Tapped")
        }
    }
    .padding()
}
