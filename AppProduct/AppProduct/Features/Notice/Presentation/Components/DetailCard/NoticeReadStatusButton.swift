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
            VStack(spacing: DefaultSpacing.spacing12) {
                // 상단: 제목 + 진행률 텍스트
                HStack {
                    HStack(spacing: DefaultSpacing.spacing8) {
                        Image(systemName: "checkmark.circle.fill")
                            .appFont(.body, color: .green)

                        Text("수신 확인 현황")
                            .appFont(.calloutEmphasis, color: .black)
                    }
                    
                    Spacer()
                    
                    Text(progressText)
                        .appFont(.subheadline)
                        .foregroundStyle(.black)
                }
                .foregroundStyle(.grey000)
                
                // 중간: Gauge
                Gauge(value: progress, in: 0...1) {}
                    .gaugeStyle(.linearCapacity)
                    .tint(.indigo500)
                
                // 하단: 안내 텍스트
                Text("터치하여 미확인 인원 관리하기")
                    .appFont(.footnote, color: .grey600)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal, DefaultSpacing.spacing16)
            .padding(.vertical, DefaultSpacing.spacing12)
            .background {
                RoundedRectangle(cornerRadius: DefaultConstant.defaultCornerRadius)
                    .fill(.clear)
                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: DefaultConstant.defaultCornerRadius))
            }
        }
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
