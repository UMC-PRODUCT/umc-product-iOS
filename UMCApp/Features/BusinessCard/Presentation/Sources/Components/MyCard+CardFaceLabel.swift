//
//  MyCard+CardFaceLabel.swift
//  BusinessCardPresentation
//
//  Created by euijjang97 on 8/31/26.
//

import BusinessCardDomain
import CryptoKit
import Foundation

/// 명함 면(面) 표기의 단일 진실 원천.
///
/// 표기 이름은 ``MyCard/nameWithNickname``(#1236) 한 곳에 있고 여기서는 그것을 읽기만 한다.
/// 라이선스 톤 재설계(#1347)로 늘어난 표기 — 뒷면 시리얼과 앞면 기록 슬롯 — 도 여기 모은다.
/// 2D(``BusinessCardFaceView``)와 3D(`BusinessCardComposer`)가 같은 문자열을 써야 하므로
/// 파생 규칙이 뷰 안으로 흩어지면 두 카드가 서로 다른 값을 찍게 된다.
///
/// 접근성 라벨은 표기 이름과 달리 **면(面)이 있는 카드만** 여기 것을 쓴다.
/// 명함첩 셀·요약 카드는 뒤집히지 않아 「앞면.」 접두어가 붙으면 없는 뒷면을 암시한다.
extension MyCard {

    // MARK: - License

    /// 뒷면 시리얼 (`A1B2-C3D4`).
    ///
    /// ``memberId`` 를 그대로도, 잘라서도 싣지 않는다 — 회원 식별자는 명함 딥링크
    /// (``CardLink``)와 교환 페이로드에 그대로 쓰이는 값이라, 카드를 찍은 사진 한 장으로
    /// 남의 프로필 링크를 조립할 수 있게 된다. 앞 몇 자만 잘라 싣는 것도 같은 노출이다.
    ///
    /// SHA-256 앞 4바이트를 대문자 hex 로 접는다 — 같은 회원은 언제나 같은 시리얼이고
    /// (결정론적이라 서버 왕복이 필요 없다) 거꾸로 되돌릴 수는 없다. 충돌은 신경 쓰지 않는다:
    /// 이 값은 조회 키가 아니라 카드가 「발급된 물건」처럼 읽히게 하는 표기일 뿐이다.
    var licenseSerial: String {
        let hex = SHA256.hash(data: Data(memberId.utf8))
            .prefix(Constants.serialByteCount)
            .map { String(format: "%02X", $0) }
            .joined()
        let split = hex.index(hex.startIndex, offsetBy: hex.count / 2)
        return "\(hex[..<split])\(Constants.serialSeparator)\(hex[split...])"
    }

    // MARK: - Accessibility

    /// 「앞면. 홍길동/길동, iOS 파트, 12기, 스터디 3건, …, ○○대학교」.
    ///
    /// 접두어가 **지금 보이는 면**을 전달한다. 3D 카드는 `RealityView` 라 VoiceOver 에
    /// 아무것도 주지 않아서, 면 정보가 라벨에 없으면 어느 쪽을 보고 있는지 알 방법이 없다.
    ///
    /// 낭독 순서는 화면 순서를 그대로 따른다 — 학교는 하단 발급 행으로 내려갔으므로
    /// 맨 뒤에서 읽는다. 못 센 기록 칸은 통째로 빠진다(``CardRecordSlot/spokenPhrase(in:)``).
    func frontFaceAccessibilityLabel(stat: ActivityStat) -> String {
        let identity = [
            nameWithNickname,
            "\(partDisplayName)\(Constants.partSuffix)",
            "\(generation)\(Constants.generationSuffix)"
        ]
        let records = CardRecordSlot.allCases.compactMap { $0.spokenPhrase(in: stat) }
        return Constants.frontPrefix
            + (identity + records + [university]).joined(separator: Constants.separator)
    }

