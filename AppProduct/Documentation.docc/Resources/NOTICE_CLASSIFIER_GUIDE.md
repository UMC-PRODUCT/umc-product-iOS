# NoticeClassifierML 사용 가이드

공지사항 텍스트를 4가지 유형으로 자동 분류하는 Core ML 모델 사용 및 학습 가이드입니다.

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
| **파일명** | NoticeClassifierML.mlmodel |
| **위치** | `AppProduct/AppleCreateML/NoticeAlarmHistory/` |
| **모델 크기** | 약 12KB |
| **입력** | 공지사항 텍스트 (String) |
| **출력** | 분류 레이블 (success, warning, info, error) |
| **목적** | 공지사항 알림 UI 자동화 (색상, 아이콘 선택) |

### 모델 특징

- ✅ **온디바이스 실행**: 네트워크 없이 로컬에서 즉시 분류
- ✅ **경량**: 12KB로 앱 용량에 미미한 영향
- ✅ **빠른 속도**: 밀리초 단위 분류 (실시간 가능)
- ✅ **신뢰도 제공**: 분류 결과의 확률값 제공
- ✅ **한국어 최적화**: 한국어 공지사항에 특화

---

## 분류 카테고리

### 1. success (성공/완료)

**설명**: 긍정적인 완료, 승인, 성공 메시지

**UI 표현**:
- 🟢 색상: `Color.green`
- ✅ 아이콘: `checkmark.circle.fill`
- 뱃지: "성공"

**학습 데이터 예시**:
```
✓ "중앙 해커톤 참여 확정 축하합니다!"
✓ "결제 완료 귀하의 결제가 성공적으로 완료되었습니다"
✓ "회비 납부 완료 1월 회비가 정상적으로 납부되었습니다"
✓ "가입 승인 회원 가입이 승인되었습니다"
✓ "과제 제출 완료 과제가 성공적으로 제출되었습니다"
```

**사용 시나리오**:
- 결제/납부 완료 알림
- 신청/등록 승인 알림
- 과제/프로젝트 제출 완료

### 2. warning (경고/주의)

**설명**: 주의 필요, 경고, 마감 임박 메시지

**UI 표현**:
- 🟡 색상: `Color.yellow`
- ⚠️ 아이콘: `exclamationmark.triangle.fill`
- 뱃지: "주의"

**학습 데이터 예시**:
```
⚠ "회비 미납 경고 회비를 납부해주세요"
⚠ "출석률 저조 출석률이 낮습니다"
⚠ "마감 임박 과제 제출 마감이 임박했습니다"
⚠ "패널티 경고 지각 패널티가 부과됩니다"
```

**사용 시나리오**:
- 미납/미제출 경고
- 마감 임박 알림
- 규정 위반 경고

### 3. info (정보/안내)

**설명**: 일반 정보, 안내, 공지사항

**UI 표현**:
- 🔵 색상: `Color.blue`
- ℹ️ 아이콘: `info.circle.fill`
- 뱃지: "안내"

**학습 데이터 예시**:
```
ℹ "세미나 안내 다음 주 세미나가 예정되어 있습니다"
ℹ "공지사항 새로운 공지사항이 등록되었습니다"
ℹ "이벤트 안내 신규 이벤트를 확인하세요"
```

**사용 시나리오**:
- 일반 공지사항
- 일정 안내
- 이벤트 소개

### 4. error (오류/긴급)

**설명**: 오류, 실패, 긴급 메시지

**UI 표현**:
- 🔴 색상: `Color.red`
- ❌ 아이콘: `xmark.circle.fill`
- 뱃지: "오류"

**학습 데이터 예시**:
```
❌ "제출 마감 과제 제출 기한이 지났습니다"
❌ "시스템 오류 일시적인 오류가 발생했습니다"
❌ "접근 거부 권한이 없습니다"
❌ "결제 실패 결제가 실패했습니다"
```

**사용 시나리오**:
- 시스템 오류 알림
- 마감 경과 알림
- 결제/등록 실패

---

## Swift 코드 사용법

### 1. NoticeClassifier 구현

```swift
import CoreML
import NaturalLanguage

/// 공지사항 텍스트를 4가지 유형으로 분류하는 분류기
final class NoticeClassifier {
    // MARK: - Property

    private let model: NoticeClassifierML

    // MARK: - Initializer

    init() {
        do {
            let config = MLModelConfiguration()
            self.model = try NoticeClassifierML(configuration: config)
        } catch {
            fatalError("NoticeClassifierML 로드 실패: \(error)")
        }
    }

    // MARK: - Public Methods

    /// 공지사항 텍스트를 분류합니다.
    func classify(text: String) -> NoticeType {
        do {
            let prediction = try model.prediction(text: text)
            return NoticeType(rawValue: prediction.label) ?? .info
        } catch {
            print("[NoticeClassifier] 분류 실패: \(error)")
            return .info
        }
    }

    /// 신뢰도와 함께 분류합니다.
    func classifyWithConfidence(text: String) -> (type: NoticeType, confidence: Double) {
        do {
            let prediction = try model.prediction(text: text)
            let confidence = prediction.labelProbability[prediction.label] ?? 0.0

            return (
                type: NoticeType(rawValue: prediction.label) ?? .info,
                confidence: confidence
            )
        } catch {
            return (.info, 0.0)
        }
    }
}
```

