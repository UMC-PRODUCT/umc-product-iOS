//
//  StudyManagementCard.swift
//  AppProduct
//
//  Created by 이예지 on 1/8/26.
//

import SwiftUI

// MARK: - StudyManagementCard
struct StudyManagementCard: View, Equatable {
    
    // MARK: - Property
    let studyManagementItem: StudyManagementItem

    // MARK: - Constants
    fileprivate enum Constants {
        static let hstackSpacing: CGFloat = 15
        static let innerPadding: CGFloat = 16
        static let radius: CGFloat = 14
    }
    
    // MARK: - Body
    var body: some View {
        HStack(spacing: Constants.hstackSpacing) {
            StudyImagePresenter(studyManagementItem: studyManagementItem)
            StudyTextPresenter(studyManagementItem: studyManagementItem)
            Spacer()
            StudyChevronPresenter()
        }
        .padding(Constants.innerPadding)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: Constants.radius)
                .strokeBorder(.grey000)
        }
    }
}


// MARK: - StudyImagePresenter
/// 프로필 사진
/// CoreStudyManagementCard에서도 쓰이는 struct
struct StudyImagePresenter: View, Equatable {
    
    // MARK: - Property
    let studyManagementItem: StudyManagementItem

    // MARK: - Constants
    fileprivate enum Constants {
        static let imageSize: CGSize = .init(width: 40, height: 40)
    }
    
    // MARK: - Body
    var body: some View {
        Image(studyManagementItem.profile ?? "")
            .resizable()
            .frame(width: Constants.imageSize.width, height: Constants.imageSize.height)
            .clipShape(Circle())
            .aspectRatio(contentMode: .fit)
    }
}

// MARK: - StudyTextPresenter
private struct StudyTextPresenter: View, Equatable {
    
    // MARK: - Property
    let studyManagementItem: StudyManagementItem
    
    // MARK: - Constants
    fileprivate enum Constants {
        static let vstackSpacing: CGFloat = 5
    }
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.vstackSpacing) {
            StudyTopTextPresenter(studyManagementItem: studyManagementItem)
            
            StudyBottomTextPresenter(studyManagementItem: studyManagementItem)
        }
    }
}

// MARK: - StudyTopTextPresenter
/// 이름, 파트
private struct StudyTopTextPresenter: View, Equatable {
    
    // MARK: - Property
    let studyManagementItem: StudyManagementItem

    // MARK: - Constants
    fileprivate enum Constants {
        static let horizonPadding: CGFloat = 4
        static let verticalPadding: CGFloat = 2
        static let radius: CGFloat = 8
    }
    
    // MARK: - Body
    var body: some View {
        HStack {
            Text(studyManagementItem.name)
                .appFont(.calloutEmphasis)
                .foregroundStyle(.grey800)
            
            Text(studyManagementItem.part)
                .font(.app(.caption1, weight: .regular))
                .padding(.horizontal, Constants.horizonPadding)
                .padding(.vertical, Constants.verticalPadding)
                .overlay(
                    RoundedRectangle(cornerRadius: Constants.radius)
                        .strokeBorder(.grey200)
                        .foregroundStyle(.clear)
                )
        }
    }
}

// MARK: - StudyBottomTextPresenter
/// 학교, 과제제출명
private struct StudyBottomTextPresenter: View, Equatable {
    
    // MARK: - Property
    let studyManagementItem: StudyManagementItem

    // MARK: - Constants
    fileprivate enum Constants {
        static let rectangleSize: CGSize = .init(width: 1, height: 16)
        static let hstackSpacing: CGFloat = 5
        static let imageSize: CGSize = .init(width: 9, height: 11)
    }
    
    // MARK: - Body
    var body: some View {
        HStack {
            Text(studyManagementItem.school)
                .font(.app(.footnote, weight: .regular))
                .foregroundStyle(Color.grey600)
            
            Rectangle()
                .frame(width: Constants.rectangleSize.width, height: Constants.rectangleSize.height)
                .foregroundStyle(Color.grey600)
            
            HStack(spacing: Constants.hstackSpacing) {
                Image(systemName: "text.document")
                    .resizable()
                    .frame(width: Constants.imageSize.width, height: Constants.imageSize.height)
                
                Text(studyManagementItem.title)
                    .font(.app(.footnote, weight: .regular))
            }
            .foregroundStyle(Color.indigo400)
        }
    }
}



// MARK: - StudyChevronPresenter
/// 스와이프 표시
private struct StudyChevronPresenter: View, Equatable {

    // MARK: - Constants
    fileprivate enum Constants {
        static let vstackSpacing: CGFloat = 6
        static let imageSize: CGSize = .init(width: 4, height: 8)
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: Constants.vstackSpacing) {
            Image(systemName: "chevron.right")
                .resizable()
                .frame(width: Constants.imageSize.width, height: Constants.imageSize.height)
            
            Text("스와이프")
                .font(.app(.caption2, weight: .regular))
        }
        .foregroundStyle(Color.grey600)
    }
}


// MARK: - Preview
#Preview(traits: .sizeThatFitsLayout) {
    StudyManagementCard(studyManagementItem: StudyManagementItem(profile: nil, name: "이예지", school: "가천대학교", part: "iOS", title: "SwiftUI로 화면 구성하기", state: .examine))
        
}
