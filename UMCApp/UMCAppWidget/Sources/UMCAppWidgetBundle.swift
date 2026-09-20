//
//  UMCAppWidgetBundle.swift
//  UMCAppWidget
//
//  Created by euijjang97 on 4/23/26.
//

import CoreDesignSystem
import WidgetKit
import SwiftUI

@main
struct UMCAppWidgetBundle: WidgetBundle {
    init() {
        // 익스텐션은 앱과 다른 프로세스라 Pretendard 를 따로 등록해야 한다.
        CoreDesignSystem.registerFonts()
    }

    var body: some Widget {
        UMCHomeWidget()
        AttendanceLiveActivity()
    }
}
