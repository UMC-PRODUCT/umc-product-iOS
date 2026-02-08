//
//  SwipeableRow.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/8/26.
//

import SwiftUI

// MARK: - Constants

fileprivate enum SwipeableRowConstants {
    static let minimumDragDistance: CGFloat = 20
    static let swipeThreshold: CGFloat = 60

    /// 드래그 중 인터랙티브 스프링 파라미터
    /// response: 높을수록 부드럽게 따라옴
    static let interactiveResponse: Double = 0.20
    /// dampingFraction: 1.0 미만이면 약간의 탄성 부여
    static let interactiveDamping: Double = 0.92
}

/// 스와이프 가능한 행 컴포넌트
///
/// 좌측 스와이프 시 액션 버튼을 노출하는 제네릭 컴포넌트입니다.
/// SwipeStateManager와 연동하여 한 번에 하나의 셀만 열리도록 관리합니다.
///
/// - Parameters:
///   - Content: 메인 콘텐츠 뷰 타입
///   - Actions: 액션 버튼 영역 뷰 타입
struct SwipeableRow<Content: View, Actions: View>: View {
    // MARK: - Properties

    /// 셀 고유 식별자
    let id: UUID

    /// 액션 영역 너비
    let actionWidth: CGFloat

    /// 메인 콘텐츠 빌더
    @ViewBuilder let content: () -> Content

    /// 액션 버튼 빌더
    @ViewBuilder let actions: () -> Actions

    /// 스와이프 상태 관리자
    @Environment(SwipeStateManager.self) private var swipeState

    /// 현재 offset 상태
    @State private var offset: CGFloat = 0

    /// 드래그 시작 시점의 offset (열린 상태에서 닫을 때 필요)
    @State private var dragStartOffset: CGFloat = 0

    /// 수평 드래그 여부 (방향 판단용)
    @State private var isHorizontalDrag: Bool? = nil

    // MARK: - Computed Properties

    /// 스와이프 진행률 (0.0 ~ 1.0)
    private var swipeProgress: CGFloat {
        guard actionWidth > 0 else { return 0 }
        return min(1.0, abs(offset) / actionWidth)
    }

    /// 액션 버튼 불투명도 (부드러운 등장)
    private var actionOpacity: CGFloat {
        // 20% 스와이프부터 서서히 나타남
        let adjustedProgress = max(0, (swipeProgress - 0.2) / 0.8)
        return adjustedProgress
    }

    /// 액션 버튼 스케일 (부드러운 확대)
    private var actionScale: CGFloat {
        // 0.8에서 1.0으로 확대
        return 0.8 + (swipeProgress * 0.2)
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .trailing) {
            // 액션 버튼 영역 (항상 존재, opacity로 제어)
            actions()
                .frame(width: actionWidth)
                .opacity(actionOpacity)
                .scaleEffect(actionScale)
                .allowsHitTesting(offset < 0)

            // 메인 콘텐츠 - 전체 너비 차지
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .offset(x: offset)
        }
        .clipped(if: swipeState.isOpen(id) || offset != 0)
        .onChange(of: swipeState.openCellID) { oldValue, newValue in
            // 다른 셀이 열리면 빠르게 닫기 (잔상 방지)
            if newValue != id, offset != 0 {
                closeCellQuickly()
            }
        }
        .simultaneousGesture(swipeGesture)
    }

    // MARK: - Gesture

    /// 스와이프 제스처
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: SwipeableRowConstants.minimumDragDistance)
            .onChanged { value in
                handleDragChanged(value)
            }
            .onEnded { value in
                handleDragEnded(value)
            }
    }

    // MARK: - Functions

    /// 드래그 진행 중 처리
    private func handleDragChanged(_ value: DragGesture.Value) {
        // 최초 드래그 시 방향 판단 및 시작 offset 저장
        if isHorizontalDrag == nil {
            let horizontalDistance = abs(value.translation.width)
            let verticalDistance = abs(value.translation.height)
            isHorizontalDrag = horizontalDistance > verticalDistance
            dragStartOffset = offset  // 드래그 시작 시점의 offset 저장
        }

        // 수평 드래그만 처리
        guard isHorizontalDrag == true else { return }

        // 시작 offset + translation으로 새 offset 계산
        // 열린 상태에서 닫을 때도 손가락을 따라감
        let newOffset = min(0, max(-actionWidth, dragStartOffset + value.translation.width))

        // 드래그 중에는 interactiveSpring으로 velocity 자동 추적
        withAnimation(.interactiveSpring(
            response: SwipeableRowConstants.interactiveResponse,
            dampingFraction: SwipeableRowConstants.interactiveDamping
        )) {
            offset = newOffset
        }
    }

    /// 드래그 종료 처리
    private func handleDragEnded(_ value: DragGesture.Value) {
        defer {
            isHorizontalDrag = nil
            dragStartOffset = 0
        }

        // 수평 드래그가 아니면 무시
        guard isHorizontalDrag == true else { return }

        let velocity = value.velocity.width
        let finalOffset = dragStartOffset + value.translation.width

        // 최종 offset이 절반 이상 열렸거나, 빠른 속도로 왼쪽 스와이프
        let shouldOpen = -finalOffset > (actionWidth / 2) || velocity < -500

        // 빠른 속도로 오른쪽 스와이프하면 닫기
        let shouldClose = velocity > 500

        if shouldClose {
            closeCell(velocity: velocity)
        } else if shouldOpen {
            openCell(velocity: velocity)
        } else {
            closeCell(velocity: velocity)
        }
    }

    /// 셀 열기 (smooth 애니메이션 - bounce 없이 부드럽게)
    private func openCell(velocity: CGFloat = 0) {
        withAnimation(.smooth) {
            offset = -actionWidth
        }
        swipeState.open(id)
    }

    /// 셀 닫기 (smooth 애니메이션 - bounce 없이 부드럽게)
    private func closeCell(velocity: CGFloat = 0) {
        withAnimation(.smooth) {
            offset = 0
        }
        if swipeState.isOpen(id) {
            swipeState.close()
        }
    }

    /// 셀 빠르게 닫기 (다른 셀이 열릴 때 잔상 방지)
    private func closeCellQuickly() {
        withAnimation(.smooth(duration: 0.2)) {
            offset = 0
        }
    }
}

// MARK: - View Extension

private extension View {
    /// 조건부 클리핑
    ///
    /// 스와이프 중일 때만 클리핑을 적용하여 평상시 그림자가 보이도록 합니다.
    @ViewBuilder
    func clipped(if condition: Bool) -> some View {
        if condition {
            self.clipped()
        } else {
            self
        }
    }
}
