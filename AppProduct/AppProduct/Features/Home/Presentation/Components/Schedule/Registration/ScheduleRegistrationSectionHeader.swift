//
//  RegistrationSectionHeader.swift
//  AppProduct
//
//  Created by euijjang97 on 1/21/26.
//

import SwiftUI

/// 일정 등록 헤더
struct ScheduleRegistrationSectionHeader: View {
    
    let title: String
    let required: Bool
    let type: TrailingContentType
    
    enum TrailingContentType {
        case none
        case allDay(isOn: Binding<Bool>)
        case csv(action: () -> Void)
    }
    
    private enum Constants {
        static let starSize: CGFloat = 8
        static let toggleSize: CGFloat = 100
        static let allDaysText: String = "종일"
        static let getCSVText: String = "CSV 가져오기"
        static let csvImage: String = "square.and.arrow.up"
        static let starImage: String = "staroflife.fill"
    }
    
    
    var body: some View {
        HStack {
            headerTitle
            Spacer()
            trailingContent
        }
    }
    
    private var headerTitle: some View {
        HStack(alignment: .center, spacing: DefaultSpacing.spacing8, content: {
            Text(title)
                .appFont(.title3Emphasis, color: .black)
            
            if required {
                Image(systemName: Constants.starImage)
                    .renderingMode(.template)
                    .resizable()
                    .foregroundStyle(.red)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Constants.starSize, height: Constants.starSize)
            }
        })
    }
    
    // MARK: - TrailingContent
    @ViewBuilder
    private var trailingContent: some View {
        switch type {
        case .none:
            EmptyView()
        case .allDay(let isOn):
            toggle(isOn: isOn)
        case .csv(let action):
            button(action: action)
        }
    }
    
    private func toggle(isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(Constants.allDaysText)
                .appFont(.footnote, color: .grey500)
        }
        .tint(.indigo500)
        .scaleEffect(0.9)
        .frame(width: Constants.toggleSize)
    }
    
    private func button(action: @escaping () -> Void) -> some View {
        Button(action: {
            action()
        }, label: {
            Label(Constants.getCSVText, systemImage: Constants.csvImage)
                .appFont(.footnote, color: .white)
                .labelIconToTitleSpacing(DefaultSpacing.spacing4)
        })
        .tint(.indigo500)
        .buttonStyle(.glassProminent)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    @Previewable @State var isOn: Bool = false
    ScheduleRegistrationSectionHeader(title: "일정 제목", required: true, type: .allDay(isOn: $isOn))
    ScheduleRegistrationSectionHeader(title: "참여자 명단(3명)", required: false, type: .csv(action: {
        print("hello")
    }))
}