    /// 「뒷면. 시리얼 번호 A1B2-C3D4, QR 코드, github.com/umc, …」.
    ///
    /// 값 없는 링크는 빼고 읽는다 — `BusinessCardFaceView.linkRow` 가 「값 없으면 줄 자체를
    /// 안 그린다」는 규칙과 같다. 빈 줄을 읽으면 서버 미입력이 링크가 있는 것처럼 들린다.
    var backFaceAccessibilityLabel: String {
        let links = [github, linkedIn, blog].compactMap { link -> String? in
            guard let link, !link.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return nil
            }
            return link
        }
        let head = ["\(Constants.serialLabel)\(licenseSerial)", Constants.qrLabel]
        return Constants.backPrefix + (head + links).joined(separator: Constants.separator)
    }
}

// MARK: - CardRecordSlot

/// 앞면 기록 슬롯 4칸 (#1347).
///
/// 뷰(`BusinessCardFaceView.recordSlots`)와 접근성 라벨이 **이 하나의 목록**을 읽는다 —
/// 칸을 한쪽에만 늘리면 보이는 것과 읽히는 것이 갈린다.
///
/// 레퍼런스(RIFE)의 호(arc) 게이지는 옮기지 않았다. 진척률에 대응하는 값이 도메인에 없어
/// 호를 그리면 없는 정량 정보를 지어내는 꼴이 된다 — 그 자리는 파트·기수 칩이 대신한다.
enum CardRecordSlot: CaseIterable {
    case study
    case activity
    case cards
    case bookmark

    /// 카드에 찍히는 라벨. 라틴 대문자 고정이라 `uppercased()` 를 거치지 않는다.
    var label: String {
        switch self {
        case .study:    return "STUDY"
        case .activity: return "ACTIVITY"
        case .cards:    return "CARDS"
        case .bookmark: return "BOOKMARK"
        }
    }

    /// VoiceOver 가 읽는 한국어 이름. 라틴 라벨을 그대로 흘리면 「스터디」가 아니라
    /// 「에스 티 유…」로 들린다.
    var spokenName: String {
        switch self {
        case .study:    return "스터디"
        case .activity: return "활동"
        case .cards:    return "받은 명함"
        case .bookmark: return "북마크"
        }
    }

    /// 낭독 단위 — 마이페이지 행(`MyActivitySection`·`BusinessCardSection`)과 맞춘다.
    private var unit: String {
        switch self {
        case .study, .activity: return "건"
        case .cards:            return "장"
        case .bookmark:         return "개"
        }
    }

    func count(in stat: ActivityStat) -> String? {
        switch self {
        case .study:    return stat.studyCount
        case .activity: return stat.activityCount
        case .cards:    return stat.receivedCardCount
        case .bookmark: return stat.bookmarkCount
        }
    }

    /// 카드에 찍는 값.
    ///
    /// `nil` 은 「0」이 아니라 **「아직 못 셌다」**라서 "-" 로 그린다 (#1222) — 통신이 끊긴
    /// 카드가 「스터디 0건」이라고 단언하면 안 된다. `"50+"` 같은 서버 잘림 표기는 손대지
    /// 않고 그대로 싣는다 (핵심규칙 #2 — 카운트는 전 레이어 String).
    func displayValue(in stat: ActivityStat) -> String {
        count(in: stat) ?? Constants.emptyCount
    }

    /// 못 센 칸은 낭독에서 통째로 뺀다 — 뒷면 링크 3줄과 같은 규칙이다. "-" 를 읽으면
    /// 「빼기」로 들려 값이 있는 것처럼 오해된다.
    func spokenPhrase(in stat: ActivityStat) -> String? {
        count(in: stat).map { "\(spokenName) \($0)\(unit)" }
    }
}

// MARK: - Constants

private enum Constants {
    static let frontPrefix = "앞면. "
    static let backPrefix = "뒷면. "
    static let separator = ", "
    static let partSuffix = " 파트"
    static let generationSuffix = "기"
    static let qrLabel = "QR 코드"
    static let serialLabel = "시리얼 번호 "
    /// 4바이트 = hex 8자 = `XXXX-XXXX`. 레퍼런스 시리얼과 같은 길이감이면 충분하다.
    static let serialByteCount = 4
    static let serialSeparator = "-"
    static let emptyCount = "-"
}
