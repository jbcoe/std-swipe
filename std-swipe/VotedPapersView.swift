
//
//  VotedPapersView.swift
//  std-swipe
//
//  Shows the history of papers the user has approved or rejected.
//

import SwiftUI

struct VotedPapersView: View {
    @ObservedObject var store: PaperStore
    @State private var filter: FilterOption = .all

    enum FilterOption: String, CaseIterable, Identifiable {
        case all = "All"
        case approved = "Approved"
        case rejected = "Rejected"
        var id: Self { self }
    }

    private var filteredPapers: [VotedPaper] {
        switch filter {
        case .all:      return store.votedPapers
        case .approved: return store.votedPapers.filter { $0.vote == .approve }
        case .rejected: return store.votedPapers.filter { $0.vote == .reject }
        }
    }

    var body: some View {
        Group {
            if store.votedPapers.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .navigationTitle("My Votes")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Picker("Filter", selection: $filter) {
                    ForEach(FilterOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .frame(minWidth: 200)
            }
        }
    }

    private var list: some View {
        List(filteredPapers) { voted in
            Link(destination: voted.paper.url) {
                HStack(alignment: .top, spacing: 12) {
                    // Vote icon
                    Image(systemName: voted.vote == .approve ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(voted.vote == .approve ? Color.green : Color.red)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(voted.paper.id)
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.accentColor, in: Capsule())
                            Spacer()
                            Text(voted.vote == .approve ? "Approved" : "Rejected")
                                .font(.caption.bold())
                                .foregroundStyle(voted.vote == .approve ? Color.green : Color.red)
                        }
                        Text(voted.paper.title)
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                        if !voted.paper.authors.isEmpty {
                            Text(voted.paper.authors)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.insetGrouped)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 50))
                .foregroundStyle(.tertiary)
            Text("No votes yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Swipe right to approve or left to reject papers on the main screen.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

#Preview {
    let store = PaperStore()
    store.votedPapers = [
        VotedPaper(
            paper: Paper(id: "P3795R1", title: "Miscellaneous Reflection Cleanup", authors: "Barry Revzin",
                         url: URL(string: "https://www.open-std.org")!, year: 2026),
            vote: .approve
        ),
        VotedPaper(
            paper: Paper(id: "P3826R3", title: "Fix Sender Algorithm Customization", authors: "Eric Niebler",
                         url: URL(string: "https://www.open-std.org")!, year: 2026),
            vote: .reject
        ),
    ]
    return NavigationStack {
        VotedPapersView(store: store)
    }
}
