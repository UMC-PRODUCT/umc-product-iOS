//
//  CommunityThreadRoomViewModel+Image.swift
//  CommunityPresentation
//
//  Created by euijjang97 on 9/19/26.
//

import Foundation
import ImageIO
import PhotosUI
import UIKit
import CommunityDomain

/// 사진 메시지 전송 (#1451).
///
/// 업로드(prepare → PUT → confirm)가 끝나야 실어 보낼 `fileId` 가 생긴다. 그래서 낙관적 버블을
/// 먼저 꽂고, 업로드가 끝난 뒤에야 전송 타임아웃을 건다 — 업로드 시간까지 타임아웃에 넣으면
/// 느린 망에서 멀쩡한 전송이 실패로 뒤집힌다.
///
/// 낙관적 버블의 첨부는 다시 인코딩한 JPEG 을 임시 폴더에 쓴 로컬 파일이다. 버블은 서버 첨부와
/// 같은 경로로 그리고, 재전송은 이 파일을 다시 읽어 올린다.
extension CommunityThreadRoomViewModel {

    // MARK: - Computed Property

    /// 사진 버튼 활성 조건. 본문 검증이 없다는 것만 ``canSend`` 와 다르다.
    public var canAttachImage: Bool {
        canWrite && sendCooldownNotice == nil
    }

    // MARK: - Function

    /// 앨범에서 고른 사진을 IMAGE 메시지 한 통으로 보낸다.
    ///
    /// 읽거나 변환하지 못한 사진은 건너뛴다. 전부 실패하면 아무것도 보내지 않는다.
    public func sendImages(_ items: [PhotosPickerItem]) async {
        var images: [Data] = []
        for item in items {
            guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
            // 수천만 화소 사진의 디코딩·인코딩이 메인 스레드를 잡지 않게 넘긴다.
            let encoded = await Task.detached(priority: .userInitiated) {
                CommunityThreadRoomViewModel.jpegData(from: data)
            }.value
            if let encoded { images.append(encoded) }
        }
        await sendImages(jpegData: images)
    }

    /// 인코딩까지 끝난 JPEG 을 보낸다. 테스트는 PhotosPicker 없이 이 경로를 부른다.
    func sendImages(jpegData images: [Data]) async {
        guard canAttachImage else { return }
        let files = images
            .prefix(CommunityThreadRoomUseCase.imageMaxCount)
            .compactMap(Self.localFile(_:))
        guard !files.isEmpty else { return }

        let clientMessageId = UUID().uuidString.lowercased()
        messages.append(
            ThreadMessage(
                id: clientMessageId,
                threadId: threadId,
                senderId: currentMemberId ?? "",
                senderName: "",
                content: "",
                type: .image,
                files: files,
                clientMessageId: clientMessageId,
                createdAt: Date(),
                deliveryState: .sending
            )
        )
        await dispatchImages(clientMessageId: clientMessageId, files: files)
    }

    /// 업로드 → 전송. 어느 단계든 실패하면 버블을 `.failed` 로 돌려 재전송 버튼을 띄운다.
    /// 전역 Alert 을 띄우지 않는 이유는 텍스트 전송과 같다 (스펙 §7).
    ///
    /// ponytail: 재전송은 업로드부터 다시 한다 — 앞선 시도가 올린 파일은 서버에 남는다.
    /// 재전송이 잦아지면 clientMessageId 별로 fileId 를 들고 있다가 전송만 다시 한다.
    func dispatchImages(clientMessageId: String, files: [ThreadMessageFile]) async {
        do {
            var fileIds: [String] = []
            for file in files {
                guard let url = URL(string: file.fileURL) else {
                    throw CocoaError(.fileReadNoSuchFile)
                }
                let data = try Data(contentsOf: url)
                fileIds.append(try await useCase.uploadImage(jpegData: data))
            }
            startTimeout(for: clientMessageId)
            try await useCase.sendImage(
                threadId: threadId,
                clientMessageId: clientMessageId,
                fileMetadataIds: fileIds
            )
        } catch {
            markFailed(clientMessageId: clientMessageId)
        }
    }

    // MARK: - Static Function

    /// 긴 변을 ``Constants/maxPixelSize`` 로 줄여 JPEG 으로 다시 인코딩한다.
    ///
    /// ImageIO 썸네일 경로를 쓴다. 원본 전체를 `UIImage` 로 풀지 않아 메모리가 튀지 않고,
    /// EXIF 회전을 픽셀에 반영하며(`WithTransform`), HEIC 도 같은 경로로 읽는다. 원본이 더
    /// 작으면 키우지 않는다. GIF 는 첫 프레임만 남는다.
    nonisolated static func jpegData(from data: Data) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: Constants.maxPixelSize
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            options as CFDictionary
        ) else { return nil }
        return UIImage(cgImage: image).jpegData(compressionQuality: Constants.jpegQuality)
    }

    /// 낙관적 버블이 그릴 로컬 파일.
    ///
    /// ponytail: 임시 폴더 정리는 OS 에 맡긴다. 방을 오래 켜 두고 사진을 많이 보내는 경우가
    /// 문제가 되면 에코로 교체될 때 지운다.
    nonisolated private static func localFile(_ data: Data) -> ThreadMessageFile? {
        let id = UUID().uuidString.lowercased()
        let url = FileManager.default.temporaryDirectory.appending(path: "\(id).jpg")
        guard (try? data.write(to: url)) != nil else { return nil }
        return ThreadMessageFile(
            id: id,
            fileName: url.lastPathComponent,
            fileSize: String(data.count),
            fileURL: url.absoluteString
        )
    }
}

// MARK: - Constants

fileprivate enum Constants {
    /// 긴 변 상한(px). 채팅 화면과 전체 화면 뷰어 모두 이 이상은 티가 나지 않고, 서버 상한
    /// (장당 10MB)보다 훨씬 작게 떨어진다.
    static let maxPixelSize = 2_048
    static let jpegQuality: CGFloat = 0.8
}
