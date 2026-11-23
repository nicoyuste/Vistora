import ComposableArchitecture
import ExploreFeature
import Foundation
import PhotoAPI
import PhotoViewerFeature
import Testing

@MainActor
@Suite struct ExploreFeatureTests {
    @Test func appearingLoadsTheFirstPageOnlyWhenTheFeedIsEmpty() async {
        let page = PhotoPage(photos: [photo("one")], nextPage: 2, remainingRequests: 49)
        let store = TestStore(initialState: ExploreFeature.State()) {
            ExploreFeature()
        } withDependencies: {
            $0.photosAPI = StubPhotosAPI { collection, number in
                #expect(collection == .random)
                #expect(number == 1)
                return page
            }
        }

        await store.send(.onAppear)
        await store.receive(.loadNextPage) {
            $0.isLoading = true
        }
        await store.receive(.pageResponse(.random, 1, 0, .success(page))) {
            $0.isLoading = false
            $0.photos = page.photos
            $0.nextPage = 2
            $0.remainingRequests = 49
        }

        let populated = TestStore(initialState: ExploreFeature.State(photos: [photo("one")])) {
            ExploreFeature()
        }
        await populated.send(.onAppear)
    }

    @Test func appearingUsesTheSavedEditorialMode() async {
        let suiteName = "vistora-saved-feed-mode-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(ExploreFeedMode.editorial.rawValue, forKey: "exploreFeedMode")
        let initialState = withDependencies {
            $0.defaultAppStorage = defaults
        } operation: {
            ExploreFeature.State()
        }
        let page = PhotoPage(photos: [], nextPage: nil)
        let store = TestStore(initialState: initialState) {
            ExploreFeature()
        } withDependencies: {
            $0.defaultAppStorage = defaults
            $0.photosAPI = StubPhotosAPI { collection, number in
                #expect(collection == .editorial)
                #expect(number == 1)
                return page
            }
        }

        await store.send(.onAppear) {
            $0.collection = .editorial
            $0.requestGeneration = 1
        }
        await store.receive(.loadNextPage) { $0.isLoading = true }
        await store.receive(.pageResponse(.editorial, 1, 1, .success(page))) {
            $0.isLoading = false
            $0.nextPage = nil
        }
    }

    @Test func nextPageAppendsOnlyNewPhotoIDsAndStopsAtTheLastPage() async {
        let page = PhotoPage(
            photos: [photo("one"), photo("two"), photo("two")],
            nextPage: nil,
            remainingRequests: 12
        )
        let store = TestStore(
            initialState: ExploreFeature.State(photos: [photo("one")], nextPage: 2)
        ) {
            ExploreFeature()
        } withDependencies: {
            $0.photosAPI = StubPhotosAPI { collection, number in
                #expect(collection == .random)
                #expect(number == 2)
                return page
            }
        }

        await store.send(.loadNextPage) { $0.isLoading = true }
        await store.receive(.pageResponse(.random, 2, 0, .success(page))) {
            $0.isLoading = false
            $0.photos = [photo("one"), photo("two")]
            $0.nextPage = nil
            $0.remainingRequests = 12
        }
        await store.send(.loadNextPage)
    }

    @Test func loadingAndExhaustedFeedsDoNotStartAnotherRequest() async {
        let loading = TestStore(initialState: ExploreFeature.State(isLoading: true)) {
            ExploreFeature()
        }
        await loading.send(.loadNextPage)

        let exhausted = TestStore(initialState: ExploreFeature.State(nextPage: nil)) {
            ExploreFeature()
        }
        await exhausted.send(.loadNextPage)
    }

    @Test func repeatedLoadRequestsWhileFetchingStartOnlyOnePage() async {
        let api = PausedPhotosAPI()
        let page = PhotoPage(photos: [photo("two")], nextPage: nil)
        let store = TestStore(
            initialState: ExploreFeature.State(photos: [photo("one")], nextPage: 2)
        ) {
            ExploreFeature()
        } withDependencies: {
            $0.photosAPI = api
        }

        await store.send(.loadNextPage) { $0.isLoading = true }
        await api.waitUntilStarted()
        await store.send(.loadNextPage)
        let inFlightRequestCount = await api.requestCount
        #expect(inFlightRequestCount == 1)

        await api.complete(with: page)
        await store.receive(.pageResponse(.random, 2, 0, .success(page))) {
            $0.isLoading = false
            $0.photos = [photo("one"), photo("two")]
            $0.nextPage = nil
        }
        await store.send(.loadNextPage)
        let finalRequestCount = await api.requestCount
        #expect(finalRequestCount == 1)
    }

