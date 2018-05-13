import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import RxGesture
import ReactorKit
import AlamofireImage
import Hero
import NVActivityIndicatorView

class PictureListViewController: BaseViewController, ReactorKit.View {
    
    typealias PictureInfoSectionType = AnimatableSectionModel<String, PictureInfoSectionItem>
    typealias RxPictureInfoDataSource = RxCollectionViewSectionedAnimatedDataSource<PictureInfoSectionType>
    typealias PictureSectionType = AnimatableSectionModel<String, PictureSectionItem>
    typealias RxPictureDataSource = RxCollectionViewSectionedAnimatedDataSource<PictureSectionType>
    
    @IBOutlet weak var imageCollectionView: UICollectionView!
    
    @IBOutlet weak var infoCollectionView: UICollectionView!
        
    @IBOutlet weak var segmentedDataSource: UISegmentedControl!
    
    @IBOutlet weak var emptyStateView: UIView!
    
    @IBOutlet weak var filterIcon: UIBarButtonItem!
    
    let scrollSpeedEvaluator = ScrollSpeedEvaluator()
    
    let collectionViewTransformer = CollectionCellsTransformer()
    
    let focusedItemEvaluator = FocusedItemEvaluator()
    
    let pictureFocusedSubject = PublishSubject<Picture>()
    
    var pictureDataSource: RxPictureDataSource!
    
    var pictureInfoDataSource: RxPictureInfoDataSource!
    
    private let transitionAnimator = TransitionAnimator()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pictureDataSource = createPictureDataSource()
        pictureInfoDataSource = createPictureInfoDataSource()
        
        infoCollectionView.delegate = self
        
