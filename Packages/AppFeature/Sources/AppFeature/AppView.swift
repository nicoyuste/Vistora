import ComposableArchitecture
import ExploreFeature
import PhotoViewerFeature
import SettingsFeature
import SwiftUI

public struct AppView: View {
    @Bindable private var store: StoreOf<AppFeature>

    public init(store: StoreOf<AppFeature>) {
        self.store = store
    }

    public init(initialState: AppFeature.State = .init()) {
        self.store = Store(initialState: initialState) { AppFeature() }
    }

    public var body: some View {
        if #available(iOS 18, *) {
            explore
        } else {
            // iOS 18+ uses the native zoom transition in ExploreView. Keep the existing
            // overlay on iOS 17: its small usage share does not justify a custom animation.
            // iOS Ref reports 93.5% on iOS 18 or later (November 3, 2026), based on
            // general iPhone/iPad traffic, not Vistora analytics: https://iosref.com/ios-usage.
            // iOS 17 remains supported; only the new transition requires iOS 18.
            legacyPhotoPresentation
        }
    }

    private var legacyPhotoPresentation: some View {
        ZStack {
            explore
            if let photo = store.explore.photoViewer?.photo {
                Color.black
                    .ignoresSafeArea()
                    .zIndex(1)

                PhotoViewerView(photo: photo) {
                    store.send(.explore(.photoViewer(.presented(.closeTapped))))
                }
                .zIndex(2)
            }
        }
    }

    private var explore: some View {
        ExploreView(store: store.scope(state: \.explore, action: \.explore))
            .sheet(item: $store.scope(state: \.settings, action: \.settings)) { settingsStore in
                SettingsView(store: settingsStore)
            }
    }
}
