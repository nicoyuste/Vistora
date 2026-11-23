import AppFeature
import ComposableArchitecture
import Testing

@MainActor
@Test func settingsButtonPresentsAndDismissesSettings() async {
    let store = TestStore(initialState: AppFeature.State()) {
        AppFeature()
    }

    await store.send(.explore(.delegate(.settingsTapped))) {
        $0.settings = .init()
    }
    await store.send(.settings(.dismiss)) {
        $0.settings = nil
    }
}

@MainActor
@Test func settingsScenarioStartsWithSheet() {
    let state = AppFeature.State(settings: .init())
    #expect(state.explore == .init())
    #expect(state.settings == .init())
}
