//
//  TesteA.swift
//  AppProduct
//
//  Created by euijjang97 on 1/13/26.
//

import SwiftUI

/// 참여 기수 및 누적 활동일 표시
struct SeasonCard: View, Equatable {
    
    // MARK: - Type
    let type: SeasonType
    @Namespace var namespace
    @Environment(\.colorScheme) var color
    
    // MARK: - Equatable
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.type == rhs.type
    }
    
    // MARK: - Constant
    private enum Constants {
        static let iconSize: CGFloat = 28
        static let iconPadding: CGFloat = 8
        static let concentricRadius: CGFloat = 40
        static let glassContainerSpacing: CGFloat = 20
        static let bottomSpacingValue: CGFloat = 8
        static let mainPadding: EdgeInsets = .init(top: 16, leading: 24, bottom: 16, trailing: 28)
        static let cardSize: CGSize = .init(width: 180, height: 125)
    }
    
    // MARK: - Init
    init(type: SeasonType) {
        self.type = type
    }
    
    // MARK: - Bdoy
    var body: some View {
        VStack(alignment: .leading, content: {
            topTag
            Spacer()
            bottomContents
        })
        .frame(width: Constants.cardSize.width, height: Constants.cardSize.height, alignment: .leading)
        .padding(Constants.mainPadding)
        .background {
            ContainerRelativeShape()
                .fill(color == .light ? .grey000 : .grey100)
        }
        .containerShape(.rect(cornerRadius: Constants.concentricRadius))
        .glassEffect(.regular, in: .rect(cornerRadius: Constants.concentricRadius))
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
            .padding(DefaultConstant.defaultBtnPadding)
            .background {
                Circle()
                    .fill(.white)
                    .glass()
            }
    }
    
    // MARK: - Bottom
    private var bottomContents: some View {
        VStack(alignment: .leading, spacing: Constants.bottomSpacingValue, content: {
            title
            value
        })
    }
    private var title: some View {
        Text(type.text)
            .appFont(.bodyEmphasis, color: type.fontColor)
    }
    
    private var value: some View {
        HStack(alignment: .lastTextBaseline, content: {
            Text("\(type.value)")
                .appFont(.title1Emphasis, color: .grey900)
                .fontWeight(.heavy)
            
            Text(type.valueTag)
                .appFont(.bodyEmphasis, color: .grey600)
        })
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    VStack {
        SeasonCard(type: .gens([10,11,12]))
        SeasonCard(type: .days(300))
    }
}
