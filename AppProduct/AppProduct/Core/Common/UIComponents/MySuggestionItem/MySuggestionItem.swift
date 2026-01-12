//
//  MySuggestionItem.swift
//  AppProduct
//
//  Created by 김미주 on 1/7/26.
//

import SwiftUI

// MARK: - Constants

private enum Constant {
    static let mainVSpacing: CGFloat = 8
    static let questionAnswerSpacing: CGFloat = 16
    static let mainPadding: CGFloat = 16
    static let mainBoxRadius: CGFloat = 20
    // status
    static let statusPadding: EdgeInsets = .init(top: 4, leading: 8, bottom: 4, trailing: 8)
    // question
    static let questionContentPadding: EdgeInsets = .init(top: 12, leading: 12, bottom: 12, trailing: 12)
    static let questionContentBoxRadius: CGFloat = 10
    // answer
    static let answerIconPadding: EdgeInsets = .init(top: 7, leading: 7, bottom: 7, trailing: 7)
    static let answerVSpacing: CGFloat = 4
}

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
            .equatable()
    }
}

// MARK: - Presenter

private struct MySuggestionItemPresenter: View, Equatable {
    let model: MySuggestionItemModel

    static func == (lhs: MySuggestionItemPresenter, rhs: MySuggestionItemPresenter) -> Bool {
        lhs.model == rhs.model
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Constant.mainVSpacing) {
            TopSection(model: model)
            QuestionSection(model: model)
            Spacer().frame(height: Constant.questionAnswerSpacing)
            if model.answer?.isEmpty == false {
                AnswerSection(model: model)
            }
        }
        .padding(Constant.mainPadding)
        .background(.white, in: RoundedRectangle(cornerRadius: Constant.mainBoxRadius))
    }
}

// 상태 + 날짜
private struct TopSection: View, Equatable {
    let model: MySuggestionItemModel

    var body: some View {
        HStack {
            Text(model.status.text)
                .appFont(.caption2, color: model.status.mainColor)
                .padding(Constant.statusPadding)
                .background(model.status.subColor, in: Capsule())
                .overlay(Capsule().strokeBorder(model.status.mainColor))

            Spacer()

            Text(model.date.toYearMonthDay())
                .appFont(.caption1, color: .black)
        }
    }
}

// 질문
private struct QuestionSection: View, Equatable {
    let model: MySuggestionItemModel

    var body: some View {
        Text(model.title)
            .appFont(.subheadlineEmphasis, color: .black)

        Text(model.question)
            .appFont(.caption1, color: .black)
            .padding(Constant.questionContentPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.grey100, in: RoundedRectangle(cornerRadius: Constant.questionContentBoxRadius))
    }
}

// 답변
private struct AnswerSection: View, Equatable {
    let model: MySuggestionItemModel

    var body: some View {
        HStack(alignment: .top) {
            Text("A")
                .appFont(.caption2, color: .indigo900)
                .padding(Constant.answerIconPadding)
                .background(.indigo100, in: Circle())

            VStack(alignment: .leading, spacing: Constant.answerVSpacing) {
                Text("운영진 답변")
                    .appFont(.caption1Emphasis, color: .indigo900)

                Text(model.answer ?? "")
                    .appFont(.caption1, color: .black)
            }
        }
    }
}

#Preview {
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
