//
//  MyAttendanceItem.swift
//  AppProduct
//
//  Created by 김미주 on 1/9/26.
//

import SwiftUI

// MARK: - MyAttendanceItem

// 활동 탭 - 출석 체크 - 나의 출석 현황

struct MyAttendanceItem: View {
    // MARK: - Properties

    private let model: MyAttendanceItemModel

    // MARK: - Init

    init(model: MyAttendanceItemModel) {
        self.model = model
    }

    // MARK: - Body

    var body: some View {
        MyAttendanceItemPresenter(model: model)
    }
}

// MARK: - Presenter

private struct MyAttendanceItemPresenter: View, Equatable {
    let model: MyAttendanceItemModel

    static func == (lhs: MyAttendanceItemPresenter, rhs: MyAttendanceItemPresenter) -> Bool {
        lhs.model == rhs.model
    }

    var body: some View {
        HStack(spacing: 13) {
            // 주차
            Text(model.week)
                .font(.system(size: 14).bold())
                .foregroundStyle(.gray)

            HStack {
                // 제목 + 날짜
                VStack(alignment: .leading) {
                    Text(model.title)
                        .font(.system(size: 14).bold())
                    Text(formatDate(model.date))
                        .font(.system(size: 12))
                        .foregroundStyle(.gray)
                }

                Spacer()

                Text(model.status.text)
                    .font(.system(size: 12).bold())
                    .foregroundStyle(.white)
                    .padding(.vertical, 2)
                    .padding(.horizontal, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(model.status.color)
                    )
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.gray.opacity(0.1))
            )
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
}

#Preview {
    struct MyAttendanceItemPreview: View {
        var body: some View {
            VStack(spacing: 20) {
                MyAttendanceItem(model: .init(week: "3주차", title: "정기 세션", date: Date(), status: .present))
                MyAttendanceItem(model: .init(week: "2주차", title: "블라블라", date: Date(), status: .late))
                MyAttendanceItem(model: .init(week: "1주차", title: "OT", date: Date(), status: .absent))
            }
            .padding()
        }
    }

    return MyAttendanceItemPreview()
}
