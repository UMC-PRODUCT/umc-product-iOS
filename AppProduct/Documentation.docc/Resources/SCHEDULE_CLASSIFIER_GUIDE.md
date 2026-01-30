# ScheduleListClassifierML 사용 가이드

일정 제목을 7가지 카테고리로 자동 분류하는 Core ML 모델 사용 및 학습 가이드입니다.

## 목차

1. [개요](#개요)
2. [분류 카테고리](#분류-카테고리)
3. [Swift 코드 사용법](#swift-코드-사용법)
4. [SwiftUI 통합](#swiftui-통합)
5. [모델 학습 방법](#모델-학습-방법)
6. [성능 최적화](#성능-최적화)
7. [FAQ](#faq)

---

## 개요

### 모델 정보

| 항목 | 내용 |
|------|------|
| **파일명** | ScheduleListClassifierML.mlmodel |
| **위치** | `AppProduct/AppleCreateML/ScheduleList/` |
| **모델 크기** | 약 9KB |
| **입력** | 일정 제목 (String) |
| **출력** | 카테고리 레이블 (leadership, study, project, event, workshop, meeting, deadline) |
| **목적** | 일정 카테고리 자동 태깅 및 필터링 |

### 모델 특징

- ✅ **온디바이스 실행**: 네트워크 없이 로컬에서 즉시 분류
- ✅ **초경량**: 9KB로 거의 용량 없음
- ✅ **빠른 속도**: 실시간 분류 가능
- ✅ **신뢰도 제공**: 분류 결과의 확률값 제공
- ✅ **한국어 최적화**: 한국어 일정 제목에 특화

---

## 분류 카테고리

### 1. leadership (리더십/운영)

**설명**: 리더십 교육, 운영진 활동, 조직 관리

**UI 표현**:
- 🟣 색상: `Color.purple`
- 👥 아이콘: `person.2.fill`
- 태그: "리더십"

**학습 데이터 예시**:
```
👥 "LT 리더십 강연"
👥 "단체 활동 OT"
👥 "운영진 회의"
👥 "파트 리더 미팅"
👥 "임원 워크샵"
👥 "리더십 트레이닝"
👥 "조직 문화 세션"
```

**사용 시나리오**:
- 리더십 교육 일정
- 운영진 미팅
- 조직 문화 활동

### 2. study (스터디/학습)

**설명**: 스터디 모임, 세미나, 학습 활동

**UI 표현**:
- 🔵 색상: `Color.blue`
- 📚 아이콘: `book.fill`
- 태그: "스터디"

**학습 데이터 예시**:
```
📚 "알고리즘 스터디"
📚 "React 기초 세미나"
📚 "Swift 스터디 모임"
📚 "데이터베이스 학습"
📚 "코딩 테스트 준비"
📚 "기술 스택 세미나"
```

**사용 시나리오**:
- 정기 스터디 일정
- 기술 세미나
- 학습 모임

### 3. project (프로젝트)

**설명**: 프로젝트 관련 일정, 발표, 제출

**UI 표현**:
- 🟢 색상: `Color.green`
- 💼 아이콘: `briefcase.fill`
- 태그: "프로젝트"

**학습 데이터 예시**:
```
💼 "중간 발표"
💼 "프로젝트 킥오프"
💼 "데모데이"
💼 "최종 결과물 제출"
💼 "프로젝트 회고"
💼 "클라이언트 미팅"
```

**사용 시나리오**:
- 프로젝트 마일스톤
- 발표 일정
- 결과물 제출

### 4. event (이벤트/행사)

**설명**: MT, 네트워킹, 행사

**UI 표현**:
- 🟡 색상: `Color.yellow`
- 🎉 아이콘: `party.popper.fill`
- 태그: "이벤트"

**학습 데이터 예시**:
```
🎉 "MT 출발"
🎉 "네트워킹 데이"
🎉 "송년회"
🎉 "신입생 환영회"
🎉 "해커톤 대회"
🎉 "체육대회"
```

**사용 시나리오**:
- MT, 워크숍
- 네트워킹 행사
- 동아리 행사

### 5. workshop (워크샵)

**설명**: 실습 중심 워크샵, 부트캠프

**UI 표현**:
- 🟠 색상: `Color.orange`
- 🛠️ 아이콘: `hammer.fill`
- 태그: "워크샵"

**학습 데이터 예시**:
```
🛠️ "디자인 워크샵"
🛠️ "코딩 부트캠프"
🛠️ "UI/UX 실습"
🛠️ "Git 실습 세션"
🛠️ "API 개발 워크샵"
```

**사용 시나리오**:
- 실습 세션
- 핸즈온 워크샵
- 부트캠프

### 6. meeting (회의)

**설명**: 정기 회의, 파트 미팅

**UI 표현**:
- ⚪ 색상: `Color.gray`
- 💬 아이콘: `bubble.left.and.bubble.right.fill`
- 태그: "회의"

**학습 데이터 예시**:
```
💬 "정기 회의"
💬 "파트 미팅"
💬 "주간 회의"
💬 "전체 회의"
💬 "기획 회의"
```

**사용 시나리오**:
- 정기 미팅
- 파트별 회의
- 기획 논의

### 7. deadline (마감/제출)

**설명**: 과제 마감, 제출 기한

**UI 표현**:
- 🔴 색상: `Color.red`
- ⏰ 아이콘: `clock.fill`
- 태그: "마감"

**학습 데이터 예시**:
```
⏰ "과제 제출"
⏰ "최종 발표"
⏰ "회비 납부 마감"
⏰ "신청 마감"
⏰ "결과물 제출"
```

**사용 시나리오**:
- 과제 제출 기한
- 신청 마감
- 납부 기한

---

## Swift 코드 사용법

### 1. ScheduleClassifier 구현

```swift
import CoreML
import NaturalLanguage

/// 일정 제목을 7가지 카테고리로 분류하는 분류기
final class ScheduleClassifier {
    // MARK: - Property

    private let model: ScheduleListClassifierML

    // MARK: - Initializer

    init() {
        do {
            let config = MLModelConfiguration()
            self.model = try ScheduleListClassifierML(configuration: config)
        } catch {
            fatalError("ScheduleListClassifierML 로드 실패: \(error)")
        }
    }

    // MARK: - Public Methods

    /// 일정 제목을 분류합니다.
    func classify(title: String) -> ScheduleCategory {
        do {
            let prediction = try model.prediction(text: title)
            return ScheduleCategory(rawValue: prediction.label) ?? .meeting
        } catch {
            print("[ScheduleClassifier] 분류 실패: \(error)")
            return .meeting
        }
    }

    /// 신뢰도와 함께 분류합니다.
    func classifyWithConfidence(title: String) -> (category: ScheduleCategory, confidence: Double) {
        do {
            let prediction = try model.prediction(text: title)
            let confidence = prediction.labelProbability[prediction.label] ?? 0.0

            return (
                category: ScheduleCategory(rawValue: prediction.label) ?? .meeting,
                confidence: confidence
            )
        } catch {
            return (.meeting, 0.0)
        }
    }

    /// 일정 리스트를 카테고리별로 그룹화합니다.
    func groupByCategory(_ schedules: [Schedule]) -> [ScheduleCategory: [Schedule]] {
        var grouped: [ScheduleCategory: [Schedule]] = [:]

        for schedule in schedules {
            let category = classify(title: schedule.title)
            grouped[category, default: []].append(schedule)
        }

        return grouped
    }

    /// 특정 카테고리의 일정만 필터링합니다.
    func filter(_ schedules: [Schedule], by category: ScheduleCategory) -> [Schedule] {
        schedules.filter { schedule in
            classify(title: schedule.title) == category
        }
    }
}
```

### 2. ScheduleCategory Enum

```swift
import SwiftUI

enum ScheduleCategory: String, CaseIterable, Codable {
    case leadership = "leadership"
    case study = "study"
    case project = "project"
    case event = "event"
    case workshop = "workshop"
    case meeting = "meeting"
    case deadline = "deadline"

    var color: Color {
        switch self {
        case .leadership: return .purple
        case .study: return .blue
        case .project: return .green
        case .event: return .yellow
        case .workshop: return .orange
        case .meeting: return .gray
        case .deadline: return .red
        }
    }

    var icon: String {
        switch self {
        case .leadership: return "person.2.fill"
        case .study: return "book.fill"
        case .project: return "briefcase.fill"
        case .event: return "party.popper.fill"
        case .workshop: return "hammer.fill"
        case .meeting: return "bubble.left.and.bubble.right.fill"
        case .deadline: return "clock.fill"
        }
    }

    var displayName: String {
        switch self {
        case .leadership: return "리더십"
        case .study: return "스터디"
        case .project: return "프로젝트"
        case .event: return "이벤트"
        case .workshop: return "워크샵"
        case .meeting: return "회의"
        case .deadline: return "마감"
        }
    }
}
```

### 3. 기본 사용 예시

```swift
let classifier = ScheduleClassifier()
let scheduleTitle = "알고리즘 스터디"
let category = classifier.classify(title: scheduleTitle)

print("카테고리: \(category.displayName)")  // "스터디"
print("색상: \(category.color)")              // Color.blue
print("아이콘: \(category.icon)")            // "book.fill"
```

---

## SwiftUI 통합

### 1. 일정 카드 뷰

```swift
struct ScheduleRowView: View {
    let schedule: Schedule
    @State private var classifier = ScheduleClassifier()

    var body: some View {
        let category = classifier.classify(title: schedule.title)

        HStack(spacing: 12) {
            // 카테고리 아이콘
            Image(systemName: category.icon)
                .foregroundColor(category.color)
                .frame(width: 40, height: 40)
                .background(category.color.opacity(0.2))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                // 일정 제목
                Text(schedule.title)
                    .font(.headline)

                HStack {
                    // 카테고리 태그
                    Text(category.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(category.color.opacity(0.2))
                        .foregroundColor(category.color)
                        .cornerRadius(8)

                    // 시간
                    Text(schedule.formattedTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(12)
    }
}
```

### 2. 캘린더 뷰

```swift
struct CalendarView: View {
    let schedules: [Schedule]
    @State private var classifier = ScheduleClassifier()
    @State private var selectedCategory: ScheduleCategory? = nil

    var filteredSchedules: [Schedule] {
        guard let category = selectedCategory else {
            return schedules
        }
        return classifier.filter(schedules, by: category)
    }

    var body: some View {
        VStack {
            // 카테고리 필터
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    CategoryFilterButton(
                        title: "전체",
                        icon: "list.bullet",
                        color: .gray,
                        isSelected: selectedCategory == nil
                    ) {
                        selectedCategory = nil
                    }

                    ForEach(ScheduleCategory.allCases, id: \.self) { category in
                        CategoryFilterButton(
                            title: category.displayName,
                            icon: category.icon,
                            color: category.color,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal)
            }

            // 일정 리스트
            List(filteredSchedules) { schedule in
                ScheduleRowView(schedule: schedule)
            }
        }
        .navigationTitle("일정")
    }
}

struct CategoryFilterButton: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? color : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}
```

### 3. 실시간 카테고리 예측

```swift
struct CreateScheduleView: View {
    @State private var title = ""
    @State private var predictedCategory: ScheduleCategory = .meeting
    @State private var classifier = ScheduleClassifier()

    var body: some View {
        Form {
            Section("일정 정보") {
                TextField("일정 제목", text: $title)
                    .onChange(of: title) { _, newValue in
                        predictedCategory = classifier.classify(title: newValue)
                    }
            }

            Section("자동 분류된 카테고리") {
                HStack {
                    Image(systemName: predictedCategory.icon)
                        .foregroundColor(predictedCategory.color)

                    Text(predictedCategory.displayName)
                        .foregroundColor(predictedCategory.color)

                    Spacer()

                    Text("AI 예측")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("일정 추가")
    }
}
```

---

## 모델 학습 방법

### 1. 학습 데이터 준비

**ScheduleTrainingData.json** 파일 형식:

```json
[
  {
    "text": "LT 리더십 강연",
    "label": "leadership"
  },
  {
    "text": "알고리즘 스터디",
    "label": "study"
  },
  {
    "text": "중간 발표",
    "label": "project"
  },
  {
    "text": "MT 출발",
    "label": "event"
  },
  {
    "text": "디자인 워크샵",
    "label": "workshop"
  },
  {
    "text": "정기 회의",
    "label": "meeting"
  },
  {
    "text": "과제 제출",
    "label": "deadline"
  }
]
```

**학습 데이터 작성 가이드**:

| 카테고리 | 최소 예제 수 | 권장 예제 수 | 중요 키워드 |
|---------|------------|------------|------------|
| leadership | 30개 | 50개 | LT, 리더십, 운영진, 임원 |
| study | 40개 | 70개 | 스터디, 세미나, 학습, 강의 |
| project | 30개 | 50개 | 프로젝트, 발표, 데모, 킥오프 |
| event | 30개 | 50개 | MT, 네트워킹, 행사, 파티 |
| workshop | 25개 | 40개 | 워크샵, 실습, 부트캠프 |
| meeting | 30개 | 50개 | 회의, 미팅, 논의 |
| deadline | 30개 | 50개 | 마감, 제출, 납부, 신청 |

### 2. Create ML로 모델 학습

#### Step 1: Create ML 프로젝트 생성

1. Xcode 실행
2. **File > New > Project**
3. **Other** 탭에서 **Create ML** 선택
4. 프로젝트 이름: `ScheduleListClassifierML`
5. 저장 위치: `AppProduct/AppleCreateML/ScheduleList/`

#### Step 2: 학습 데이터 가져오기

1. **Data** 탭 선택
2. **Training Data** 섹션에서 `+` 버튼 클릭
3. `ScheduleTrainingData.json` 파일 선택
4. **Text Column**: `text` 선택
5. **Label Column**: `label` 선택

#### Step 3: 데이터 분포 확인

**Training Data** 섹션에서 각 레이블별 데이터 수 확인:

```
leadership: 45개
study: 68개
project: 52개
event: 48개
workshop: 38개
meeting: 50개
deadline: 47개
──────────────────
총 348개
```

**균형 체크**:
- ✅ 각 레이블당 30개 이상
- ⚠️ 특정 레이블이 2배 이상 많으면 균형 조정 필요

#### Step 4: 검증 데이터 설정

**옵션 1: 자동 분할** (권장)
1. **Validation** 섹션에서 **Automatic** 선택
2. 학습 데이터의 20%가 자동으로 검증용으로 사용됨

**옵션 2: 별도 파일**
1. `ScheduleValidationData.json` 생성 (학습 데이터의 20%)
2. **Validation** 섹션에서 파일 선택

#### Step 5: 모델 학습

1. **Training** 탭 선택
2. **Algorithm**: `Transfer Learning` (권장)
   - 한국어 지원
   - 빠른 학습
   - 높은 정확도
3. **Language**: `Korean` 선택
4. **Max Iterations**: `25` (기본값)
5. **Train** 버튼 클릭

**학습 시간**: 약 30초~2분 (데이터 양에 따라)

#### Step 6: 모델 평가

**Evaluation** 탭에서 지표 확인:

| 지표 | 목표값 | 현재값 예시 | 평가 |
|------|--------|-----------|------|
| **Training Accuracy** | 90% 이상 | 92.5% | ✅ 양호 |
| **Validation Accuracy** | 85% 이상 | 87.3% | ✅ 양호 |

**혼동 행렬 (Confusion Matrix)** 확인:
- 대각선 값이 높을수록 좋음
- 특정 카테고리 간 혼동이 많으면 학습 데이터 보강 필요

예시:
```
             예측
실제    | lead study proj event work meet dead
──────────────────────────────────────────────
lead    |  42    1     0    1     0    1    0
study   |  1    65     0    0     1    1    0
project |  0    0     50    1     0    1    0
event   |  2    0     0    44    1    1    0
workshop|  0    2     0    1    34    1    0
meeting |  1    1     1    0     0   46    1
deadline|  0    0     1    0     0    1   45
```

#### Step 7: 모델 테스트

**Preview** 탭에서 실시간 테스트:

1. 테스트 문구 입력:
```
입력: "React 세미나"
예측: study (97.2%)

입력: "데모데이 발표"
예측: project (94.8%)

입력: "과제 제출 마감"
예측: deadline (99.1%)
```

2. 잘못 분류되는 경우:
   - 해당 예제를 학습 데이터에 추가
   - 재학습

#### Step 8: 모델 내보내기

1. **Output** 탭 선택
2. **Get** 버튼 클릭
3. `ScheduleListClassifierML.mlmodel` 저장
4. Xcode 프로젝트에 드래그 앤 드롭
   - ✅ **Target Membership**: AppProduct 체크
   - Xcode가 자동으로 Swift 클래스 생성

### 3. 모델 개선 전략

#### 문제: 특정 카테고리 정확도 낮음

**해결 방법**:
1. 해당 카테고리 학습 데이터 추가 (50개 이상)
2. 혼동되는 카테고리와의 차이점 명확화
3. 키워드가 명확한 예제 추가

예시:
```json
// study와 workshop이 혼동되는 경우
// study 데이터 강화
{"text": "React 이론 세미나", "label": "study"},
{"text": "알고리즘 개념 학습", "label": "study"},

// workshop 데이터 강화
{"text": "React 실습 워크샵", "label": "workshop"},
{"text": "알고리즘 코딩 실습", "label": "workshop"}
```

#### 문제: 전체 정확도 낮음 (80% 미만)

**체크리스트**:
- [ ] 각 레이블당 최소 30개 이상 예제 확보
- [ ] 레이블이 명확하게 구분되는지 확인
- [ ] 중복 데이터 제거
- [ ] 오타 수정
- [ ] Transfer Learning 알고리즘 사용
- [ ] Korean 언어 설정

---

## 성능 최적화

### 1. 싱글톤 패턴

```swift
final class ScheduleClassifierManager {
    static let shared = ScheduleClassifierManager()

    private let model: ScheduleListClassifierML

    private init() {
        let config = MLModelConfiguration()
        self.model = try! ScheduleListClassifierML(configuration: config)
    }

    func classify(title: String) -> ScheduleCategory {
        do {
            let prediction = try model.prediction(text: title)
            return ScheduleCategory(rawValue: prediction.label) ?? .meeting
        } catch {
            return .meeting
        }
    }
}
```

### 2. 배치 분류 (async/await)

```swift
extension ScheduleClassifier {
    func batchClassifyAsync(_ schedules: [Schedule]) async -> [ClassifiedSchedule] {
        await withTaskGroup(of: ClassifiedSchedule.self) { group in
            for schedule in schedules {
                group.addTask {
                    let category = self.classify(title: schedule.title)
                    return ClassifiedSchedule(
                        schedule: schedule,
                        category: category
                    )
                }
            }

            var results: [ClassifiedSchedule] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
    }
}

struct ClassifiedSchedule: Identifiable {
    let id: UUID
    let schedule: Schedule
    let category: ScheduleCategory

    init(schedule: Schedule, category: ScheduleCategory) {
        self.id = schedule.id
        self.schedule = schedule
        self.category = category
    }
}
```

### 3. DIContainer 등록

```swift
@Observable
final class DIContainer {
    private(set) lazy var scheduleClassifier: ScheduleClassifier = {
        ScheduleClassifier()
    }()
}
```

---

## FAQ

### Q1. 짧은 제목도 잘 분류되나요?

**A**: 네! "스터디", "회의" 같은 한 단어도 학습 데이터에 포함되어 있으면 잘 분류됩니다.

### Q2. 여러 키워드가 섞인 경우는?

**A**: 모델이 가장 주된 의미를 파악합니다:
```swift
"프로젝트 중간 발표 회의"
→ project (프로젝트가 주요 키워드)

"알고리즘 스터디 회의"
→ study (스터디가 주요 키워드)
```

### Q3. 신뢰도가 낮은 경우 어떻게 처리하나요?

**A**: 임계값을 사용하거나 사용자 확인을 요청하세요:
```swift
let (category, confidence) = classifier.classifyWithConfidence(title: title)

if confidence < 0.6 {
    // 사용자에게 카테고리 선택 요청
    showCategoryPicker()
} else {
    return category
}
```

### Q4. 모델을 언제 업데이트해야 하나요?

**A**:
- 새로운 일정 유형 추가 시
- 정확도가 떨어진다고 느낄 때
- 분기별 1회 업데이트 권장

### Q5. 영어 일정도 지원하나요?

**A**: 현재는 한국어만 학습되어 있습니다. 영어를 지원하려면:
1. 영어 학습 데이터 추가
2. Language 설정을 Multilingual 또는 English로 변경
3. 재학습

---

## 참고 자료

- [Apple Create ML Documentation](https://developer.apple.com/documentation/createml)
- [Text Classifier Tutorial](https://developer.apple.com/documentation/createml/creating-a-text-classifier-model)
- [Core ML Best Practices](https://developer.apple.com/documentation/coreml/core_ml_api/integrating_a_core_ml_model_into_your_app)
