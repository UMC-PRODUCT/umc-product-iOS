//
//  HomeScheduleItem.swift
//  AppProduct
//
//  Created by 김미주 on 1/9/26.
//

import SwiftUI

// MARK: - HomeScheduleItem

/// 홈 - 일정 리스트

struct HomeScheduleItem: View {
    // MARK: - Properties

    private let model: HomeScheduleItemModel
    private let action: () -> Void

    // MARK: - Init

    init(model: HomeScheduleItemModel, action: @escaping () -> Void) {
        self.model = model
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            HomeScheduleItemPresenter(model: model)
        }
        .disabled(model.isDone)
    }
}

// MARK: - Presenter

private struct HomeScheduleItemPresenter: View, Equatable {
    let model: HomeScheduleItemModel

    static func == (lhs: HomeScheduleItemPresenter, rhs: HomeScheduleItemPresenter) -> Bool {
        lhs.model == rhs.model
    }

    var body: some View {
        HStack(spacing: 16) {
            // 날짜
            VStack {
                Text(formatMonth(model.date))
                    .font(.system(size: 10).bold())
                Text(formatDay(model.date))
                    .font(.system(size: 18).bold())
            }
            .frame(width: 48, height: 48)
            .foregroundStyle(model.isDone ? .gray : .blue)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(model.isDone ? .gray.opacity(0.1) : .blue.opacity(0.1))
                    .strokeBorder(model.isDone ? .gray.opacity(0.2) : .blue.opacity(0.2))
            )

            // 정보
            VStack(alignment: .leading, spacing: 2.5) {
                Text(model.title)
                    .font(.system(size: 14).bold())
                    .foregroundStyle(.black)
                Text("\(formatTime(model.date)) • \(model.type)")
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
            }

            Spacer()

            // 디데이 + 화살표
            HStack(spacing: 8) {
                if !model.isDone {
                    Text(formatDDay(model.date))
                        .font(.system(size: 12))
                        .foregroundStyle(.gray)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.gray.opacity(0.2))
                        )
                }

                Image(systemName: "chevron.right")
                    .foregroundStyle(.gray)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.white)
        )
        .opacity(model.isDone ? 0.5 : 1)
    }

    // MARK: - formatter

    private func formatMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date).uppercased()
    }

    private func formatDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: date)
    }

    private func formatDDay(_ date: Date) -> String {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.startOfDay(for: date)

        let diff = calendar.dateComponents([.day], from: start, to: end).day ?? 0

        if diff > 0 { return "D-\(diff)" }
        if diff < 0 { return "" }
        return "D-DAY"
    }
}

#Preview {
    struct HomeScheduleItemPreview: View {
        let date1 = Calendar.current.date(from: DateComponents(
            year: 2026,
            month: 1,
            day: 16,
            hour: 10,
            minute: 0
        ))!
        let date2 = Calendar.current.date(from: DateComponents(
            year: 2026,
            month: 1,
            day: 5,
            hour: 10,
            minute: 0
        ))!

        var body: some View {
            ZStack {
                Color.neutral100

                VStack(spacing: 20) {
                    HomeScheduleItem(
                        model: .init(
                            date: date2,
                            title: "아이디어톤",
                            type: "행사"
                        ), action: {
                            print("1번 행사")
                        }
                    )

                    HomeScheduleItem(
                        model: .init(
                            date: date1,
                            title: "아이디어톤",
                            type: "행사"
                        ), action: {
                            print("2번 행사")
                        }
                    )
                }
                .padding()
            }
        }
    }
    return HomeScheduleItemPreview()
}
