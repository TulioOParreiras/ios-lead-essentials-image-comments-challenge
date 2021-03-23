//
//  ImageCommentsUIIntegrationTests.swift
//  EssentialAppTests
//
//  Created by Tulio de Oliveira Parreiras on 23/03/21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import XCTest
import EssentialFeed

final class ImageCommentsLoaderPresentationAdapter: ImageCommentsViewControllerDelegate {
	private let loader: ImageCommentsLoader
	var presenter: ImageCommentsPresenter?
	
	init(loader: ImageCommentsLoader) {
		self.loader = loader
	}
	
	func didRequestCommentsReload() {
		presenter?.didStartLoadingComments()
		
		loader.load { _ in
			self.presenter?.didFinishLoadingComments(with: [])
		}
	}
	
}

final class ImageCommentsUIComposer {
	private init() { }
	
	static func imageComments(loader: ImageCommentsLoader) -> ImageCommentsViewController {
		let presentationAdapter = ImageCommentsLoaderPresentationAdapter(loader: loader)
		
		let controller = ImageCommentsViewController()
		let presenter = ImageCommentsPresenter(commentsView: controller, loadingView: controller, errorView: controller)
		presentationAdapter.presenter = presenter
		
		controller.title = ImageCommentsPresenter.title
		controller.delegate = presentationAdapter
		return controller
	}
}

protocol ImageCommentsLoader {
	typealias Result = Swift.Result<[FeedImageComment], Error>
	
	func load(completion: @escaping(Result) -> Void)
}

protocol ImageCommentsViewControllerDelegate {
	func didRequestCommentsReload()
}

final class ImageCommentsViewController: UITableViewController, ImageCommentsView, ImageCommentsLoadingView, ImageCommentsErrorView {
	
	var delegate: ImageCommentsViewControllerDelegate?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		refreshControl = UIRefreshControl()
		refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
		refresh()
	}
	
	@objc func refresh() {
		delegate?.didRequestCommentsReload()
	}
	
	func display(_ isLoading: Bool) {
		isLoading ? refreshControl?.beginRefreshing() : refreshControl?.endRefreshing()
	}
	
	func display(_ comments: [FeedImageComment]) {
		
	}
	
	func display(_ errorMessage: String?) {
		
	}
	
}

final class ImageCommentsUIIntegrationTests: XCTestCase {
	
	func test_imageCommentsView_hasTitle() {
		let (sut, _) = makeSUT()
		
		sut.loadViewIfNeeded()
		
		let key = "IMAGE_COMMENTS_VIEW_TITLE"
		let table = "ImageComments"
		let bundle = Bundle(for: ImageCommentsPresenter.self)
		let title = bundle.localizedString(forKey: key, value: nil, table: table)
		
		XCTAssertEqual(sut.title, title)
	}

	func test_loadCommentsActions_requestCommentsFromLoader() {
		let (sut, loader) = makeSUT()
		XCTAssertEqual(loader.loadCallCount, 0)
		
		sut.loadViewIfNeeded()
		XCTAssertEqual(loader.loadCallCount, 1)
		
		sut.simulateUserInitiatedCommentsReload()
		XCTAssertEqual(loader.loadCallCount, 2)
		
		sut.simulateUserInitiatedCommentsReload()
		XCTAssertEqual(loader.loadCallCount, 3)
	}
	
	func test_loadingCommentsIndicator_isVisibleWhileLoadingComments() {
		let (sut, loader) = makeSUT()
		
		sut.loadViewIfNeeded()
		XCTAssertTrue(sut.isShowingLoadingIndicator)
		
		loader.completeCommentsLoading(at: 0)
		XCTAssertFalse(sut.isShowingLoadingIndicator)
		
		sut.simulateUserInitiatedCommentsReload()
		XCTAssertTrue(sut.isShowingLoadingIndicator)
		
		loader.completeCommentsLoading(at: 1)
		XCTAssertFalse(sut.isShowingLoadingIndicator)
	}
	
	// MARK: - Helpers
	
	private func makeSUT() -> (sut: ImageCommentsViewController, loader: LoaderSpy) {
		let loader = LoaderSpy()
		let sut = ImageCommentsUIComposer.imageComments(loader: loader)
		return (sut, loader)
	}
	
	private final class LoaderSpy: ImageCommentsLoader {
		var loadCallCount: Int {
			messages.count
		}
		private var messages = [(ImageCommentsLoader.Result) -> Void]()
		
		func load(completion: @escaping (ImageCommentsLoader.Result) -> Void) {
			messages.append(completion)
		}
		
		func completeCommentsLoading(with comments: [FeedImageComment] = [], at index: Int = 0) {
			messages[index](.success(comments))
		}
	}

}

private extension ImageCommentsViewController {
	func simulateUserInitiatedCommentsReload() {
		refreshControl?.simulate(event: .valueChanged)
	}
	
	var isShowingLoadingIndicator: Bool {
		return refreshControl?.isRefreshing == true
	}
}
