//
//  RetryContentUnavailableView.swift
//  CoreUIComponents
//
//  Created by 이예지 on 5/30/26.
//

import SwiftUI
import UIKit
import UMCFoundation

// MARK: - Constants

fileprivate enum Constants {
    static let reportTitle = "앱 문제 알리기"
    static let reportMessage = "오류 내용이 자동으로 복사돼요. "
        + "카카오톡 문의 채널로 넘어가서 채팅창에 붙여넣기해서 문의해 주시기 바랍니다."
    static let reportConfirmTitle = "문의 채널로 이동"
    static let reportCancelTitle = "취소"
}

// MARK: - Environment

extension EnvironmentValues {
    /// 문의 채널(카카오톡)을 여는 액션. 앱 루트가 주입한다.
    ///
    /// `CoreUIComponents` 가 KakaoSDK 에 의존하지 않도록 열기는 밖에서 넘겨받는다.
    /// 주입되지 않은 곳(프리뷰 등)에서는 `앱 문제 알리기` 버튼을 띄우지 않는다.
    @Entry public var openInquiryChannel: (@MainActor () -> Void)? = nil
}

/// 로딩 실패 시 재시도 액션을 함께 제공하는 공통 Unavailable View입니다.
///
/// `error` 가 앱 결함(``AppError/isReportable``)이면 `다시 시도` 아래에 `앱 문제 알리기`를
/// 띄운다. 채팅에 본문을 미리 채울 수 없어서(카카오 SDK 제약), 안내 알럿에서 확인하면 리포트를
/// 클립보드에 복사한 뒤 문의 채널을 연다. 취소하면 사용자 클립보드를 건드리지 않는다.
public struct RetryContentUnavailableView: View {

    // MARK: - Property
    public let title: String
    public let systemImage: String
    public let description: String
    public let retryTitle: String
    public let isRetrying: Bool
    public let minRetryButtonWidth: CGFloat
    public let minRetryButtonHeight: CGFloat
    public let topPadding: CGFloat
    public let error: AppError?
    public let screenName: String
    public let retryAction: () async -> Void

    @Environment(\.openInquiryChannel) private var openInquiryChannel
    @State private var reportPrompt: AlertPrompt?
    /// 리포트의 발생 시각. 실패 화면이 처음 뜬 시점으로 잡는다.
    @State private var failedAt = Date()

    // MARK: - Initializer

    /// - Parameters:
    ///   - error: 실패 원인. 앱 결함일 때만 `앱 문제 알리기`를 띄운다.
    ///   - screenName: 리포트에 적을 화면. 기본값은 호출한 파일(`#fileID`).
    public init(
        title: String,
        systemImage: String,
        description: String,
        retryTitle: String = "다시 시도",
        isRetrying: Bool,
        minRetryButtonWidth: CGFloat = 72,
        minRetryButtonHeight: CGFloat = 20,
        topPadding: CGFloat = .zero,
        error: AppError? = nil,
        screenName: String = #fileID,
        retryAction: @escaping () async -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.description = description
        self.retryTitle = retryTitle
        self.isRetrying = isRetrying
        self.minRetryButtonWidth = minRetryButtonWidth
        self.minRetryButtonHeight = minRetryButtonHeight
        self.topPadding = topPadding
        self.error = error
        self.screenName = screenName
        self.retryAction = retryAction
    }

    // MARK: - Body
    public var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(description)
                .multilineTextAlignment(.center)
        } actions: {
            Button {
                Task {
                    await retryAction()
                }
            } label: {
                ZStack {
                    Text(retryTitle)
                        .opacity(isRetrying ? 0 : 1)
                    if isRetrying {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
                .frame(
                    minWidth: minRetryButtonWidth,
                    minHeight: minRetryButtonHeight
                )
            }
            .buttonStyle(.glassProminent)
            .disabled(isRetrying)

            if let error, error.isReportable, openInquiryChannel != nil {
                Button(Constants.reportTitle) {
                    presentReportPrompt(for: error)
                }
                .buttonStyle(.glass)
            }
        }
        .padding(.top, topPadding)
        .alertPrompt(item: $reportPrompt)
    }

    // MARK: - Function

    /// 카카오톡으로 넘어가면 토스트는 앱 전환과 함께 사라지므로, 확인해야 넘어가는 알럿으로 안내한다.
    private func presentReportPrompt(for error: AppError) {
        let report = makeReport(for: error)
        reportPrompt = AlertPrompt(
            title: Constants.reportTitle,
            message: Constants.reportMessage,
            positiveBtnTitle: Constants.reportConfirmTitle,
            positiveBtnAction: {
                UIPasteboard.general.string = report
                openInquiryChannel?()
            },
            negativeBtnTitle: Constants.reportCancelTitle
        )
    }

    /// 운영진이 원인을 찾는 데 쓰는 리포트. 토큰·이메일 같은 개인 정보는 넣지 않는다.
    ///
    /// API 경로는 데이터 계층이 detail 에 넣어 둔 경우 `오류` 줄에 함께 실린다.
    private func makeReport(for error: AppError) -> String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "-"
        let build = info?["CFBundleVersion"] as? String ?? "-"
        return """
            [UMC 앱 문제 알림]
            화면: \(screenName)
            오류: \(error.errorDescription ?? "-")
            앱 버전: \(version) (\(build))
            iOS: \(UIDevice.current.systemVersion)
            기기: \(hardwareModel)
            발생 시각: \(failedAt.formatted(Date.ISO8601FormatStyle(timeZone: .current)))
            """
    }

    /// 기기 하드웨어 식별자 (`iPhone17,3`). `UIDevice.model` 은 `iPhone` 까지만 준다.
    private var hardwareModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafeBytes(of: systemInfo.machine) { bytes in
            String(decoding: bytes.prefix { $0 != 0 }, as: UTF8.self)
        }
    }
}