    @Test func changingCollectionTrimsTheQueryAndResetsPaging() async {
        let page = PhotoPage(photos: [photo("flower")], nextPage: nil)
        let store = TestStore(
            initialState: ExploreFeature.State(
                photos: [photo("old")],
                nextPage: 3,
                error: .transport,
                remainingRequests: 8
            )
        ) {
            ExploreFeature()
        } withDependencies: {
            $0.photosAPI = StubPhotosAPI { collection, number in
                #expect(collection == .search("flowers"))
                #expect(number == 1)
                return page
            }
        }

        await store.send(.collectionChanged(.search("  flowers \n"))) {
            $0 = ExploreFeature.State(collection: .search("flowers"), requestGeneration: 1)
        }
        await store.receive(.loadNextPage) { $0.isLoading = true }
        await store.receive(.pageResponse(.search("flowers"), 1, 1, .success(page))) {
            $0.isLoading = false
            $0.photos = page.photos
            $0.nextPage = nil
        }
        await store.send(.collectionChanged(.search("flowers")))
    }

    @Test func blankSearchReturnsToExplore() async {
        let page = PhotoPage(photos: [], nextPage: nil)
        let store = TestStore(
            initialState: ExploreFeature.State(collection: .search("flowers"))
        ) {
            ExploreFeature()
        } withDependencies: {
            $0.photosAPI = StubPhotosAPI { collection, number in
                #expect(collection == .random)
                #expect(number == 1)
                return page
            }
        }

        await store.send(.collectionChanged(.search(" \n "))) {
            $0 = ExploreFeature.State(collection: .random, requestGeneration: 1)
        }
        await store.receive(.loadNextPage) { $0.isLoading = true }
        await store.receive(.pageResponse(.random, 1, 1, .success(page))) {
            $0.isLoading = false
            $0.nextPage = nil
        }
    }

    @Test func changingFeedModeReloadsExploreFromFirstPage() async {
        let page = PhotoPage(photos: [photo("editorial")], nextPage: nil)
        let suiteName = "vistora-explore-mode-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let initialState = withDependencies {
            $0.defaultAppStorage = defaults
        } operation: {
            ExploreFeature.State(photos: [photo("random")], nextPage: 3)
        }
        let store = TestStore(
            initialState: initialState
        ) {
            ExploreFeature()
        } withDependencies: {
            $0.defaultAppStorage = defaults
            $0.photosAPI = StubPhotosAPI { collection, number in
                #expect(collection == .editorial)
                #expect(number == 1)
                return page
            }
        }

