//
//  ScheduleDatePicker.swift
//  AppProduct
//
//  Created by 김미주 on 1/10/26.
//

import SwiftUI

// MARK: - ScheduleDatePicker

/// 홈 - 일정 생성 - 일시

struct ScheduleDatePicker: View {
    // MARK: - Properties

    private let model: ScheduleDatePickerModel

    // MARK: - Init

    init(model: ScheduleDatePickerModel) {
        self.model = model
    }

    // MARK: - Body

    var body: some View {
        ScheduleDatePickerPresenter(model: model)
    }
}

// MARK: - Presenter

private struct ScheduleDatePickerPresenter: View, Equatable {
    let model: ScheduleDatePickerModel

    static func == (lhs: ScheduleDatePickerPresenter, rhs: ScheduleDatePickerPresenter) -> Bool {
        lhs.model == rhs.model
    }

    var body: some View {
        HStack(spacing: 12) {
            // 아이콘
            Image(systemName: "calendar")
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder()
                )
                .foregroundStyle(model.type.tintColor)

            // 타이틀
            Text(model.type.title)
                .font(.system(size: 14))
                .foregroundStyle(Color.neutral800)
            
            Spacer()

            // 시간
            VStack(alignment: .trailing) {
                Text(formatDate(model.date))
                    .font(.system(size: 14).bold())
                    .foregroundStyle(.black)

                Text(formatTime(model.date))
                    .font(.system(size: 10).bold())
                    .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 17.5)
        .padding(.horizontal, 20)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd (E)"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "a h:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
}

#Preview {
    struct ScheduleDatePickerPreview: View {
        let startDate = Calendar.current.date(from: DateComponents(
            year: 2026,
            month: 1,
            day: 16,
            hour: 10,
            minute: 0
        ))!
        let endDate = Calendar.current.date(from: DateComponents(
            year: 2026,
            month: 1,
            day: 16,
            hour: 12,
            minute: 0
        ))!

        var body: some View {
            VStack {
                ScheduleDatePicker(
                    model: .init(
                        type: .start,
                        date: startDate
                    )
                )

                ScheduleDatePicker(
                    model: .init(
                        type: .end,
                        date: endDate
                    )
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.neutral100)
            )
            .padding()
        }
    }

    return ScheduleDatePickerPreview()
}