### 2. NoticeType Enum

```swift
import SwiftUI

enum NoticeType: String, CaseIterable, Codable {
    case success = "success"
    case warning = "warning"
    case info = "info"
    case error = "error"

    var color: Color {
        switch self {
        case .success: return .green
        case .warning: return .yellow
        case .info: return .blue
        case .error: return .red
        }
    }

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        case .error: return "xmark.circle.fill"
        }
    }

    var title: String {
        switch self {
        case .success: return "성공"
        case .warning: return "주의"
        case .info: return "안내"
        case .error: return "오류"
        }
    }
}
```

### 3. 기본 사용 예시

```swift
let classifier = NoticeClassifier()
let noticeText = "결제 완료되었습니다"
let type = classifier.classify(text: noticeText)

print("분류 결과: \(type.title)")  // "성공"
print("색상: \(type.color)")        // Color.green
```

---

## SwiftUI 통합

### 공지사항 카드 뷰

```swift
struct NoticeCardView: View {
    let notice: Notice
    @State private var classifier = NoticeClassifier()

    var body: some View {
        let noticeType = classifier.classify(text: notice.content)

        HStack(spacing: 16) {
            // 아이콘
            Image(systemName: noticeType.icon)
                .font(.system(size: 24))
                .foregroundColor(noticeType.color)
                .frame(width: 48, height: 48)
                .background(noticeType.color.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 8) {
                // 유형 뱃지
                Text(noticeType.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(noticeType.color.opacity(0.2))
                    .foregroundColor(noticeType.color)
                    .cornerRadius(4)

                // 제목
                Text(notice.title)
                    .font(.headline)

                // 내용
                Text(notice.content)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}
```

---

## 모델 학습 방법

### 1. 학습 데이터 준비

**NoticeTrainingData.json** 파일 형식:

```json
[
  {
    "text": "중앙 해커톤 참여 확정 축하합니다",
    "label": "success"
  },
  {
    "text": "회비 미납 경고 회비를 납부해주세요",
    "label": "warning"
  },
  {
    "text": "세미나 안내 다음 주 세미나가 예정되어 있습니다",
    "label": "info"
  },
  {
    "text": "제출 마감 과제 제출 기한이 지났습니다",
    "label": "error"
  }
]
```

**학습 데이터 작성 팁**:
- ✅ 각 레이블당 **최소 50개 이상** 예제 준비
- ✅ 다양한 표현 방식 포함 (축약형, 정중체, 반말 등)
- ✅ 실제 공지사항에서 수집한 텍스트 사용
- ✅ 레이블이 명확하게 구분되도록 작성

### 2. Create ML로 모델 학습

#### Step 1: Create ML 프로젝트 생성

1. Xcode 실행
2. **File > New > Project**
3. **Other** 탭에서 **Create ML** 선택
4. 프로젝트 이름: `NoticeClassifier`
5. 저장 위치: `AppProduct/AppleCreateML/NoticeAlarmHistory/`

#### Step 2: 학습 데이터 가져오기

1. **Data** 탭 선택
2. **Training Data** 섹션에서 `+` 버튼 클릭
3. `NoticeTrainingData.json` 파일 선택
4. **Text Column**: `text` 선택
5. **Label Column**: `label` 선택

#### Step 3: 검증 데이터 설정 (선택사항)

1. **Validation Data** 섹션에서 `+` 버튼 클릭
2. 검증용 JSON 파일 선택 (학습 데이터의 20% 정도)
3. 또는 자동으로 분할: **Split from Training Data** 선택

#### Step 4: 모델 학습

1. **Training** 탭 선택
2. **Algorithm**: `Transfer Learning` (권장) 또는 `Maximum Entropy`
3. **Language**: `Korean` 선택
4. **Train** 버튼 클릭
5. 학습 진행 상황 확인 (수 초~수 분 소요)

#### Step 5: 모델 평가

학습 완료 후 **Evaluation** 탭에서 확인:

| 지표 | 권장값 | 의미 |
|------|--------|------|
| **Accuracy** | 80% 이상 | 전체 정확도 |
| **Precision** | 75% 이상 | 예측의 정확성 |
| **Recall** | 75% 이상 | 실제 케이스 포착률 |

**정확도가 낮은 경우**:
- ❌ 70% 미만: 학습 데이터 재검토 필요
- ⚠️ 70~80%: 학습 데이터 추가 권장
- ✅ 80% 이상: 배포 가능

