//
//  ProjectInfoEditorView.swift
//  ProjectPresentation
//
//  Created by euijjang97 on 9/20/26.
//

import CoreDesignSystem
import CoreDI
import CorePhoto
import CoreUIComponents
import PhotosUI
import SwiftUI
import UIKit
import UMCFoundation

struct ProjectInfoEditorView: View {

    // MARK: - Property

    @State private var viewModel: ProjectInfoEditorViewModel
    @State private var thumbnailItem: PhotosPickerItem?
    @State private var logoItem: PhotosPickerItem?
    @Environment(\.dismiss) private var dismiss
    @Environment(ErrorHandler.self) private var errorHandler

    fileprivate enum Constants {
        static let title = "기본 정보 수정"
        static let infoHeader = "프로젝트 정보"
        static let imageHeader = "이미지"
        static let thumbnail = "썸네일 선택"
        static let logo = "로고 선택"
        static let maxPixelLength: CGFloat = 2_048
        static let maxByteCount = 10 * 1_024 * 1_024
    }

    // MARK: - Init

    init(container: DIContainer, projectId: String) {
        _viewModel = State(
            initialValue: ProjectInfoEditorViewModel(container: container, projectId: projectId)
        )
    }

    // MARK: - Body

    var body: some View {
        content
            .navigationTitle(Constants.title)
            .navigationBarTitleDisplayMode(.inline)
            .umcDefaultBackground()
            .toolbar {
                ToolBarCollection.ConfirmBtn(
                    action: save,
                    disable: !viewModel.canSave,
                    isLoading: viewModel.isSaving,
                    dismissOnTap: false
                )
            }
            .task { await viewModel.fetch() }
            .onChange(of: thumbnailItem) { _, item in
                Task { viewModel.thumbnailData = await imageData(from: item) }
            }
            .onChange(of: logoItem) { _, item in
                Task { viewModel.logoData = await imageData(from: item) }
            }
    }

    // MARK: - View Component

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            ProgressView()

        case .loaded:
            Form {
                Section(Constants.infoHeader) {
                    TextField("프로젝트명", text: $viewModel.name)
                    TextField("설명", text: $viewModel.projectDescription, axis: .vertical)
                        .lineLimit(3...6)
                    TextField("외부 링크", text: $viewModel.externalLink)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                }
                Section(Constants.imageHeader) {
                    PhotosPicker(selection: $thumbnailItem, matching: .images) {
                        Label(Constants.thumbnail, systemImage: "photo")
                    }
                    PhotosPicker(selection: $logoItem, matching: .images) {
                        Label(Constants.logo, systemImage: "app.dashed")
                    }
                }
            }
            .scrollContentBackground(.hidden)

        case .failed(let error):
            RetryContentUnavailableView(
                title: "프로젝트 정보를 불러오지 못했어요",
                systemImage: "square.and.pencil",
                description: error.userMessage,
                isRetrying: viewModel.loadState.isLoading,
                error: error,
                retryAction: { await viewModel.fetch() }
            )
        }
    }

    // MARK: - Function

    private func save() {
        Task {
            do {
                try await viewModel.save()
                dismiss()
            } catch {
                errorHandler.handle(
                    error,
                    context: ErrorContext(feature: "Project", action: "updateProject")
                )
            }
        }
    }

    private func imageData(from item: PhotosPickerItem?) async -> Data? {
        guard let rawData = try? await item?.loadTransferable(type: Data.self),
              let image = UIImage(data: rawData)
        else { return nil }
        return image.jpegDataForUpload(
            maxPixelLength: Constants.maxPixelLength,
            maxByteCount: Constants.maxByteCount
        )
    }
}
