//
//  CertificateListView.swift
//  MyPagePresentation
//
//  Created by euijjang97 on 9/19/26.
//

import CoreDesignSystem
import CoreDI
import CoreDomain
import CoreUIComponents
import MyPageDomain
import QuickLook
import SwiftUI
import UMCFoundation

/// 「수료증 ・인증서」 — 발급 이력 목록 + 수료증 발급 메뉴.
///
/// 행을 누르면 PDF 를 받아 Quick Look 으로 보여주고, 받은 뒤에는 행에 공유 버튼이 붙는다.
struct CertificateListView: View {

    // MARK: - Property

    @State private var viewModel: CertificateListViewModel
    @Environment(ErrorHandler.self) private var errorHandler

    fileprivate enum Constants {
        static let icon = "rosette"
        static let emptyTitle = "발급받은 수료증이 없어요"
        static let emptyDescription = "수료한 기수의 수료증을 우측 상단에서 발급할 수 있어요."
        static let failedTitle = "수료증을 불러오지 못했어요"
        static let issueMenuTitle = "수료증 발급"
        static let shareIcon = "square.and.arrow.up"
        static let revokedBadge = "폐기됨"
        static let expiredBadge = "만료됨"
    }

    // MARK: - Init

    init(container: DIContainer) {
        _viewModel = State(initialValue: CertificateListViewModel(container: container))
    }

    // MARK: - Body

    var body: some View {
        content
            .navigation(naviTitle: NavigationTitle.MyPage.certificates, displayMode: .inline)
            .umcDefaultBackground()
            .toolbar {
                if !viewModel.issuableGisus.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        issueMenu
                    }
                }
            }
            .quickLookPreview($viewModel.previewURL)
            .task {
                await viewModel.fetch()
            }
    }

    // MARK: - View Component

    @ViewBuilder
    private var content: some View {
        switch viewModel.certificates {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .loaded(let certificates) where certificates.isEmpty:
            ContentUnavailableView(
                Constants.emptyTitle,
                systemImage: Constants.icon,
                description: Text(Constants.emptyDescription)
            )

        case .loaded(let certificates):
            List(certificates) { certificate in
                row(certificate)
                    .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .refreshable {
                await viewModel.fetch()
            }

        case .failed(let error):
            RetryContentUnavailableView(
                title: Constants.failedTitle,
                systemImage: Constants.icon,
                description: error.userMessage,
                isRetrying: viewModel.certificates.isLoading,
                error: error,
                retryAction: { await viewModel.fetch() }
            )
        }
    }

    private var issueMenu: some View {
        Menu {
            ForEach(viewModel.issuableGisus, id: \.gisuId) { record in
                Button("\(record.gisu)기 수료증") {
                    issue(gisuId: record.gisuId)
                }
            }
        } label: {
            Label(Constants.issueMenuTitle, systemImage: "plus")
        }
        .disabled(viewModel.isIssuing)
    }

    private func row(_ certificate: Certificate) -> some View {
        HStack(spacing: DefaultSpacing.spacing12) {
            Button {
                openPreview(certificate)
            } label: {
                HStack(spacing: DefaultSpacing.spacing12) {
                    VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
                        Text(certificate.title)
                            .appFont(.subheadline, weight: .semibold, color: .grey900)
                        Text(subtitle(certificate))
                            .appFont(.footnote, color: .grey500)
                    }
                    Spacer()
                    statusAccessory(certificate)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!certificate.isDownloadable || viewModel.downloadingId != nil)

            if let fileURL = viewModel.downloadedFiles[certificate.id] {
                ShareLink(item: fileURL) {
                    Image(systemName: Constants.shareIcon)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("\(certificate.title) 공유")
            }
        }
        .padding(.vertical, DefaultSpacing.spacing8)
    }

    @ViewBuilder
    private func statusAccessory(_ certificate: Certificate) -> some View {
        switch certificate.status {
        case .revoked:
            InfoBadge(Constants.revokedBadge)
        case .expired:
            InfoBadge(Constants.expiredBadge)
        case .issued where viewModel.downloadingId == certificate.id:
            Progress(size: .small)
        case .issued:
            Image(systemName: "chevron.right")
                .foregroundStyle(Color.grey500)
        }
    }

    // MARK: - Function

    private func subtitle(_ certificate: Certificate) -> String {
        let generation = "\(certificate.gisuGeneration)기"
        guard let issuedAt = certificate.issuedAt else { return generation }
        return "\(generation) · \(issuedAt.toYearMonthDay()) 발급"
    }

    private func issue(gisuId: String) {
        Task {
            do {
                try await viewModel.issue(gisuId: gisuId)
            } catch {
                errorHandler.handle(
                    error,
                    context: ErrorContext(feature: "MyPage", action: "issueCertificate")
                )
            }
        }
    }

    private func openPreview(_ certificate: Certificate) {
        Task {
            do {
                try await viewModel.openPreview(certificate)
            } catch {
                errorHandler.handle(
                    error,
                    context: ErrorContext(feature: "MyPage", action: "downloadCertificate")
                )
            }
        }
    }
}
