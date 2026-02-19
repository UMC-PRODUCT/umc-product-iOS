//
//  OperatorLocationChangeSheetView.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/6/26.
//

import SwiftUI

/// 세션 위치 변경 시트
///
/// 세션 정보를 표시하고 새 위치를 검색하여 선택할 수 있는 시트입니다.
struct OperatorLocationChangeSheetView: View {

    // MARK: - Property

    private let session: Session?
    private let errorHandler: ErrorHandler
    private let onDismiss: () -> Void
    private let onConfirm: (PlaceSearchInfo) -> Void

    @State private var selectedPlace: PlaceSearchInfo = .init(
        name: "",
        address: "",
        coordinate: .init(latitude: 0, longitude: 0)
    )
    @State private var showSearchPlaceSheet: Bool = false

    // MARK: - Constant

    private enum Constants {
        static let rootHorizontalPadding: CGFloat = 14
        static let rootTopPadding: CGFloat = 6
        static let rootBottomPadding: CGFloat = 16
    }

    // MARK: - Init

    init(
        session: Session?,
        errorHandler: ErrorHandler,
        onDismiss: @escaping () -> Void,
        onConfirm: @escaping (PlaceSearchInfo) -> Void
    ) {
        self.session = session
        self.errorHandler = errorHandler
        self.onDismiss = onDismiss
        self.onConfirm = onConfirm
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: DefaultSpacing.spacing12) {
                if let session = session {
                    sessionInfoCard(session: session)
                    placeSelectionCard
                } else {
                    Text("세션 정보를 불러올 수 없습니다.")
                        .appFont(.subheadline, color: .grey500)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, DefaultSpacing.spacing8)
                }
            }
            .padding(.horizontal, Constants.rootHorizontalPadding)
            .padding(.top, Constants.rootTopPadding)
            .padding(.bottom, Constants.rootBottomPadding)
            .navigationTitle("위치 변경")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.height(320)])
            .presentationDragIndicator(.hidden)
            .toolbar {
                ToolBarCollection.CancelBtn {
                    onDismiss()
                }

                ToolBarCollection.ConfirmBtn(action: {
                    onConfirm(selectedPlace)
                }, disable: selectedPlace.name.isEmpty)
            }
            .sheet(isPresented: $showSearchPlaceSheet) {
                SearchMapView(errorHandler: errorHandler) { place in
                    selectedPlace = place
                    showSearchPlaceSheet = false
                }
            }
        }
    }

    // MARK: - Session Info Card

    private func sessionInfoCard(session: Session) -> some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
            Text("세션")
                .appFont(.caption1, color: .grey500)

            Text(session.info.title)
                .appFont(.calloutEmphasis)

            Text(session.info.startTime.timeRange(to: session.info.endTime))
                .appFont(.footnote, color: .grey500)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: DefaultConstant.cornerRadius))
        .glass()
    }

    // MARK: - Place Selection Card

    private var placeSelectionCard: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
            Text("새 위치")
                .appFont(.caption1, color: .grey500)

            Group {
                if selectedPlace.name == "" {
                    placeholderPlaceInfo
                } else {
                    selectedPlaceInfo
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                showSearchPlaceSheet = true
            }
        }
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: DefaultConstant.cornerRadius))
        .glass()
    }
    
    private var placeholderPlaceInfo: some View {
        HStack {
            Image(systemName: "location.circle")
                .foregroundStyle(.grey400)
            Text("위치 선택하기")
                .appFont(.callout, color: .grey500)
        }
        .padding(.vertical, 2)
    }

    private var selectedPlaceInfo: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
            Text(selectedPlace.name)
                .appFont(.calloutEmphasis)

            Text(selectedPlace.address)
                .appFont(.footnote, color: .grey500)
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    NavigationStack {
        Text("1")
    }
    .sheet(isPresented: .constant(true)) {
        OperatorLocationChangeSheetView(
            session: OperatorAttendancePreviewData.sessions.first?.session,
            errorHandler: AttendancePreviewData.errorHandler,
            onDismiss: {},
            onConfirm: { _ in }
        )
    }
}
#endif
