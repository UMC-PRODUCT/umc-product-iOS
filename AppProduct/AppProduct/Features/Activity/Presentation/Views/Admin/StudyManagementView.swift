//
//  StudyManagementView.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/23/26.
//

import SwiftUI

/// Admin 모드의 스터디 관리 섹션
///
/// 운영진이 스터디와 활동을 관리하는 화면입니다.
struct StudyManagementView: View {
    var body: some View {
        ScrollView {
            ContentUnavailableView {
                Label("스터디 관리", systemImage: "book.pages.fill")
            } description: {
                Text("스터디 생성, 수정, 삭제 등 스터디를 관리합니다")
            }
            .safeAreaPadding(.vertical, DefaultConstant.defaultSafeBottom)
        }
    }
}

#Preview {
    StudyManagementView()
}
