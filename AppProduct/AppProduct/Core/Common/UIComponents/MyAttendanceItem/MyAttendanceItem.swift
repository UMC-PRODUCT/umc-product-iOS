//
//  MyAttendanceItem.swift
//  AppProduct
//
//  Created by 김미주 on 1/9/26.
//

import SwiftUI

// MARK: - Constant

private enum Constant {
    static let mainHSpacing: CGFloat = 16
    // status
    static let statusPadding: EdgeInsets = .init(top: 2, leading: 7, bottom: 2, trailing: 7)
    static let statusRadius: CGFloat = 8
    // content
    static let contentPadding: EdgeInsets = .init(top: 12, leading: 12, bottom: 12, trailing: 12)
    static let contentRadius: CGFloat = 10
}

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
            .equatable()
    }
}

// MARK: - Presenter

private struct MyAttendanceItemPresenter: View, Equatable {
    let model: MyAttendanceItemModel

    static func == (lhs: MyAttendanceItemPresenter, rhs: MyAttendanceItemPresenter) -> Bool {
        lhs.model == rhs.model
    }

    var body: some View {
        HStack(spacing: Constant.mainHSpacing) {
            // 주차
            Text(model.week)
                .appFont(.subheadlineEmphasis, color: .gray)

            HStack {
                // 제목 + 날짜
                VStack(alignment: .leading) {
                    Text(model.title)
                        .appFont(.subheadlineEmphasis, color: .black)
                    Text(model.date.toMonthDay())
                        .appFont(.caption1, color: .gray)
                }

                Spacer()

                Text(model.status.text)
                    .appFont(.caption1Emphasis, color: .white)
                    .foregroundStyle(.white)
                    .padding(Constant.statusPadding)
                    .background(model.status.color, in: RoundedRectangle(cornerRadius: Constant.statusRadius))
            }
            .padding(Constant.contentPadding)
            .background(.grey100, in: RoundedRectangle(cornerRadius: Constant.contentRadius))
        }
    }
}

#Preview {
    MyAttendanceItem(model: .init(week: "3주차", title: "정기 세션", date: Date(), status: .present))
}
