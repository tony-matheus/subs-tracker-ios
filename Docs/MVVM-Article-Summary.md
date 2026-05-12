# MVVM in SwiftUI — Article Summary

> Source: ["View Model Patterns in SwiftUI: MVVM Done Right"](https://medium.com/@21zerixpm/view-model-patterns-in-swiftui-mvvm-done-right-4205cc2e079f) by 21zerixpm.

This document distills the article into the conventions we use in this project.

---

## 1. Core Principle

> "The view's job is only to render current state and dispatch user actions."

A View in SwiftUI is **pure UI**. It owns no business logic, no data fetching, no
derived computation that the user could not understand from looking at the rendered
pixels. Everything else lives in the **ViewModel**.

That gives three benefits:

1. Views become trivial to read and review.
2. ViewModels become trivial to test (no SwiftUI required).
3. Logic can be reused across multiple Views.

---

## 2. ViewModel declaration

The article shows two valid styles. We use **only the modern one** (iOS 17+, and
this project targets iOS 26.4).

### Legacy (do not use here)

```swift
class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
}
```

### Modern — `@Observable` (use this)

```swift
@Observable
final class ProfileViewModel {
    var user: User?
    var isLoading = false
}
```

The `@Observable` macro removes the `@Published` noise and only triggers view
re-renders for properties the View actually reads. No `ObservableObject`,
no `@Published`, no Combine plumbing.

---

## 3. How Views consume ViewModels

| You want to…                                    | Use this in the View                      |
| ----------------------------------------------- | ----------------------------------------- |
| **Own** the VM's lifetime (created by the View) | `@State private var vm = MyViewModel()`   |
| **Receive** a VM that someone else owns         | `let vm: MyViewModel` (plain `let`)       |
| **Two-way bind** to a VM property               | `@Bindable var vm: MyViewModel` in body   |

`@StateObject` is no longer needed once you adopt `@Observable`.

### Two-way binding example

```swift
struct SearchView: View {
    @State private var viewModel: SearchViewModel

    init(store: AppStore) {
        _viewModel = State(initialValue: SearchViewModel(store: store))
    }

    var body: some View {
        @Bindable var vm = viewModel
        TextField("Search", text: $vm.searchText)
    }
}
```

---

## 4. Where business logic lives

ViewModels encapsulate:

- Data fetching, API calls, persistence
- State management (loading / error / success)
- Validation
- **Computed properties that derive UI state from raw data** (filter, sort, group…)
- User action handlers (`func didTapSave()`, `func didChangeSort(_:)`)

Anything a View does *besides* describing its layout is a smell — push it down
into the ViewModel.

---

## 5. Dependency injection

Services are injected through the ViewModel's initializer, preferably behind a
protocol so tests can substitute fakes:

```swift
protocol UserServiceProtocol { /* … */ }

@Observable
final class ProfileViewModel {
    private let userService: UserServiceProtocol
    init(userService: UserServiceProtocol = UserService()) {
        self.userService = userService
    }
}
```

In this project, our shared services (`StorageService`, `SubscriptionService`,
`CalendarService`) are currently static. Migrating them to protocol-based DI is a
later step — see [ViewModel-Patterns.md](./ViewModel-Patterns.md).

---

## 6. Named patterns

The article names four ViewModel shapes worth recognising:

1. **State-Based** — model UI as an enum (`.idle | .loading | .loaded | .error`)
   so impossible combinations cannot be expressed.
2. **List ViewModel** — paginated lists, filtering, refresh; isolates list
   complexity from the rendering view.
3. **Coordinator ViewModel** — owns multi-step navigation flows (checkout,
   onboarding) so each step view stays small.
4. **Input / Output** — protocol that splits *what the consumer triggers*
   (Input) from *what the consumer receives* (Output). Makes the VM's contract
   explicit and trivial to mock.

See [ViewModel-Patterns.md](./ViewModel-Patterns.md) for when to pick each.

---

## 7. Folder layout (our convention)

The article does not prescribe a folder layout, so we define ours:

```
Features/<Feature>/
  Models/        feature-local value types & enums
  ViewModels/    @Observable classes — all logic
  Views/        SwiftUI structs — UI only
    Components/  sub-views used only by this feature
  Services/      feature-scoped services (optional)
```

Cross-feature reusable code lives in `Core/`. Globally shared services live in
the top-level `Services/` folder.
