import XCTest
@testable import PaginatedListView
import Foundation

@MainActor
final class PaginatedListViewModelTests: XCTestCase {
    
    let viewModel = PaginatedListViewModel<MockItem>()
    
    func testFetchItemsSuccessfully() async {
        viewModel.fetchBlock = { page, pageSize in
            return (1...pageSize).map { MockItem(id: $0, title: "\($0)") }
        }
        
        await viewModel.fetchItems()
        
        XCTAssertFalse(viewModel.items.isEmpty)
        XCTAssertEqual(viewModel.items.count, 10)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    
    func testFetchItemsWithError() async {
        viewModel.fetchBlock = { _, _ in throw NSError(domain: "TestError", code: 1) }
        
        await viewModel.fetchItems()
        
        XCTAssertTrue(viewModel.items.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    
    func testFetchItemsResetsCorrectly() async {
        viewModel.fetchBlock = { page, pageSize in
            return (1...pageSize).map { MockItem(id: $0, title: "\($0)") }
        }
        
        await viewModel.fetchItems()
        XCTAssertEqual(viewModel.items.count, 10)
        
        await viewModel.fetchItems(reset: true)
        XCTAssertEqual(viewModel.items.count, 10)
    }
    
    
    func testLoadMoreIfNeeded() async {
        viewModel.fetchBlock = { page, pageSize in
            return (1...pageSize).map { MockItem(id: $0, title: "\($0)") }
        }
        
        await viewModel.fetchItems()
        XCTAssertEqual(viewModel.items.count, 10)
        
        await viewModel.loadMoreIfNeeded(currentIndex: 9)
        XCTAssertEqual(viewModel.items.count, 20)
    }
    
    
    func testUpdateSearchQueryTriggersFetch() async {
        let expectation = expectation(description: "Search should complete")
        
        viewModel.searchBlock = { query, _, _ in
            defer { expectation.fulfill() }
            return [MockItem(id: 1, title: "1"), MockItem(id: 2, title: "2")]
        }
        
        await viewModel.updateSearchQuery("test")
        await fulfillment(of: [expectation], timeout: 1.0)
        
        XCTAssertEqual(viewModel.items.count, 2)
    }
  
    
    func testSearchCancelsPreviousTask() async {
        var searchCallCount = 0
        let expectation = expectation(description: "Search should complete")

        viewModel.searchBlock = { query, _, _ in
            defer { expectation.fulfill() }
            searchCallCount += 1
            return [MockItem(id: 1, title: "1")]
        }
        
        await viewModel.updateSearchQuery("first")
        await viewModel.updateSearchQuery("second")
        await fulfillment(of: [expectation], timeout: 1.0)

        XCTAssertEqual(searchCallCount, 1, "Previous search should be cancelled")
    }
     
}
