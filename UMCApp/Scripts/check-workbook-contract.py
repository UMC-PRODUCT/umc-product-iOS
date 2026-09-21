#!/usr/bin/env python3
# Created by euijjang97 on 2026-09-21.
import pathlib
import subprocess
import tempfile

root = pathlib.Path(__file__).resolve().parents[1]
activity = root / "Features/Activity"
paths = [
    root / "Core/Foundation/Sources/Extensions/KeyedDecodingContainer+FlexibleNumber.swift",
    activity / "Domain/Sources/Models/Study/WorkbookDetail.swift",
    activity / "Data/Sources/DTOs/WorkbookDetailDTO.swift",
]
source = "\n".join(
    "\n".join(line for line in path.read_text().splitlines()
              if not line.startswith(("import ActivityDomain", "import UMCFoundation")))
    for path in paths
)
router = (activity / "Data/Sources/Routers/WorkbookRouter.swift").read_text()
source += "\n" + router[router.index("struct MissionSubmissionRequestDTO"):router.index("enum WorkbookRouter")]
assert '.requestData(Data(content.utf8))' in router
assert '"text/plain; charset=utf-8"' in router
source += r'''
let decoder = JSONDecoder()
let originalJSON = #"{"originalWorkbookId":"10","title":"Week","missionList":[{"originalWorkbookMissionId":21,"title":"Memo","missionType":"MEMO","isNecessary":true}]}"#
let personalJSON = #"{"challengerWorkbookId":30,"originalWorkbookId":"10","receivedStudyGroupId":null,"memberId":"40","isExcused":false,"submissions":[{"missionSubmissionId":50,"originalWorkbookMissionId":"21","status":"PASS","submittedContent":"hello","feedbacks":[{"missionFeedbackId":"60","reviewerMemberId":70,"content":"good","feedbackResult":"PASS"}]}]}"#
let original = try decoder.decode(OriginalWorkbookDetailDTO.self, from: Data(originalJSON.utf8))
let personal = try decoder.decode(ChallengerWorkbookDetailDTO.self, from: Data(personalJSON.utf8))
assert(original.toDomain().missionList.first?.originalWorkbookMissionId == "21")
assert(personal.toDomain().challengerWorkbookId == "30")
assert(personal.toDomain().receivedStudyGroupId == nil)
assert(personal.toDomain().submissions.first?.missionSubmissionId == "50")
assert(personal.toDomain().submissions.first?.feedbacks.first?.reviewerMemberId == "70")
let roundtrip = try decoder.decode(ChallengerWorkbookDetailDTO.self,
                                  from: JSONEncoder().encode(personal))
assert(roundtrip.toDomain() == personal.toDomain())
let request = MissionSubmissionRequestDTO(originalWorkbookMissionId: 21,
                                          challengerMissionId: 30, content: nil)
let object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(request)) as! [String: Any]
assert(object["originalWorkbookMissionId"] as? Int == 21)
assert(object["challengerMissionId"] as? Int == 30)
assert(object["content"] == nil)
let feedback = MissionFeedbackRequestDTO(missionSubmissionId: 50, content: "text", result: "FAIL")
let feedbackObject = try JSONSerialization.jsonObject(with: JSONEncoder().encode(feedback)) as! [String: Any]
assert(feedbackObject["result"] as? String == "FAIL")
let content = "quote \" / slash \\ / line\n한글"
assert(String(data: Data(content.utf8), encoding: .utf8) == content)
print("Workbook DTO and request contract checks passed")
'''
with tempfile.TemporaryDirectory(prefix="workbook-contract-") as temporary:
    swift = pathlib.Path(temporary) / "main.swift"
    swift.write_text(source)
    subprocess.run(["xcrun", "swift", str(swift)], check=True)
