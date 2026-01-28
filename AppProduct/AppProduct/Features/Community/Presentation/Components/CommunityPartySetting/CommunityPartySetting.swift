//
//  CommunityPartySetting.swift
//  AppProduct
//
//  Created by 김미주 on 1/26/26.
//

import SwiftUI

struct CommunityPartySetting: View {
    // MARK: - Properties

    @State private var selectedDate = Date()
    @State private var maxParticipants = 3
    @State private var showPlaceSheet = false
    @State private var linkText: String = ""
    
    @FocusState private var focusedField: Bool
    
    @Environment(ErrorHandler.self) var errorHandler
    
    // MARK: - Constants
    
    private enum Constant {
    }

    // MARK: - Body

    var body: some View {
        Form {
            Section("날짜 및 시간") {
                dateField
                timeField
            }
            Section("최대 인원") {
                maxParticipantsField
            }
            Section("장소") {
                placeField
            }
            Section("오픈채팅 링크") {
                linkField
            }
        }
        .sheet(isPresented: $showPlaceSheet, content: {
            SearchMapView(errorHandler: errorHandler) { place in
                print(place)
            }
            .presentationDragIndicator(.visible)
        })
    }

    // MARK: - Fields

    private var dateField: some View {
        DatePicker("날짜",
                   selection: $selectedDate,
                   displayedComponents: [.date])
            .datePickerStyle(.compact)
    }
    
    private var timeField: some View {
        DatePicker("시간",
                   selection: $selectedDate,
                   displayedComponents: [.hourAndMinute])
    }

    private var maxParticipantsField: some View {
        Stepper(value: $maxParticipants, in: 2...20) {
            Text("\(maxParticipants)명")
                .appFont(.body, color: .black)
                .foregroundStyle(.primary)
        }
    }

    private var placeField: some View {
        Button(action: {
            showPlaceSheet.toggle()
        }, label: {
            HStack {
                Text("장소 선택")
                    .appFont(.body, color: .black)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.grey500)
            }
        })
    }

    private var linkField: some View {
        TextField("https://open.kakao.com/...", text: $linkText)
            .focused($focusedField)
            .keyboardType(.URL)
            .autocapitalization(.none)
            .autocorrectionDisabled()
    }
}

#Preview {
    NavigationView {
        CommunityPartySetting()
    }
    .environment(ErrorHandler())
}
