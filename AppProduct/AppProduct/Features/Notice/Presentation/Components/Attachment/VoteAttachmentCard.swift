//
//  VoteAttachmentCard.swift
//  AppProduct
//
//  Created by 이예지 on 1/29/26.
//

import SwiftUI

enum VoteCardMode {
    case editable    // 공지 작성: 수정 가능
    case readonly    // 공지 수정: 읽기 전용 (삭제만 가능)
}

struct VoteAttachmentCard: View {
    
    @Binding var formData: VoteFormData
    var mode: VoteCardMode = .editable
    var onDelete: (() -> Void)?
    var onEdit: (() -> Void)? = nil
    
    fileprivate enum Constants {
        static let textSpacing: CGFloat = 35
        static let bgOpacity: Double = 0.6
    }
    
    var body: some View {
        HStack(alignment: .center) {
            textSection
            Spacer()
            iconSection
        }
        .padding(DefaultConstant.defaultSafeHorizon)
        .background {
            RoundedRectangle(cornerRadius: DefaultConstant.defaultCornerRadius)
                .fill(.indigo100)
                .opacity(Constants.bgOpacity)
                .glassEffect(.clear, in: .rect(cornerRadius: DefaultConstant.defaultCornerRadius))
        }
        .contextMenu{
            if mode == VoteCardMode.editable {
                Button {
                    onEdit?()
                } label: {
                    Label("수정하기", systemImage: "pencil")
                }
            }
            Button(role: .destructive) {
                onDelete?()
            } label: {
                Label("삭제하기", systemImage: "trash")
            }
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
    
    private var iconSection: some View {
        Group {
            switch mode {
            case .editable:
                Image(systemName: "ellipsis")
                    .foregroundStyle(.grey500)
            case .readonly:
                Button {
                    onDelete?()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.grey500)
                }
            }
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    @Previewable @State var formData = VoteFormData()
    
    VStack {
        VoteAttachmentCard(formData: $formData, mode: .editable)
        
        VoteAttachmentCard(
            formData: $formData,
            mode: .readonly,
            onDelete: { print("투표 삭제됨") }
        )
    }
}
