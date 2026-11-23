import DesignSystem
import PhotoAPI
import SDWebImageSwiftUI
import SwiftUI

public struct PhotoViewerView: View {
    public let photo: Photo
    private let onClose: () -> Void
    @State private var zoomScale: CGFloat = 1
    @State private var zoomOffset: CGSize = .zero
    @State private var pinchStart: ZoomPosition?
    @State private var dragStartOffset: CGSize?
    @State private var regularImageLoaded = false
    @GestureState private var isPinching = false

    private struct ZoomPosition {
        let scale: CGFloat
        let offset: CGSize
    }

    public init(photo: Photo, onClose: @escaping () -> Void) {
        self.photo = photo
        self.onClose = onClose
    }

    public var body: some View {
        ZStack {
            zoomableImage

            VStack(alignment: .leading) {
                HStack {
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .accessibilityLabel(Text("Close photo", bundle: .module))
                    .accessibilityIdentifier(
                        "photoViewer.close.\(photo.id)\(regularImageLoaded ? ".loaded" : "")"
                    )
                }

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    Text(photo.caption ?? String(localized: "Untitled photo", bundle: .module))
                        .font(VistoraStyle.Fonts.body)
                    Text(photo.photographer.name)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                .opacity(zoomScale > 1.01 ? 0 : 1)
                .accessibilityHidden(zoomScale > 1.01)
            }
            .padding(16)
        }
        .foregroundStyle(.white)
    }

    private var zoomableImage: some View {
        GeometryReader { geometry in
            image
                .scaleEffect(zoomScale)
                .offset(zoomOffset)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .contentShape(Rectangle())
                .gesture(magnifyGesture(in: geometry.size))
                .simultaneousGesture(
                    dragGesture(in: geometry.size),
                    isEnabled: zoomScale > 1.01
                )
        }
        .onChange(of: isPinching) { _, active in
            if !active {
                pinchStart = nil
            }
        }
    }

    private func magnifyGesture(in size: CGSize) -> some Gesture {
        MagnifyGesture()
            .updating($isPinching) { _, active, _ in active = true }
            .onChanged { value in
                if pinchStart == nil {
                    pinchStart = ZoomPosition(scale: zoomScale, offset: zoomOffset)
                    dragStartOffset = nil
                }
                guard let pinchStart else { return }

                let nextScale = min(max(pinchStart.scale * value.magnification, 1), 4)
                let ratio = nextScale / pinchStart.scale
                let focalPoint = CGSize(
                    width: value.startLocation.x - size.width / 2,
                    height: value.startLocation.y - size.height / 2
                )
                let proposedOffset = CGSize(
                    width: focalPoint.width + (pinchStart.offset.width - focalPoint.width) * ratio,
                    height: focalPoint.height + (pinchStart.offset.height - focalPoint.height) * ratio
                )
                zoomScale = nextScale
                zoomOffset = boundedOffset(proposedOffset, scale: nextScale, in: size)
            }
            .onEnded { _ in
                pinchStart = nil
                if zoomScale <= 1.01 {
                    zoomScale = 1
                    zoomOffset = .zero
                }
            }
    }

    private func dragGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard !isPinching, zoomScale > 1.01 else { return }
                if dragStartOffset == nil {
                    dragStartOffset = zoomOffset
                }
                guard let dragStartOffset else { return }
                zoomOffset = boundedOffset(
                    CGSize(
                        width: dragStartOffset.width + value.translation.width,
                        height: dragStartOffset.height + value.translation.height
                    ),
                    scale: zoomScale,
                    in: size
                )
            }
            .onEnded { _ in dragStartOffset = nil }
    }

    private func boundedOffset(_ offset: CGSize, scale: CGFloat, in viewport: CGSize) -> CGSize {
        guard photo.width > 0, photo.height > 0, viewport.width > 0, viewport.height > 0 else {
            return .zero
        }
        let aspectRatio = CGFloat(photo.width) / CGFloat(photo.height)
        let fittedWidth = min(viewport.width, viewport.height * aspectRatio)
        let fittedHeight = min(viewport.height, viewport.width / aspectRatio)
        let horizontalLimit = max(0, (fittedWidth * scale - viewport.width) / 2)
        let verticalLimit = max(0, (fittedHeight * scale - viewport.height) / 2)
        return CGSize(
            width: min(max(offset.width, -horizontalLimit), horizontalLimit),
            height: min(max(offset.height, -verticalLimit), verticalLimit)
        )
    }

    private var image: some View {
        ZStack {
            WebImage(url: photo.imageURLs.thumb) { phase in
                switch phase {
                case let .success(image):
                    image.resizable().scaledToFit()
                case .empty:
                    ProgressView().tint(.white)
                case .failure:
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundStyle(.white.opacity(0.6))
                @unknown default:
                    EmptyView()
                }
            }

            WebImage(url: photo.imageURLs.regular) { phase in
                if case let .success(image) = phase {
                    image
                        .resizable()
                        .scaledToFit()
                }
            }
            .onSuccess { _, _, _ in regularImageLoaded = true }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel(photo.caption ?? String(localized: "Untitled photo", bundle: .module))
    }
}
