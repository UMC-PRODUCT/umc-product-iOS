//
//  SelectedChallenger.swift
//  AppProduct
//
//  Created by euijjang97 on 1/25/26.
//

import SwiftUI

/// 일정 등록 화면에서 챌린저 추가 화면 클릭 시 보여지는 뷰입니다.
///
/// 선택된 챌린저 목록을 확인하고, 새로운 챌린저를 검색하여 추가하거나 삭제할 수 있는 기능을 제공합니다.
struct SelectedChallengerView: View {
    
    // MARK: - Properties
    
    /// 외부에서 주입받는 선택된 챌린저 목록 (Binding)
    ///
    /// 이 배열은 상위 뷰와 공유되며, 챌린저 추가 및 삭제 시 실시간으로 업데이트됩니다.
    @Binding var challenger: [Participant]
    
    /// 챌린저 검색 화면으로의 네비게이션 활성화 여부
    @State var searchNavi: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle("초대할 챌린저")
                .navigationSubtitle("총 \(challenger.count)명")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(content: {
                    // 취소 버튼 (현재 기능 없음)
                    ToolBarCollection.CancelBtn(action: {})
                    
                    // 챌린저 추가 버튼 (검색 화면으로 이동)
                    ToolBarCollection.AddBtn(action: {
                        searchNavi = true
                    })
                })
                // 검색 화면으로 네비게이션 이동
                .navigationDestination(isPresented: $searchNavi, destination: {
                    SearchChallengerView(selectedChallengers: $challenger)
                })
        }
    }
    
    // MARK: - Private Views
    
    /// 챌린저 목록의 존재 여부에 따라 보여질 뷰를 결정하는 메인 컨텐츠 뷰
    @ViewBuilder
    private var content: some View {
        if challenger.isEmpty {
            unSelectedContent
        } else {
            ChallengerFormView(challenger: $challenger, isDeletAction: true)
        }
    }
    
    /// 선택된 챌린저가 없을 때 나타나는 안내 뷰
    private var unSelectedContent: some View {
        ContentUnavailableView(
            "선택된 챌린저가 없습니다",
            systemImage: "person.3.fill",
            description: Text("새로운 챌린저를 초대하여 함께 도전해보세요.")
        )
    }
}

#Preview {
    @Previewable @State var challenger: [Participant] = .init()
    SelectedChallengerView(challenger: $challenger)
}
