//
//  DIContainer.swift
//  DIContainer
//
//  Created by euijjang97 on 12/29/25.
//

import Foundation

// MARK: - DIContainer 사용 예시
/// DIContainer는 의존성 주입(Dependency Injection)을 관리하는 컨테이너입니다.
/// 프로토콜과 구현체를 등록하고, 필요한 곳에서 resolve하여 사용합니다.
///
/// ## 기본 사용법
///
/// ### 1. 컨테이너 생성 및 의존성 등록
/// ```swift
/// let container = DIContainer()
///
/// // 프로토콜 타입으로 등록 (권장)
/// container.register(UserRepositoryProtocol.self) {
///     UserRepository()
/// }
///
/// // UseCase 등록 (Repository 의존성 주입)
/// container.register(LoginUseCaseProtocol.self) {
///     LoginUseCase(repository: container.resolve(UserRepositoryProtocol.self))
/// }
/// ```
///
/// ### 2. 등록된 의존성 사용
/// ```swift
/// // resolve로 인스턴스 가져오기 (싱글톤처럼 캐싱됨)
/// let userRepository = container.resolve(UserRepositoryProtocol.self)
/// let loginUseCase = container.resolve(LoginUseCaseProtocol.self)
/// ```
///
/// ### 3. 캐시 관리
/// ```swift
/// // 특정 타입의 캐시만 초기화
/// container.resetCache(for: UserRepositoryProtocol.self)
///
/// // 모든 캐시 초기화 (로그아웃 시 활용)
/// container.resetCache()
/// ```
///
/// ## SwiftUI에서 활용
///
/// ### App 진입점에서 Environment로 주입
/// ```swift
/// @main
/// struct MyApp: App {
///     @State private var container = DIContainer()
///
///     var body: some Scene {
///         WindowGroup {
///             ContentView()
///                 .environment(container)
///         }
///     }
/// }
/// ```
///
/// ### View에서 사용
/// ```swift
/// struct LoginView: View {
///     @Environment(\.di) private var container
///
///     var body: some View {
///         Button("로그인") {
///             let useCase = container.resolve(LoginUseCaseProtocol.self)
///             useCase.execute()
///         }
///     }
/// }
/// ```

@Observable
final class DIContainer {
    
    // MARK: - Storage
    private var factories: [ObjectIdentifier: Any] = [:]
    private var cachedInstances: [ObjectIdentifier: Any] = [:]
    
    // MARK: - Registration
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = ObjectIdentifier(type)
        factories[key] = factory
    }
    
    // MARK: - Resolution
    func resolve<T>(_ type: T.Type) -> T {
        let key = ObjectIdentifier(type)
        if let cached = cachedInstances[key] as? T {
            return cached
        }
        guard let factory = factories[key] as? () -> T else {
            fatalError("DIContainer Error: No Factory registered for type '\(T.self)'.")
        }
        let instance = factory()
        cachedInstances[key] = instance
        return instance
    }
    
    // MARK: - Cache Management
    func resetCache() {
        cachedInstances.removeAll()
    }
    
    func resetCache<T>(for type: T.Type) {
        let key = ObjectIdentifier(type)
        cachedInstances.removeValue(forKey: key)
    }
}
