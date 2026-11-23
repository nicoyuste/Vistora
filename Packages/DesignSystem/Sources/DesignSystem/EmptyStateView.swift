import SwiftUI

public struct EmptyStateView: View {
    private let title: Text
    private let message: Text?
    private let actionTitle: Text?
    private let action: (() -> Void)?

    public init(
        title: Text,
        message: Text? = nil,
        actionTitle: Text? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: 16) {
            title.font(VistoraStyle.Fonts.secondaryTitle)

            if let message {
                message.font(VistoraStyle.Fonts.body)
            }

            if let actionTitle, let action {
                CTAButton(action: action) { actionTitle }
                    .padding(.top, 8)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(24)
    }
}
