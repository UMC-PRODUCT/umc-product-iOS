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
/// 빌드가 통과하는** 두 가지다 — 면이 언제 갈리는지, 회전이 끝난 뒷면이 거울상인지.
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

    /// 교체 지점의 카드는 폭이 0 이라 갈아 끼우는 순간이 어느 프레임에도 보이지 않는다.
    /// 이 값이 0 에서 멀어지면 교체가 눈에 띈다.
    @Test("면이 갈리는 지점에서 카드가 모서리만 보인다")
    func cardIsEdgeOnAtSwapPoint() {
        #expect(CardFlipGeometry(angle: 90).facing < 1e-9)
    }

    // MARK: - 2. 거울상 방지

    /// 뒷면을 미리 돌려 둔 각(``counterTurn``)과 바깥 회전을 더하면 정지 상태에서
    /// 한 바퀴의 배수여야 한다. 아니면 그 면은 좌우가 뒤집혀 보인다 — 텍스트도 QR 도.
    @Test("정지 상태의 총 회전이 한 바퀴의 배수다", arguments: [0.0, 180.0])
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

    @Test("정지 상태에서는 그림자가 정면값을 그대로 쓴다", arguments: [0.0, 180.0])
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
}