        await store.send(.feedModeChanged(.editorial)) {
            $0.$feedMode.withLock { $0 = ExploreFeedMode.editorial.rawValue }
            $0.collection = .editorial
            $0.photos = []
            $0.nextPage = 1
            $0.requestGeneration = 1
        }
        await store.receive(.loadNextPage) { $0.isLoading = true }
        await store.receive(.pageResponse(.editorial, 1, 1, .success(page))) {
            $0.isLoading = false
            $0.photos = page.photos
            $0.nextPage = nil
        }
    }

    @Test func changingFeedModeKeepsSearchResultsUntilSearchIsCleared() async {
        let page = PhotoPage(photos: [], nextPage: nil)
        let suiteName = "vistora-explore-search-mode-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let initialState = withDependencies {
            $0.defaultAppStorage = defaults
        } operation: {
            ExploreFeature.State(
                collection: .search("flowers"), photos: [photo("flower")], nextPage: nil
            )
        }
        let store = TestStore(
            initialState: initialState
        ) {
            ExploreFeature()
        } withDependencies: {
            $0.defaultAppStorage = defaults
            $0.photosAPI = StubPhotosAPI { collection, number in
                #expect(collection == .editorial)
                #expect(number == 1)
                return page
            }
        }

        await store.send(.feedModeChanged(.editorial)) {
            $0.$feedMode.withLock { $0 = ExploreFeedMode.editorial.rawValue }
        }
        #expect(store.state.photos.map(\.id) == ["flower"])
        await store.send(.collectionChanged(.search(""))) {
            $0.collection = .editorial
            $0.photos = []
            $0.nextPage = 1
            $0.requestGeneration = 1
        }
        await store.receive(.loadNextPage) { $0.isLoading = true }
        await store.receive(.pageResponse(.editorial, 1, 1, .success(page))) {
            $0.isLoading = false
        }
    }

    @Test func staleResponsesDoNotChangeTheCurrentFeed() async {
        let page = PhotoPage(photos: [photo("old")], nextPage: nil)
        let store = TestStore(
            initialState: ExploreFeature.State(
                collection: .search("new"),
                nextPage: 2,
                isLoading: true,
                requestGeneration: 4
            )
        ) {
            ExploreFeature()
        }

        await store.send(.pageResponse(.random, 2, 4, .success(page)))
        await store.send(.pageResponse(.search("new"), 2, 3, .success(page)))
        await store.send(.pageResponse(.search("new"), 1, 4, .success(page)))
        #expect(store.state.isLoading)
        #expect(store.state.photos.isEmpty)

        let idle = TestStore(initialState: ExploreFeature.State(isLoading: false)) {
            ExploreFeature()
        }
        await idle.send(.pageResponse(.random, 1, 0, .success(page)))
        #expect(idle.state.photos.isEmpty)
    }

    @Test func switchingCollectionsCancelsThePreviousRequest() async {
        let api = CancellationProbe()
        let store = TestStore(initialState: ExploreFeature.State()) {
            ExploreFeature()
        } withDependencies: {
            $0.photosAPI = api
        }

        await store.send(.loadNextPage) { $0.isLoading = true }
        await api.waitUntilExploreStarted()
        await store.send(.collectionChanged(.search("flowers"))) {
            $0 = ExploreFeature.State(collection: .search("flowers"), requestGeneration: 1)
        }
        await api.waitUntilCancelled()
        await store.receive(.loadNextPage) { $0.isLoading = true }
        await store.receive(
            .pageResponse(
                .search("flowers"),
                1,
                1,
                .success(PhotoPage(photos: [], nextPage: nil))
            )
        ) {
            $0.isLoading = false
            $0.nextPage = nil
        }
    }

    @Test func failedFirstPageCanBeRetried() async {
        let page = PhotoPage(photos: [photo("one")], nextPage: nil)
        let api = FailsOncePhotosAPI(successfulPage: page)
        let store = TestStore(initialState: ExploreFeature.State()) {
            ExploreFeature()
        } withDependencies: {
            $0.photosAPI = api
        }

        await store.send(.onAppear)
        await store.receive(.loadNextPage) { $0.isLoading = true }
        await store.receive(.pageResponse(.random, 1, 0, .failure(.transport))) {
            $0.isLoading = false
            $0.error = .transport
        }
        #expect(store.state.nextPage == 1)

        await store.send(.loadNextPage) {
            $0.isLoading = true
            $0.error = nil
        }
        await store.receive(.pageResponse(.random, 1, 0, .success(page))) {
            $0.isLoading = false
            $0.photos = page.photos
            $0.nextPage = nil
        }
        #expect(await api.requestCount == 2)
    }

    @Test func retryingAFailedLaterPagePreservesLoadedPhotos() async {
        let page = PhotoPage(photos: [photo("two")], nextPage: nil)
        let store = TestStore(
            initialState: ExploreFeature.State(
                photos: [photo("one")],
                nextPage: 2,
                isLoading: true
            )
        ) {
            ExploreFeature()
        } withDependencies: {
            $0.photosAPI = StubPhotosAPI { collection, number in
                #expect(collection == .random)
                #expect(number == 2)
                return page
            }
        }

        await store.send(.pageResponse(.random, 2, 0, .failure(.transport))) {
            $0.isLoading = false
            $0.error = .transport
        }
        #expect(store.state.photos.map(\.id) == ["one"])
        #expect(store.state.nextPage == 2)

        await store.send(.loadNextPage) {
            $0.isLoading = true
            $0.error = nil
        }
        await store.receive(.pageResponse(.random, 2, 0, .success(page))) {
            $0.isLoading = false
            $0.photos = [photo("one"), photo("two")]
            $0.nextPage = nil
        }
    }

    @Test func typedErrorsAreReported() async {
        let store = TestStore(initialState: ExploreFeature.State()) {
            ExploreFeature()
        } withDependencies: {
            $0.photosAPI = StubPhotosAPI { _, _ in throw PhotoAPIError.rateLimited }
        }

        await store.send(.loadNextPage) { $0.isLoading = true }
        await store.receive(.pageResponse(.random, 1, 0, .failure(.rateLimited))) {
            $0.isLoading = false
            $0.error = .rateLimited
        }
        #expect(store.state.nextPage == 1)
    }

    @Test func unexpectedErrorsBecomeTransportErrors() async {
        let store = TestStore(initialState: ExploreFeature.State()) {
            ExploreFeature()
        } withDependencies: {
            $0.photosAPI = StubPhotosAPI { _, _ in throw URLError(.notConnectedToInternet) }
        }

        await store.send(.loadNextPage) { $0.isLoading = true }
        await store.receive(.pageResponse(.random, 1, 0, .failure(.transport))) {
            $0.isLoading = false
            $0.error = .transport
        }
        #expect(store.state.nextPage == 1)
    }

    @Test func tappingAndClosingAPhotoUpdatesPresentationState() async {
        let selectedPhoto = photo("selected")
        let store = TestStore(initialState: ExploreFeature.State(photos: [selectedPhoto])) {
            ExploreFeature()
        }

        await store.send(.photoTapped(selectedPhoto)) {
            $0.photoViewer = PhotoViewerFeature.State(photo: selectedPhoto)
        }
        await store.send(.photoViewer(.presented(.closeTapped))) {
            $0.photoViewer = nil
        }
    }

    @Test func systemDismissalClearsPhotoViewerAndPreservesGrid() async {
        let selectedPhoto = photo("one")
        let store = TestStore(
            initialState: ExploreFeature.State(
                photos: [selectedPhoto],
                nextPage: nil,
                photoViewer: PhotoViewerFeature.State(photo: selectedPhoto)
            )
        ) {
            ExploreFeature()
        }

        await store.send(.photoViewer(.dismiss)) {
            $0.photoViewer = nil
        }
    }
}

