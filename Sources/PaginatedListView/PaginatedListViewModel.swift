//
//  PaginatedListViewModel.swift
//  Auto1
//
//  Created by Javier Serrano Muñoz on 19/11/24.
//

import SwiftUI

public protocol SendableItem: Equatable, Sendable { }

@MainActor
open class PaginatedListViewModel<Item: SendableItem>: ObservableObject {
    @Published public var items: [Item] = []
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    @Published private(set) var debouncedSearchQuery: String = ""
    @Published public var searchQuery: String = ""
    
    private var currentPage = 1
    private let pageSize = 10
    private var canLoadMore = true
    
    private let fetchBlock: (_ page: Int, _ pageSize: Int) async throws -> [Item]
    private let searchBlock: (_ query: String, _ page: Int, _ pageSize: Int) async throws -> [Item]
    
    private var searchTask: Task<Void, Never>?

    public init(
        fetchBlock: @escaping (_ page: Int, _ pageSize: Int) async throws -> [Item],
        searchBlock: @escaping (_ query: String, _ page: Int, _ pageSize: Int) async throws -> [Item]
    ) {
        self.fetchBlock = fetchBlock
        self.searchBlock = searchBlock
    }
    
    public func fetchItems(reset: Bool = false) async {
            guard !isLoading else { return }
            
            isLoading = true
            defer { isLoading = false }

            if reset {
                currentPage = 1
                canLoadMore = true
                items.removeAll()
            }

            do {
                let newItems: [Item]
                if searchQuery.isEmpty {
                    newItems = try await fetchBlock(currentPage, pageSize)
                } else {
                    newItems = try await searchBlock(searchQuery, currentPage, pageSize)
                }

                if newItems.isEmpty {
                    canLoadMore = false
                } else {
                    items.append(contentsOf: newItems)
                    currentPage += 1
                }
                errorMessage = nil
            } catch {
                errorMessage = "Failed to load items: \(error.localizedDescription)"
            }
        }
    
    public func loadMoreIfNeeded(currentIndex: Int) async {
        guard canLoadMore, currentIndex == items.count - 1 else { return }
        await fetchItems()
    }
    
    public func updateSearchQuery(_ query: String) async {
        searchTask?.cancel()
        searchQuery = query
        
        searchTask = Task {
            do {
                try await Task.sleep(nanoseconds: 300_000_000) // 300ms delay
                if !Task.isCancelled {
                    await fetchItems(reset: true)
                }
            } catch {
                print("Task cancelled or sleep interrupted: \(error)")
            }
        }
    }

}
