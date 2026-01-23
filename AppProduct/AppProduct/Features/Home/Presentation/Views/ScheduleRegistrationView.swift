//
//  RegistrationView.swift
//  AppProduct
//
//  Created by euijjang97 on 1/22/26.
//

import SwiftUI

/// 일정 생성 화면
struct ScheduleRegistrationView: View {
    
    @State var viewModel: ScheduleRegistrationViewModel
    
    init() {
        self._viewModel = .init(wrappedValue: .init())
    }
    
    var body: some View {
        Form {
            Section {
                sectionView(.title)
                sectionView(.place)
            }
        }
    }
    
    @ViewBuilder
    private func sectionView(_ type: ScheduleGenerationType) -> some View {
        switch type {
        case .title:
            TitleView(text: $viewModel.title)
                .equatable()
        case .place:
            PlaceView(place: $viewModel.place)
        case .date:
            EmptyView()
        case .memo:
            EmptyView()
        case .participation:
            EmptyView()
        case .category:
            EmptyView()
        }
    }
}

fileprivate struct TitleView: View, Equatable {
    @Binding var text: String
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.text == rhs.text
    }
    
    var body: some View {
        TextField("", text: $text, prompt: placeholer)
            .submitLabel(.return)
            .tint(.indigo500)
            .appFont(.body, color: .black)
    }
    
    private var placeholer: Text {
        Text(ScheduleGenerationType.title.placeholder ?? "")
            .font(ScheduleGenerationType.title.placeholderFont)
    }
}

fileprivate struct PlaceView: View, Equatable {
    @Binding var place: PlaceSearchInfo
    @State var showSearchMap: Bool = false
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.place == rhs.place
    }
    
    var body: some View {
        Button(action: {
            showSearchMap = true
        }, label: {
            TextField("", text: $place.name, prompt: placeholer, axis: .vertical)
                .appFont(.body, color: .black)
                .disabled(true)
        })
    }
    
    private var placeholer: Text {
        Text(ScheduleGenerationType.place.placeholder ?? "")
            .font(ScheduleGenerationType.place.placeholderFont)
    }
}

#Preview {
    ScheduleRegistrationView()
}
