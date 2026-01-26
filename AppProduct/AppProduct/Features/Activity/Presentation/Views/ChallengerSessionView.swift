//
//  ChallengerSessionView.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/16/26.
//

import SwiftUI

struct ChallengerSessionView: View {
    @State private var attendanceViewModel: ChallengerAttendanceViewModel
    
    init(
        container: DIContainer,
        errorHandler: ErrorHandler
    ) {
        self._attendanceViewModel = .init(wrappedValue: .init(
            container: container,
            errorHandler: errorHandler,
            challengeAttendanceUseCase: container.resolve(ChallengerAttendanceUseCaseProtocol.self)))
    }
    
    var body: some View {
        Text("")
    }
}

#Preview {
    ChallengerSessionView(
        container: AttendancePreviewData.container,
        errorHandler: AttendancePreviewData.errorHandler
    )
}
