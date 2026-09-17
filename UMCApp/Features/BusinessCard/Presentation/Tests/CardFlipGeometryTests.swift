//
//  CardFlipGeometryTests.swift
//  BusinessCardPresentationTests
//
//  Created by euijjang97 on 9/16/26.
//

import Foundation
import Testing
@testable import BusinessCardPresentation

/// 명함 플립(#1348)의 기하 규칙을 잠근다.
///
/// 회전 자체는 눈으로 보는 것이고 프리뷰가 보여준다. 여기서 보는 것은 **조용히 틀려도
/// 빌드가 통과하는** 것들이다 — 면이 언제 갈리는지, 회전이 끝난 뒷면이 거울상인지,
/// 드래그로 쌓인 각(#1390)이 어느 면에 서는지.
///
/// 실행: `cd UMCApp && make test SCHEME=BusinessCardPresentation`
@Suite("명함 플립 기하")
struct CardFlipGeometryTests {

    // MARK: - 1. 면 교체 시점

    @Test("90° 를 넘기 전까지는 앞면이다", arguments: [0.0, 1.0, 89.0, 89.999])
    func showsFrontBeforeHalfway(angle: Double) {
        #expect(!CardFlipGeometry(angle: angle).showsBack)
    }

    @Test("90° 부터 뒷면이다", arguments: [90.0, 90.001, 120.0, 180.0])
    func showsBackFromHalfway(angle: Double) {
        #expect(CardFlipGeometry(angle: angle).showsBack)
    }

    /// 드래그로 여러 바퀴 돌거나 왼쪽으로 돌리면 각이 한 바퀴 밖으로 나간다(#1390).
    @Test("누적 각에서도 한 바퀴로 접어 앞면을 고른다", arguments: [360.0, 720, -360, 630, -90])
    func showsFrontAtAccumulatedAngles(angle: Double) {
        #expect(!CardFlipGeometry(angle: angle).showsBack)
    }

    @Test("누적 각에서도 한 바퀴로 접어 뒷면을 고른다", arguments: [540.0, -180, 450, -100])
    func showsBackAtAccumulatedAngles(angle: Double) {
        #expect(CardFlipGeometry(angle: angle).showsBack)
    }

    /// 교체 지점의 카드는 폭이 0 이라 갈아 끼우는 순간이 어느 프레임에도 보이지 않는다.
    /// 이 값이 0 에서 멀어지면 교체가 눈에 띈다.
    @Test("면이 갈리는 지점에서 카드가 모서리만 보인다")
    func cardIsEdgeOnAtSwapPoint() {
        #expect(CardFlipGeometry(angle: 90).facing < 1e-9)
    }

    // MARK: - 2. 거울상 방지

    /// 뒷면을 미리 돌려 둔 각(``counterTurn``)과 바깥 회전을 더하면 정지 상태에서
    /// 한 바퀴의 배수여야 한다. 아니면 그 면은 좌우가 뒤집혀 보인다 — 텍스트도 QR 도.
    @Test(
        "정지 상태의 총 회전이 한 바퀴의 배수다",
        arguments: [0.0, 180, 360, 540, -180, -360, 1080]
    )
    func restingFacesAreNotMirrored(angle: Double) {
        let geometry = CardFlipGeometry(angle: angle)
        let total = geometry.counterTurn + angle

        #expect(total.truncatingRemainder(dividingBy: 360) == 0)
    }

    @Test("앞면은 되돌릴 각이 없다")
    func frontFaceNeedsNoCounterTurn() {
        #expect(CardFlipGeometry(angle: 0).counterTurn == 0)
    }

    // MARK: - 3. 그림자

    @Test(
        "정지 상태에서는 그림자가 정면값을 그대로 쓴다",
        arguments: [0.0, 180, 360, 540, -180]
    )
    func shadowIsFullAtRest(angle: Double) {
        let geometry = CardFlipGeometry(angle: angle)

        #expect(abs(geometry.facing - 1) < 1e-9)
        // 정면이면 좌우로 쓸리지 않는다 — 정지 오프셋만 남는다.
        #expect(abs(geometry.sway) < 1e-9)
    }

    @Test("회전 중에는 그림자가 옅어지고 한쪽으로 쓸린다")
    func shadowFollowsRotation() {
        let quarter = CardFlipGeometry(angle: 45)
        let threeQuarter = CardFlipGeometry(angle: 135)

        #expect(quarter.facing < 1)
        // 축 하나를 넘어가면 쓸리는 방향이 바뀌지 않는다 — 같은 방향으로 계속 돈다.
        #expect(quarter.sway > 0)
        #expect(threeQuarter.sway > 0)
    }

    /// 얇은 판은 반 바퀴 돌면 윤곽이 같다. 그림자가 바퀴 수나 도는 방향에 따라 달라지면
    /// 여러 바퀴 스핀하는 동안 그림자만 따로 튄다.
    @Test("그림자는 반 바퀴 주기다", arguments: [45.0, 135, 200])
    func shadowRepeatsEveryHalfTurn(angle: Double) {
        let base = CardFlipGeometry(angle: angle)

        for shifted in [angle + 360, angle - 360, angle + 180] {
            let geometry = CardFlipGeometry(angle: shifted)
            #expect(abs(geometry.facing - base.facing) < 1e-9)
            #expect(abs(geometry.sway - base.sway) < 1e-9)
        }
    }

    // MARK: - 4. 정지 각

    @Test(
        "가장 가까운 반 바퀴 배수에 선다",
        arguments: [
            (89.0, 0.0), (91, 180), (269, 180), (271, 360),
            (-89, 0), (-91, -180), (1000, 1080),
        ]
    )
    func restsOnNearestHalfTurn(angle: Double, expected: Double) {
        #expect(CardFlipGeometry.restingAngle(near: angle) == expected)
    }

    /// 놓는 순간 확정한 면(``CardFlipGeometry/restingAngle(near:)`` 의 면)과 화면에 보이던
    /// 면이 경계에서 어긋나면, 소유자의 ``isFlipped`` 가 카드와 반대로 남는다.
    @Test(
        "정지 각의 면은 원래 각의 면과 같다 — 경계 포함",
        arguments: [90.0, 270, -90, -270, 450, 630, 89.999, -89.999]
    )
    func restingAngleKeepsFace(angle: Double) {
        let resting = CardFlipGeometry(angle: CardFlipGeometry.restingAngle(near: angle))

        #expect(resting.showsBack == CardFlipGeometry(angle: angle).showsBack)
    }

    /// 관성 투영(속도 × 투영 시간)을 더한 각이 여러 바퀴를 넘어도 제한 없이 선다.
    /// 3000pt/s 플릭 → 1500°/s × 0.35초 = +525° → 540°(한 바퀴 반).
    @Test("세게 튕긴 투영 각은 여러 바퀴 뒤 면에 선다")
    func fastFlickSpinsMultipleTurns() {
        #expect(CardFlipGeometry.restingAngle(near: 525) == 540)
        #expect(CardFlipGeometry.restingAngle(near: -525) == -540)
    }
}
