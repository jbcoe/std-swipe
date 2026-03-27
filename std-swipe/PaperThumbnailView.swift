
//
//  PaperThumbnailView.swift
//  std-swipe
//
//  Fetches the first page of a WG21 paper PDF and renders it as a thumbnail.
//

import SwiftUI
import PDFKit

struct PaperThumbnailView: View {
    let pdfURL: URL

    @State private var thumbnail: UIImage? = nil
    @State private var failed = false

    var body: some View {
        Group {
            if let image = thumbnail {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
            } else if failed {
                failurePlaceholder
            } else {
                loadingPlaceholder
            }
        }
        .task(id: pdfURL) {
            await loadThumbnail()
        }
    }

    // MARK: - Placeholders

    private var loadingPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(.secondarySystemBackground))
            ProgressView()
        }
        .frame(height: 180)
    }

    private var failurePlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(.secondarySystemBackground))
            VStack(spacing: 6) {
                Image(systemName: "doc.richtext")
                    .font(.largeTitle)
                    .foregroundStyle(.tertiary)
                Text("Preview unavailable")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(height: 180)
    }

    // MARK: - Loading

    private func loadThumbnail() async {
        // Download the PDF data off the main thread.
        guard let data = try? await URLSession.shared.data(from: pdfURL).0 else {
            failed = true
            return
        }
        // PDFDocument and thumbnail rendering can be slow; keep it off-main.
        let image = await Task.detached(priority: .userInitiated) {
            guard let doc = PDFDocument(data: data),
                  let page = doc.page(at: 0) else { return UIImage?.none }
            let size = CGSize(width: 600, height: 800)
            return page.thumbnail(of: size, for: .mediaBox)
        }.value

        if let image {
            thumbnail = image
        } else {
            failed = true
        }
    }
}

#Preview {
    PaperThumbnailView(
        pdfURL: URL(string: "https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2026/p3795r1.pdf")!
    )
    .padding()
    .frame(width: 320)
}