        imageCollectionView.delegate = self
        imageCollectionView.decelerationRate = 10
        imageCollectionView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        
        reactor = assembler.reactorProvider.createPictureListReactor()
    }
    
    func bind(reactor: PictureListReactor) {
        let dataObservable = reactor.state
            .getChange { $0.data }
        
        let errorObservable = reactor.state
            .getChange { $0.isError }
        
        let loadingObservable = reactor.state
            .getChange { $0.isLoading }
        
        let focusedPictureObservable = reactor.state
            .filter { $0.focusedPicture != nil }
            .getChange { $0.focusedPicture! }
        
        let isFilterDataSource = reactor.state
            .map { $0.dataSource == DataSourceType.filtered }
            .getChange { $0 }
        
        let dataErrorLoadingObservable =
            Observable.combineLatest(dataObservable, errorObservable, loadingObservable) { ($0, $1, $2) }
        
        let scroll = imageCollectionView.rx.didScroll.map { _ in Void() }
        
        let interval = Observable<Int>.interval(RxTimeInterval(0.2), scheduler: MainScheduler.instance).map { _ in Void() }
    
        // Change loading, error and data state of pictures collectionview
        dataErrorLoadingObservable
            .map { dataErrorLoading in
                let (data, isError, isLoading) = dataErrorLoading
                return self.createPictureSectionModels(data: data, isError: isError, isLoading: isLoading)
            }
            .bind(to: imageCollectionView.rx.items(dataSource: self.pictureDataSource))
            .disposed(by: self.disposeBag)
        
        // Change data state of pictures info collectionview
        dataObservable
            .map { $0.map { AnimatableSectionModel(model: $0.id, items: [PictureInfoSectionItem.pictureInfo(picture: $0)]) } }
            .bind(to: infoCollectionView.rx.items(dataSource: self.pictureInfoDataSource))
            .disposed(by: self.disposeBag)
        
        // Toggl empty state view visibility
        reactor.state
            .getChange { $0.isEmptyState() }
            .subscribe(onNext: { isEmptyState in
                self.emptyStateView.isHidden = !isEmptyState
            })
            .disposed(by: self.disposeBag)
        
        // Scroll pictures to start when data source change
        reactor.state
            .observeChange { $0.dataSource }
            .filter { !$0.isEmptyState() }
            .subscribe(onNext: { _ in
                self.scrollPictures(at: IndexPath(row: 0, section: 1), animated: false)
            })
            .disposed(by: self.disposeBag)
        
        // Transform cells
        imageCollectionView.rx.didEndDisplayingCell
            .subscribe(onNext: { index in
                self.transformCellsByDistanceFromCenter()
            })
            .disposed(by: self.disposeBag)
        
        // Trancform cells when collection view scroll
        imageCollectionView.rx.didScroll
            .subscribe(onNext: { index in
                self.transformCellsByDistanceFromCenter()
            })
            .disposed(by: self.disposeBag)
        
        // Snap to focused item when drag ends
        imageCollectionView.rx.didEndDragging
            .filter { _ in !self.imageCollectionView.isDecelerating }
            .subscribe(onNext: { _ in
                self.snapToFocusedItem()
            })
            .disposed(by: self.disposeBag)
        
        // Snap to focused item when collection view stops scrolling
        imageCollectionView.rx.didEndDecelerating
            .subscribe(onNext: { _ in
                self.snapToFocusedItem()
            })
            .disposed(by: self.disposeBag)
        
        // Snap to focused item when error or loading state are changed and collection view is not scrolling or is not being dragged
        dataErrorLoadingObservable
            .flatMapLatest { _ in Observable<Int>.timer(RxTimeInterval(0.2), scheduler: MainScheduler.instance) }
            .filter { _ in !self.imageCollectionView.isDragging && !self.imageCollectionView.isDecelerating }
            .subscribe(onNext: { _ in
                self.snapToFocusedItem()
            })
            .disposed(by: self.disposeBag)
        
        // Change focused item when collection view is scrolled
        Observable.merge(scroll)
            .withLatestFrom(reactor.state)
            .subscribe(onNext: { state in
                if let focusedItemSection = self.focusedItemEvaluator.getFocusedItemSection(self.imageCollectionView) {
                    let index = IndexPath(row: 0, section: focusedItemSection)
                    let item = self.pictureDataSource[index]
                    switch item {
                        case let .DataItem(picture):
                            self.pictureFocusedSubject.onNext(picture)
                        default:
                            break
                    }
                }
            })
            .disposed(by: self.disposeBag)
        
        // Transform cells when they are scrolled or in given interval
        Observable.merge(scroll, interval)
            .subscribe(onNext: { _ in
                self.transformCellsByDistanceFromCenter()
            })
            .disposed(by: self.disposeBag)
        
        // Transform cells when they are not being dragged
        Observable.merge(rx.viewWillAppear, rx.viewDidAppear)
            .flatMapLatest { _ in scroll.takeUntil(self.rx.viewWillDisappear) }
            .flatMapLatest { Observable<Int>.interval(RxTimeInterval(0.5), scheduler: MainScheduler.instance) }
            .filter { _ in !self.imageCollectionView.isDragging }
            .subscribe(onNext: { _ in
                self.transformCellsByDistanceFromCenter()
            })
            .disposed(by: self.disposeBag)
        
        // Snap to focused item and transform cells when viewDidAppear is called
        rx.viewDidAppear
            .subscribe(onNext: { _ in
                self.snapToFocusedItem()
                self.transformCellsByDistanceFromCenter()
            })
            .disposed(by: self.disposeBag)
        
        // Scroll to selected item when it is changed
        focusedPictureObservable
            .withLatestFrom(reactor.state.map { $0.data }) { picture, data in self.getIndex(data, picture) }
            .map { self.addOffsetToPicturesIndex($0) }
            .subscribe(onNext: { index in
                self.imageCollectionView.scrollToItem(at: index, at: .centeredHorizontally, animated: true)
                self.transformCellsByDistanceFromCenter()
            })
            .disposed(by: self.disposeBag)
        
        // Scroll to picture info section when focused item is changed
        Observable.merge(pictureFocusedSubject.distinctUntilChanged(), focusedPictureObservable)
            .distinctUntilChanged()
            .withLatestFrom(reactor.state) { picture, state -> IndexPath? in
                let index = state.data.index(of: picture)
                guard let safeIndex = index else { return nil }
                let intIndex = state.data.distance(from: state.data.startIndex, to: safeIndex)
                return IndexPath(row: 0, section: intIndex)
            }
            .subscribe(onNext: { (index) in
                if let index = index {
                    self.infoCollectionView.scrollToItem(at: index, at: .centeredHorizontally, animated: true)
                }
            })
            .disposed(by: self.disposeBag)
        
        // Show filter view controller when filter icon is clicked
        filterIcon.rx.tap
            .subscribe(onNext: { _ in
                self.performSegue(withIdentifier: FilterViewController.sequeIdentifier, sender: nil)
            })
            .disposed(by: self.disposeBag)
        
        // Send load more action if is last cell shown
        imageCollectionView.rx.willDisplayCell
            .map { _, indexPath in indexPath }
            .filter { index in
                self.pictureDataSource[index].identity == PictureSectionItemId.endEdgePaddingId
            }
            .withLatestFrom(reactor.state) { _, state in state }
            .filter { state in state.isMoreLoadingEnabled }
            .map { _ in .loadMore }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        // Send allDataSelected action when segment control button is clicked
        segmentedDataSource.rx.selectedSegmentIndex.asObservable()
            .filter { $0 == 0 }
            .map { _ in PictureListReactor.Action.allDataSelected }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        // Send favouriteDataSelected action when segment control button is clicked
        segmentedDataSource.rx.selectedSegmentIndex.asObservable()
            .filter { $0 == 1 }
            .map { _ in PictureListReactor.Action.favouriteDataSelected }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        // Send filteredDataSelected action when segment control button is clicked
        segmentedDataSource.rx.selectedSegmentIndex.asObservable()
            .filter { $0 == 2 }
            .map { _ in PictureListReactor.Action.filteredDataSelected }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        // Send initialize action when viewWillAppear is clicked
        rx.viewWillAppear
            .take(1)
            .map { _ in .initialize }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        // Transform cells size after viewDidAppear is called
        rx.viewDidAppear
            .delay(RxTimeInterval(1), scheduler: MainScheduler.instance)
            .subscribe(onNext: { _ in
                self.transformCellsByDistanceFromCenter()
            })
            .disposed(by: self.disposeBag)
        
        // Show/Hide filter button
        isFilterDataSource
            .subscribe(onNext: { isFilter in
                if isFilter {
                    self.filterIcon.isEnabled = true
                    self.filterIcon.tintColor = UIColor.white
                } else {
                    self.filterIcon.isEnabled = false
                    self.filterIcon.tintColor = UIColor.clear
                }
            })
            .disposed(by: self.disposeBag)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let destinationViewController = segue.destination as? PictureDetailViewController {
            if let picture = sender as? Picture {
                 destinationViewController.initialPicture = picture
            }
        }
        
        if let filterViewController = segue.destination as? FilterViewController {
            filterViewController.modalTransitionStyle = .crossDissolve
        }
    }
    
    private func createPictureSectionModels(data: [Picture], isError: Bool, isLoading: Bool) -> [PictureSectionType] {
        let dataItems = data.map { PictureSectionItem.DataItem(item: $0) }
        let dataModels = dataItems.map { AnimatableSectionModel(model: $0.identity, items: [$0]) }
        let loadingMoreItem = PictureSectionItem.FooterItem(isLoading: isLoading, isError: isError)
        let loadingMoreModel = AnimatableSectionModel(model: loadingMoreItem.identity, items: [loadingMoreItem])
        let startPaddingModel = AnimatableSectionModel(model: PictureSectionItem.startEdgePadding.identity, items: [PictureSectionItem.startEdgePadding])
        let endPaddingModel = AnimatableSectionModel(model: PictureSectionItem.endEdgePadding.identity, items: [PictureSectionItem.endEdgePadding])
        
        var models = [startPaddingModel] + dataModels
        if isLoading != false || isError != false {
            models += [loadingMoreModel]
        }
        return models + [endPaddingModel]
    }
    
    private func getIndex(_ pictures: [Picture], _ picture: Picture) -> IndexPath {
        let index = pictures.index(of: picture)
        guard let safeIndex = index else {
            fatalError("Unknown picture \(picture)")
        }
        let intIndex = pictures.distance(from: pictures.startIndex, to: safeIndex)
        return IndexPath(row: 0, section: intIndex)
    }
    
    private func addOffsetToPicturesIndex(_ indexPath: IndexPath) -> IndexPath {
        var index = indexPath
        index.section = indexPath.section + 1
        return index
    }
    
    private func scrollPictures(at index: IndexPath, animated: Bool = true) {
        self.imageCollectionView.scrollToItem(at: index, at: .centeredHorizontally, animated: animated)
        self.transformCellsByDistanceFromCenter()
    }
    
    private func scrollInfo(at index: IndexPath, animated: Bool = true) {
        self.infoCollectionView.scrollToItem(at: index, at: .centeredHorizontally, animated: animated)
    }
}

