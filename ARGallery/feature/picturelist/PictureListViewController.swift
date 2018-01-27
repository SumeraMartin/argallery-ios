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
    
    @IBOutlet weak var retryButton: UIButton!
    
    @IBOutlet weak var errorContainer: UIView!
    
    @IBOutlet weak var loadingView: NVActivityIndicatorView!
    
    @IBOutlet weak var imageCollectionView: UICollectionView!
    
    @IBOutlet weak var infoCollectionView: UICollectionView!
    
    @IBOutlet weak var loadingContainer: UIView!
    
    @IBOutlet weak var filterIcon: UIImageView!
    
    let scrollSpeedEvaluator = ScrollSpeedEvaluator()
    
    let collectionViewResizer = CollectionViewResizer()
    
    let snapHelper = SnapHelper()
    
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
        imageCollectionView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        
        reactor = assembler.reactorProvider.createPictureListReactor()
    }
    
    func bind(reactor: PictureListReactor) {
        let dataSectionObservable = reactor.state
            .getChange { $0.data }
            .map { $0.map { AnimatableSectionModel(model: $0.id, items: [PictureSectionItem.DataItem(item: $0)]) } }
        
        let isLoadingMoreObservable = reactor.state
            .getChange { $0.isLoadingMore }
        
        let isLoadingMoreErrorObservable = reactor.state
            .getChange { $0.isLoadingMoreError }
        
        Observable.combineLatest(dataSectionObservable, isLoadingMoreObservable, isLoadingMoreErrorObservable)
            .map { (dataItems, isLoadingMore, isLoadingMoreError) in
                let footerItem = PictureSectionItem.FooterItem(isLoading: isLoadingMore, isError: isLoadingMoreError)
                let model = AnimatableSectionModel(model: footerItem.identity, items: [footerItem])
                
                let startPaddingModel = AnimatableSectionModel(model: PictureSectionItem.startEdgePadding.identity, items: [PictureSectionItem.startEdgePadding])
                
                let endPaddingModel = AnimatableSectionModel(model: PictureSectionItem.endEdgePadding.identity, items: [PictureSectionItem.endEdgePadding])
                
                return [startPaddingModel] + dataItems + [model] + [endPaddingModel]
            }
            .bind(to: imageCollectionView.rx.items(dataSource: self.pictureDataSource))
            .disposed(by: self.disposeBag)
        
        reactor.state
            .getChange { $0.data }
            .map { $0.map { AnimatableSectionModel(model: $0.id, items: [PictureInfoSectionItem.pictureInfo(picture: $0)]) } }
            .bind(to: infoCollectionView.rx.items(dataSource: self.pictureInfoDataSource))
            .disposed(by: self.disposeBag)
        
        reactor.state
            .getChange { $0.isLoadingMainError }
            .subscribe(onNext: { (isMainError) in
                self.errorContainer.isHidden = !isMainError
            })
            .disposed(by: self.disposeBag)
        
        reactor.state
            .getChange { $0.isLoadingMain }
            .subscribe(onNext: { (isLoading) in
                if isLoading {
                    self.loadingView.startAnimating()
                    self.loadingContainer.isHidden = false
                } else {
                    self.loadingView.stopAnimating()
                    self.loadingContainer.isHidden = true
                }
            })
            .disposed(by: self.disposeBag)
        
        pictureFocusedSubject
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
            .withLatestFrom(reactor.state.map { $0.data }) { ($0, $1) }
            .filter { indexAndData in indexAndData.0.section == indexAndData.1.count - 1 }
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
            if let index = sender as? IndexPath {
                 destinationViewController.initialPictureIndex = index.section
            }
        }
    }
    
    func pictureSnapped(index: Int) {
        reactor!.state
            .asObservable()
            .take(1)
            .map { $0.data }
            .subscribe(onNext: { (data) in
//                print(data[index])
                print(index)
            })
            .disposed(by: self.disposeBag)
    }
}

extension PictureListViewController {
    func createPictureDataSource() -> RxPictureDataSource {
        return RxPictureDataSource(configureCell: { dataSource, tableView, indexPath, _ in
            switch dataSource[indexPath] {
                case let .DataItem(picture):
                    let cell = self.imageCollectionView.dequeueReusableCell(withReuseIdentifier: PictureCell.identifier, for: indexPath) as! PictureCell

                    cell.picture.heroID = picture.id
                    
                    if let url = picture.pictureURL {
                        cell.picture.af_setImage(withURL: url )
                    }
                    
                    cell.picture.rx
                        .tapGesture()
                        .when(.recognized)
                        .subscribe(onNext: { _ in self.performSegue(withIdentifier: PictureDetailViewController.sequeIdentifier, sender: indexPath) })
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
            switch dataSource[indexPath] {
                case .DataItem(_):
                    return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: PictureReusableView.identifier, for: indexPath) as! PictureReusableView
                case .FooterItem(_, _):
                    return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: LoadingMoreReusableView.identifier, for: indexPath) as! LoadingMoreReusableView
                case .startEdgePadding:
                    return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: LoadingMoreReusableView.identifier, for: indexPath) as! LoadingMoreReusableView
                case .endEdgePadding:
                    return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: LoadingMoreReusableView.identifier, for: indexPath) as! LoadingMoreReusableView
            }
        })
    }
}

extension PictureListViewController {
    func createPictureInfoDataSource() -> RxPictureInfoDataSource {
        return RxPictureInfoDataSource(configureCell: { dataSource, tableView, indexPath, _ in
            switch dataSource[indexPath] {
                case let .pictureInfo(picture):
                    let cell = self.infoCollectionView.dequeueReusableCell(withReuseIdentifier: PictureInfoCell.identifier, for: indexPath) as! PictureInfoCell
                    
                    cell.title.text = picture.title.value
                    
                    return cell
            }
        }, configureSupplementaryView: { (dataSource, collectionView, kind, indexPath) in
            return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: PictureReusableView.identifier, for: indexPath) as! PictureReusableView
        })
    }
}

extension PictureListViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == imageCollectionView {
            if indexPath.section == 0 {
                return CGSize(width: 150, height: collectionView.frame.height)
            }
            return CGSize(width: 300, height: collectionView.frame.height)
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
            collectionViewResizer.resizeCenteredItems(in: imageCollectionView)
            if scrollSpeedEvaluator.isScrollingSlowly(scrollView) {
                let focusedItemSection = snapHelper.getFocusedItemSection(imageCollectionView)
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
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == imageCollectionView {
            snapHelper.snap(imageCollectionView)
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView == imageCollectionView {
            if !decelerate {
                snapHelper.snap(imageCollectionView)
            }
        }
    }
}


