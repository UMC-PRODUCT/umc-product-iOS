//
//  ChallengerCodeAlert.swift
//  MyPagePresentation
//
//  Created by euijjang97 on 9/14/26.
//

import CoreDI
import CoreDomain
import SwiftUI
import UMCFoundation

/// 운영진 발급 코드로 챌린저 기록을 추가하는 입력 alert.
///
/// 「명함 편집」(``MyPageProfileView``)과 「활동 이력」(``MyActivityLogsView``)이 같은 입력·검증·
/// 실패 문구를 쓰므로 한 곳에 모았다. 기록이 추가되면 역할·기수가 바뀌어 로컬 세션 저장소도
/// 어긋나므로, 성공 후 동기화까지 이 modifier 가 맡는다.
private struct ChallengerCodeAlertModifier: ViewModifier {

    // MARK: - Property

    @Binding private var isPresented: Bool
    private let onSubmit: (String) async throws -> Void

    @Environment(\.di) private var di
    @Environment(ErrorHandler.self) private var errorHandler
    @State private var challengerCode: String = ""
    @State private var alertPrompt: AlertPrompt?

    private enum Constants {
        static let title = "챌린저 코드 입력"
        static let message = "운영진에게 발급받은 6자리 코드를 입력해주세요."
        static let fieldPlaceholder = "6자리 코드"
        static let codeLength = 6
    }

    // MARK: - Init

    init(isPresented: Binding<Bool>, onSubmit: @escaping (String) async throws -> Void) {
        self._isPresented = isPresented
        self.onSubmit = onSubmit
    }

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .alert(
                Constants.title,
                isPresented: $isPresented,
                actions: alertActions,
                message: alertMessage
            )
            .alertPrompt(item: $alertPrompt)
    }

    // MARK: - View Component

    @ViewBuilder
    private func alertActions() -> some View {
        TextField(Constants.fieldPlaceholder, text: $challengerCode)
            .keyboardType(.asciiCapable)

        Button("닫기", role: .cancel) {
            challengerCode = ""
        }

        Button("전송", action: submitChallengerCode)
    }

    private func alertMessage() -> some View {
        Text(Constants.message)
    }

    // MARK: - Function

    private func submitChallengerCode() {
        let trimmedCode = challengerCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidChallengerCode(trimmedCode) else {
            errorHandler.handle(
                AppError.validation(
                    .invalidFormat(
                        field: "challengerCode",
                        expected: "\(Constants.codeLength)자리 영숫자 코드"
                    )
                ),
                context: ErrorContext(feature: "MyPage", action: "submitChallengerCode")
            )
            return
        }

        Task {
            defer { challengerCode = "" }

            do {
                try await onSubmit(trimmedCode)
                await syncProfileStorage()
            } catch let error as RepositoryError {
                presentFailurePrompt(code: error.code, message: error.userMessage)
            } catch {
                errorHandler.handle(
                    error,
                    context: ErrorContext(feature: "MyPage", action: "addActivityLog")
                )
            }
        }
    }

    private func isValidChallengerCode(_ code: String) -> Bool {
        code.count == Constants.codeLength
            && code.unicodeScalars.allSatisfy(CharacterSet.alphanumerics.contains)
    }

    /// 활동 이력이 추가되면 역할·기수가 바뀌므로 `AppStorageKey` 기반 로컬 세션 값도 맞춘다.
    ///
    /// 동기화 실패는 이력 추가 자체를 되돌리지 않으므로 화면 흐름을 끊지 않는다.
    private func syncProfileStorage() async {
        let fetchProfile = di.resolve(FetchMemberProfileUseCaseProtocol.self)

        guard let profile = try? await fetchProfile.execute() else { return }

        di.resolve(SyncProfileStorageUseCaseProtocol.self).execute(profile: profile)
    }

    private func presentFailurePrompt(code: String?, message: String) {
        let resolvedMessage: String

        switch code {
        case "CHALLENGER-0002":
            resolvedMessage = "이미 등록된 사용자입니다."
        case "CHALLENGER-0012":
            resolvedMessage = "이미 사용된 챌린저 기록 추가용 코드입니다."
        case "CHALLENGER-0013":
            resolvedMessage = "코드에 등록된 사용자 이름이 요청자와 일치하지 않습니다."
        case "CHALLENGER-0014":
            resolvedMessage = "코드에 등록된 학교가 요청자 소속과 일치하지 않습니다."
        case "CHALLENGER-0016":
            resolvedMessage = "챌린저 기록 코드를 먼저 입력해주세요."
        default:
            resolvedMessage = message.strippingServerErrorCode()
        }

        alertPrompt = AlertPrompt(
            title: "인증 실패",
            message: resolvedMessage,
            positiveBtnTitle: "확인"
        )
    }
}

extension View {
    /// 챌린저 코드 입력 alert 를 붙인다.
    ///
    /// - Parameters:
    ///   - isPresented: alert 표시 여부
    ///   - onSubmit: 6자리 영숫자 검증을 통과한 코드를 서버에 보내는 동작. 성공 후 로컬 세션
    ///     저장소 동기화와 실패 문구 표시는 modifier 가 맡는다.
    func challengerCodeAlert(
        isPresented: Binding<Bool>,
        onSubmit: @escaping (String) async throws -> Void
    ) -> some View {
        modifier(ChallengerCodeAlertModifier(isPresented: isPresented, onSubmit: onSubmit))
    }
}
