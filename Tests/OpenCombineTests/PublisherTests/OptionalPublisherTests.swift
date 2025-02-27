//
//  OptionalPublisherTests.swift
//  
//
//  Created by Sergej Jaskiewicz on 18.06.2019.
//

import XCTest

#if OPENCOMBINE_COMPATIBILITY_TEST
import Combine
#else
import OpenCombine
#endif

@available(macOS 10.15, iOS 13.0, *)
final class OptionalPublisherTests: XCTestCase {

    static let allTests = [
        ("testSuccessNoInitialDemand", testSuccessNoInitialDemand),
        ("testSuccessWithInitialDemand", testSuccessWithInitialDemand),
        ("testSuccessCancelOnSubscription", testSuccessCancelOnSubscription),
        ("testNil", testNil),
        ("testLifecycle", testLifecycle),
        ("testMinOperatorSpecialization", testMinOperatorSpecialization),
        ("testMaxOperatorSpecialization", testMaxOperatorSpecialization),
        ("testContainsOperatorSpecialization", testContainsOperatorSpecialization),
        ("testRemoveDuplicatesOperatorSpecialization",
         testRemoveDuplicatesOperatorSpecialization),
        ("testAllSatifyOperatorSpecialization", testAllSatifyOperatorSpecialization),
        ("testCollectOperatorSpecialization", testCollectOperatorSpecialization),
        ("testCountOperatorSpecialization", testCountOperatorSpecialization),
        ("testDropFirstOperatorSpecialization", testDropFirstOperatorSpecialization),
        ("testDropWhileOperatorSpecialization", testDropWhileOperatorSpecialization),
        ("testFirstOperatorSpecialization", testFirstOperatorSpecialization),
        ("testFirstWhereOperatorSpecializtion", testFirstWhereOperatorSpecializtion),
        ("testLastOperatorSpecialization", testLastOperatorSpecialization),
        ("testLastWhereOperatorSpecializtion", testLastWhereOperatorSpecializtion),
        ("testFilterOperatorSpecialization", testFilterOperatorSpecialization),
        ("testIgnoreOutputOperatorSpecialization",
         testIgnoreOutputOperatorSpecialization),
        ("testMapOperatorSpecialization", testMapOperatorSpecialization),
        ("testCompactMapOperatorSpecialization", testCompactMapOperatorSpecialization),
        ("testReplaceErrorOperatorSpecialization",
         testReplaceErrorOperatorSpecialization),
        ("testReplaceEmptyOperatorSpecialization",
         testReplaceEmptyOperatorSpecialization),
        ("testRetryOperatorSpecialization", testRetryOperatorSpecialization),
        ("testReduceOperatorSpecialization", testReduceOperatorSpecialization),
        ("testScanOperatorSpecialization", testScanOperatorSpecialization),
        ("testOutputAtIndexOperatorSpecialization",
         testOutputAtIndexOperatorSpecialization),
        ("testOutputInRangeOperatorSpecialization",
         testOutputInRangeOperatorSpecialization),
        ("testPrefixOperatorSpecialization", testPrefixOperatorSpecialization),
        ("testPrefixWhileOperatorSpecialization", testPrefixWhileOperatorSpecialization),
        ("testTestSuiteIncludesAllTests", testTestSuiteIncludesAllTests),
    ]

#if OPENCOMBINE_COMPATIBILITY_TEST || !canImport(Combine)
    private typealias Sut<Output> = Optional<Output>.Publisher
#else
    private typealias Sut<Output> = Optional<Output>.OCombine.Publisher
#endif

    func testSuccessNoInitialDemand() {
        let success = Sut(42)
        let tracking = TrackingSubscriberBase<Int, Never>()
        success.subscribe(tracking)

        XCTAssertEqual(tracking.history, [.subscription("Optional")])

        tracking.subscriptions.first?.request(.max(100))
        tracking.subscriptions.first?.request(.max(1))

        XCTAssertEqual(tracking.history, [.subscription("Optional"),
                                          .value(42),
                                          .completion(.finished)])
    }

    func testSuccessWithInitialDemand() {
        let just = Sut(42)
        let tracking = TrackingSubscriberBase<Int, Never>(
            receiveSubscription: { $0.request(.unlimited) }
        )
        just.subscribe(tracking)

        XCTAssertEqual(tracking.history, [.subscription("Optional"),
                                          .value(42),
                                          .completion(.finished)])
    }

