//
//  NavigationRoutable.swift
//  AppProduct
//
//  Created by euijjang97 on 1/8/26.
//

import Foundation
import Combine

// MARK: - NavigationRoutable 사용 예시
/// NavigationRoutable은 네비게이션 동작을 정의하는 프로토콜입니다.
/// NavigationRouter는 이 프로토콜의 기본 구현체로, 앱 전체 네비게이션을 관리합니다.
///
/// ## DIContainer에 등록
/// ```swift
/// container.register(NavigationRouter.self) {
///     NavigationRouter()
/// }
/// ```
///
/// ## View에서 사용
///
/// ### 화면 이동 (push)
/// ```swift
/// struct LoginView: View {
///     @Environment(\.di) private var container
///
///     var body: some View {
///         Button("회원가입으로 이동") {
///             let router = container.resolve(NavigationRouter.self)
///             router.push(to: .auth(.signup))
///         }
///     }
/// }
/// ```
///
/// ### 이전 화면으로 돌아가기 (pop)
/// ```swift
/// Button("뒤로가기") {
///     router.pop()
/// }
/// ```
///
/// ### 루트 화면으로 돌아가기 (popToRootView)
/// ```swift
/// Button("처음으로") {
///     router.popToRootView()
/// }
/// ```
///
/// ## NavigationStack과 연결
/// ```swift
/// struct ContentView: View {
///     @Environment(\.di) private var container
///
///     var body: some View {
///         let router = container.resolve(NavigationRouter.self)
///
///         NavigationStack(path: Binding(
///             get: { router.destination },
///             set: { router.destination = $0 }
///         )) {
///             HomeView()
///                 .navigationDestination(for: NavigationDestination.self) { destination in
///                     NavigationRoutingView(destination: destination)
///                 }
///         }
///     }
/// }
/// ```

protocol NavigationRoutable {
    var destination: [NavigationDestination] { get set }
    func push(to view: NavigationDestination)
    func pop()
    func popToRootView()
}

@Observable
class NavigationRouter: NavigationRoutable {
    var destination: [NavigationDestination] = .init()
    
    func push(to view: NavigationDestination) {
        destination.append(view)
    }
    
    func pop() {
        _ = destination.popLast()
    }
    
    func popToRootView() {
        destination.removeAll()
    }
}

