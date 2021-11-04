
import XCTest
import GBMChallengeKit
import GBMChallengeiOS
import TestHelpers
import Combine
import Charts


class IPCFeedUIIntegrationTests: XCTestCase {
    
    
    func test_fetchActions_requestsFromRepository() {
        let (sut, repo, counter) = makeSut()
        
        XCTAssertEqual(repo.fetchValuesCallCount, 0, "Expected no fetch requests before view is loaded")
        
        sut.loadViewIfNeeded()
        XCTAssertEqual(repo.fetchValuesCallCount, 1, "Expected one fetch requests once view is loaded")
        
        sut.simulateUserInitiatedReload()
        XCTAssertEqual(repo.fetchValuesCallCount, 2, "Expected 2 fetch requests once the user initiates a reload")
        
        counter.send(0)
        XCTAssertEqual(repo.fetchValuesCallCount, 3, "Expected 3 fetch requests once the countdown counter reach 0")
    }
    
    func test_loading_isVisibleWhileFetching() {
        
        let (sut, repo, counter) = makeSut()
        
        sut.loadViewIfNeeded()
        XCTAssertTrue(sut.isUserInitiatedLoading, "Expected loading indicator once view is loaded")
        
        repo.send((.cache, []))
        XCTAssertTrue(sut.isUserInitiatedLoading && sut.isAutomaticLoading, "Expected loading indicator once view renders cache result.")
        
        repo.send((.remote, []))
        repo.complete(at: 0)
        XCTAssertFalse(sut.isUserInitiatedLoading || sut.isAutomaticLoading, "Expected no loading indicator once fetching completes")
        
        sut.simulateUserInitiatedReload()
        XCTAssertTrue(sut.isUserInitiatedLoading && sut.isAutomaticLoading, "Expected loading indicator once the user initiates a reload")
        
        repo.complete(with: makeAnyError(), at: 1)
        XCTAssertFalse(sut.isUserInitiatedLoading || sut.isAutomaticLoading, "Expected no loading indicator once fetching completes with error")
        
        counter.send(0)
        XCTAssertTrue(sut.isAutomaticLoading && !sut.isUserInitiatedLoading, "Expected loading indicator once the counter reach 0")
        
        repo.send((.remote, []))
        repo.complete(at: 2)
        XCTAssertFalse(sut.isUserInitiatedLoading || sut.isAutomaticLoading, "Expected no loading indicator once the repo completes")
    }
    
    func test_fetchCompletion_rendersSuccesfullyTheFeed() {
        let (sut, repo, _) = makeSut()
        sut.loadViewIfNeeded()
        
        XCTAssertEqual(sut.numberOfCells, 0, "Expect empty collection on initial loading")
        
        let cacheResult = (IPCRepositorySource.cache, makeUniqueValues())
        repo.send(cacheResult)
        
        assert(sut: sut, isRendering: cacheResult)
    }
    
    func test_fetchCompletion_dispatchesFromBackgroundToMainThread() {
        let (sut, repo, _) = makeSut()
        
        sut.loadViewIfNeeded()
        
        let exp = expectation(description: "Wait for background queue")
        DispatchQueue.global().async {
            repo.send((.remote, []))
            repo.complete()
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_changeRange_reloadsChart() throws {
        let rangeOptions: [RangeOption] = [.max, .minute(10)]
        let selectedIndex = 1
        let selectedRange = rangeOptions[selectedIndex]
        let (sut, repo, _) = makeSut(rangeOptions: rangeOptions)
        sut.loadViewIfNeeded()
        
        let fixedDate = Date(string: "2020-08-18T04:12:54.067-05:00")
        let values: [IPCValue] = makeUniqueValues(for: [
            fixedDate.addingTimeInterval(-selectedRange.toSeconds() - 1),
            fixedDate.addingTimeInterval(-selectedRange.toSeconds()),
            fixedDate.addingTimeInterval(-selectedRange.toSeconds() + 1),
            fixedDate])
        
        repo.send((.remote, values))
        
        try sut.simulateRangeSelection(index: selectedIndex)
        
        
        let filteredValues = values.filter({ $0.date >= values.last!.date.addingTimeInterval(-selectedRange.toSeconds()) })
        
        let chartCell = try XCTUnwrap(sut.chartCell())
        let dataSet = try XCTUnwrap(chartCell.lineChartView.data?.dataSets.first as? LineChartDataSet)
        
        XCTAssertEqual(filteredValues.map({ $0.date.timeIntervalSinceReferenceDate }), dataSet.map({ TimeInterval($0.x) }))
    }
    
    func test_fetchError_sendErrorToDelegate() throws {
        
        class DelegateSpy: IPCFeedViewControllerDelegate {
            var receivedError: Error?
            func ipcFeedViewController(_ viewController: IPCFeedViewController, didReceiveFetchingError error: Error) {
                receivedError = error
            }
        }
        
        let delegateSpy = DelegateSpy()
        
        let (sut, repo, _) = makeSut()
        sut.delegate = delegateSpy
        sut.loadViewIfNeeded()
        
        let anyError = makeAnyError()
        repo.complete(with: anyError, at: 0)
        
        
        XCTAssertNotNil(delegateSpy.receivedError)
        XCTAssertEqual(delegateSpy.receivedError?.localizedDescription, "No se pudo actualizar el IPC, intente más tarde")
    }
    
    //MARK: - Helpers
    
    func makeSut(rangeOptions: [RangeOption] = RangeOption.defaultOptions, file: StaticString = #filePath, line: UInt = #line) -> (sut: IPCFeedViewController, repository: IPCRepositorySpy, coutner: CounterSpy) {
        
        let repository = IPCRepositorySpy()
        let counter = CounterSpy()
        let sut = IPCFeedUIComposer.composeIPCViewController(repository: repository, counter: counter, rangeOptions: rangeOptions)
        
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(repository, file: file, line: line)
        trackForMemoryLeaks(counter, file: file, line: line)

        return (sut, repository, counter)
    }

    func assert(sut: IPCFeedViewController, isRendering result: (source: IPCRepositorySource, values: [IPCValue]), file: StaticString = #filePath, line: UInt = #line) {
        
        sut.view.enforceLayoutCycle()
        
        XCTAssertEqual(4, sut.numberOfCells(inSection: 0), "Expected RefreshStatusCell, LatestValueCell, ChartCell, RangeControlCell", file: file, line: line)
        
        XCTAssertEqual(sut.numberOfCells(inSection: 1), result.values.count, "Expected one cell per value")
        
        //TODO: Assert that each cell renders its contents correctly (This step was skipped by manually testing the sut)
    }
}
