# Response DTO Decoding

> 서버가 모든 정수를 String으로 직렬화하는 문제에 대한 디코딩 규칙 상세 레퍼런스.
> 핵심 요약은 `CLAUDE.md` 참고.

서버는 **응답으로 내려주는 모든 정수 값을 String 으로 직렬화**합니다.
JSON Number 가 아닌 String 으로 오므로, Response DTO 가 `Int` 로
선언된 필드를 그대로 디코딩하면 런타임 `DecodingError.typeMismatch`
가 발생합니다.

- 작성자: 제옹(euijjang97)

## 원칙

1. **Response DTO 의 모든 `Int` 필드는 String 폴백을 보장한다**
2. **synthesized `Codable` 금지** — `Int` 필드가 있으면 반드시 custom
   `init(from:)` + `encode(to:)` 를 작성
3. **`decode(Int.self)` / `decodeIfPresent(Int.self)` 직접 호출 금지** —
   `decodeIntFlexibleIfPresent` 헬퍼 사용
4. **폴백 순서**: `Int` → `String("123")` → `Double(123.0)` → throw
5. **Request DTO (Encodable, 우리가 보내는 쪽) 는 제외** — `Int` 그대로 OK
6. **헬퍼는 `UMCFoundation` 공용 확장을 쓴다** — 파일마다 `private extension` 을 다시 정의하지 않는다 (아래 "공용 헬퍼").

## 공용 헬퍼 (`UMCFoundation`)

`UMCApp/Core/Foundation/Sources/Extensions/KeyedDecodingContainer+FlexibleNumber.swift` 의
`public extension KeyedDecodingContainer` 가 단일 정본이다. `import UMCFoundation` 만 하면 쓸 수 있다.

| 헬퍼 | 용도 |
|------|------|
| `decodeIntFlexible` / `decodeIntFlexibleIfPresent` | 정수 — `Int` → `String` → `Double` 폴백 |
| `decodeDoubleFlexible` / `decodeDoubleFlexibleIfPresent` | 실수 — 같은 폴백 |
| `decodeBoolFlexibleIfPresent` | 불리언 — `Bool`/`"true"`/`1` 등 |
| `decodeFlexibleString` / `…IfPresent` / `…OrNil` / `…OrEmpty` | 문자열 — 숫자로 와도 `String` 으로 (핵심 규칙 #2 의 "전 레이어 String" 에 맞춤) |
| `decodeFlexibleStringArray` | `[String]` — 원소가 숫자여도 문자열로 |
| `decodeFirstNonEmptyString(forKeys:)` | 서버가 키 이름을 바꿔 보내는 과도기 필드 |

> 핵심 규칙 #2 에 따라 **Response DTO 의 식별자·카운트 필드는 애초에 `String` 으로 선언**하고
> `decodeFlexibleString*` 로 읽는 것이 기본이다. `Int` 로 둬야 하는 연산용 필드만 `decodeIntFlexible*` 을 쓴다.

## ❌ 안티패턴

```swift
struct UserDTO: Codable {
    let userId: Int           // synthesized Codable — "123" String 응답에서 typeMismatch
    let name: String
}

// 또는 custom init 안에서 직접 Int decode
init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    userId = try container.decodeIfPresent(Int.self, forKey: .userId) ?? 0
}
```

## ✅ 권장 패턴

```swift
import UMCFoundation

struct UserDTO: Codable {
    let userId: String      // 핵심 규칙 #2 — 식별자는 String
    let name: String
    let point: Int          // 연산용 정수만 Int

    private enum CodingKeys: String, CodingKey {
        case userId, name, point
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userId = container.decodeFlexibleStringOrEmpty(forKey: .userId)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        point = try container.decodeIntFlexibleIfPresent(forKey: .point) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userId, forKey: .userId)
        try container.encode(name, forKey: .name)
        try container.encode(point, forKey: .point)
    }
}
```

헬퍼 본체는 `UMCFoundation` 에 있으므로 DTO 파일에 다시 쓰지 않는다. 폴백 규칙(`Int` → `String` → `Double` → throw)을
바꿔야 하면 `KeyedDecodingContainer+FlexibleNumber.swift` 와 그 테스트를 고친다.

## 리뷰 체크리스트

Response DTO 변경이 포함된 PR 리뷰 시 검증:

- [ ] `Int` / `Int?` / `[Int]` / `Int64` 등 정수 타입 필드가 있는가
- [ ] 정수 필드가 있다면 custom `init(from:)` 이 정의되어 있는가 (synthesized Codable 금지)
- [ ] `init(from:)` 안에서 `decodeIntFlexibleIfPresent` (또는 동급) 사용 — `decode(Int.self)` 직접 호출 없음
- [ ] 헬퍼를 `UMCFoundation` 공용 확장에서 쓰고 있는가 — DTO 파일에 `private extension KeyedDecodingContainer` 를 다시 만들지 않았는가
- [ ] 식별자·카운트 필드가 `String` 으로 선언돼 `decodeFlexibleString*` 로 읽히는가 (핵심 규칙 #2)
- [ ] **Request/Encodable DTO 는 적용 제외 확인** — 보내는 쪽이라 무관

## 적용 범위

- **신규 Response DTO**: 처음부터 위 패턴 적용
- **기존 Response DTO**: 발견 시 별도 마이그레이션 PR 로 진행
- **공용 헬퍼**: `UMCFoundation/Extensions/KeyedDecodingContainer+FlexibleNumber.swift` 로 단일화 완료 — 저장소에 다른 정의가 없다
