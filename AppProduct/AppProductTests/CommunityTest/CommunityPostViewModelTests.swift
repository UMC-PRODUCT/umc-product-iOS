//
//  CommunityPostViewModelTests.swift
//  AppProductTests
//
//  Created by euijjang97 on 3/10/26.
//

@testable import AppProduct
import Testing

struct CommunityPostViewModelTests {

    @Test("번개글 위치 문자열을 수정 폼용 장소 정보로 복원한다")
    func makePlaceSearchInfoParsesAddressAndName() {
        let place = CommunityPostViewModel.makePlaceSearchInfo(
            from: "서울특별시 성동구 왕십리로 83-21, 멋쟁이사자처럼 캠퍼스"
        )

        #expect(place.address == "서울특별시 성동구 왕십리로 83-21")
        #expect(place.name == "멋쟁이사자처럼 캠퍼스")
    }

    @Test("장소명이 없거나 주소와 같으면 수정 요청에 기존 주소만 유지한다")
    func serializePlaceKeepsRawAddressWhenNameIsMissingOrSame() {
        let rawAddressOnly = PlaceSearchInfo(
            name: "서울특별시 성동구 왕십리로 83-21",
            address: "서울특별시 성동구 왕십리로 83-21",
            coordinate: .init(latitude: 0.0, longitude: 0.0)
        )
        let fullPlace = PlaceSearchInfo(
            name: "멋쟁이사자처럼 캠퍼스",
            address: "서울특별시 성동구 왕십리로 83-21",
            coordinate: .init(latitude: 0.0, longitude: 0.0)
        )

        #expect(
            CommunityPostViewModel.serializePlace(rawAddressOnly)
                == "서울특별시 성동구 왕십리로 83-21"
        )
        #expect(
            CommunityPostViewModel.serializePlace(fullPlace)
                == "서울특별시 성동구 왕십리로 83-21, 멋쟁이사자처럼 캠퍼스"
        )
    }
}
