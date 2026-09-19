//
//  LocalCredentialViewModel.swift
//  MyPagePresentation
//
//  Created by euijjang97 on 9/19/26.
//

import AuthDomain
import CoreDI
import Foundation
import os.log

private let logger = Logger(subsystem: "UMCApp", category: "LocalCredential")

/// 설정 화면 회원관리의 비밀번호 행 분기 상태.
///
/// 소셜로만 가입해 로컬 비밀번호가 없는 회원은 「비밀번호 등록」, 있는 회원은 「비밀번호 변경」을
/// 본다. 공유 ``MyPageViewModel``을 건드리지 않도록 ``CalendarSyncViewModel``처럼 따로 둔다.
@Observable
@MainActor
final class LocalCredentialViewModel {

    // MARK: - Property

    /// 로컬 비밀번호 보유 여부. 조회에 한 번도 성공하지 못했으면 `nil`이고, 이때 행을 숨긴다.
    private(set) var hasLocalCredential: Bool?

    private let fetchHasLocalCredentialUseCase: FetchHasLocalCredentialUseCaseProtocol

    // MARK: - Init

    init(container: DIContainer) {
        fetchHasLocalCredentialUseCase = container.resolve(
            FetchHasLocalCredentialUseCaseProtocol.self
        )
    }

    // MARK: - Function

    /// 등록 화면에서 돌아올 때마다 다시 불러 행이 「비밀번호 변경」으로 바뀌게 한다.
    ///
    /// 행 분기용 보조 조회라 실패해도 흐름을 막는 Alert을 띄우지 않고 직전 값을 유지한다.
    func fetch() async {
        do {
            hasLocalCredential = try await fetchHasLocalCredentialUseCase.execute()
        } catch {
            logger.error("로컬 비밀번호 보유 여부 조회 실패: \(error.localizedDescription)")
        }
    }
}
