//
//  StudyManagementCard.swift
//  AppProduct
//
//  Created by 이예지 on 1/8/26.
//

import SwiftUI

// MARK: - StudyManagementCard

struct StudyManagementCard: View {
    
    // MARK: - Property
    
    let studyManagementItem: StudyManagementItem

    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 15) {
            StudyImagePresenter(studyManagementItem: studyManagementItem)
            StudyTextPresenter(studyManagementItem: studyManagementItem)
            Spacer()
            StudyChevronPresenter()
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.border)
        )
    }
}


// MARK: - StudyImagePresenter
/// 프로필 사진
struct StudyImagePresenter: View, Equatable {
    
    let studyManagementItem: StudyManagementItem
    
    var body: some View {
        Image(studyManagementItem.profile)
            .resizable()
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            .aspectRatio(contentMode: .fit)
    }
}

// MARK: - StudyTextPresenter
/// 이름, 파트, 학교, 과제제출명
struct StudyTextPresenter: View, Equatable {
    
    let studyManagementItem: StudyManagementItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(studyManagementItem.name)
                    .font(.app(.callout, weight: .bold))
                    
                Text(studyManagementItem.part)
                    .font(.app(.caption2, weight: .regular))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.border)
                            .foregroundStyle(.clear)
                    )
            }
            
            HStack {
                Text(studyManagementItem.school)
                    .font(.app(.footnote, weight: .regular))
                    .foregroundStyle(Color.neutral700)
                
                Rectangle()
                    .frame(width: 1, height: 16)
                    .foregroundStyle(Color.border)
                
                HStack(spacing: 5) {
                    Image(systemName: "text.document")
                        .resizable()
                        .frame(width: 9, height: 11)
                    
                    Text(studyManagementItem.title)
                        .font(.app(.footnote, weight: .regular))
                }
                .foregroundStyle(Color.primary500)
            }
        }
    }
}

// MARK: - StudyChevronPresenter
/// 스와이프 표시
struct StudyChevronPresenter: View, Equatable {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "chevron.right")
                .resizable()
                .frame(width: 4, height: 8)
            
            Text("스와이프")
                .font(.app(.caption2, weight: .regular))
        }
        .foregroundStyle(Color.border)
    }
}


// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    StudyManagementCard(studyManagementItem: StudyManagementItem(profile: .profile, name: "이예지", school: "가천대학교", part: "iOS", title: "SwiftUI로 화면 구성하기", state: .examine))
        
}
