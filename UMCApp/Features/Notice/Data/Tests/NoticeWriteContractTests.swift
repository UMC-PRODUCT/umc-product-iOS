import Foundation
import Testing

@testable import NoticeData

@Suite("Notice write contracts")
struct NoticeWriteContractTests {
    @Test func retainsFileUUIDSeparatelyFromRowID() throws {
        let data = Data(
            #"""
            {"id":"12",
            "fileId":"A2542D53-24E1-4933-A604-F7A9D267B205",
            "url":"https://example.com/a",
            "displayOrder":"0"}
            """#
            .utf8)
        let image = try JSONDecoder().decode(NoticeDetailImageDTO.self, from: data)
        #expect(image.id == "12")
        #expect(image.fileId == "A2542D53-24E1-4933-A604-F7A9D267B205")
    }

    @Test func missingFileUUIDDoesNotFallBackToRowID() throws {
        let data = Data(#"{"id":"12","url":"https://example.com/a","displayOrder":"0"}"#.utf8)
        let image = try JSONDecoder().decode(NoticeDetailImageDTO.self, from: data)
        #expect(image.fileId == nil)
    }

    @Test(arguments: [true, false]) func preservesMustRead(_ mustRead: Bool) throws {
        let data = Data("{\"id\":\"1\",\"viewCount\":\"0\",\"mustRead\":\(mustRead)}".utf8)
        let detail = try JSONDecoder().decode(NoticeDetailDTO.self, from: data).toDomain()
        let request = UpdateNoticeRequestDTO(
            title: "edited", content: "edited", mustRead: detail.isMustRead
        )
        let json = try #require(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(request))
                as? [String: Any])
        #expect(json["mustRead"] as? Bool == mustRead)
    }
    @Test func listPreservesMustRead() throws {
        let data = Data(
            #"""
            {"id":"1",
            "title":"notice",
            "content":"body",
            "viewCount":"0",
            "createdAt":"2026-09-27T00:00:00Z",
            "mustRead":true,
            "targetInfo":{"targetGisuId":"1"}}
            """#
            .utf8)
        let item = try JSONDecoder().decode(NoticeDTO.self, from: data).toItemModel()
        #expect(item.mustRead)
    }

    @Test func malformedImagesFailInsteadOfErasingAttachments() {
        let data = Data(
            #"{"id":"1","viewCount":"0","images":[{"id":"1","url":null,"displayOrder":"0"}]}"#.utf8
        )
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(NoticeDetailDTO.self, from: data)
        }
    }

}
