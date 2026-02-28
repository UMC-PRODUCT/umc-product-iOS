//
//  TagListView.swift
//  AppProduct
//
//  Created by euijjang97 on 1/23/26.
//

import SwiftUI

/// 태그 선택을 위한 리스트 뷰
struct TagListView: View {
    
    /// 선택된 태그 리스트 바인딩
    @Binding var tagList: [ScheduleIconCategory]
    
    var body: some View {
        NavigationStack {
            Form {
                ForEach(ScheduleIconCategory.allCases, id: \.self) { category in
                    TagRow(
                        category: category,
                        isSelected: tagList.contains(category),
                        tap: {
                            toggleSelection(category)
                        })
                    .equatable()
                }
            }
            .navigation(naviTitle: .tag, displayMode: .inline)
            .toolbar(content: {
                ToolBarCollection.CancelBtn(action: {
                    tagList.removeAll()
                })
                
                ToolBarCollection.ConfirmBtn(action: {})
            })
        }
    }
    
    /// 태그 선택 상태를 토글하는 메서드
    /// - Parameter category: 토글할 카테고리
    private func toggleSelection(_ category: ScheduleIconCategory) {
        if let index = tagList.firstIndex(of: category) {
            tagList.remove(at: index)
        } else {
            tagList.append(category)
        }
    }
}

// MARK: - TagRow
/// 개별 태그 행을 표시하는 뷰
fileprivate struct TagRow: View, Equatable {
    /// 태그 카테고리 정보
    let category: ScheduleIconCategory
    /// 선택 여부
    let isSelected: Bool
    /// 탭 액션 클로저
    let tap: () -> Void
    
    /// UI 상수
    private enum Constants {
        static let iconSize: CGFloat = 40
        static let checkMark: String = "checkmark.circle.fill"
        static let circle: String = "circle"
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.category == rhs.category &&
        lhs.isSelected == rhs.isSelected
    }
    
    var body: some View {
        Button(action: {
            tap()
        }, label: {
            HStack(spacing: DefaultSpacing.spacing12, content: {
                Image(systemName: category.symbol)
                    .font(.body)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Constants.iconSize, height: Constants.iconSize)
                    .foregroundStyle(.white)
                    .clipShape(.circle)
                    .glassEffect(.clear.tint(category.color), in: .circle)
                
                Text(category.korean)
                    .appFont(.body, color: .black)
                
                Spacer()
                
                Image(systemName: isSelected ? Constants.checkMark : Constants.circle)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .indigo500 : .grey300)
            })
            .contentShape(Rectangle())
        })
        .buttonStyle(.plain)
    }
}

#Preview {
    @Previewable @State var tagList: [ScheduleIconCategory] = .init()
    
    TagListView(tagList: $tagList)
}