    func testSuccessCancelOnSubscription() {
        let success = Sut(42)
        let tracking = TrackingSubscriberBase<Int, Never>(
            receiveSubscription: { $0.request(.max(1)); $0.cancel() }
        )
        success.subscribe(tracking)

        XCTAssertEqual(tracking.history, [.subscription("Optional"),
                                          .value(42),
                                          .completion(.finished)])
    }

    func testNil() {
        let success = Sut<Int>(nil)
        let tracking = TrackingSubscriberBase<Int, Never>()
        success.subscribe(tracking)

        XCTAssertEqual(tracking.history, [.subscription("Empty"),
                                          .completion(.finished)])
    }

    func testLifecycle() {
        var deinitCount = 0
        do {
            let once = Sut(42)
            let tracking = TrackingSubscriberBase<Int, Never>(
                onDeinit: { deinitCount += 1 }
            )
            once.subscribe(tracking)
            tracking.subscriptions.first?.cancel()
        }
        XCTAssertEqual(deinitCount, 1)
    }

    // MARK: - Operator specializations for Optional

    func testMinOperatorSpecialization() {
        XCTAssertEqual(Sut<Int>(112).min(), Sut(112))
        XCTAssertEqual(Sut<Int>(nil).min(), Sut(nil))

        var count = 0
        let comparator: (Int, Int) -> Bool = { count += 1; return $0 > $1 }
        XCTAssertEqual(Sut<Int>(1).min(by: comparator), Sut(1))
        XCTAssertEqual(Sut<Int>(nil).min(by: comparator), Sut(nil))

        XCTAssertEqual(count, 0, "comparator should not be called for min(by:)")
    }

    func testMaxOperatorSpecialization() {
        XCTAssertEqual(Sut<Int>(341).max(), Sut(341))
        XCTAssertEqual(Sut<Int>(nil).max(), Sut(nil))

        var count = 0
        let comparator: (Int, Int) -> Bool = { count += 1; return $0 > $1 }

        XCTAssertEqual(Sut<Int>(2).max(by: comparator), Sut(2))
        XCTAssertEqual(Sut<Int>(nil).max(by: comparator), Sut(nil))

        XCTAssertEqual(count, 0, "comparator should not be called for max(by:)")
    }

    func testContainsOperatorSpecialization() {
        XCTAssertEqual(Sut<Int>(10).contains(12), Sut(false))
        XCTAssertEqual(Sut<Int>(10).contains(10), Sut(true))
        XCTAssertEqual(Sut<Int>(nil).contains(10), Sut(nil))

        var count = 0
        let predicate: (Int) -> Bool = { count += 1; return $0 < 100 }

        XCTAssertEqual(Sut<Int>(64).contains(where: predicate), Sut(true))
        XCTAssertEqual(Sut<Int>(112).contains(where: predicate), Sut(false))
        XCTAssertEqual(Sut<Int>(nil).contains(where: predicate), Sut(nil))

        XCTAssertEqual(count, 2)
    }

    func testRemoveDuplicatesOperatorSpecialization() {
        XCTAssertEqual(Sut<Int>(1000).removeDuplicates(), Sut(1000))
        XCTAssertEqual(Sut<Int>(nil).removeDuplicates(), Sut(nil))

        var count = 0
        let comparator: (Int, Int) -> Bool = { count += 1; return $0 == $1 }

        XCTAssertEqual(Sut<Int>(44).removeDuplicates(by: comparator), Sut(44))
        XCTAssertEqual(Sut<Int>(nil).removeDuplicates(by: comparator), Sut(nil))

        XCTAssertEqual(count,
                       0,
                       "comparator should not be called for removeDuplicates(by:)")
    }

    func testAllSatifyOperatorSpecialization() {

        var count = 0
        let predicate: (Int) -> Bool = { count += 1; return $0 > 0 }

        XCTAssertEqual(Sut<Int>(0).allSatisfy(predicate), Sut(false))
        XCTAssertEqual(Sut<Int>(1).allSatisfy(predicate), Sut(true))
        XCTAssertEqual(Sut<Int>(nil).allSatisfy(predicate), Sut(nil))

        XCTAssertEqual(count, 2)
    }

    func testCollectOperatorSpecialization() {
        XCTAssertEqual(Sut<Int>(13).collect(), Sut([13]))
        XCTAssertEqual(Sut<Int>(nil).collect(), Sut([]))
    }

