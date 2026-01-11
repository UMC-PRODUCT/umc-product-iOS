//
//  MySuggestionItem.swift
//  AppProduct
//
//  Created by 김미주 on 1/7/26.
//

import SwiftUI

// MARK: - MySuggestionItem

/// 마이페이지 - 건의함 - 건의 내역 리스트

struct MySuggestionItem: View {
    // MARK: - Properties

    private let model: MySuggestionItemModel

    // MARK: - Init

    init(model: MySuggestionItemModel) {
        self.model = model
    }

    // MARK: - Body

    var body: some View {
        MySuggestionItemPresenter(model: model)
    }
}

// MARK: - Presenter

private struct MySuggestionItemPresenter: View, Equatable {
    let model: MySuggestionItemModel

    static func == (lhs: MySuggestionItemPresenter, rhs: MySuggestionItemPresenter) -> Bool {
        lhs.model.id == rhs.model.id &&
            lhs.model.status == rhs.model.status &&
            lhs.model.date == rhs.model.date &&
            lhs.model.title == rhs.model.title &&
            lhs.model.question == rhs.model.question &&
            lhs.model.answer == rhs.model.answer
    }

    var body: some View {
        VStack(alignment: .leading) {
            // 상태 + 날짜
            HStack {
                Text(model.status.text)
                    .foregroundStyle(model.status.mainColor)
                    .padding(5)
                    .background(
                        Capsule()
                            .fill(model.status.subColor)
                            .stroke(model.status.mainColor)
                    )

                Spacer()

                Text(formatDate(model.date))
            }

            // 질문
            Text(model.title)
                .font(.title3.bold())

            Text(model.question)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.gray.opacity(0.1))
                )

            Spacer().frame(height: 20)

            // 답변
            if model.answer?.isEmpty == false {
                HStack(alignment: .top) {
                    Text("A")
                        .padding(7)
                        .foregroundStyle(.blue)
                        .background(
                            Circle()
                                .fill(.blue.opacity(0.2))
                        )

                    VStack(alignment: .leading) {
                        Text("운영진 답변")
                            .bold()
                            .foregroundStyle(.blue)

                        Text(model.answer ?? "")
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
        )
        .padding(.horizontal)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
}

#Preview("MySuggestionItem") {
    struct SuggestionPreview: View {
        var body: some View {
            ZStack {
                Color.grey100

                MySuggestionItem(
                    model: .init(
                        status: .answered,
                        date: Date(),
                        title: "세션 시간 조정 건의합니다.",
                        question: "7시는 너무 늦는 것 같아요. 6시 30분으로 조정 가능할까요?",
                        answer: "네, 운영진 회의 후 적극 반영하겠습니다."
                    )
                )
            }
        }
    }

    return SuggestionPreview()
}
