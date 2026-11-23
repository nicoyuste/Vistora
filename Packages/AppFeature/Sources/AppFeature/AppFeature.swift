import ComposableArchitecture
import ExploreFeature
import SettingsFeature

@Reducer
public struct AppFeature {
    @ObservableState
    public struct State: Equatable {
        public var explore: ExploreFeature.State
        @Presents public var settings: SettingsFeature.State?

        public init(
            explore: ExploreFeature.State = .init(),
            settings: SettingsFeature.State? = nil
        ) {
            self.explore = explore
            self.settings = settings
        }
    }

    public enum Action {
        case explore(ExploreFeature.Action)
        case settings(PresentationAction<SettingsFeature.Action>)
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Scope(state: \.explore, action: \.explore) {
            ExploreFeature()
        }
        Reduce { state, action in
            switch action {
            case .explore(.delegate(.settingsTapped)):
                state.settings = SettingsFeature.State()
                return .none
            case let .settings(.presented(.feedModeChanged(mode))):
                return .send(.explore(.feedModeChanged(mode)))
            case .explore, .settings:
                return .none
            }
        }
        .ifLet(\.$settings, action: \.settings) {
            SettingsFeature()
        }
    }
}
