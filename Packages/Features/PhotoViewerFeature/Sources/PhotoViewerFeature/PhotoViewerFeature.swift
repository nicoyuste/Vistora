import ComposableArchitecture
import PhotoAPI

@Reducer
public struct PhotoViewerFeature {
    @ObservableState
    public struct State: Equatable, Identifiable {
        public let photo: Photo
        public var id: String { photo.id }

        public init(photo: Photo) {
            self.photo = photo
        }
    }

    public enum Action: Equatable, Sendable {
        case closeTapped
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { _, _ in .none }
    }
}
