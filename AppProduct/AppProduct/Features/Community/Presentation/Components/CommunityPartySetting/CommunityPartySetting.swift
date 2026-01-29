//
//  CommunityPartySetting.swift
//  AppProduct
//
//  Created by 김미주 on 1/26/26.
//

import SwiftUI

struct CommunityPartySetting: View {
    // MARK: - Properties
    @State var vm: CommunityPostViewModel
    @FocusState private var focusedField: Bool
    
    // MARK: - Constants
    
    private enum Constant {
    }

    // MARK: - Body

    var body: some View {
        Group {
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
    }

    // MARK: - Fields

    private var dateField: some View {
        DatePicker("날짜",
                   selection: $vm.selectedDate,
                   displayedComponents: [.date])
            .datePickerStyle(.compact)
    }
    
    private var timeField: some View {
        DatePicker("시간",
                   selection: $vm.selectedDate,
                   displayedComponents: [.hourAndMinute])
    }

    private var maxParticipantsField: some View {
        Stepper(value: $vm.maxParticipants, in: 2...20) {
            Text("\(vm.maxParticipants)명")
                .appFont(.body, color: .black)
                .foregroundStyle(.primary)
        }
    }

    private var placeField: some View {
        Button(action: {
            vm.showPlaceSheet.toggle()
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
        TextField("https://open.kakao.com/...", text: $vm.linkText)
            .focused($focusedField)
            .keyboardType(.URL)
            .autocapitalization(.none)
            .autocorrectionDisabled()
    }
}
