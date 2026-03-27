
//
//  PaperCardView.swift
//  std-swipe
//
//  A single swipeable paper card with approve/reject gesture support.
//

import SwiftUI

struct PaperCardView: View {
    let paper: Paper
    let onSwipe: (SwipeVote) -> Void

    @GestureState private var dragOffset: CGSize = .zero
    @State private var finalOffset: CGSize = .zero
    @State private var isRemoved = false

    private let swipeThreshold: CGFloat = 100

    var body: some View {
        ZStack {
            cardBackground
            cardContent
            voteOverlay
        }
        .frame(maxWidth: .infinity)
        .frame(height: 580)
        .offset(x: dragOffset.width + finalOffset.width,
                y: dragOffset.height + finalOffset.height)
        .rotationEffect(.degrees(Double(dragOffset.width + finalOffset.width) / 20))
        .gesture(dragGesture)
        .opacity(isRemoved ? 0 : 1)
    }

    // MARK: - Subviews

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color(.systemBackground))
            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Paper number badge
            HStack {
                Text(paper.id)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.accentColor, in: Capsule())
                Spacer()
                Link(destination: paper.url) {
                    Image(systemName: "link.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                }
            }

            // Title
            Text(paper.title)
                .font(.title3.bold())
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(4)

            // Authors
            if !paper.authors.isEmpty {
                Label(paper.authors, systemImage: "person.2.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            // First-page thumbnail
            PaperThumbnailView(pdfURL: paper.pdfURL)
                .frame(maxWidth: .infinity)

            Spacer()

            // Swipe hint
            HStack {
                Label("Reject", systemImage: "xmark.circle.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.red.opacity(0.6))
                Spacer()
                Label("Approve", systemImage: "checkmark.circle.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.green.opacity(0.6))
            }
        }
        .padding(24)
    }

    private var voteOverlay: some View {
        let dx = dragOffset.width + finalOffset.width
        return ZStack {
            // Approve indicator
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.green, lineWidth: 4)
                .opacity(approveOpacity(dx: dx))

            Text("APPROVE")
                .font(.largeTitle.bold())
                .foregroundStyle(.green)
                .rotationEffect(.degrees(-15))
                .opacity(approveOpacity(dx: dx))

            // Reject indicator
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.red, lineWidth: 4)
                .opacity(rejectOpacity(dx: dx))

            Text("REJECT")
                .font(.largeTitle.bold())
                .foregroundStyle(.red)
                .rotationEffect(.degrees(15))
                .opacity(rejectOpacity(dx: dx))
        }
    }

    // MARK: - Gesture

    private var dragGesture: some Gesture {
        DragGesture()
            .updating($dragOffset) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                let dx = value.translation.width
                if dx > swipeThreshold {
                    finalOffset = CGSize(width: 500, height: value.translation.height)
                    withAnimation(.easeOut(duration: 0.3)) {
                        isRemoved = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onSwipe(.approve)
                    }
                } else if dx < -swipeThreshold {
                    finalOffset = CGSize(width: -500, height: value.translation.height)
                    withAnimation(.easeOut(duration: 0.3)) {
                        isRemoved = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onSwipe(.reject)
                    }
                }
                // else snap back — dragOffset resets automatically via @GestureState
            }
    }

    // MARK: - Helpers

    private func approveOpacity(dx: CGFloat) -> Double {
        dx > 0 ? min(Double(dx) / Double(swipeThreshold), 1.0) : 0
    }

    private func rejectOpacity(dx: CGFloat) -> Double {
        dx < 0 ? min(Double(-dx) / Double(swipeThreshold), 1.0) : 0
    }
}

#Preview {
    PaperCardView(
        paper: Paper(
            id: "P3795R1",
            title: "Miscellaneous Reflection Cleanup",
            authors: "Barry Revzin",
            url: URL(string: "https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2026/p3795r1.html")!,
            year: 2026
        )
    ) { vote in
        print("Swiped: \(vote)")
    }
    .padding()
}
