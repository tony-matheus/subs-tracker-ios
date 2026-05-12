import Foundation

extension String {

    // MARK: - Smart match score

    /// Returns a ranked match score (lower = better) against `query`, or `nil` if there is no match.
    ///
    /// Tiers:
    ///   0 — exact match (case-insensitive)
    ///   1 — self starts with query
    ///   2 — any whitespace-separated word starts with query
    ///   3 — self contains query as a substring
    ///   4 — query is a fuzzy subsequence of self (≥ 80% chars matched in order, min 3 chars)
    func smartMatchScore(for query: String) -> Int? {
        let haystack = self.lowercased()
        let needle   = query.lowercased()
        guard !needle.isEmpty else { return nil }

        if haystack == needle                               { return 0 }
        if haystack.hasPrefix(needle)                       { return 1 }
        if haystack.hasWordPrefixMatch(for: needle)         { return 2 }
        if haystack.contains(needle)                        { return 3 }
        if haystack.isFuzzyMatch(for: needle)               { return 4 }
        return nil
    }

    /// Returns `true` if this string is a smart match for `query` at any tier.
    func isSmartMatch(for query: String) -> Bool {
        smartMatchScore(for: query) != nil
    }

    // MARK: - Private helpers

    /// True if any whitespace-separated word starts with `needle` (already lowercased).
    private func hasWordPrefixMatch(for needle: String) -> Bool {
        components(separatedBy: .whitespaces).contains { $0.hasPrefix(needle) }
    }

    /// True when ≥ 80% of `needle`'s characters appear in `self` in order.
    /// Requires `needle` to be at least 3 characters to avoid noisy hits.
    private func isFuzzyMatch(for needle: String) -> Bool {
        guard needle.count >= 3 else { return false }
        var matched = 0
        var it = makeIterator()
        for ch in needle {
            while let hc = it.next() {
                if hc == ch { matched += 1; break }
            }
        }
        return Double(matched) / Double(needle.count) >= 0.8
    }
}

// MARK: - Collection smart search

extension Collection {

    /// Filters and ranks `self` using smart matching against `query`.
    /// Each element is scored via `stringValue`, and results are sorted best-first.
    /// Returns the full collection when `query` is empty.
    func smartSearch(query: String, by stringValue: (Element) -> String) -> [Element] {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return Array(self) }

        return compactMap { element -> (Element, Int)? in
            guard let score = stringValue(element).smartMatchScore(for: q) else { return nil }
            return (element, score)
        }
        .sorted { $0.1 < $1.1 }
        .map(\.0)
    }
}