    func testCountOperatorSpecialization() {
        XCTAssertEqual(Sut<Int>(10000).count(), Sut(1))
        XCTAssertEqual(Sut<Int>(nil).count(), Sut(nil))
    }

    func testDropFirstOperatorSpecialization() {
        XCTAssertEqual(Sut<Int>(10000).dropFirst(), Sut(nil))
        XCTAssertEqual(Sut<Int>(10000).dropFirst(100), Sut(nil))
        XCTAssertEqual(Sut<Int>(10000).dropFirst(0), Sut(10000))
        XCTAssertEqual(Sut<Int>(nil).dropFirst(), Sut(nil))
    }

    func testDropWhileOperatorSpecialization() {
        var count = 0
        let predicate: (Int) -> Bool = { count += 1; return $0 != 42 }

        XCTAssertEqual(Sut<Int>(42).drop(while: predicate), Sut(42))
        XCTAssertEqual(Sut<Int>(-13).drop(while: predicate), Sut(nil))
        XCTAssertEqual(Sut<Int>(nil).drop(while: predicate), Sut(nil))

        XCTAssertEqual(count, 2)
    }

    func testFirstOperatorSpecialization() {
        XCTAssertEqual(Sut<Int>(3).first(), Sut(3))
        XCTAssertEqual(Sut<Int>(nil).first(), Sut(nil))
    }

    func testFirstWhereOperatorSpecializtion() {
        var count = 0
        let predicate: (Int) -> Bool = { count += 1; return $0 == 42 }

        XCTAssertEqual(Sut<Int>(42).first(where: predicate), Sut(42))
        XCTAssertEqual(Sut<Int>(-13).first(where: predicate), Sut(nil))
        XCTAssertEqual(Sut<Int>(nil).first(where: predicate), Sut(nil))

        XCTAssertEqual(count, 2)
    }

    func testLastOperatorSpecialization() {
        XCTAssertEqual(Sut<Int>(4).last(), Sut(4))
        XCTAssertEqual(Sut<Int>(nil).last(), Sut(nil))
    }

    func testLastWhereOperatorSpecializtion() {
        var count = 0
        let predicate: (Int) -> Bool = { count += 1; return $0 == 42 }

        XCTAssertEqual(Sut<Int>(42).last(where: predicate), Sut(42))
        XCTAssertEqual(Sut<Int>(-13).last(where: predicate), Sut(nil))
        XCTAssertEqual(Sut<Int>(nil).last(where: predicate), Sut(nil))

        XCTAssertEqual(count, 2)
    }

    func testFilterOperatorSpecialization() {
        var count = 0
        let predicate: (Int) -> Bool = { count += 1; return $0 == 42 }

        XCTAssertEqual(Sut<Int>(42).filter(predicate), Sut(42))
        XCTAssertEqual(Sut<Int>(-13).filter(predicate), Sut(nil))
        XCTAssertEqual(Sut<Int>(nil).filter(predicate), Sut(nil))

        XCTAssertEqual(count, 2)
    }

    func testIgnoreOutputOperatorSpecialization() {
        XCTAssertTrue(Sut<Double>(13.0).ignoreOutput().completeImmediately)
    }

    func testMapOperatorSpecialization() {
        var count = 0
        let transform: (Int) -> String = { count += 1; return String($0) }

        XCTAssertEqual(Sut<Int>(42).map(transform), Sut("42"))
        XCTAssertEqual(Sut<Int>(nil).map(transform), Sut(nil))

        XCTAssertEqual(count, 1)
    }

    func testCompactMapOperatorSpecialization() {
        var count = 0
        let transform: (Int) -> String? = {
            count += 1
            return $0 == 42 ? String($0) : nil
        }

        XCTAssertEqual(Sut<Int>(42).compactMap(transform), Sut("42"))
        XCTAssertEqual(Sut<Int>(100).compactMap(transform), Sut(nil))
        XCTAssertEqual(Sut<Int>(nil).compactMap(transform), Sut(nil))

        XCTAssertEqual(count, 2)
    }

    func testReplaceErrorOperatorSpecialization() {
        XCTAssertEqual(Sut<Int>(1).replaceError(with: 100), Sut(1))
        XCTAssertEqual(Sut<Int>(nil).replaceError(with: 100), Sut(nil))
    }

