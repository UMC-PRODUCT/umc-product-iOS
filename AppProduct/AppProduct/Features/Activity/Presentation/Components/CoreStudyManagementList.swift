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
    
    // MARK: - Body
    var body: some View {
        HStack(spacing: 12) {
            StudyImagePresenter(studyManagementItem: studyManagementItem)
            CoreStudyTextPresenter(
                name: studyManagementItem.name,
                part: studyManagementItem.part,
                title: studyManagementItem.title
            )
            Spacer()
            Text(studyManagementItem.state.rawValue)
                .font(.app(.callout, weight: .bold))
                .padding(.horizontal, 11)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - CoreStudyTextPresenter
/// 이름, 파트, 과제명
struct CoreStudyTextPresenter: View {
    
    let name: String
    let part: String
    let title: String

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(name)
                    .font(.app(.callout, weight: .bold))
                Text(part)
                    .font(.app(.caption2, weight: .regular))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.grey300)
                            .foregroundStyle(.clear)
                    )
            }
            Text(title)
                .font(.app(.caption1, weight: .regular))
                .foregroundStyle(Color.indigo500)
        }
    }
}

// MARK: - Preview
#Preview (traits: .sizeThatFitsLayout){
    CoreStudyManagementList(studyManagementItem: StudyManagementItem(profile: .profile, name: "이예지", school: "가천대학교", part: "iOS", title: "SwiftUI로 화면 구성하기", state: StudySubmitState.examine))
}
