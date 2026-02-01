//
//  TesteA.swift
//  AppProduct
//
//  Created by euijjang97 on 1/13/26.
//

import SwiftUI

/// 참여 기수 및 누적 활동일 표시 카드
///
/// 사용자의 활동 기록(참여 기수, 누적 활동일)을 시각적으로 보여주는 카드 뷰입니다.
struct SeasonCard: View, Equatable {
    
    // MARK: - Properties
    
    /// 카드 타입 (일수/기수)
    let type: SeasonType
    
    /// 애니메이션 네임스페이스
    @Namespace var namespace
    
    // MARK: - Equatable
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.type == rhs.type
    }
    
    // MARK: - Constant
    
    private enum Constants {
        /// 아이콘 크기
        static let iconSize: CGFloat = 24
        /// 아이콘 패딩
        static let iconPadding: CGFloat = 4
        /// 미사용 (이전 디자인 잔재 가능성)
        static let glassContainerSpacing: CGFloat = 20
        /// 하단 간격 값
        static let bottomSpacingValue: CGFloat = 8
        /// 카드 메인 패딩
        static let mainPadding: EdgeInsets = .init(top: 16, leading: 24, bottom: 16, trailing: 24)
        /// 카드 크기
        static let cardSize: CGSize = .init(width: 130, height: 125)
    }
    
    // MARK: - Init
    
    /// SeasonCard 생성자
    /// - Parameter type: 표시할 시즌 타입 (days 또는 gens)
    init(type: SeasonType) {
        self.type = type
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .leading) {
            // 배경 컨테이너 (Glass 효과 적용)
            ConcentricRectangle(corners: .concentric(minimum: DefaultConstant.concentricRadius), isUniform: true)
                .fill(.white)
                .frame(height: Constants.cardSize.height, alignment: .leading)
                .glassEffect(.regular, in: .rect(corners: .concentric(minimum: DefaultConstant.concentricRadius)))
            
            // 전경 컨텐츠
            VStack(alignment: .leading, content: {
                topTag
                Spacer()
                bottomContents
            })

            .padding(Constants.mainPadding)
        }
    }
    
    // MARK: - Top
    
    /// 상단
    @ViewBuilder
    private var topTag: some View {
        if let image = type.image {
            image
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Constants.iconSize, height: Constants.iconSize)
                .foregroundStyle(.white)
                .padding(Constants.iconPadding)
                .background {
                    RoundedRectangle(cornerRadius: DefaultConstant.defaultCornerRadius)
                        .fill(.indigo500)
                }
        } else if let gens = type.gens {
            topGens(gens: gens)
        }
    }
    
    @ViewBuilder
     private func topGens(gens: [Int]) -> some View {
         HStack(spacing: .zero) {
             ForEach(Array(gens.enumerated()), id: \.offset) { index, gen in
                 self.gen(value: gen)
                     .offset(x: CGFloat(index * -8))
                     .zIndex(Double(index))
             }
         }
     }
    
    /// 기수 뱃지 생성
    /// - Parameter value: 기수 값
    /// - Returns: 뱃지 glass
    private func gen(value: Int) -> some View {
        Text("\(value)")
            .appFont(.caption1Emphasis, color: .indigo500)
            .padding(Constants.bottomSpacingValue)
            .background {
                Circle()
                    .fill(.white)
                    .glass()
            }
    }
    
    // MARK: - Bottom
    private var bottomContents: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing4, content: {
            title
            value
        })
    }
    private var title: some View {
        Text(type.text)
            .appFont(.calloutEmphasis, color: type.fontColor)
    }
    
    private var value: some View {
        HStack(alignment: .lastTextBaseline, content: {
            Text("\(type.value)")
                .appFont(.bodyEmphasis, color: .grey900)
                .fontWeight(.heavy)
            
            Text(type.valueTag)
                .appFont(.callout, weight: .medium, color: .grey600)
        })
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    VStack {
        SeasonCard(type: .gens([10,11,12]))
    }
}
