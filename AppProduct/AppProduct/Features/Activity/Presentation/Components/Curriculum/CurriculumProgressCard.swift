//
//  CurriculumProgressCard.swift
//  AppProduct
//
//  Created by jaewon Lee on 02/01/26.
//

import SwiftUI

// MARK: - CurriculumProgressCard

/// 커리큘럼 진행률 카드 컴포넌트
///
/// 파트명, 달성률, 커리큘럼 제목, 프로그레스바를 표시합니다.
struct CurriculumProgressCard: View, Equatable {

    // MARK: - Property

    let model: CurriculumProgressModel

    // MARK: - Equatable

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.model == rhs.model
    }

    // MARK: - Constants

    private enum Constants {
        static let progressBarHeight: CGFloat = 8
        static let iconName: String = "book.fill"
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing16) {
            headerSection
            statsSection
            titleSection
            progressSection
            footerSection
        }
        .padding(DefaultConstant.defaultCardPadding)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: DefaultConstant.defaultListCornerRadius))
        .containerShape(.rect(cornerRadius: DefaultConstant.defaultCornerRadius))
        .glass()
    }

    // MARK: - View Components

    /// 헤더: 아이콘 + 파트명 + 달성률 라벨
    private var headerSection: some View {
        HStack(spacing: DefaultSpacing.spacing12) {
            CardIconImage(
                image: Constants.iconName,
                color: .indigo500,
                isLoading: .constant(false)
            )

            Text(model.partName)
                .appFont(.calloutEmphasis, color: .indigo500)

            Spacer()

            Text("달성률")
                .appFont(.footnote, color: .gray)
        }
    }

    /// 통계: 퍼센트 숫자
    private var statsSection: some View {
        HStack(alignment: .lastTextBaseline, spacing: DefaultSpacing.spacing4) {
            Text("\(model.progressPercentage)")
                .appFont(.title1Emphasis)

            Text("%")
                .appFont(.title2Emphasis, color: .grey400)
        }
    }

    /// 제목: 커리큘럼명
    private var titleSection: some View {
        Text(model.curriculumTitle)
            .appFont(.calloutEmphasis)
    }

    /// 프로그레스바: Gauge + linearCapacity
    private var progressSection: some View {
        Gauge(value: model.progress) {
            EmptyView()
        }
        .gaugeStyle(.linearCapacity)
        .tint(
            LinearGradient(
                colors: [.indigo300, .indigo600],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .frame(height: Constants.progressBarHeight)
    }

    /// 푸터: 완료 카운트
    private var footerSection: some View {
        HStack {
            Spacer()
            Text(model.completionText)
                .appFont(.footnote, color: .grey500)
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("CurriculumProgressCard - Single") {
    CurriculumProgressCard(
        model: CurriculumProgressModel(
            partName: "WEB PART CURRICULUM",
            curriculumTitle: "웹 프론트엔드 기초",
            completedCount: 2,
            totalCount: 8
        )
    )
    .padding()
    .background(Color.grey100)
}

#Preview("CurriculumProgressCard - Multiple") {
    ScrollView {
        VStack(spacing: DefaultSpacing.spacing16) {
            CurriculumProgressCard(
                model: CurriculumProgressModel(
                    partName: "WEB PART CURRICULUM",
                    curriculumTitle: "웹 프론트엔드 기초",
                    completedCount: 2,
                    totalCount: 8
                )
            )

            CurriculumProgressCard(
                model: CurriculumProgressModel(
                    partName: "iOS PART CURRICULUM",
                    curriculumTitle: "Swift 기초 문법",
                    completedCount: 5,
                    totalCount: 10
                )
            )

            CurriculumProgressCard(
                model: CurriculumProgressModel(
                    partName: "ANDROID PART CURRICULUM",
                    curriculumTitle: "Kotlin 입문",
                    completedCount: 10,
                    totalCount: 10
                )
            )
        }
        .padding()
    }
    .background(Color.grey100)
}
#endif
