//
//  VoteAttachmentCard.swift
//  AppProduct
//
//  Created by 이예지 on 1/29/26.
//

import SwiftUI

struct VoteAttachmentCard: View {
    
    @Binding var formData: VoteFormData
    
    fileprivate enum Constants {
        static let textSpacing: CGFloat = 35
        static let bgOpacity: Double = 0.6
    }
  
    var body: some View {
        HStack(alignment: .center) {
            textSection
            Spacer()
            chevronSection
        }
        .padding(DefaultConstant.defaultSafeHorizon)
        .background {
            RoundedRectangle(cornerRadius: DefaultConstant.defaultCornerRadius)
                .fill(.indigo100)
                .opacity(Constants.bgOpacity)
                .glassEffect(.clear, in: .rect(cornerRadius: DefaultConstant.defaultCornerRadius))
        }
    }
    
    private var textSection: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing8) {
            Label("투표", systemImage: "chart.bar.fill")
                .appFont(.calloutEmphasis)
            Text("\(anonymousLabel), \(allowMultipleLabel), \(formData.validOptionsCount)개 항목")
                .padding(.leading, Constants.textSpacing)
                .appFont(.footnote, color: .grey500)
        }
    }
    
    private var anonymousLabel: String {
        formData.isAnonymous ? "익명" : "공개"
    }
    
    private var allowMultipleLabel: String {
        formData.allowMultipleSelection ? "복수 선택 가능" : "1개 선택 가능"
    }
    
    private var chevronSection: some View {
        Image(systemName: "chevron.right")
            .foregroundStyle(.grey500)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    @Previewable @State var formData = VoteFormData()
    
    VoteAttachmentCard(formData: $formData)
}
