import ComposableArchitecture
import DesignSystem
import PhotoAPI
import SwiftUI

public struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject public var store: StoreOf<SettingsFeature>

    public init(store: StoreOf<SettingsFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack(path: $store.scope(\.path, action: \.path)) {
            content
        } destination: { store in
            switch store.state {
            case .designSystem:
                DesignSystemView()
            }
        }
    }

    private var content: some View {
        List {
            Section {
                Image("SettingsArtwork", bundle: .module)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 240)
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
            }

            Section {
                Stepper(
                    value: Binding(
                        get: { store.gridColumnCount },
                        set: { store.send(.gridColumnCountChanged($0)) }
                    ),
                    in: 2...3
                ) {
                    HStack {
                        Text("Grid columns", bundle: .module)
                        Spacer()
                        Text("\(store.gridColumnCount)")
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityLabel(Text("Grid columns", bundle: .module))
                .accessibilityValue(Text("\(store.gridColumnCount)"))
                .accessibilityIdentifier("settings.gridColumnCount")
                .listRowBackground(VistoraStyle.defaultColor)
            } header: {
                Text("Configuration", bundle: .module)
                    .font(VistoraStyle.Fonts.caption)
            }

            Section {
                Picker(
                    selection: Binding(
                        get: { store.selectedFeedMode },
                        set: { store.send(.feedModeChanged($0)) }
                    )
                ) {
                    Text("Random", bundle: .module).tag(ExploreFeedMode.random)
                    Text("Editorial", bundle: .module).tag(ExploreFeedMode.editorial)
                } label: {
                    Text("Explore feed", bundle: .module)
                }
                .accessibilityIdentifier("settings.exploreFeedMode")
                .listRowBackground(VistoraStyle.defaultColor)
            } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Random shows a fresh mix of photos in each batch.", bundle: .module)
                    Text("Editorial shows Unsplash's latest photos in order.", bundle: .module)
                }
            }

            #if DEBUG || QA
                Section {
                    NavigationLink(
                        state: SettingsFeature.PathState.designSystem
                    ) {
                        Text("Design system", bundle: .module)
                    }
                    .listRowBackground(VistoraStyle.defaultColor)
                } header: {
                    Text("Debug", bundle: .module)
                    .font(VistoraStyle.Fonts.caption)
                }
            #endif
        }
        .font(VistoraStyle.Fonts.body)
        .scrollContentBackground(.hidden)
        .background(VistoraStyle.backgroundColor.ignoresSafeArea())
        .tint(VistoraStyle.accentColor)
        .navigationTitle(Text("Settings", bundle: .module))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    Text("Done", bundle: .module)
                }
            }
        }
    }
}
