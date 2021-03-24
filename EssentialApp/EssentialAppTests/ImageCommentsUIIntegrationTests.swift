//
//  ImageCommentsUIIntegrationTests.swift
//  EssentialAppTests
//
//  Created by Tulio de Oliveira Parreiras on 23/03/21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import XCTest
import EssentialFeed
import EssentialFeediOS

final class ImageCommentsLoaderPresentationAdapter: ImageCommentsViewControllerDelegate {
	private let loader: ImageCommentsLoader
	var presenter: ImageCommentsPresenter?
	
	init(loader: ImageCommentsLoader) {
		self.loader = loader
	}
	
	func didRequestCommentsReload() {
		presenter?.didStartLoadingComments()
		
		loader.load { result in
			switch result {
			case let .success(comments):
				self.presenter?.didFinishLoadingComments(with: comments)
			case let .failure(error):
				self.presenter?.didFinishLoadingComments(with: error)
			}
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
	private(set) var errorView = UILabel()
	
	private var models = [FeedImageComment]() {
		didSet {
			tableView.reloadData()
		}
	}
	
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
		models = comments
	}
	
	func display(_ errorMessage: String?) {
		errorView.text = errorMessage
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return models.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = ImageCommentCell()
		let model = models[indexPath.row]
		cell.usernameLabel.text = model.author.username
		cell.dateLabel.text = String(describing: model.createdAt)
		cell.messageLabel.text = model.message
		return cell
	}
	
}

final class ImageCommentCell: UITableViewCell {
	private(set) lazy var usernameLabel = UILabel()
	private(set) lazy var dateLabel = UILabel()
	private(set) lazy var messageLabel = UILabel()
}

final class ImageCommentsUIIntegrationTests: XCTestCase {
	
	func test_imageCommentsView_hasTitle() {
		let (sut, _) = makeSUT()
		
		sut.loadViewIfNeeded()
		XCTAssertEqual(sut.title, localized("IMAGE_COMMENTS_VIEW_TITLE"))
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
	
	func test_loadCommentsCompletion_rendersSuccessfullyLoadedComments() {
		let comment1 = makeComment(message: "a message", authorName: "a name")
		let comment2 = makeComment(message: "another message", authorName: "another name")
		let (sut, loader) = makeSUT()
		
		sut.loadViewIfNeeded()
		assertThat(sut, isRendering: [])
		
		loader.completeCommentsLoading(with: [comment1])
		assertThat(sut, isRendering: [comment1])
		
		sut.simulateUserInitiatedCommentsReload()
		loader.completeCommentsLoading(with: [comment1, comment2], at: 1)
		assertThat(sut, isRendering: [comment1, comment2])
	}
	
	func test_loadCommentsCompletion_rendersSuccessfullyLoadedEmptyComentsAfterNonEmptyComments() {
		let comment1 = makeComment(message: "a message", authorName: "a name")
		let comment2 = makeComment(message: "another message", authorName: "another name")
		let (sut, loader) = makeSUT()
		
		sut.loadViewIfNeeded()
		loader.completeCommentsLoading(with: [comment1, comment2], at: 0)
		assertThat(sut, isRendering: [comment1, comment2])
		
		sut.simulateUserInitiatedCommentsReload()
		loader.completeCommentsLoading(with: [], at: 1)
		assertThat(sut, isRendering: [])
	}
	
	func test_loadCommentsCompletion_doesNotAlterCurrentRenderingStateOnError() {
		let comment1 = makeComment(message: "a message", authorName: "a name")
		let (sut, loader) = makeSUT()
		
		sut.loadViewIfNeeded()
		loader.completeCommentsLoading(with: [comment1], at: 0)
		assertThat(sut, isRendering: [comment1])
		
		sut.simulateUserInitiatedCommentsReload()
		loader.completeCommentsLoadingWithError(at: 1)
		assertThat(sut, isRendering: [comment1])
	}
	
	func test_loadCommentsCompletion_rendersErrorMessageOnErrorUntilNextReload() {
		let (sut, loader) = makeSUT()
		
		sut.loadViewIfNeeded()
		XCTAssertEqual(sut.errorMessage, nil)
		
		loader.completeCommentsLoadingWithError(at: 0)
		XCTAssertEqual(sut.errorMessage, localized("IMAGE_COMMENTS_LOAD_ERROR"))
		
		sut.simulateUserInitiatedCommentsReload()
		XCTAssertEqual(sut.errorMessage, nil)
	}
	
	// MARK: - Helpers
	
	private func makeSUT() -> (sut: ImageCommentsViewController, loader: LoaderSpy) {
		let loader = LoaderSpy()
		let sut = ImageCommentsUIComposer.imageComments(loader: loader)
		return (sut, loader)
	}
	
	func localized(_ key: String) -> String {
		let table = "ImageComments"
		let bundle = Bundle(for: ImageCommentsPresenter.self)
		let value = bundle.localizedString(forKey: key, value: nil, table: table)
		return value
	}
	
	func makeComment(message: String = "any message", authorName: String = "any name") -> FeedImageComment {
		return FeedImageComment(id: UUID(), message: message, createdAt: Date(), author: CommentAuthor(username: authorName))
	}
	
	func assertThat(_ sut: ImageCommentsViewController, isRendering comments: [FeedImageComment], file: StaticString = #filePath, line: UInt = #line) {
		sut.view.enforceLayoutCycle()
		
		guard sut.numberOfRenderedCommentViews() == comments.count else {
			return XCTFail("Expected \(comments.count) images, got \(sut.numberOfRenderedCommentViews()) instead.", file: file, line: line)
		}
		
		comments.enumerated().forEach { index, comment in
			assertThat(sut, hasViewConfiguredFor: comment, at: index, file: file, line: line)
		}
		
		executeRunLoopToCleanUpReferences()
	}
	
	func assertThat(_ sut: ImageCommentsViewController, hasViewConfiguredFor comment: FeedImageComment, at index: Int, file: StaticString = #filePath, line: UInt = #line) {
		let view = sut.commentView(at: index)

		guard let cell = view as? ImageCommentCell else {
			return XCTFail("Expected \(ImageCommentCell.self) instance, got \(String(describing: view)) instead", file: file, line: line)
		}
		
		XCTAssertEqual(cell.username, comment.author.username)
		XCTAssertEqual(cell.date, String(describing: comment.createdAt))
		XCTAssertEqual(cell.message, comment.message)
	}
	
	private func executeRunLoopToCleanUpReferences() {
		RunLoop.current.run(until: Date())
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
		
		func completeCommentsLoadingWithError(_ error: Error = anyNSError(), at index: Int = 0) {
			messages[index](.failure(error))
		}
	}

}

private extension ImageCommentCell {
	var username: String? {
		usernameLabel.text
	}

	var date: String? {
		dateLabel.text
	}
	
	var message: String? {
		messageLabel.text 
	}
}

private extension ImageCommentsViewController {
	func simulateUserInitiatedCommentsReload() {
		refreshControl?.simulate(event: .valueChanged)
	}
	
	var isShowingLoadingIndicator: Bool {
		return refreshControl?.isRefreshing == true
	}
	
	private var commentsSection: Int {
		return 0
	}
	
	func numberOfRenderedCommentViews() -> Int {
		tableView.numberOfRows(inSection: commentsSection)
	}
	
	func commentView(at index: Int) -> UITableViewCell? {
		let ds = tableView.dataSource
		return ds?.tableView(tableView, cellForRowAt: IndexPath(row: index, section: commentsSection))
	}
	
	var errorMessage: String? {
		return errorView.text
	}
}
