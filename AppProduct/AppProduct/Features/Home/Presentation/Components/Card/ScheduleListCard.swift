//
//  ScheduleListCard.swift
//  AppProduct
//
//  Created by euijjang97 on 1/18/26.
//

import SwiftUI
import Playgrounds

/// 선택된 달력에 대한 리스트 카드
struct ScheduleListCard: View, Equatable {
    
    // MARK: - Property
    let data: ScheduleData
    @State var category: ScheduleIconCategory = .general
    @State var isLoading: Bool = true
    @Environment(\.colorScheme) var color
    
    private enum Constants {
        static let iconPadding: CGFloat = 8
        static let padding: EdgeInsets = .init(top: 20, leading: 16, bottom: 20, trailing: 16)
        static let chevronImage: String = "chevron.forward"
        static let cornerRadius: CGFloat = 24
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.data == rhs.data
    }
    
    // MARK: - Init
    init(data: ScheduleData) {
        self.data = data
    }
    
    var body: some View {
        Button(action: {
            print("hello")
        }, label: {
            HStack(spacing: DefaultSpacing.spacing24, content: {
                CardIconImage(image: category.symbol, color: category.color, isLoading: $isLoading)
                infoContent
                Spacer()
                chevron
            })
            .padding(Constants.padding)
            .background {
                RoundedRectangle(cornerRadius: Constants.cornerRadius)
                    .fill(cardColor)
                    .glass()
            }
            .task {
                let classifier = ScheduleSymbolClassifier()
                category = await classifier.getCategory(data.title)
                isLoading = false
            }
        })
    }
    
    private var infoContent: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing8, content: {
            Text(data.title)
                .appFont(.bodyEmphasis, color: .grey900)
            Text(data.subTitle)
                .appFont(.footnote, color: .grey600)
        })
    }
    
    private var chevron: some View {
        Image(systemName: Constants.chevronImage)
            .renderingMode(.template)
            .foregroundStyle(.grey900)
            .padding(Constants.iconPadding)
    }
    
    private var cardColor: Color {
        if color == .dark {
            return .grey100
        } else {
            return .white
        }
    }
}

#Preview {
    VStack {
        ScheduleListCard(data: .init(title: "컨퍼런스", subTitle: "테스트"))
        ScheduleListCard(data: .init(title: "데모데이", subTitle: "테스트"))
    }
    .safeAreaPadding(.horizontal, 16)
}

#Playground {
    let data = ScheduleData(title: "컨퍼런스", subTitle: "테스트")
    @State var symbol: String = "calendar"
    
    let classifier = ScheduleSymbolClassifier()
    symbol = await classifier.getSymbol(data.title)
}
