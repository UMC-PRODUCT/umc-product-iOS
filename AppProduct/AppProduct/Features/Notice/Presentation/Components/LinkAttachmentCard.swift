//
//  LinkAttachmentCard.swift
//  AppProduct
//
//  Created by 이예지 on 1/26/26.
//

import SwiftUI

struct LinkAttachmentCard: View, Equatable {
    
    // MARK: - Property
    @Binding var link: String
    var onDismiss: () -> Void
    
    // MARK: - Constant
    fileprivate enum Constants {
        static let xmarkSize: CGFloat = 18
        static let topSectionHPadding: CGFloat = 12
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.link == rhs.link
    }
    
    // MARK: - Body
    var body: some View {
        VStack {
            topSection
            textfieldSection
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: DefaultConstant.defaultCornerRadius)
                .fill(.grey200)
                .glass()
        }
    }
    
    /// 링크 카드 타이틀, 카드 삭제 버튼
    private var topSection: some View {
        HStack {
            Image(systemName: "link")
            Text("링크 첨부")
                .appFont(.body, weight: .bold)
            Spacer()
            Button(action: {
                onDismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: Constants.xmarkSize))
                    .foregroundStyle(.black)
            }
        }
        .padding(.horizontal, Constants.topSectionHPadding)
    }
    
    /// 링크 TextField
    private var textfieldSection: some View {
        TextField("",
                  text: $link,
                  prompt: Text(verbatim: "https://example.com").foregroundStyle(.grey400))
            .textInputAutocapitalization(.never)
            .keyboardType(.URL)
            .autocorrectionDisabled()
            .appFont(.callout)
            .padding(DefaultConstant.defaultTextFieldPadding)
            .background {
                RoundedRectangle(cornerRadius: DefaultConstant.defaultCornerRadius)
                    .fill(.grey000)
            }
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var noticeLinkItems: [NoticeLinkItem] = []
    
    VStack(spacing: 12) {
        ForEach($noticeLinkItems) { $item in
            LinkAttachmentCard(link: $item.link) {
                noticeLinkItems.removeAll { $0.id == item.id }
            }
        }
        
        Button("링크 카드 추가") {
            noticeLinkItems.append(NoticeLinkItem())
        }
    }
    .safeAreaPadding(.horizontal, 16)
}
