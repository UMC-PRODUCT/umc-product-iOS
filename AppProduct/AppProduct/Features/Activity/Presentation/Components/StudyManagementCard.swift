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
        List {
            ForEach(1..<10) { _ in
                HStack {
                    ImagePresenter(studyManagementItem: studyManagementItem)
                    TextPresenter(studyManagementItem: studyManagementItem)
                    ChevronPresenter()
                }
                .padding(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.border)
                )
                .swipeActions(edge: .leading) {
                    Button(action: {}, label: {
                        SwipeButtonPresenter(swipeButtonType: .best)
                    })
                    Button(action: {}, label: {
                        SwipeButtonPresenter(swipeButtonType: .review)
                    })
                }
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
    }
}


// MARK: - ImagePresenter
/// 프로필 사진
struct ImagePresenter: View, Equatable {
    
    let studyManagementItem: StudyManagementItem
    
    var body: some View {
        Image(studyManagementItem.profile)
            .resizable()
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            .aspectRatio(contentMode: .fit)
    }
}

// MARK: - TextPresenter
/// 이름, 파트, 학교, 과제제출명
struct TextPresenter: View, Equatable {
    
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
                            .stroke(Color.border)
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

// MARK: - ChevronPresenter
/// 스와이프 표시
struct ChevronPresenter: View, Equatable {
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


// MARK: - SwipeButtonPresenter
/// 왼쪽 스와이프 시 보이는 버튼(베스트, 검토)
struct SwipeButtonPresenter: View, Equatable {
    
    let swipeButtonType: SwipeButtonType
    
    enum SwipeButtonType: String {
        case best = "베스트"
        case review = "검토"
        
        var icon: Image {
            switch self {
            case .best:
                return Image(systemName: "gift")
            case .review:
                return Image(systemName: "checkmark.circle")
            }
        }
        
        var color: Color {
            switch self {
            case .best:
                return .warning700
            case .review:
                return .primary700
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 3) {
            swipeButtonType.icon
            
            Text(swipeButtonType.rawValue)
        }
        .foregroundStyle(swipeButtonType.color)
    }
}


// MARK: - Preview
#Preview {
    StudyManagementCard(studyManagementItem: StudyManagementItem(profile: .profile, name: "이예지", school: "가천대학교", part: "iOS", title: "SwiftUI로 화면 구성하기"))
}
