import DesignSystem
import PhotoAPI
import SDWebImageSwiftUI
import SwiftUI

struct ExplorePhotoCell: View {
    let photo: Photo
    let transitionNamespace: Namespace.ID
    let onTap: () -> Void
    @State private var thumbnailLoaded = false

    var body: some View {
        Button(action: onTap) {
            content
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("explore.photo.\(photo.id)\(thumbnailLoaded ? ".loaded" : "")")
        .accessibilityLabel(photo.caption ?? String(localized: "Untitled photo", bundle: .module))
        .accessibilityHint(Text("Open photo", bundle: .module))
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 6) {
            thumbnail

            Text(photo.caption ?? String(localized: "Untitled photo", bundle: .module))
                .font(VistoraStyle.Fonts.body)
                .lineLimit(2)

            Text(photo.photographer.name)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if #available(iOS 18, *) {
            thumbnailImage
                .matchedTransitionSource(id: photo.id, in: transitionNamespace)
        } else {
            thumbnailImage
        }
    }

    private var thumbnailImage: some View {
        GeometryReader { geometry in
            photoImage(size: geometry.size)
        }
        .aspectRatio(
            photo.width > 0 && photo.height > 0
                ? CGFloat(photo.width) / CGFloat(photo.height)
                : 1,
            contentMode: .fit
        )
    }

    private func photoImage(size: CGSize) -> some View {
        WebImage(url: photo.imageURLs.thumb) { phase in
            switch phase {
            case let .success(image):
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .accessibilityHidden(true)
                    .onAppear { thumbnailLoaded = true }

            case .failure:
                ZStack {
                    VistoraStyle.defaultColor
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                        .accessibilityLabel(Text("Image unavailable", bundle: .module))
                }

            case .empty:
                ZStack {
                    VistoraStyle.defaultColor
                    ProgressView()
                        .tint(VistoraStyle.accentColor)
                }
                .accessibilityHidden(true)

            @unknown default:
                VistoraStyle.defaultColor.accessibilityHidden(true)
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
