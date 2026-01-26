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
    @State private var placeText: String = ""
    @State private var linkText: String = ""
    
    @FocusState private var focusedField: Field?
    
    // MARK: - Constants
    
    private enum Field: Hashable {
        case place
        case link
    }
    
    private enum Constant {
        static let mainPadding: EdgeInsets = .init(top: 16, leading: 16, bottom: 24, trailing: 16)
        static let calendarPadding: EdgeInsets = .init(top: 0, leading: 12, bottom: 0, trailing: 12)
        static let textFieldPadding: EdgeInsets = .init(top: 8, leading: 16, bottom: 8, trailing: 16)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing16) {
            headerView
            
            VStack(spacing: DefaultSpacing.spacing16) {
                dateField
                Divider()
                maxParticipantsField
                Divider()
                placeField
                Divider()
                linkField
            }
        }
        .padding(Constant.mainPadding)
        .background(
            RoundedRectangle(cornerRadius: DefaultConstant.defaultCornerRadius)
                .fill(.white)
        )
        .glass()
    }

    // MARK: - Views
    
    private var headerView: some View {
        Text("⚡️ 번개 설정")
            .appFont(.bodyEmphasis, color: .black)
    }

    // MARK: - Fields

    private var dateField: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing8) {
            Text("날짜 및 시간")
                .appFont(.subheadline, color: .grey700)
            
            DatePicker("",
                       selection: $selectedDate,
                       displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.graphical)
                .padding(Constant.calendarPadding)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: DefaultConstant.defaultCornerRadius)
                )
        }
    }

    private var maxParticipantsField: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing8) {
            Text("최대 인원")
                .appFont(.subheadline, color: .grey700)
            
            Stepper(value: $maxParticipants, in: 2...20) {
                Text("\(maxParticipants)명")
                    .font(.body)
                    .foregroundStyle(.primary)
            }
        }
    }

    private var placeField: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing8) {
            Text("장소")
                .appFont(.subheadline, color: .grey700)
            
            TextField("예: 강남역 3번출구", text: $placeText, axis: .vertical)
                .focused($focusedField, equals: .place)
                .lineLimit(1)
                .padding(Constant.textFieldPadding)
                .background(Color(.secondarySystemBackground), in: Capsule())
        }
    }

    private var linkField: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing8) {
            Text("오픈채팅 링크")
                .appFont(.subheadline, color: .grey700)
            
            TextField("https://open.kakao.com/...", text: $linkText)
                .focused($focusedField, equals: .link)
                .keyboardType(.URL)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .padding(Constant.textFieldPadding)
                .background(Color(.secondarySystemBackground), in: Capsule())
        }
    }
}

#Preview {
    ScrollView {
        CommunityPartySetting()
            .padding()
    }
    .background(Color(.secondarySystemBackground))
}