extension PictureListViewController {
    func createPictureDataSource() -> RxPictureDataSource {
        return RxPictureDataSource(configureCell: { dataSource, tableView, indexPath, _ in
            switch dataSource[indexPath] {
                case let .DataItem(picture):
                    let cell = self.imageCollectionView.dequeueReusableCell(withReuseIdentifier: PictureCell.identifier, for: indexPath) as! PictureCell

                    cell.picture.heroID = picture.id
                    
                    if let url = picture.url {
                        cell.picture.af_setImage(withURL: url)
                    }
                    
                    cell.picture.rx.tapGesture().when(.recognized)
                        .subscribe(onNext: { _ in self.performSegue(withIdentifier: PictureDetailViewController.sequeIdentifier, sender: picture) })
                        .disposed(by: cell.disposeBagCell)
                    
                    return cell
                case let .FooterItem(isLoading, isError):
                    let cell = self.imageCollectionView.dequeueReusableCell(withReuseIdentifier: LoadingMoreCell.identifier, for: indexPath) as! LoadingMoreCell
                    
                    if isLoading {
                        cell.setLoadingState()
                    } else if isError {
                        cell.setErrorState()
                    }
                    
                    cell.tryAgainButton.rx.tapGesture()
                        .when(.recognized)
                        .map { _ in .loadMore }
                        .debug("TAP")
                        .bind(to: self.reactor!.action)
                        .disposed(by: cell.disposeBagCell)
                    
                    return cell
                case .startEdgePadding:
                    return self.imageCollectionView.dequeueReusableCell(withReuseIdentifier: PaddingCell.identifier, for: indexPath)
                case .endEdgePadding:
                    return self.imageCollectionView.dequeueReusableCell(withReuseIdentifier: PaddingCell.identifier, for: indexPath)
            }
        }, configureSupplementaryView: { (dataSource, collectionView, kind, indexPath) in
            return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: DummyReusableView.identifier, for: indexPath)
        })
    }
}

