//
//  Project.swift
//  Community
//
//  Created by euijjang97 on 3/6/26.
//

import ProjectDescription
import ProjectDescriptionHelpers

let project = featureProject(
    name: "Community",
    domainExtraDependencies: [
        // 공지 링크 카드(#1142)의 메타를 NoticeDomain 의 공지 상세 조회에서 가져온다.
        .project(target: "NoticeDomain", path: .relativeToRoot("Features/Notice")),
    ],
    presentationExtraDependencies: [
        .project(target: "CoreDI", path: .relativeToRoot("Core/DI")),
        .project(target: "CoreDomain", path: .relativeToRoot("Core/Domain")),
        .project(target: "CoreRouting", path: .relativeToRoot("Core/Routing")),
        // 스레드 생성의 챌린저 초대(#1325)가 Activity 의 챌린저 검색 UI(SelectedChallengerView)를
        // 그대로 쓴다. ActivityDomain 은 그 이니셜라이저의 검색 UseCase 타입 해석에 필요하다.
        // 일정 등록(`Features/Home/Project.swift`)이 같은 이유로 이미 같은 쌍을 참조하고 있고,
        // Activity 쪽은 HomeDomain 만 참조하므로 타겟 그래프에 순환이 생기지 않는다.
        .project(target: "ActivityDomain", path: .relativeToRoot("Features/Activity")),
        .project(target: "ActivityPresentation", path: .relativeToRoot("Features/Activity")),
        // 공지 링크 카드 탭이 상위로 넘기는 값이 `NoticeDomain.NoticeDetail` 이다.
        .project(target: "NoticeDomain", path: .relativeToRoot("Features/Notice")),
    ],
    includesDomainTests: true,
    includesDataTests: true,
    dataTestDependencies: [
        .target(name: "CommunityDomain"),
        .project(target: "CoreNetwork", path: .relativeToRoot("Core/Network")),
        .project(target: "UMCFoundation", path: .relativeToRoot("Core/Foundation")),
    ],
    includesPresentationTests: true,
    presentationTestDependencies: [
        .target(name: "CommunityDomain"),
        // 생성 폼의 초대 선택 상태가 `CoreDomain.ChallengerInfo` 배열이다.
        .project(target: "CoreDomain", path: .relativeToRoot("Core/Domain")),
        .project(target: "UMCFoundation", path: .relativeToRoot("Core/Foundation")),
    ]
)
