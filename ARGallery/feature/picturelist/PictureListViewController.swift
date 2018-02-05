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
    
    @IBOutlet weak var filterIcon: UIImageView!
    
    let scrollSpeedEvaluator = ScrollSpeedEvaluator()
    
    let collectionViewTransformer = CollectionCellsTransformer()
    
    let focusedItemEvaluator = FocusedItemEvaluator()
    
    let pictureFocusedSubject = PublishSubject<Picture>()
    
    var refresher: UIRefreshControl!
    
    var pictureDataSource: RxPictureDataSource!
    
    var pictureInfoDataSource: RxPictureInfoDataSource!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        refresher = UIRefreshControl()
        refresher.tintColor = UIColor.blue
        
        pictureDataSource = createPictureDataSource()
        pictureInfoDataSource = createPictureInfoDataSource()
        
        infoCollectionView.delegate = self
        
        imageCollectionView.delegate = self
        imageCollectionView.decelerationRate = 10
        imageCollectionView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        
        reactor = assembler.reactorProvider.createPictureListReactor()
    }
    
    func bind(reactor: PictureListReactor) {
        let dataObservable = reactor.state.getChange { $0.data }
        let errorObservable = reactor.state.getChange { $0.isError }
        let loadingObservable = reactor.state.getChange { $0.isLoading }
        let loadingMoreEnabledObservable = reactor.state.getChange { $0.isMoreLoadingEnabled }
        let focusedPictureObservable = reactor.state.filter { $0.focusedPicture != nil }.getChange { $0.focusedPicture! }
        let dataErrorLoadingObservable =  Observable.combineLatest(dataObservable, errorObservable, loadingObservable) { ($0, $1, $2) }
        
        dataErrorLoadingObservable
            .map { dataErrorLoading in
                let (data, isError, isLoading) = dataErrorLoading
                return self.createPictureSectionModels(data: data, isError: isError, isLoading: isLoading)
            }
            .bind(to: imageCollectionView.rx.items(dataSource: self.pictureDataSource))
            .disposed(by: self.disposeBag)
        
        imageCollectionView.rx.didEndDisplayingCell
            .subscribe(onNext: { index in
                self.transformCellsByDistanceFromCenter()
            })
            .disposed(by: self.disposeBag)
        
        imageCollectionView.rx.didEndDisplayingCell
            .take(1)
            .subscribe(onNext: { index in
                self.snapToFocusedItem()
            })
            .disposed(by: self.disposeBag)
        
        dataErrorLoadingObservable
            .subscribe(onNext: { index in
                self.transformCellsByDistanceFromCenter()
            })
            .disposed(by: self.disposeBag)
        
        dataObservable
            .map { $0.map { AnimatableSectionModel(model: $0.id, items: [PictureInfoSectionItem.pictureInfo(picture: $0)]) } }
            .bind(to: infoCollectionView.rx.items(dataSource: self.pictureInfoDataSource))
            .disposed(by: self.disposeBag)
        
        reactor.state
            .getChange { $0.focusedPicture }
            .filter { $0 != nil }
            .withLatestFrom(reactor.state.map { $0.data }) { picture, data in self.getIndex(data, picture!) }
            .map { self.addOffsetToPicturesIndex($0) }
            .subscribe(onNext: { index in
                self.imageCollectionView.scrollToItem(at: index, at: .centeredHorizontally, animated: true)
                self.transformCellsByDistanceFromCenter()
            })
            .disposed(by: self.disposeBag)
        
        Observable.merge(pictureFocusedSubject.asObservable(), focusedPictureObservable)
            .distinctUntilChanged()
            .withLatestFrom(reactor.state) { picture, state in
                let index = state.data.index(of: picture)
                guard let safeIndex = index else { fatalError() }
                let intIndex = state.data.distance(from: state.data.startIndex, to: safeIndex)
                return IndexPath(row: 0, section: intIndex)
            }
            .subscribe(onNext: { (index) in
                self.infoCollectionView.scrollToItem(at: index, at: .centeredHorizontally, animated: true)
            })
            .disposed(by: self.disposeBag)
        
        filterIcon.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { _ in
                self.performSegue(withIdentifier: FilterViewController.sequeIdentifier, sender: nil)
            })
            .disposed(by: self.disposeBag)
        
        refresher.rx.controlEvent(.valueChanged)
            .map { .refresh }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        imageCollectionView.rx.willDisplayCell
            .map { _, indexPath in indexPath }
            .filter { index in self.pictureDataSource[index].identity == PictureSectionItemId.endEdgePaddingId }
            .withLatestFrom(reactor.state) { _, state in state }
            .filter { state in state.isMoreLoadingEnabled }
            .map { _ in .loadMore }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        rx.viewWillAppear
            .take(1)
            .map { _ in .initialize }
            .bind(to: reactor.action)
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
    
    func pictureSnapped(index: Int) {

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
                    
                    cell.picture.rx
                        .tapGesture()
                        .when(.recognized)
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
        
        fatalError("Unknown collection view")
    }
}

extension PictureListViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == imageCollectionView {
            
            transformCellsByDistanceFromCenter()
            
            if scrollSpeedEvaluator.isScrollingSlowly(scrollView) {
                if let focusedItemSection = focusedItemEvaluator.getFocusedItemSection(imageCollectionView) {
                    let index = IndexPath(row: 0, section: focusedItemSection)
                    let item = pictureDataSource[index]
                    switch item {
                        case let .DataItem(picture):
                            pictureFocusedSubject.onNext(picture)
                        default:
                            break
                    }
                }
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == imageCollectionView {
             snapToFocusedItem()
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView == imageCollectionView  && !decelerate {
            snapToFocusedItem()
        }
    }
    
    func transformCellsByDistanceFromCenter() {
        collectionViewTransformer.transformByDistanceFromCenter(in: imageCollectionView)
    }
    
    func snapToFocusedItem(withAnimation: Bool = true) {
        focusedItemEvaluator.snapToFocusedItem(imageCollectionView, withAnimation: withAnimation)
    }
}


