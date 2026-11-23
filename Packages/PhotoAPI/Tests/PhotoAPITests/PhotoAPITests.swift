import Foundation
@testable import PhotoAPI
import Testing

@Test func buildsAKeyedAndEncodedSearchRequest() throws {
    let api = UnsplashPhotosImpl(accessKey: "  local-key  ")
    let request = try api.request(for: .search("  red flowers  "), number: 2)
    let url = try #require(request.url)
    let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))

    #expect(components.path == "/search/photos")
    #expect(components.queryItems?.first { $0.name == "query" }?.value == "red flowers")
    #expect(components.queryItems?.first { $0.name == "page" }?.value == "2")
    #expect(components.queryItems?.first { $0.name == "per_page" }?.value == "30")
    #expect(request.value(forHTTPHeaderField: "Authorization") == "Client-ID local-key")
    #expect(request.value(forHTTPHeaderField: "Accept-Version") == "v1")
}

@Test func decodesPhotoMetadataAndCaptionFallback() throws {
    let json = """
        {
            "total_pages": 2,
            "results": [
                {
                    "id": "one",
                    "alt_description": "  A red flower  ",
                    "description": "Fallback",
                    "width": 1200,
                    "height": 800,
                    "urls": {
                        "thumb": "https://images.unsplash.com/one?ixid=abc&w=200",
                        "regular": "https://images.unsplash.com/one?ixid=abc&w=1080"
                    },
                    "user": {
                        "name": "A Photographer",
                        "links": { "html": "https://unsplash.com/@person" }
                    }
                },
                {
                    "id": "two",
                    "alt_description": " ",
                    "description": "  A blue sky  ",
                    "width": 800,
                    "height": 1200,
                    "urls": {
                        "thumb": "https://images.unsplash.com/two?ixid=def&w=200",
                        "regular": "https://images.unsplash.com/two?ixid=def&w=1080"
                    },
                    "user": {
                        "name": "Another Photographer",
                        "links": { "html": "https://unsplash.com/@other" }
                    }
                }
            ]
        }
        """
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let result = try decoder.decode(UnsplashSearchDTO.self, from: Data(json.utf8))

    #expect(result.totalPages == 2)
    #expect(result.results.map { $0.photo().caption } == ["A red flower", "A blue sky"])
    #expect(result.results[0].photo().imageURLs.thumb.absoluteString.contains("ixid=abc"))
    #expect(result.results[0].photo().photographer.name == "A Photographer")
}
