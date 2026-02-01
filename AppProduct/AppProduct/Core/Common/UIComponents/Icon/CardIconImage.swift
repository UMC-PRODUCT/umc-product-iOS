//
//  CardIconImage.swift
//  AppProduct
//
//  Created by euijjang97 on 1/19/26.
//

import Foundation
import SwiftUI

/// 카드 내부에서 사용되는 공통 아이콘 이미지 뷰
///
/// 로딩 상태를 처리할 수 있으며, Glassmorphism 효과가 적용된 배경을 가집니다.
struct CardIconImage: View {
    
    // MARK: - Properties
    
    /// 표시할 시스템 아이콘 이름
    let image: String
    /// 아이콘 및 배경 틴트 색상
    let color: Color
    /// 로딩 상태 바인딩 (true일 경우 인디케이터 표시)
    @Binding var isLoading: Bool
    
    // MARK: - Constants
    
    private enum Constants {
        /// 아이콘 패딩
        static let iconPadding: CGFloat = 8
        /// 아이콘 크기
        static let iconSize: CGFloat = 36
        /// 배경 라운드 값
        static let cornerRadius: CGFloat = 24
    }
    
    var body: some View {
        iconView
    }
    
    /// 아이콘 또는 로딩 인디케이터 뷰
    @ViewBuilder
    private var iconView: some View {
        Group {
            if isLoading {
                ProgressView()
                    .tint(.black)
            } else {
                Image(systemName: image)
                    .font(.title2)
                    .foregroundStyle(color)
            }
        }
        .frame(width: DefaultConstant.iconSize, height: DefaultConstant.iconSize)
        .padding(DefaultConstant.iconPadding)
        .background(color.opacity(0.4))
        .clipShape(ContainerRelativeShape())
        .glassEffect(.clear, in: .containerRelative)
    }
}
