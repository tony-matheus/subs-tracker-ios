# ViewModel Patterns — Playbook for LinguicaSubTracker

A practical guide for choosing the right ViewModel shape in this project. Pair this
with [MVVM-Article-Summary.md](./MVVM-Article-Summary.md) for the underlying
principles.

---

## Picking a pattern

| Situation                                       | Pattern               |
| ----------------------------------------------- | --------------------- |
| Single screen, derived data, no async           | **Stateless**         |
| Async work with multiple UI phases              | **State-Based**       |
| Collection + search / filter / sort             | **List ViewModel**    |
| Multi-screen flow (wizard, checkout)            | **Coordinator**       |
| VM consumed by tests / multiple views           | **Input / Output**    |

---

## 1. Stateless / Derived

A pure transformation of an input store into UI-ready state. No internal storage
beyond what the user is currently typing or selecting. Use when the screen is
fundamentally a *view onto* something the store already owns.

```swift
@Observable
final class SearchViewModel {
    var searchText: String = ""

    private let store: AppStore
    init(store: AppStore) { self.store = store }

    var hasQuery: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var results: [Subscription] {
        let q = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return [] }
        return store.subscriptions.filter { /* … */ }
    }
}
```

This is what we use for **Search**.

---

## 2. State-Based

When the screen has clearly distinct phases (loading vs error vs content), model
them as an enum so the View only ever sees one valid combination:

```swift
@Observable
final class StatsViewModel {
    enum Phase {
        case idle
        case loading
        case loaded(items: [DialItem], total: Double)
        case empty
    }

    private(set) var phase: Phase = .idle
    var year: Int = Calendar.current.component(.year, from: .now)

    private let store: AppStore
    private let settings: SettingsStore
    init(store: AppStore, settings: SettingsStore) {
        self.store = store
        self.settings = settings
        recompute()
    }

    func recompute() { /* fills phase */ }
}
```

The View switches on `phase` and renders one branch per case — impossible to
display "loading" and "error" at the same time.

This is a good fit for **Stats** when we refactor it next.

---

## 3. List ViewModel

A subtype of stateless built specifically for collections that need
search / filter / sort / pagination. Keeps the list complexity out of the view.

```swift
@Observable
final class AllSubscriptionsViewModel {
    var sort: SubscriptionSortType = .price
    var direction: SortDirection = .descending

    private let store: AppStore
    init(store: AppStore) { self.store = store }

    var sortedSubscriptions: [Subscription] {
        let subs = store.subscriptions
        let asc = direction == .ascending
        switch sort { /* … */ }
    }

    func handleSortPick(_ type: SubscriptionSortType) {
        if sort == type {
            direction.toggle()
        } else {
            sort = type
            direction = type.defaultDirection
        }
    }
}
```

We use this for **AllSubscriptionsView**.

---

## 4. Coordinator

When a feature spans multiple Views and you need to centralise navigation, lift
the path into a Coordinator-style ViewModel.

```swift
@Observable
final class SearchFlowViewModel {
    enum Stage { case search, all }

    var stage: Stage = .search
    var path: [Subscription] = []

    func showAll()       { stage = .all }
    func push(_ sub: Subscription) { path.append(sub) }
    func reset()         { path.removeAll(); stage = .search }
}
```

The current `SearchFlow.swift` already plays this role with `@State` — promoting
it to a VM is the natural next step if the flow grows.

---

## 5. Input / Output protocol

Useful when the VM has a non-trivial public surface and you want to mock it in
previews or tests. Split the protocol in two:

```swift
protocol SearchViewModelInput {
    func didTapShowAll()
    func didSelect(_ subscription: Subscription)
}

protocol SearchViewModelOutput {
    var searchText: String { get set }
    var hasQuery: Bool { get }
    var results: [Subscription] { get }
}

typealias SearchViewModelType = SearchViewModelInput & SearchViewModelOutput
```

The View receives `some SearchViewModelType` and can be previewed with a
trivial `MockSearchViewModel`. Reserve this for non-trivial cases — overkill
for small screens.

---

## How a View should look after this refactor

Rule of thumb: a View file should contain **no verbs** other than UI actions
(`onTapGesture`, `animation`, `padding`). If you see `filter`, `sorted`, `reduce`,
`map`, date math, or `if / switch` over business state inside a View body, that
logic belongs in the ViewModel.

```swift
struct SearchView: View {
    @State private var viewModel: SearchViewModel

    init(store: AppStore) {
        _viewModel = State(initialValue: SearchViewModel(store: store))
    }

    var body: some View {
        @Bindable var vm = viewModel
        VStack {
            SearchBar(text: $vm.searchText)
            if vm.hasQuery {
                List(vm.results) { SubscriptionRow(subscription: $0) }
            } else {
                EmptyStateView()
            }
        }
    }
}
```

---

## Migration order for this codebase

1. ✅ **Search** — Stateless / List VM (this PR).
2. **Stats** — State-Based VM (heavy derivation in view today).
3. **Settings sub-sheets** — small Stateless VMs each.
4. **SubscriptionForm** — biggest win, save for last.
5. Split `AppStore` (domain data vs UI navigation state).
6. Protocolise `StorageService` / `SubscriptionService` for DI.