private struct StubPhotosAPI: PhotosAPI {
    let fetch: @Sendable (PhotoCollection, Int) async throws -> PhotoPage

    func page(for collection: PhotoCollection, number: Int) async throws -> PhotoPage {
        try await fetch(collection, number)
    }
}

private actor FailsOncePhotosAPI: PhotosAPI {
    let successfulPage: PhotoPage
    private(set) var requestCount = 0

    init(successfulPage: PhotoPage) {
        self.successfulPage = successfulPage
    }

    func page(for collection: PhotoCollection, number: Int) async throws -> PhotoPage {
        #expect(collection == .random)
        #expect(number == 1)
        requestCount += 1
        if requestCount == 1 { throw PhotoAPIError.transport }
        return successfulPage
    }
}

private actor PausedPhotosAPI: PhotosAPI {
    private(set) var requestCount = 0
    private var startedWaiter: CheckedContinuation<Void, Never>?
    private var responseWaiter: CheckedContinuation<PhotoPage, Never>?

    func page(for collection: PhotoCollection, number: Int) async throws -> PhotoPage {
        requestCount += 1
        startedWaiter?.resume()
        startedWaiter = nil
        return await withCheckedContinuation { responseWaiter = $0 }
    }

    func waitUntilStarted() async {
        if requestCount > 0 { return }
        await withCheckedContinuation { startedWaiter = $0 }
    }

    func complete(with page: PhotoPage) {
        responseWaiter?.resume(returning: page)
        responseWaiter = nil
    }
}

private actor CancellationProbe: PhotosAPI {
    private var exploreStarted = false
    private var exploreStartWaiter: CheckedContinuation<Void, Never>?
    private var cancelled = false
    private var cancellationWaiter: CheckedContinuation<Void, Never>?

    func page(for collection: PhotoCollection, number: Int) async throws -> PhotoPage {
        if collection == .search("flowers") {
            return PhotoPage(photos: [], nextPage: nil)
        }

        exploreStarted = true
        exploreStartWaiter?.resume()
        exploreStartWaiter = nil
        return try await withTaskCancellationHandler {
            try await Task.sleep(for: .seconds(30))
            return PhotoPage(photos: [], nextPage: nil)
        } onCancel: {
            Task { await self.markCancelled() }
        }
    }

    func waitUntilExploreStarted() async {
        if exploreStarted { return }
        await withCheckedContinuation { exploreStartWaiter = $0 }
    }

    func waitUntilCancelled() async {
        if cancelled { return }
        await withCheckedContinuation { cancellationWaiter = $0 }
    }

    private func markCancelled() {
        cancelled = true
        cancellationWaiter?.resume()
        cancellationWaiter = nil
    }
}

private func photo(_ id: String) -> Photo {
    Photo(
        id: id,
        caption: id,
        width: 800,
        height: 600,
        imageURLs: PhotoImageURLs(
            thumb: URL(string: "https://example.com/\(id)/thumb")!,
            regular: URL(string: "https://example.com/\(id)/regular")!
        ),
        photographer: Photographer(
            name: "Photographer",
            profileURL: URL(string: "https://example.com/photographer")!
        )
    )
}
