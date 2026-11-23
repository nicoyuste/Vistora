import Foundation

struct UnsplashPhotoDTO: Decodable {
    let id: String
    let description: String?
    let altDescription: String?
    let width: Int
    let height: Int
    let urls: URLs
    let user: User

    struct URLs: Decodable {
        let thumb: URL
        let regular: URL
    }

    struct User: Decodable {
        let name: String
        let links: Links

        struct Links: Decodable {
            let html: URL
        }
    }

    func photo() -> Photo {
        Photo(
            id: id,
            caption: [altDescription, description]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .first { !$0.isEmpty },
            width: width,
            height: height,
            imageURLs: PhotoImageURLs(thumb: urls.thumb, regular: urls.regular),
            photographer: Photographer(name: user.name, profileURL: user.links.html)
        )
    }
}

struct UnsplashSearchDTO: Decodable {
    let totalPages: Int
    let results: [UnsplashPhotoDTO]
}
