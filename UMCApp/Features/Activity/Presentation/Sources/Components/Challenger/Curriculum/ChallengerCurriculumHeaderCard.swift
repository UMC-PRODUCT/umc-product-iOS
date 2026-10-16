//
//  ChallengerCurriculumHeaderCard.swift
//  ActivityPresentation
//
//  Created by jaewon Lee on 7/15/26.
//

import SwiftUI
import ActivityDomain
import CoreDesignSystem
import CoreUIComponents

struct ChallengerCurriculumHeaderCard: View, Equatable {

    // MARK: - Property

    let model: CurriculumHeaderModel

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing16) {
            HStack(spacing: DefaultSpacing.spacing12) {
                CardIconImage(
                    image: "book.fill",
                    color: model.partColor,
                    isLoading: .constant(false)
                )

                Text(model.partName)
                    .appFont(.callout, weight: .semibold, color: model.partColor)
            }

            Text(model.curriculumTitle)
                .appFont(.callout, weight: .semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DefaultConstant.defaultCardPadding)
        .background {
            ConcentricRectangle(
                corners: .concentric(minimum: DefaultConstant.concentricRadius),
                isUniform: true
            )
            .fill(Color.white)
            .cardShadow()
        }
    }
}

#if DEBUG
#Preview {
    ChallengerCurriculumHeaderCard(model: MissionPreviewData.sampleHeader)
        .padding()
        .background(Color.grey100)
}
#endif
