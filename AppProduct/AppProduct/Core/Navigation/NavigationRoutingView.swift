//
//  NavigationRoutingView.swift
//  AppProduct
//
//  Created by euijjang97 on 1/8/26.
//

import SwiftUI

// MARK: - NavigationRoutingView 사용 예시
/// NavigationRoutingView는 NavigationDestination에 따라 적절한 화면을 렌더링하는 라우팅 뷰입니다.
/// navigationDestination modifier와 함께 사용하여 타입 세이프한 화면 전환을 구현합니다.
///
/// ## 사용 방법
///
/// ### NavigationStack에서 연결
/// ```swift
/// NavigationStack(path: $router.destination) {
///     RootView()
///         .navigationDestination(for: NavigationDestination.self) { destination in
///             NavigationRoutingView(destination: destination)
///         }
/// }
/// ```
///
/// ## 새로운 화면 라우팅 추가
///
/// ### switch문에 case 추가
/// ```swift
/// var body: some View {
///     switch destination {
///     case .auth(let auth):
///         switch auth {
///         case .test:
///             AuthTestView()
///         case .login:
///             LoginView()        // 새 화면 추가
///         case .signup(let email):
///             SignupView(email: email)
///         }
///     case .home(let home):
///         switch home {
///         case .test:
///             HomeTestView()
///         }
///     }
/// }
/// ```

struct NavigationRoutingView: View {
    @Environment(\.di) var di: DIContainer
    @State var destination: NavigationDestination
    
    var body: some View {
        switch destination {
        case .auth:
            Text("A")
        case .home:
            Text("B")
        }
    }
}