#### Step 6: 모델 내보내기

1. **Output** 탭 선택
2. **Get** 버튼 클릭
3. `NoticeClassifierML.mlmodel` 파일 저장
4. Xcode 프로젝트에 드래그 앤 드롭
   - **Target Membership**: ✅ AppProduct 체크
   - Xcode가 자동으로 Swift 클래스 생성

### 3. 모델 업데이트 워크플로우

#### 새 데이터 추가

1. `NoticeTrainingData.json`에 예제 추가:
```json
[
  {
    "text": "새로운 공지사항 예제",
    "label": "info"
  }
]
```

2. Create ML 프로젝트 열기
3. **Data** 탭에서 데이터 새로고침
4. **Train** 버튼으로 재학습
5. 정확도 확인 후 모델 내보내기

#### 버전 관리

```
NoticeAlarmHistory/
├── NoticeClassifierML_v1.0.mlmodel  (초기 버전)
├── NoticeClassifierML_v1.1.mlmodel  (개선 버전)
├── NoticeClassifierML.mlmodel       (현재 사용 중)
└── NoticeTrainingData.json
```

### 4. 학습 데이터 수집 전략

#### 방법 1: 기존 공지사항에서 수집

```swift
// 서버에서 받은 공지사항을 JSON으로 변환
struct TrainingDataCollector {
    func collectFromNotices(_ notices: [Notice]) -> String {
        let trainingData = notices.map { notice in
            [
                "text": notice.content,
                "label": "info"  // 수동으로 레이블 지정 필요
            ]
        }

        let jsonData = try! JSONEncoder().encode(trainingData)
        return String(data: jsonData, encoding: .utf8)!
    }
}
```

#### 방법 2: 사용자 피드백 활용

```swift
struct NoticeFeedbackView: View {
    let notice: Notice
    @State private var suggestedType: NoticeType?

    var body: some View {
        VStack {
            NoticeCardView(notice: notice)

            Text("이 분류가 정확한가요?")
                .font(.caption)

            HStack {
                ForEach(NoticeType.allCases, id: \.self) { type in
                    Button(type.title) {
                        suggestedType = type
                        // 서버로 피드백 전송
                        sendFeedback(notice: notice, type: type)
                    }
                }
            }
        }
    }

    func sendFeedback(notice: Notice, type: NoticeType) {
        // 피드백을 서버로 전송하여 학습 데이터로 활용
    }
}
```

---

## 성능 최적화

### 1. 싱글톤 패턴

```swift
final class NoticeClassifierManager {
    static let shared = NoticeClassifierManager()

    private let model: NoticeClassifierML

    private init() {
        let config = MLModelConfiguration()
        self.model = try! NoticeClassifierML(configuration: config)
    }

    func classify(text: String) -> NoticeType {
        do {
            let prediction = try model.prediction(text: text)
            return NoticeType(rawValue: prediction.label) ?? .info
        } catch {
            return .info
        }
    }
}
```

### 2. async/await 지원

```swift
extension NoticeClassifier {
    func classifyAsync(text: String) async -> NoticeType {
        await Task.detached {
            self.classify(text: text)
        }.value
    }
}
```

### 3. DIContainer 등록

```swift
@Observable
final class DIContainer {
    private(set) lazy var noticeClassifier: NoticeClassifier = {
        NoticeClassifier()
    }()
}
```

---

## FAQ

### Q1. 모델이 잘못 분류하는 경우는?

**A**: 신뢰도 임계값을 사용하세요:
```swift
let (type, confidence) = classifier.classifyWithConfidence(text: text)
if confidence < 0.7 {
    return .info  // 신뢰도 낮으면 기본값
}
return type
```

### Q2. 모델 크기를 더 줄일 수 있나요?

**A**: 12KB는 이미 매우 작습니다. Text Classifier는 Neural Network가 아닌 통계 모델이라 경량입니다.

### Q3. 실시간 분류가 가능한가요?

**A**: 네! 밀리초 단위로 매우 빠릅니다:
```swift
TextField("내용", text: $content)
    .onChange(of: content) { _, newValue in
        predictedType = classifier.classify(text: newValue)
    }
```

### Q4. 오프라인에서도 작동하나요?

**A**: 네! Core ML은 완전히 온디바이스에서 실행됩니다.

### Q5. 얼마나 자주 재학습해야 하나요?

**A**:
- 새로운 공지사항 유형 추가 시
- 정확도가 떨어진다고 느낄 때
- 월 1회 정도 새 데이터로 업데이트 권장

---

## 참고 자료

- [Apple Create ML Documentation](https://developer.apple.com/documentation/createml)
- [Text Classifier in Create ML](https://developer.apple.com/documentation/createml/creating-a-text-classifier-model)
- [Core ML Documentation](https://developer.apple.com/documentation/coreml)
