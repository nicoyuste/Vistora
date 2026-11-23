import ComposableArchitecture
import Foundation
import PhotoAPI
import SettingsFeature
import Testing

@MainActor
@Test func selectingGridColumnCountPersistsTheChoice() async {
    let store = TestStore(initialState: SettingsFeature.State()) {
        SettingsFeature()
    }

    await store.send(.gridColumnCountChanged(3)) {
        $0.$gridColumnCount.withLock { $0 = 3 }
    }

    await store.send(.gridColumnCountChanged(4))
    #expect(store.state.gridColumnCount == 3)
}

@MainActor
@Test func selectingExploreFeedModePersistsTheChoice() async {
    let suiteName = "vistora-feed-mode-tests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let store = withDependencies {
        $0.defaultAppStorage = defaults
    } operation: {
        TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }
    }

    await store.send(.feedModeChanged(.editorial)) {
        $0.$feedMode.withLock { $0 = ExploreFeedMode.editorial.rawValue }
    }
    #expect(store.state.selectedFeedMode == .editorial)
    #expect(defaults.string(forKey: "exploreFeedMode") == "editorial")
}

@MainActor
@Test func designSystemDestinationCanBePushedAndPopped() async {
    let store = TestStore(initialState: SettingsFeature.State()) {
        SettingsFeature()
    }
    let destination = SettingsFeature.PathState.designSystem

    await store.send(.path(.push(id: 0, state: destination))) {
        $0.path[id: 0] = destination
    }
    await store.send(.path(.popFrom(id: 0))) {
        $0.path.removeAll()
    }
}

@MainActor
@Test func storedGridColumnCountIsClampedAtStartup() {
    for (stored, expected) in [(1, 2), (4, 3)] {
        let suiteName = "vistora-settings-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(stored, forKey: "exploreGridColumnCount")

        let state = withDependencies {
            $0.defaultAppStorage = defaults
        } operation: {
            SettingsFeature.State()
        }

        #expect(state.gridColumnCount == expected)
        #expect(defaults.integer(forKey: "exploreGridColumnCount") == expected)
    }
}
