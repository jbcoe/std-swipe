
//
//  SwipeView.swift
//  std-swipe
//
//  The main card-deck screen that shows papers one at a time.
//

import SwiftUI

struct SwipeView: View {
    @ObservedObject var store: PaperStore
    @State private var currentIndex: Int = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                if store.isLoading {
                    loadingView
                } else if let error = store.errorMessage {
                    errorView(message: error)
                } else if store.papers.isEmpty {
                    emptyView
                } else if currentIndex >= store.papers.count {
                    allDoneView
                } else {
                    cardDeck
                }
            }
            .navigationTitle("std::swipe")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        VotedPapersView(store: store)
                    } label: {
                        Label("Voted", systemImage: "list.bullet.clipboard")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    yearPicker
                }
            }
        }
        .task {
            if store.papers.isEmpty {
                await store.loadPapers(forYear: selectedYear)
            }
        }
    }

    // MARK: - Year picker

    @State private var selectedYear: Int = 2026

    private var yearPicker: some View {
        Menu {
            ForEach((2020...2026).reversed(), id: \.self) { year in
                Button(String(year)) {
                    selectedYear = year
                    currentIndex = 0
                    Task { await store.loadPapers(forYear: year) }
                }
            }
        } label: {
            Label(String(selectedYear), systemImage: "calendar")
        }
    }

    // MARK: - Card deck

    private var cardDeck: some View {
        VStack {
            // Progress indicator
            progressBar

            // Stack: show current + next card peeking behind
            ZStack {
                // Background card (peek)
                if currentIndex + 1 < store.papers.count {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.secondarySystemBackground))
                        .frame(maxWidth: .infinity)
                        .frame(height: 580)
                        .padding(.horizontal, 32)
                        .scaleEffect(0.95)
                        .offset(y: 12)
                }

                // Foreground card
                PaperCardView(paper: store.papers[currentIndex]) { vote in
                    store.vote(vote, for: store.papers[currentIndex])
                    withAnimation(.spring(response: 0.3)) {
                        currentIndex += 1
                    }
                }
                .padding(.horizontal, 16)
                .id(currentIndex) // force re-creation on advance
            }

        }
        .padding(.bottom, 20)
    }

    private var progressBar: some View {
        VStack(spacing: 4) {
            ProgressView(value: Double(currentIndex), total: Double(store.papers.count))
                .padding(.horizontal, 20)
            Text("\(currentIndex) of \(store.papers.count) papers")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    // MARK: - State views

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Fetching papers…")
                .foregroundStyle(.secondary)
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text("Could not load papers")
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Retry") {
                Task { await store.loadPapers(forYear: selectedYear) }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No papers found for \(selectedYear)")
                .foregroundStyle(.secondary)
            Button("Try another year") {
                selectedYear = 2025
                Task { await store.loadPapers(forYear: 2025) }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var allDoneView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.accentColor)
            Text("All done!")
                .font(.largeTitle.bold())
            Text("You've reviewed all \(store.papers.count) papers.")
                .foregroundStyle(.secondary)
            NavigationLink {
                VotedPapersView(store: store)
            } label: {
                Label("View your votes", systemImage: "list.bullet.clipboard")
            }
            .buttonStyle(.borderedProminent)
            Button("Start over") {
                currentIndex = 0
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

}

#Preview {
    let store = PaperStore()
    store.papers = [
        Paper(id: "P3795R1", title: "Miscellaneous Reflection Cleanup", authors: "Barry Revzin",
              url: URL(string: "https://www.open-std.org")!, year: 2026),
        Paper(id: "P3826R3", title: "Fix Sender Algorithm Customization", authors: "Eric Niebler",
              url: URL(string: "https://www.open-std.org")!, year: 2026),
    ]
    return SwipeView(store: store)
}
