//
//  NoticeAlarmView.swift
//  AppProduct
//
//  Created by euijjang97 on 1/20/26.
//

import SwiftUI
import SwiftData
import Playgrounds

struct NoticeAlarmView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \NoticeHistoryData.createdAt, order: .reverse)
    var notice: [NoticeHistoryData]
    
    
    var body: some View {
        Form {
            if notice.isEmpty {
                unavailableView
            } else {
                alarmHistoryView
            }
        }
        .navigation(naviTitle: .noticeAlarmType, displayMode: .inline)
    }
    
    private var unavailableView: some View {
        ContentUnavailableView(
            "알림 내역이 없습니다.",
            systemImage: "bell.slash",
            description: Text("새로운 소식이 도착하면 이곳에 표시됩니다.")
        )
    }
    
    private var alarmHistoryView: some View {
        ForEach(notice, id: \.hashValue) { notice in
            NoticeAlarmCard(notice: notice)
        }
        .onDelete(perform: deleteNotices)
    }
    
    private func deleteNotices(at offsets: IndexSet) {
        for index in offsets {
            let noticeToDelete = notice[index]
            modelContext.delete(noticeToDelete)
        }
    }
}

#Preview("네비게이션 진입 테스트") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: NoticeHistoryData.self, configurations: config)
    
    let sampleData: [NoticeHistoryData] = [
        NoticeHistoryData(title: "중앙 해커톤 참여 확정", content: "축하합니다!", createdAt: .now),
        NoticeHistoryData(title: "정기 세션 불참 경고", content: "무단 결석", createdAt: .now),
        NoticeHistoryData(title: "운영진 면접 결과", content: "불합격", createdAt: .now)
    ]
    
    for item in sampleData {
        container.mainContext.insert(item)
    }
    
    return NavigationStack {
        VStack {
            Text("메인 화면이라고 가정")
                .font(.headline)
                .padding()
            
            NavigationLink("알림 화면으로 진입 >") {
                NoticeAlarmView()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .navigationTitle("메인")
    }
    .modelContainer(container)
}

#Playground {
    let repository = NoticeClassifierRepositoryImpl()
    let useCase = NoticeClassifierUseCaseImpl(repository: repository)
    
    let testCases = [
        ("중앙 해커톤 참여 확정", "축하합니다!"),
        ("정기 세션 불참 경고", "무단 결석으로 경고가 누적되었습니다"),
        ("운영진 면접 결과 안내", "아쉽게도 불합격"),
        ("12기 활동 가이드라인", "필독 가이드라인을 확인해주세요"),
        ("결제 완료", "결제가 성공적으로 완료되었습니다"),
        ("과제 제출 마감 임박", "3일 남았습니다"),
    ]
    
    print("=== CoreML 분류 테스트 ===\n")
    
    for (title, content) in testCases {
        let result = useCase.execute(title: title, content: content)
        print("📢 제목: \(title)")
        print("   내용: \(content)")
        print("   결과: \(result.rawValue) \(result.image)")
        print("   색상: \(result.color)")
        print()
    }
}
