//
//  StudySubmissionWeeksDTOTests.swift
//
//  Created by euijjang97 on 9/21/26.
//

import Foundation
import Testing
@testable import ActivityData

struct StudySubmissionWeeksDTOTests {
    @Test(arguments: ["[1,2,12]", "[\"1\",\"2\",\"12\"]", "[1,\"2\",12]"])
    func decodesWeekNumbers(_ json: String) throws {
        let weeks = try JSONDecoder().decode(StudySubmissionWeeksDTO.self, from: Data(json.utf8))
        #expect(weeks.weekNos == ["1", "2", "12"])
    }

    @Test
    func supportsEmptyCurriculumAndRejectsMalformedNumbers() throws {
        let weeks = try JSONDecoder().decode(StudySubmissionWeeksDTO.self, from: Data("[]".utf8))
        #expect(weeks.weekNos.isEmpty)
        for json in ["[true]", "[null]", "[1.5]", "[0]", "[\"invalid\"]"] {
            #expect(throws: (any Error).self) {
                try JSONDecoder().decode(StudySubmissionWeeksDTO.self, from: Data(json.utf8))
            }
        }
        let query = StudySubmissionWeeksQuery(studyGroupId: "42", gisuId: "3")
        #expect(query.toParameters["studyGroupId"] as? String == "42")
        #expect(query.toParameters["gisuId"] as? String == "3")
        #expect(query.toParameters["part"] == nil)
        #expect(StudySubmissionWeeksQuery(studyGroupId: nil).toParameters.isEmpty)
    }
}