    func testReplaceEmptyOperatorSpecialization() {
        XCTAssertEqual(Sut<Int>(1).replaceEmpty(with: 100), Just(1))
        XCTAssertEqual(Sut<Int>(nil).replaceEmpty(with: 100), Just(100))
    }

    func testRetryOperatorSpecialization() {
        XCTAssertEqual(Sut<Int>(1).retry(100), Sut(1))
        XCTAssertEqual(Sut<Int>(nil).retry(100), Sut(nil))
    }

    func testReduceOperatorSpecialization() {
        var count = 0
        let plus: (Int, Int) -> Int = { count += 1; return $0 + $1 }

        XCTAssertEqual(Sut<Int>(4).reduce(2, plus), Sut(6))
        XCTAssertEqual(Sut<Int>(nil).reduce(2, plus), Sut(nil))

        XCTAssertEqual(count, 1)
    }

    func testScanOperatorSpecialization() {
        var count = 0
        let plus: (Int, Int) -> Int = { count += 1; return $0 + $1 }

        XCTAssertEqual(Sut<Int>(4).scan(2, plus), Sut(6))
        XCTAssertEqual(Sut<Int>(nil).scan(2, plus), Sut(nil))

        XCTAssertEqual(count, 1)
    }

    func testOutputAtIndexOperatorSpecialization() {
        XCTAssertEqual(Sut<Int>(12).output(at: 0), Sut(12))
        XCTAssertEqual(Sut<Int>(nil).output(at: 0), Sut(nil))
        XCTAssertEqual(Sut<Int>(12).output(at: 1), Sut(nil))
        XCTAssertEqual(Sut<Int>(12).output(at: 42), Sut(nil))
    }

    func testOutputInRangeOperatorSpecialization() {
        XCTAssertEqual(Sut<Int>(12).output(in: 0 ..< 10), Sut(12))
        XCTAssertEqual(Sut<Int>(12).output(in: 0 ..< (.max - 2)), Sut(12))
        XCTAssertEqual(Sut<Int>(nil).output(in: 0 ..< 10), Sut(nil))
        XCTAssertEqual(Sut<Int>(12).output(in: 0 ..< 0), Sut(nil))
        XCTAssertEqual(Sut<Int>(12).output(in: 0 ... 0), Sut(12))
        XCTAssertEqual(Sut<Int>(12).output(in: 1 ..< 10), Sut(nil))
        XCTAssertEqual(Sut<Int>(12).output(in: ...0), Sut(12))
        XCTAssertEqual(Sut<Int>(12).output(in: ..<0), Sut(nil))
        XCTAssertEqual(Sut<Int>(12).output(in: ..<1), Sut(12))

        let trackingRange = TrackingRangeExpression(0 ..< 10)
        _ = Sut<Int>(12).output(in: trackingRange)
        XCTAssertEqual(trackingRange.history, [.relativeTo(0 ..< .max)])
    }

    func testPrefixOperatorSpecialization() {
        XCTAssertEqual(Sut<Int>(98).prefix(0), Sut(nil))
        XCTAssertEqual(Sut<Int>(98).prefix(1), Sut(98))
        XCTAssertEqual(Sut<Int>(98).prefix(1000), Sut(98))
        XCTAssertEqual(Sut<Int>(nil).prefix(0), Sut(nil))
        XCTAssertEqual(Sut<Int>(nil).prefix(1), Sut(nil))
    }

    func testPrefixWhileOperatorSpecialization() {
        var count = 0
        let predicate: (Int) -> Bool = { count += 1; return $0.isMultiple(of: 2) }

        XCTAssertEqual(Sut<Int>(98).prefix(while: predicate), Sut(98))
        XCTAssertEqual(Sut<Int>(99).prefix(while: predicate), Sut(nil))
        XCTAssertEqual(Sut<Int>(nil).prefix(while: predicate), Sut(nil))

        XCTAssertEqual(count, 2)
    }

    // MARK: -
    func testTestSuiteIncludesAllTests() {
        // https://oleb.net/blog/2017/03/keeping-xctest-in-sync/
#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
        let thisClass = type(of: self)
        let allTestsCount = thisClass.allTests.count
        let darwinCount = thisClass.defaultTestSuite.testCaseCount
        XCTAssertEqual(allTestsCount,
                       darwinCount,
                       "\(darwinCount - allTestsCount) tests are missing from allTests")
#endif
    }
}
