
//
//  Paper.swift
//  std-swipe
//
//  Data model for a WG21 C++ standards paper and the service that fetches them.
//

import Foundation
import Combine

struct Paper: Identifiable, Codable {
    let id: String          // e.g. "P3795R1"
    let title: String
    let authors: String
    let url: URL
    let year: Int
    var summary: String?    // generated lazily

    /// Best-effort PDF URL: swap the file extension to .pdf.
    var pdfURL: URL {
        let base = url.deletingPathExtension()
        return base.appendingPathExtension("pdf")
    }
}

enum SwipeVote {
    case approve
    case reject
}

struct VotedPaper: Identifiable {
    let id = UUID()
    let paper: Paper
    let vote: SwipeVote
}

// MARK: - Paper fetching

@MainActor
final class PaperStore: ObservableObject {
    @Published var papers: [Paper] = []
    @Published var votedPapers: [VotedPaper] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let baseURL = "https://www.open-std.org/jtc1/sc22/wg21/docs/papers"

    func loadPapers(forYear year: Int = 2026) async {
        isLoading = true
        errorMessage = nil
        do {
            let fetched = try await fetchPapers(forYear: year)
            papers = fetched
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func vote(_ vote: SwipeVote, for paper: Paper) {
        votedPapers.append(VotedPaper(paper: paper, vote: vote))
    }

    // MARK: - Private

    private func fetchPapers(forYear year: Int) async throws -> [Paper] {
        guard let url = URL(string: "\(baseURL)/\(year)/") else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        let html = String(data: data, encoding: .utf8) ?? ""
        return parsePapers(from: html, year: year)
    }

    /// Parse papers from the WG21 mailing HTML table.
    private func parsePapers(from html: String, year: Int) -> [Paper] {
        var papers: [Paper] = []
        // Each row looks like:
        //   <tr><td><a href="relative/path">PXXXXRN</a></td><td><a href="...">Title</a></td><td>Authors</td>...
        // We use a simple regex over the raw HTML.
        let rowPattern = #"<tr[^>]*>\s*<td[^>]*>\s*<a\s+href="([^"]+)"[^>]*>([NP]\d+(?:R\d+)?)</a>\s*</td>\s*<td[^>]*>\s*(?:<a[^>]*>)?([^<]+)(?:</a>)?\s*</td>\s*<td[^>]*>([^<]*)"#
        guard let regex = try? NSRegularExpression(pattern: rowPattern, options: [.dotMatchesLineSeparators]) else {
            return papers
        }
        let nsHTML = html as NSString
        let matches = regex.matches(in: html, range: NSRange(location: 0, length: nsHTML.length))
        var seen = Set<String>()
        for match in matches {
            guard match.numberOfRanges >= 5 else { continue }
            let href    = nsHTML.substring(with: match.range(at: 1))
            let number  = nsHTML.substring(with: match.range(at: 2))
            let title   = nsHTML.substring(with: match.range(at: 3)).trimmingCharacters(in: .whitespacesAndNewlines)
            let authors = nsHTML.substring(with: match.range(at: 4)).trimmingCharacters(in: .whitespacesAndNewlines)

            guard !seen.contains(number), !title.isEmpty else { continue }
            seen.insert(number)

            // Resolve URL
            let paperURLString: String
            if href.hasPrefix("http") {
                paperURLString = href
            } else {
                paperURLString = "\(baseURL)/\(year)/\(href)"
            }
            guard let paperURL = URL(string: paperURLString) else { continue }

            papers.append(Paper(id: number, title: title, authors: authors, url: paperURL, year: year))
        }
        return papers
    }
}
