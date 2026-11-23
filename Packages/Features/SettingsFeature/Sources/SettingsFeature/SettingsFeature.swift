import ComposableArchitecture
import PhotoAPI

@Reducer
public struct SettingsFeature {
    @ObservableState
    public enum PathState: Equatable {
        case designSystem
    }

    @ObservableState
    public struct State: Equatable {
        @Shared(.appStorage("exploreGridColumnCount")) public var gridColumnCount = 2
        @Shared(.appStorage("exploreFeedMode")) public var feedMode = ExploreFeedMode.random.rawValue
        public var path = StackState<PathState>()

        public var selectedFeedMode: ExploreFeedMode {
            ExploreFeedMode(rawValue: feedMode) ?? .random
        }

        public init() {
            let count = min(max(gridColumnCount, 2), 3)
            if gridColumnCount != count {
                $gridColumnCount.withLock { $0 = count }
            }
            if ExploreFeedMode(rawValue: feedMode) == nil {
                $feedMode.withLock { $0 = ExploreFeedMode.random.rawValue }
            }
        }
    }

    public enum Action {
        case gridColumnCountChanged(Int)
        case feedModeChanged(ExploreFeedMode)
        case path(StackAction<PathState, Never>)
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .gridColumnCountChanged(count):
                guard (2...3).contains(count) else { return .none }
                state.$gridColumnCount.withLock { $0 = count }
                return .none
            case let .feedModeChanged(mode):
                state.$feedMode.withLock { $0 = mode.rawValue }
                return .none
            case .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path) {
            EmptyReducer()
        }
    }
}
