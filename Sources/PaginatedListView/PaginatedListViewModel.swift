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
    private let pageSize: Int
    private var canLoadMore = true
    private var lastFetchCount = 0
    
    public var fetchBlock: ((_ page: Int, _ pageSize: Int) async throws -> [Item])?
    public var searchBlock: ((_ query: String, _ page: Int, _ pageSize: Int) async throws -> [Item])?
    
    private var searchTask: Task<Void, Never>?

    public init(
        pageSize: Int = 10,
        fetchBlock: ((_ page: Int, _ pageSize: Int) async throws -> [Item])? = nil,
        searchBlock: ((_ query: String, _ page: Int, _ pageSize: Int) async throws -> [Item])? = nil
    ) {
        self.pageSize = pageSize
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
                lastFetchCount = 0
            }

            do {
                let newItems: [Item]
                if searchQuery.isEmpty {
                    guard let fetchBlock else { return }
                    newItems = try await fetchBlock(currentPage, pageSize)
                } else {
                    guard let searchBlock else { return }
                    newItems = try await searchBlock(searchQuery, currentPage, pageSize)
                }
                
                lastFetchCount = newItems.count

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
        guard canLoadMore, lastFetchCount == pageSize, currentIndex == items.count - 1 else { return }
        await fetchItems()
    }
    
    public func updateSearchQuery(_ query: String) async {
        searchTask?.cancel()
        searchQuery = query
        
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            if !Task.isCancelled {
                await fetchItems(reset: true)
            }
            
        }
    }

}
