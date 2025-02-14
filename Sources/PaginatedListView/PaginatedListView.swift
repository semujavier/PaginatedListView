//
//  PaginatedListView.swift
//  Auto1
//
//  Created by Javier Serrano Muñoz on 19/11/24.
//

import SwiftUI

public struct PaginatedListView<Item: SendableItem, Content>: View where Content: View {
    @StateObject private var viewModel: PaginatedListViewModel<Item>
    @State private var searchText: String = ""
    let content: (Item) -> Content
    
    public init(viewModel: PaginatedListViewModel<Item>, @ViewBuilder content: @escaping (Item) -> Content) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.content = content
    }
    
    public var body: some View {
        VStack {
            TextField("Buscar...", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .onChange(of: searchText) { newValue in
                    Task {
                        await viewModel.updateSearchQuery(newValue)
                    }
                }
                .background(Color(.systemBackground))
                .zIndex(1)
            
            ScrollView {
                LazyVStack {
                    if viewModel.isLoading && viewModel.items.isEmpty {
                        ProgressView()
                    } else if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    } else if viewModel.items.isEmpty {
                        Text("No items available.")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                    } else {
                        ForEach(viewModel.items.indices, id: \.self) { index in
                            content(viewModel.items[index])
                                .onAppear {
                                    Task {
                                        await viewModel.loadMoreIfNeeded(currentIndex: index)
                                    }
                                }
                        }
                        if viewModel.isLoading {
                            ProgressView()
                        }
                    }
                }
                .padding(.horizontal)
            }
            .refreshable {
                await viewModel.fetchItems(reset: true)
            }
        }
    }
}
struct PaginatedListView_Previews: PreviewProvider {
    static var previews: some View {
        let mockItems: [MockItem] = (1...20).map { MockItem(id: $0, title: "Item \($0)") }
        
        let viewModel = PaginatedListViewModel<MockItem> (
            fetchBlock: { page, pageSize in
            // Simulate paginated fetching
            let startIndex = (page - 1) * pageSize
            guard startIndex < mockItems.count else { return [] }
            let endIndex = min(startIndex + pageSize, mockItems.count)
            return Array(mockItems[startIndex..<endIndex])
        }, searchBlock: { query, page, pageSize in
            try await Task.sleep(nanoseconds: 1_000_000_000)
            return mockItems
                .filter { $0.title.lowercased().contains(query.lowercased()) }
                .dropFirst((page - 1) * pageSize)
                .prefix(pageSize).map { $0}
            
        })

        // Preload some data for preview purposes
        Task {
            await viewModel.fetchItems()
        }

        return PaginatedListView(viewModel: viewModel) { item in
            HStack {
                Text(item.title)
                Spacer()
            }
            .padding()
        }
    }
}
