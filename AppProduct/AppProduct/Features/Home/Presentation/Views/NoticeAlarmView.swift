//
//  NoticeAlarmView.swift
//  AppProduct
//
//  Created by euijjang97 on 1/20/26.
//

import SwiftUI
import SwiftData

/// 알림 내역을 보여주는 뷰입니다.
struct NoticeAlarmView: View {
    
    // MARK: - Properties
    
    /// SwiftData 모델 컨텍스트
    @Environment(\.modelContext) private var modelContext
    
    /// 저장된 알림 내역 데이터 (최신순 정렬)
    @Query(sort: \NoticeHistoryData.createdAt, order: .reverse)
    private var notices: [NoticeHistoryData]
    
    
    // MARK: - Body
    
    var body: some View {
        Form {
            if notices.isEmpty {
                unavailableView
            } else {
                alarmHistoryView
            }
        }
        // 네비게이션 설정 (타이틀 및 모드)
        .navigation(naviTitle: .noticeAlarmType, displayMode: .inline)
        .toolbar {
            if !notices.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("전체 삭제", role: .destructive) {
                        deleteAllNotices()
                    }
                }
            }
        }
    }
    
    // MARK: - UI Components
    
    /// 알림 내역이 없을 때 표시되는 뷰
    private var unavailableView: some View {
        ContentUnavailableView(
            "알림 내역이 없습니다.",
            systemImage: "bell.slash",
            description: Text("새로운 소식이 도착하면 이곳에 표시됩니다.")
        )
    }

    /// 알림 내역 리스트 뷰
    private var alarmHistoryView: some View {
        Section {
            ForEach(notices) { notice in
                NoticeAlarmCard(notice: notice)
            }
            .onDelete(perform: deleteNotices)
        }
    }
    
    // MARK: - Methods
    
    /// 밀어서 삭제하기 동작 처리
    /// - Parameter offsets: 삭제할 인덱스 셋
    private func deleteNotices(at offsets: IndexSet) {
        for index in offsets {
            let noticeToDelete = notices[index]
            modelContext.delete(noticeToDelete)
        }
        try? modelContext.save()
    }

    /// 전체 알림 삭제
    private func deleteAllNotices() {
        for notice in notices {
            modelContext.delete(notice)
        }
        try? modelContext.save()
    }
}

#Preview("네비게이션 진입 테스트") {
    NavigationStack {
        NoticeAlarmPreviewSeedView()
    }
    .modelContainer(
        for: [NoticeHistoryData.self, GenerationMappingRecord.self],
        inMemory: true
    )
}

#Preview("알림 히스토리 더미") {
    NavigationStack {
        NoticeAlarmPreviewSeedView()
    }
    .modelContainer(
        for: [NoticeHistoryData.self, GenerationMappingRecord.self],
        inMemory: true
    )
}

private struct NoticeAlarmPreviewSeedView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \NoticeHistoryData.createdAt, order: .reverse)
    private var notices: [NoticeHistoryData]

    var body: some View {
        NoticeAlarmView()
            .task {
                guard notices.isEmpty else { return }
                seedDummyNotices(modelContext: modelContext)
            }
    }
}

private func seedDummyNotices(modelContext: ModelContext) {
    let dummyNotices: [NoticeHistoryData] = [
        NoticeHistoryData(
            title: "중앙 해커톤 참여 확정",
            content: "축하합니다! 해커톤 참가가 확정되었습니다.",
            icon: .success,
            createdAt: .now.addingTimeInterval(-60 * 5)
        ),
        NoticeHistoryData(
            title: "정기 세션 불참 경고",
            content: "무단 결석 1회가 누적되었습니다.",
            icon: .warning,
            createdAt: .now.addingTimeInterval(-60 * 30)
        ),
        NoticeHistoryData(
            title: "운영진 면접 결과 안내",
            content: "이번 기수 운영진 면접 결과를 확인해주세요.",
            icon: .info,
            createdAt: .now.addingTimeInterval(-60 * 60 * 2)
        ),
        NoticeHistoryData(
            title: "출석 점검 필요",
            content: "출석률이 기준 미만입니다. 다음 세션 출석이 필요합니다.",
            icon: .error,
            createdAt: .now.addingTimeInterval(-60 * 60 * 24)
        )
    ]

    dummyNotices.forEach { modelContext.insert($0) }
    try? modelContext.save()
}
