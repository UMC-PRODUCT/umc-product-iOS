//
//  CoreStudyManagementList.swift
//  AppProduct
//
//  Created by 이예지 on 1/10/26.
//

import SwiftUI

// MARK: - CoreStudyManagementList
struct CoreStudyManagementList: View {
    
    // MARK: - Property
    let studyManagementItem: StudyManagementItem
    
    // MARK: - Constant
    fileprivate enum Constants {
        static let horizontalPadding: CGFloat = 11
        static let verticalPadding: CGFloat = 8
    }
    
    // MARK: - Body
    var body: some View {
        HStack(spacing: DefaultSpacing.spacing12) {
            StudyImagePresenter(studyManagementItem: studyManagementItem)
            CoreStudyTextPresenter(
                name: studyManagementItem.name,
                part: studyManagementItem.part,
                title: studyManagementItem.title
            )
            Spacer()
            Text(studyManagementItem.state.rawValue)
                .appFont(.calloutEmphasis)
                .padding(.horizontal, Constants.horizontalPadding)
        }
        .padding(.vertical, Constants.verticalPadding)
    }
}

// MARK: - CoreStudyTextPresenter
/// 이름, 파트, 과제명
struct CoreStudyTextPresenter: View {
    
    let name: String
    let part: String
    let title: String
    
    private enum Constants {
        static let partPadding: EdgeInsets = .init(top: 2, leading: 4, bottom: 2, trailing: 4)
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(name)
                    .appFont(.calloutEmphasis)
                Text(part)
                    .font(.app(.caption2, weight: .regular))
                    .padding(Constants.partPadding)
                    .overlay(
                        RoundedRectangle(cornerRadius: DefaultConstant.cornerRadius)
                            .strokeBorder(Color.grey300)
                            .foregroundStyle(.clear)
                    )
            }
            Text(title)
                .font(.app(.footnote, weight: .regular))
                .foregroundStyle(Color.indigo500)
        }
    }
}

// MARK: - Preview
#Preview (traits: .sizeThatFitsLayout){
    CoreStudyManagementList(studyManagementItem: StudyManagementItem(profile: nil, name: "이예지", school: "가천대학교", part: "iOS", title: "SwiftUI로 화면 구성하기", state: StudySubmitState.examine))
}
