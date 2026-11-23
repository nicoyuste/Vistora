import ComposableArchitecture
import DesignSystem
import Foundation
import PhotoAPI
import PhotoViewerFeature
import SwiftUI

public struct ExploreView: View {
    @Bindable public var store: StoreOf<ExploreFeature>
    @State private var searchText: String
    @Namespace private var photoTransition

    public init(store: StoreOf<ExploreFeature>) {
        self.store = store
        switch store.collection {
        case .random, .editorial:
            self._searchText = State(initialValue: "")
        case let .search(query):
            self._searchText = State(initialValue: query)
        }
    }

    public var body: some View {
        if #available(iOS 18, *) {
            exploreContent
                .fullScreenCover(item: $store.scope(state: \.photoViewer, action: \.photoViewer)) { viewerStore in
                    PhotoViewerView(photo: viewerStore.photo) {
                        viewerStore.send(.closeTapped)
                    }
                    .background(Color.black.ignoresSafeArea())
                    .navigationTransition(.zoom(sourceID: viewerStore.photo.id, in: photoTransition))
                }
        } else {
            // AppView retains the existing iOS 17 overlay; see its usage/cost rationale.
            exploreContent
        }
    }

    private var exploreContent: some View {
        let columnCount = min(max(store.gridColumnCount, 2), 3)
        let prefetchIDs = Set(store.photos.suffix(columnCount * 3).map(\.id))

        return NavigationStack {
            ZStack {
                feedContent(columnCount: columnCount, prefetchIDs: prefetchIDs)
            }
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text("Search photos", bundle: .module)
            )
            .onSubmit(of: .search) {
                store.send(.collectionChanged(.search(searchText)))
            }
            .onChange(of: searchText) { _, query in
                if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    store.send(.collectionChanged(.search("")))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle(Text("Explore", bundle: .module))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.send(.delegate(.settingsTapped))
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel(Text("Settings", bundle: .module))
                    .accessibilityIdentifier("explore.settings")
                }
            }
            .tint(VistoraStyle.accentColor)
            .background(VistoraStyle.backgroundColor.ignoresSafeArea())
        }
        .task { store.send(.onAppear) }
    }

    @ViewBuilder
    private func feedContent(columnCount: Int, prefetchIDs: Set<Photo.ID>) -> some View {
        if store.isLoading && store.photos.isEmpty {
            loadingContent
        } else if let error = store.error, store.photos.isEmpty {
            initialErrorContent(for: error)
        } else if store.photos.isEmpty {
            emptyContent
        } else {
            photoGrid(columnCount: columnCount, prefetchIDs: prefetchIDs)
        }
    }

    private var loadingContent: some View {
        HStack {
            Spacer()
            VStack {
                ProgressView()
                Text("Loading...", bundle: .module)
            }
            Spacer()
        }
    }

    private func initialErrorContent(for error: PhotoAPIError) -> some View {
        EmptyStateView(
            title: Text("Could not load photos.", bundle: .module),
            message: error == .missingAccessKey
                ? Text("Add an Unsplash access key to load photos.", bundle: .module)
                : Text("Please try again.", bundle: .module),
            actionTitle: error == .missingAccessKey
                ? nil
                : Text("Retry", bundle: .module)
        ) {
            store.send(.loadNextPage)
        }
    }

    private var emptyContent: some View {
        EmptyStateView(
            title: !isSearching
                ? Text("No photos available.", bundle: .module)
                : Text("No photos found.", bundle: .module),
            message: !isSearching
                ? nil
                : Text("Try a different search.", bundle: .module)
        )
    }

    private var isSearching: Bool {
        if case .search = store.collection { return true }
        return false
    }

    private func photoGrid(columnCount: Int, prefetchIDs: Set<Photo.ID>) -> some View {
        ScrollView {
            HStack(alignment: .top, spacing: 12) {
                ForEach(0..<columnCount, id: \.self) { column in
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(photos(in: column, columnCount: columnCount)) { photo in
                            ExplorePhotoCell(photo: photo, transitionNamespace: photoTransition) {
                                store.send(.photoTapped(photo))
                            }
                            .onAppear {
                                if prefetchIDs.contains(photo.id),
                                    !store.isLoading,
                                    store.error == nil,
                                    store.nextPage != nil {
                                    store.send(.loadNextPage)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .top)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            paginationFooter
        }
        .accessibilityIdentifier("explore.feed")
    }

    private func photos(in column: Int, columnCount: Int) -> [Photo] {
        store.photos.enumerated().compactMap { index, photo in
            index % columnCount == column ? photo : nil
        }
    }

    @ViewBuilder
    private var paginationFooter: some View {
        if store.error != nil {
            paginationErrorContent
        }

        if store.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
        }
    }

    private var paginationErrorContent: some View {
        VStack(spacing: 8) {
            Text("Could not load photos.", bundle: .module)
            Button {
                store.send(.loadNextPage)
            } label: {
                Text("Retry", bundle: .module)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("explore.paginationError")
    }
}