extension PictureListViewController {
    func createPictureInfoDataSource() -> RxPictureInfoDataSource {
        return RxPictureInfoDataSource(configureCell: { dataSource, tableView, indexPath, _ in
            switch dataSource[indexPath] {
                case let .pictureInfo(picture):
                    let cell = self.infoCollectionView.dequeueReusableCell(withReuseIdentifier: PictureInfoCell.identifier, for: indexPath) as! PictureInfoCell
                    cell.bind(picture: picture)
                    return cell
            }
        }, configureSupplementaryView: { (dataSource, collectionView, kind, indexPath) in
            return collectionView.getDummyReusableCell(ofKind: kind, forIndex: indexPath)
        })
    }
}

extension PictureListViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == imageCollectionView {
            switch pictureDataSource[indexPath] {
                case .startEdgePadding:
                    return CGSize(width: 150, height: collectionView.frame.height)
                case .endEdgePadding:
                    return CGSize(width: 150, height: collectionView.frame.height)
                case .FooterItem(_, isError: _):
                    return CGSize(width: 300, height: collectionView.frame.height)
                default:
                    return CGSize(width: 300, height: collectionView.frame.height)
            }
        }
        
        if collectionView == infoCollectionView {
            return collectionView.frame.size
        }
        
        fatalError("Unknown collectionview")
    }
}

extension PictureListViewController: UIScrollViewDelegate {
    
    func transformCellsByDistanceFromCenter() {
        collectionViewTransformer.transformByDistanceFromCenter(in: imageCollectionView)
    }
    
    func snapToFocusedItem(withAnimation: Bool = true) {
        focusedItemEvaluator.snapToFocusedItem(imageCollectionView, withAnimation: withAnimation)
    }
}

extension PictureListViewController: TransitionAnimatorDelegate {
    var transitionType: Transitions.TransitionType {
        return .rollUp
    }
    
    var duration: TimeInterval {
        return 0.2
    }
    
    var mainView: UIView? {
        return nil
    }
    
    var info: [String: Any] {
        return [:]
    }
}
