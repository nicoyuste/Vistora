import DesignSystem
import SwiftUI

struct DesignSystemView: View {
    var body: some View {
        List {
            Section {
                HStack {
                    Text("Background", bundle: .module)
                    Spacer()
                    RoundedRectangle(cornerRadius: 8)
                        .fill(VistoraStyle.backgroundColor)
                        .frame(width: 48, height: 32)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(Color.primary.opacity(0.15))
                        }
                        .accessibilityHidden(true)
                }
                .listRowBackground(VistoraStyle.defaultColor)

                HStack {
                    Text("Default", bundle: .module)
                    Spacer()
                    RoundedRectangle(cornerRadius: 8)
                        .fill(VistoraStyle.defaultColor)
                        .frame(width: 48, height: 32)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(Color.primary.opacity(0.15))
                        }
                        .accessibilityHidden(true)
                }
                .listRowBackground(VistoraStyle.defaultColor)

                HStack {
                    Text("Accent", bundle: .module)
                    Spacer()
                    RoundedRectangle(cornerRadius: 8)
                        .fill(VistoraStyle.accentColor)
                        .frame(width: 48, height: 32)
                        .accessibilityHidden(true)
                }
                .listRowBackground(VistoraStyle.defaultColor)
            } header: {
                Text("Colors", bundle: .module)
                    .font(VistoraStyle.Fonts.caption)
            }

            Section {
                Text("Title", bundle: .module)
                    .font(VistoraStyle.Fonts.title)
                    .listRowBackground(VistoraStyle.defaultColor)
                Text("Secondary title", bundle: .module)
                    .font(VistoraStyle.Fonts.secondaryTitle)
                    .listRowBackground(VistoraStyle.defaultColor)
                Text("Body", bundle: .module)
                    .font(VistoraStyle.Fonts.body)
                    .listRowBackground(VistoraStyle.defaultColor)
                Text("Caption", bundle: .module)
                    .font(VistoraStyle.Fonts.caption)
                    .listRowBackground(VistoraStyle.defaultColor)
            } header: {
                Text("Typography", bundle: .module)
                    .font(VistoraStyle.Fonts.caption)
            }

            Section {
                CTAButton(action: {}) {
                    Text("Continue", bundle: .module)
                }
                .listRowBackground(VistoraStyle.defaultColor)
            } header: {
                Text("CTA button", bundle: .module)
                    .font(VistoraStyle.Fonts.caption)
            }

            Section {
                EmptyStateView(
                    title: Text("No content yet", bundle: .module),
                    message: Text("Content will appear here when available.", bundle: .module)
                )
                .listRowBackground(VistoraStyle.defaultColor)
            } header: {
                Text("Empty state", bundle: .module)
                    .font(VistoraStyle.Fonts.caption)
            }
        }
        .font(VistoraStyle.Fonts.body)
        .scrollContentBackground(.hidden)
        .background(VistoraStyle.backgroundColor.ignoresSafeArea())
        .tint(VistoraStyle.accentColor)
        .navigationTitle(Text("Design system", bundle: .module))
    }
}
