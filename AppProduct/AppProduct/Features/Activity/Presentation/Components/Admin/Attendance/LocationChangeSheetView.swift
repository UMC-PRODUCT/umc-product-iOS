//
//  LocationChangeSheetView.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/6/26.
//

import SwiftUI

/// 세션 위치 변경 시트
///
/// 세션 정보를 표시하고 새 위치를 검색하여 선택할 수 있는 시트입니다.
struct LocationChangeSheetView: View {

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
            Form {
                if let session = session {
                    sessionInfoSection(session: session)

                    placeSelectionSection
                }
            }
            .formStyle(.grouped)
            .navigationTitle("위치 변경")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.height(310)])
            .presentationDragIndicator(.visible)
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

    // MARK: - Session Info Section

    private func sessionInfoSection(session: Session) -> some View {
        Section {
            VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
                Text(session.info.title)
                    .appFont(.calloutEmphasis)

                Text(session.info.startTime.timeRange(to: session.info.endTime))
                    .appFont(.footnote, color: .grey500)
            }
        } header: {
            Text("세션 정보")
        }
    }

    // MARK: - Place Selection Section

    private var placeSelectionSection: some View {
        Section {
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
        } header: {
            Text("새 위치")
        }
    }
    
    private var placeholderPlaceInfo: some View {
        Text("위치 선택하기")
            .appFont(.calloutEmphasis, color: .gray)
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
        LocationChangeSheetView(
            session: OperatorAttendancePreviewData.sessions.first?.session,
            errorHandler: AttendancePreviewData.errorHandler,
            onDismiss: {},
            onConfirm: { _ in }
        )
    }
}
#endif
