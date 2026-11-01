//
//  ProhibitedTextCatalog.swift
//  UMCFoundation
//
//  Created by euijjang97 on 10/29/26.
//

/// 운영 정책의 ID·분류·원문을 보존한 오프라인 목록. 임의 유사어는 추가하지 않는다.
enum ProhibitedTextCatalog {
    enum Category: String, Sendable {
        case nationality = "혐오·차별 표현 — 국가·민족·인종"
        case region = "혐오·차별 표현 — 지역"
        case gender = "혐오·차별 표현 — 성별"
        case sexualOrientation = "혐오·차별 표현 — 성적 지향"
        case age = "혐오·차별 표현 — 나이"
        case disability = "혐오·차별 표현 — 장애"
        case religion = "혐오·차별 표현 — 종교"
        case illness = "혐오·차별 표현 — 질병"
        case socialStatus = "혐오·차별 표현 — 사회적 신분·직업·경제적 지위"
        case insult = "욕설·인신모욕"
        case sexualInsult = "성희롱·성적 모욕"
        case violence = "폭력·신체적 위협"
        case selfHarm = "자해·자살 조장"
        case privacy = "개인정보 노출·괴롭힘"
    }

    struct Entry: Sendable {
        let id: String
        let category: Category
        let text: String
    }

    static let entries: [Entry] = [
        // 혐오·차별 표현 — 국가·민족·인종
        Entry(id: "H001", category: .nationality, text: "짱깨"),
        Entry(id: "H002", category: .nationality, text: "짱꼴라"),
        Entry(id: "H003", category: .nationality, text: "중궈충"),
        Entry(id: "H004", category: .nationality, text: "중국충"),
        Entry(id: "H005", category: .nationality, text: "쪽바리"),
        Entry(id: "H006", category: .nationality, text: "일본충"),
        Entry(id: "H007", category: .nationality, text: "조센징"),
        Entry(id: "H008", category: .nationality, text: "조센족충"),
        Entry(id: "H009", category: .nationality, text: "똥남아"),
        Entry(id: "H010", category: .nationality, text: "동남아충"),
        Entry(id: "H011", category: .nationality, text: "베트남충"),
        Entry(id: "H012", category: .nationality, text: "깜둥이"),
        Entry(id: "H013", category: .nationality, text: "검둥이새끼"),
        Entry(id: "H014", category: .nationality, text: "니거"),
        Entry(id: "H015", category: .nationality, text: "nigger"),
        Entry(id: "H016", category: .nationality, text: "코쟁이새끼"),
        Entry(id: "H017", category: .nationality, text: "혼혈잡종"),
        Entry(id: "H018", category: .nationality, text: "양키새끼"),
        // 혐오·차별 표현 — 지역
        Entry(id: "H019", category: .region, text: "전라디언"),
        Entry(id: "H020", category: .region, text: "전라도홍어"),
        Entry(id: "H021", category: .region, text: "홍어충"),
        Entry(id: "H022", category: .region, text: "홍어새끼"),
        Entry(id: "H023", category: .region, text: "개쌍도"),
        Entry(id: "H024", category: .region, text: "경상도충"),
        Entry(id: "H025", category: .region, text: "전라도충"),
        Entry(id: "H026", category: .region, text: "경상디언"),
        // 혐오·차별 표현 — 성별
        Entry(id: "H027", category: .gender, text: "한남충"),
        Entry(id: "H028", category: .gender, text: "한녀충"),
        Entry(id: "H029", category: .gender, text: "김치녀"),
        Entry(id: "H030", category: .gender, text: "김치남"),
        Entry(id: "H031", category: .gender, text: "된장녀"),
        Entry(id: "H032", category: .gender, text: "된장남"),
        Entry(id: "H033", category: .gender, text: "맘충"),
        Entry(id: "H034", category: .gender, text: "한남새끼"),
        Entry(id: "H035", category: .gender, text: "한녀년"),
        Entry(id: "H036", category: .gender, text: "보슬아치"),
        // 혐오·차별 표현 — 성적 지향
        Entry(id: "H037", category: .sexualOrientation, text: "게이충"),
        Entry(id: "H038", category: .sexualOrientation, text: "레즈충"),
        Entry(id: "H039", category: .sexualOrientation, text: "호모충"),
        Entry(id: "H040", category: .sexualOrientation, text: "동성애충"),
        Entry(id: "H041", category: .sexualOrientation, text: "게이새끼"),
        Entry(id: "H042", category: .sexualOrientation, text: "레즈년"),
        Entry(id: "H043", category: .sexualOrientation, text: "호모새끼"),
        Entry(id: "H044", category: .sexualOrientation, text: "동성애자충"),
        // 혐오·차별 표현 — 나이
        Entry(id: "H045", category: .age, text: "틀딱"),
        Entry(id: "H046", category: .age, text: "노인충"),
        Entry(id: "H047", category: .age, text: "할배충"),
        Entry(id: "H048", category: .age, text: "할매충"),
        Entry(id: "H049", category: .age, text: "급식충"),
        Entry(id: "H050", category: .age, text: "초딩충"),
        Entry(id: "H051", category: .age, text: "중딩충"),
        // 혐오·차별 표현 — 장애
        Entry(id: "H052", category: .disability, text: "장애충"),
        Entry(id: "H053", category: .disability, text: "장애인충"),
        Entry(id: "H054", category: .disability, text: "장애인새끼"),
        Entry(id: "H055", category: .disability, text: "병신"),
        Entry(id: "H056", category: .disability, text: "정박아"),
        Entry(id: "H057", category: .disability, text: "애자새끼"),
        Entry(id: "H058", category: .disability, text: "벙어리새끼"),
        Entry(id: "H059", category: .disability, text: "절름발이새끼"),
        Entry(id: "H060", category: .disability, text: "난쟁이새끼"),
        Entry(id: "H061", category: .disability, text: "저능아새끼"),
        // 혐오·차별 표현 — 종교
        Entry(id: "H062", category: .religion, text: "개독"),
        Entry(id: "H063", category: .religion, text: "예수쟁이"),
        Entry(id: "H064", category: .religion, text: "기독교충"),
        Entry(id: "H065", category: .religion, text: "개신교충"),
        Entry(id: "H066", category: .religion, text: "예수충"),
        Entry(id: "H067", category: .religion, text: "개슬람"),
        Entry(id: "H068", category: .religion, text: "무슬림충"),
        // 혐오·차별 표현 — 질병
        Entry(id: "H069", category: .illness, text: "정신병자충"),
        Entry(id: "H070", category: .illness, text: "정신병자새끼"),
        Entry(id: "H071", category: .illness, text: "조현병충"),
        Entry(id: "H072", category: .illness, text: "에이즈충"),
        Entry(id: "H073", category: .illness, text: "암환자충"),
        Entry(id: "H074", category: .illness, text: "치매충"),
        // 혐오·차별 표현 — 사회적 신분·직업·경제적 지위
        Entry(id: "H075", category: .socialStatus, text: "외노자충"),
        Entry(id: "H076", category: .socialStatus, text: "난민충"),
        Entry(id: "H077", category: .socialStatus, text: "다문화충"),
        Entry(id: "H078", category: .socialStatus, text: "노숙자충"),
        Entry(id: "H079", category: .socialStatus, text: "흙수저충"),
        Entry(id: "H080", category: .socialStatus, text: "기초수급충"),
        Entry(id: "H081", category: .socialStatus, text: "백수충"),
        Entry(id: "H082", category: .socialStatus, text: "딸배충"),
        Entry(id: "H083", category: .socialStatus, text: "노가다충"),
        Entry(id: "H084", category: .socialStatus, text: "택배충"),
        Entry(id: "H085", category: .socialStatus, text: "알바충"),
        Entry(id: "H086", category: .socialStatus, text: "배달충"),
        // 욕설·인신모욕
        Entry(id: "A001", category: .insult, text: "씨발"),
        Entry(id: "A002", category: .insult, text: "씨팔"),
        Entry(id: "A003", category: .insult, text: "시부랄"),
        Entry(id: "A004", category: .insult, text: "씨부랄"),
        Entry(id: "A005", category: .insult, text: "개새끼"),
        Entry(id: "A006", category: .insult, text: "개색기"),
        Entry(id: "A007", category: .insult, text: "개색끼"),
        Entry(id: "A008", category: .insult, text: "개쉐끼"),
        Entry(id: "A009", category: .insult, text: "개쉑"),
        Entry(id: "A010", category: .insult, text: "개놈"),
        Entry(id: "A011", category: .insult, text: "개년"),
        Entry(id: "A012", category: .insult, text: "좆까"),
        Entry(id: "A013", category: .insult, text: "좆같"),
        Entry(id: "A014", category: .insult, text: "좆밥"),
        Entry(id: "A015", category: .insult, text: "좆병신"),
        Entry(id: "A016", category: .insult, text: "지랄"),
        Entry(id: "A017", category: .insult, text: "염병"),
        Entry(id: "A018", category: .insult, text: "썅년"),
        Entry(id: "A019", category: .insult, text: "썅놈"),
        // 성희롱·성적 모욕
        Entry(id: "S001", category: .sexualInsult, text: "육변기"),
        Entry(id: "S002", category: .sexualInsult, text: "정액받이"),
        Entry(id: "S003", category: .sexualInsult, text: "섹스노예"),
        Entry(id: "S004", category: .sexualInsult, text: "성노예"),
        Entry(id: "S005", category: .sexualInsult, text: "씹걸레"),
        Entry(id: "S006", category: .sexualInsult, text: "걸레년"),
        Entry(id: "S007", category: .sexualInsult, text: "씨받이년"),
        Entry(id: "S008", category: .sexualInsult, text: "호빠새끼"),
        Entry(id: "S009", category: .sexualInsult, text: "남창새끼"),
        Entry(id: "S010", category: .sexualInsult, text: "창놈새끼"),
        // 폭력·신체적 위협
        Entry(id: "V001", category: .violence, text: "죽여버리"),
        Entry(id: "V002", category: .violence, text: "패죽이"),
        Entry(id: "V003", category: .violence, text: "칼로찌르"),
        Entry(id: "V004", category: .violence, text: "칼빵놓"),
        Entry(id: "V005", category: .violence, text: "목졸라죽"),
        Entry(id: "V006", category: .violence, text: "뼈부러뜨리"),
        Entry(id: "V007", category: .violence, text: "다리부러뜨리"),
        Entry(id: "V008", category: .violence, text: "손가락부러뜨리"),
        Entry(id: "V009", category: .violence, text: "테러하겠"),
        Entry(id: "V010", category: .violence, text: "테러해버리"),
        // 자해·자살 조장
        Entry(id: "SH001", category: .selfHarm, text: "자살해라"),
        Entry(id: "SH002", category: .selfHarm, text: "자살해버려"),
        Entry(id: "SH003", category: .selfHarm, text: "목매라"),
        Entry(id: "SH004", category: .selfHarm, text: "손목그어라"),
        Entry(id: "SH005", category: .selfHarm, text: "죽는게답"),
        // 개인정보 노출·괴롭힘
        Entry(id: "P001", category: .privacy, text: "신상털"),
        Entry(id: "P002", category: .privacy, text: "신상뿌리"),
        Entry(id: "P003", category: .privacy, text: "주소뿌리"),
        Entry(id: "P004", category: .privacy, text: "전화번호뿌리"),
        Entry(id: "P005", category: .privacy, text: "개인정보뿌리"),
    ]
}
