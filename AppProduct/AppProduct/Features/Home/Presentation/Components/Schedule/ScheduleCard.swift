//
//  SCheduleCard.swift
//  AppProduct
//
//  Created by euijjang97 on 1/15/26.
//

import SwiftUI

struct ScheduleCard: View {
    @State private var selectedDate = Date()
    @State var scheduleMode: ScheduleMode = .horizon
    @State private var currentMonth = Date()
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    ScheduleCard()
}
