# PaginatedListView

A SwiftUI component for displaying a paginated list with built-in search functionality.

## Features
- Supports infinite scrolling with automatic data fetching.
- Built-in search functionality with debouncing.
- Displays loading indicators and error messages.
- Supports refreshable content.

## Installation

### Swift Package Manager (SPM)
Add the following dependency to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/semujavier/PaginatedListView.git", from: "1.0.0")
]
```

Or, if using Xcode, go to `File > Add Packages` and enter the repository URL.

## Usage

### 1. Define a Model
Ensure your model conforms to `SendableItem`:

```swift
struct Item: SendableItem, Identifiable {
    let id: Int
    let title: String
}
```

### 2. Create a ViewModel

```swift
let viewModel = PaginatedListViewModel<Item>(
    fetchBlock: { page, pageSize in
        // Simulate paginated fetching
        return (1...pageSize).map { Item(id: $0 + (page - 1) * pageSize, title: "Item \($0)") }
    },
    searchBlock: { query, page, pageSize in
        let filteredItems = (1...100)
            .map { Item(id: $0, title: "Item \($0)") }
            .filter { $0.title.lowercased().contains(query.lowercased()) }
        
        return Array(filteredItems.prefix(pageSize))
    }
)
```

### 3. Use `PaginatedListView`

```swift
PaginatedListView(viewModel: viewModel) { item in
    HStack {
        Text(item.title)
        Spacer()
    }
    .padding()
}
```

## API Reference

### `PaginatedListView`
A SwiftUI view that displays a paginated and searchable list of items.

#### Properties:
- `viewModel: PaginatedListViewModel<Item>` – The view model managing pagination and search.
- `content: (Item) -> Content` – Closure defining how each item is displayed.

### `PaginatedListViewModel`
An observable class that manages data fetching and pagination.

#### Methods:
- `fetchItems(reset: Bool) async` – Fetches data, either resetting or appending new items.
- `loadMoreIfNeeded(currentIndex: Int) async` – Loads more data when reaching the last item.
- `updateSearchQuery(_ query: String) async` – Updates the search query with a debounce mechanism.

## Customization
- Modify `pageSize` to adjust the number of items per fetch.
- Customize the `fetchBlock` and `searchBlock` to use API requests.
- Adjust the UI as needed by modifying `PaginatedListView`.

## License
This project is licensed under the MIT License.

