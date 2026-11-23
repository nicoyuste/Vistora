import Foundation

public struct Photo: Equatable, Identifiable, Sendable {
    public let id: String
    public let caption: String?
    public let width: Int
    public let height: Int
    public let imageURLs: PhotoImageURLs
    public let photographer: Photographer

    public init(
        id: String,
        caption: String?,
        width: Int,
        height: Int,
        imageURLs: PhotoImageURLs,
        photographer: Photographer
    ) {
        self.id = id
        self.caption = caption
        self.width = width
        self.height = height
        self.imageURLs = imageURLs
        self.photographer = photographer
    }
}

public struct PhotoImageURLs: Equatable, Sendable {
    public let thumb: URL
    public let regular: URL

    public init(thumb: URL, regular: URL) {
        self.thumb = thumb
        self.regular = regular
    }
}

public struct Photographer: Equatable, Sendable {
    public let name: String
    public let profileURL: URL

    public init(name: String, profileURL: URL) {
        self.name = name
        self.profileURL = profileURL
    }
}

public enum ExploreFeedMode: String, Hashable, Sendable {
    case random
    case editorial
}

public enum PhotoCollection: Equatable, Sendable {
    case random
    case editorial
    case search(String)
}

public struct PhotoPage: Equatable, Sendable {
    public let photos: [Photo]
    public let nextPage: Int?
    public let remainingRequests: Int?

    public init(photos: [Photo], nextPage: Int?, remainingRequests: Int? = nil) {
        self.photos = photos
        self.nextPage = nextPage
        self.remainingRequests = remainingRequests
    }
}

public enum PhotoAPIError: Error, Equatable, Sendable {
    case missingAccessKey
    case transport
    case rateLimited
    case httpStatus(Int)
    case invalidResponse
}
