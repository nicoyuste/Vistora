import ComposableArchitecture
import Foundation
import PhotoAPI
import PhotoViewerFeature

@Reducer
public struct ExploreFeature {

    @Dependency(\.photosAPI) private var photosAPI
    private enum CancelID: Hashable { case metadataRequest }

    @ObservableState
    public struct State: Equatable {
        @Shared(.appStorage("exploreGridColumnCount")) public var gridColumnCount = 2
        @Shared(.appStorage("exploreFeedMode")) public var feedMode = ExploreFeedMode.random.rawValue
        public var collection: PhotoCollection
        public var photos: [Photo]
        public var nextPage: Int?
        public var isLoading: Bool
        public var error: PhotoAPIError?
        public var remainingRequests: Int?
        public var requestGeneration: Int
        @Presents public var photoViewer: PhotoViewerFeature.State?

        public init(
            collection: PhotoCollection = .random,
            photos: [Photo] = [],
            nextPage: Int? = 1,
            isLoading: Bool = false,
            error: PhotoAPIError? = nil,
            remainingRequests: Int? = nil,
            requestGeneration: Int = 0,
            photoViewer: PhotoViewerFeature.State? = nil
        ) {
            self.collection = collection
            self.photos = photos
            self.nextPage = nextPage
            self.isLoading = isLoading
            self.error = error
            self.remainingRequests = remainingRequests
            self.requestGeneration = requestGeneration
            self.photoViewer = photoViewer
        }
    }

    public enum Action: Equatable, Sendable {
        case delegate(Delegate)
        case onAppear
        case collectionChanged(PhotoCollection)
        case feedModeChanged(ExploreFeedMode)
        case loadNextPage
        case pageResponse(PhotoCollection, Int, Int, Result<PhotoPage, PhotoAPIError>)
        case photoTapped(Photo)
        case photoViewer(PresentationAction<PhotoViewerFeature.Action>)
    }

    public enum Delegate: Equatable, Sendable {
        case settingsTapped
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .delegate:
                return .none
            case .onAppear:
                return onAppear(state: &state)

            case let .collectionChanged(collection):
                return collectionChanged(state: &state, collection: collection)

            case let .feedModeChanged(mode):
                state.$feedMode.withLock { $0 = mode.rawValue }
                if case .search = state.collection { return .none }
                return collectionChanged(state: &state, collection: mode.collection)

            case .loadNextPage:
                return loadNextPage(state: &state)

            case let .pageResponse(collection, page, generation, result):
                return pageResponse(
                    state: &state,
                    collection: collection,
                    page: page,
                    generation: generation,
                    result: result
                )

            case let .photoTapped(photo):
                state.photoViewer = PhotoViewerFeature.State(photo: photo)
                return .none

            case .photoViewer(.presented(.closeTapped)):
                state.photoViewer = nil
                return .none

            case .photoViewer:
                return .none
            }
        }
        .ifLet(\.$photoViewer, action: \.photoViewer) {
            PhotoViewerFeature()
        }
    }

    private func onAppear(state: inout State) -> Effect<Action> {
        if case .search = state.collection {
            return state.photos.isEmpty ? .send(.loadNextPage) : .none
        }
        let preferredCollection = preferredCollection(for: state)
        if state.collection != preferredCollection {
            return collectionChanged(state: &state, collection: preferredCollection)
        }
        return state.photos.isEmpty ? .send(.loadNextPage) : .none
    }

    private func collectionChanged(state: inout State, collection: PhotoCollection) -> Effect<Action> {
        let normalized = normalizedCollection(collection, preferred: preferredCollection(for: state))
        guard normalized != state.collection else { return .none }
        state = State(collection: normalized, requestGeneration: state.requestGeneration + 1)
        return .merge(
            .cancel(id: CancelID.metadataRequest),
            .send(.loadNextPage)
        )
    }

    private func preferredCollection(for state: State) -> PhotoCollection {
        (ExploreFeedMode(rawValue: state.feedMode) ?? .random).collection
    }

    private func normalizedCollection(_ collection: PhotoCollection, preferred: PhotoCollection) -> PhotoCollection {
        switch collection {
        case .random:
            return .random
        case .editorial:
            return .editorial
        case let .search(query):
            let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
            return query.isEmpty ? preferred : .search(query)
        }
    }

    private func loadNextPage(state: inout State) -> Effect<Action> {
        guard !state.isLoading, let page = state.nextPage else { return .none }
        state.isLoading = true
        state.error = nil
        let collection = state.collection
        let generation = state.requestGeneration
        let photosAPI = self.photosAPI
        return .run { send in
            do {
                let result = try await photosAPI.page(for: collection, number: page)
                await send(.pageResponse(collection, page, generation, .success(result)))
            } catch is CancellationError {
                return
            } catch let error as PhotoAPIError {
                guard !Task.isCancelled else { return }
                await send(.pageResponse(collection, page, generation, .failure(error)))
            } catch {
                guard !Task.isCancelled else { return }
                await send(.pageResponse(collection, page, generation, .failure(.transport)))
            }
        }
        .cancellable(id: CancelID.metadataRequest, cancelInFlight: true)
    }

    private func pageResponse(
        state: inout State,
        collection: PhotoCollection,
        page: Int,
        generation: Int,
        result: Result<PhotoPage, PhotoAPIError>
    ) -> Effect<Action> {
        guard state.collection == collection,
            state.requestGeneration == generation,
            state.isLoading,
            state.nextPage == page
        else {
            return .none
        }
        state.isLoading = false
        switch result {
        case let .success(response):
            var knownIDs = Set(state.photos.map(\.id))
            state.photos.append(contentsOf: response.photos.filter { knownIDs.insert($0.id).inserted })
            state.nextPage = response.nextPage
            state.remainingRequests = response.remainingRequests
        case let .failure(error):
            state.error = error
        }
        return .none
    }
}

private extension ExploreFeedMode {
    var collection: PhotoCollection {
        switch self {
        case .random: .random
        case .editorial: .editorial
        }
    }
}
