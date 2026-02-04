//
//  NoticeReadStatusSheet.swift
//  AppProduct
//
//  Created by 이예지 on 2/3/26.
//

import SwiftUI

struct NoticeReadStatusSheet: View {
    
    // MARK: - Property
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: NoticeDetailViewModel
    @State var rotationTrigger = 0
    
    // MARK: - Constant
    fileprivate enum Constants {
        static let listRowPadding: EdgeInsets = .init(top: 5, leading: .zero, bottom: 5, trailing: .zero)
        static let alarmPadding: EdgeInsets = .init(top: 10, leading: 14, bottom: 10, trailing: 14)
        static let capsulePadding: EdgeInsets = .init(top: 8, leading: 12, bottom: 8, trailing: 12)
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.readStatusState {
                case .idle:
                    Color.clear.task {
                        print("데이터 로딩이 시작되지 않음")
                    }
                case .loading:
                    Progress()
                case .loaded(_):
                    userListSection
                case .failed(_):
                    Color.clear.task {
                        print("에러 발생")
                    }
                }
            }
            .navigation(naviTitle: .noticeReadStatus, displayMode: .inline)
            .toolbar {
                ToolBarCollection.LeadingButton(image: "xmark", action: { dismiss() })
                
                ToolBarCollection.ReadStatusFilter(
                    items: Array(ReadStatusFilterType.allCases),
                    selection: $viewModel.selectedFilter,
                    itemLabel: { $0.rawValue },
                    itemIcon: nil
                )
            }
            .safeAreaBar(edge: .top) {
                segmentedSection
                    .padding(.bottom, DefaultSpacing.spacing8)

            }
            .safeAreaBar(edge: .bottom, alignment: .trailing) {
                GlassEffectContainer {
                    if viewModel.selectedReadTab == .unconfirmed {
                        reAlarmSection
                            .padding(.top, DefaultSpacing.spacing8)
                    }
                }
            }
        }
    }
    
    // 상단 세그먼트(미확인/확인)
    private var segmentedSection: some View {
        Picker("", selection: $viewModel.selectedReadTab) {
            Text("미확인 \(viewModel.unconfirmedCount)")
                .tag(ReadStatusTab.unconfirmed)
            
            Text("확인 \(viewModel.confirmedCount)")
                .tag(ReadStatusTab.confirmed)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, DefaultConstant.defaultSafeHorizon)
    }
    
    // MARK: - User List Section
    private var userListSection: some View {
        List {
            switch viewModel.selectedFilter {
            case .all:
                allUsersView
            case .branch:
                groupedView(groupedData: viewModel.groupedUsersByBranch)
            case .school:
                groupedView(groupedData: viewModel.groupedUsersBySchool)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .padding(.horizontal, DefaultConstant.defaultSafeHorizon)
    }
    
    // 전체 보기
    private var allUsersView: some View {
        ForEach(viewModel.filteredReadStatusUsers) { user in
            NoticeReadStatusItem(model: user.toItemModel())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(Constants.listRowPadding)
        }
    }
    
    // 공통 그룹화 뷰 (지부별/학교별)
    private func groupedView(groupedData: [String: [ReadStatusUser]]) -> some View {
        ForEach(Array(groupedData.keys.sorted()), id: \.self) { key in
            Section {
                ForEach(groupedData[key] ?? []) { user in
                    NoticeReadStatusItem(model: user.toItemModel())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(Constants.listRowPadding)
                }
            } header: {
                Text(key)
                    .appFont(.calloutEmphasis, color: .indigo600)
            }
        }
        .listSectionSpacing(DefaultSpacing.spacing8)
    }
    
    // 하단 버튼(미확인 탭)
    private var reAlarmSection: some View {
        Button(action: {
            rotationTrigger += 1
            // TODO: 재알림 전송 API - [이예지] 26.02.04
        }) {
            Label {
                Text("재알림 보내기")
            } icon: {
                Image(systemName: "arrow.trianglehead.clockwise")
                    .symbolEffect(.rotate, value: rotationTrigger)
                    .fontWeight(.bold)
            }
            .appFont(.body, weight: .medium, color: .white)
            .padding(Constants.alarmPadding)
            .background {
                RoundedRectangle(cornerRadius: DefaultConstant.defaultCornerRadius)
                    .fill(.indigo400)
            }
        }
        .padding(.horizontal, DefaultConstant.defaultSafeHorizon)
    }
}

// MARK: - Preview
#Preview {
    let previewVM = NoticeDetailViewModel(
        noticeID: "1",
        errorHandler: ErrorHandler(),
        initialNotice: NoticeDetailMockData.sampleNoticeWithPermission
    )
    previewVM.readStatusState = .loaded(NoticeDetailMockData.sampleReadStatus)
    
    return Text("Preview Trigger")
        .sheet(isPresented: .constant(true)) {
            NavigationStack {
                NoticeReadStatusSheet(viewModel: previewVM)
            }
        }
}
