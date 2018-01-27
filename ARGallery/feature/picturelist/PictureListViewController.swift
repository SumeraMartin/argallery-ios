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
    
    typealias SectionType = AnimatableSectionModel<String, PictureSectionItem>
    typealias RxDataSource = RxCollectionViewSectionedAnimatedDataSource<SectionType>
    
    @IBOutlet weak var retryButton: UIButton!
    
    @IBOutlet weak var errorContainer: UIView!
    
    @IBOutlet weak var loadingView: NVActivityIndicatorView!
    
    @IBOutlet weak var imageCollectionView: UICollectionView!
    
    @IBOutlet weak var loadingContainer: UIView!
    
    @IBOutlet weak var filterIcon: UIImageView!
    
    var refresher: UIRefreshControl!
    
    var rxDataSource: RxDataSource!
    
    var lastOffset:CGPoint? = CGPoint(x: 0, y: 0)
    var lastOffsetCapture:TimeInterval? = 0
    var isScrollingFast: Bool = false
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        refresher = UIRefreshControl()
        refresher.tintColor = UIColor.blue
        
        rxDataSource = dataSource()
        
        imageCollectionView.delegate = self
//        imageCollectionView.decelerationRate = UIScrollViewDecelerationRateFast
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
            .bind(to: imageCollectionView.rx.items(dataSource: self.rxDataSource))
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
    func dataSource() -> RxDataSource {
        return RxDataSource(configureCell: { dataSource, tableView, indexPath, _ in
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

extension PictureListViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 0 {
            return CGSize(width: 150, height: collectionView.frame.height)
        }
        return CGSize(width: 300, height: collectionView.frame.height)
    }
}

extension PictureListViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let visibleCenterPositionOfScrollView = Float(imageCollectionView.contentOffset.x + (self.imageCollectionView.bounds.size.width / 2))
        var closestCellIndex = -1
        var closestDistance: Float = .greatestFiniteMagnitude
        for i in 0..<imageCollectionView.visibleCells.count {
            let cell = imageCollectionView.visibleCells[i]
            let cellWidth = cell.bounds.size.width
            let cellCenter = Float(cell.frame.origin.x + cellWidth / 2)
            
            // Now calculate closest cell
            let distance: Float = fabsf(visibleCenterPositionOfScrollView - cellCenter)
            
            let resize = CGFloat(distance) / imageCollectionView.bounds.width / 2 * 0.95
            var resizePercentage = CGFloat(0.25)
            if resize < 0.25 {
                resizePercentage = resize
            }
            
            if let pictureCell = cell as? PictureCell {
                var t = CGAffineTransform.identity
                t = t.scaledBy(x: CGFloat(1 - resizePercentage), y: CGFloat(1 - resizePercentage))
               
                pictureCell.picture.transform = t
                pictureCell.layer.shadowColor = UIColor.black.cgColor
                pictureCell.layer.shadowOpacity = Float(1 - resizePercentage * 4)
                pictureCell.layer.shadowOffset = CGSize.zero
                pictureCell.layer.shadowRadius = 5
                
            }
            
            
        }
        
        let currentOffset = scrollView.contentOffset
        let currentTime = NSDate().timeIntervalSinceReferenceDate
        let timeDiff = currentTime - lastOffsetCapture!
        let captureInterval = 0.1
        
        if(timeDiff > captureInterval) {
            
            let distance = currentOffset.x - lastOffset!.x    // calc distance
            let scrollSpeedNotAbs = (distance * 10) / 1000     // pixels per ms*10
            let scrollSpeed = fabsf(Float(scrollSpeedNotAbs))  // absolute value

            if (scrollSpeed > 0.3) {
                isScrollingFast = true
                print("Fast")
            }
            else {
                isScrollingFast = false
                print("Slow")
            }
            
            lastOffset = currentOffset
            lastOffsetCapture = currentTime
            
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollToNearestVisibleCollectionViewCell()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            scrollToNearestVisibleCollectionViewCell()
        }
    }
    
    func scrollToNearestVisibleCollectionViewCell() {
        let visibleCenterPositionOfScrollView = Float(imageCollectionView.contentOffset.x + (self.imageCollectionView.bounds.size.width / 2))
        var closestCellIndex = -1
        var closestDistance: Float = .greatestFiniteMagnitude
        for i in 0..<imageCollectionView.visibleCells.count {
            let cell = imageCollectionView.visibleCells[i]
            let cellWidth = cell.bounds.size.width
            let cellCenter = Float(cell.frame.origin.x + cellWidth / 2)
            
            // Now calculate closest cell
            let distance: Float = fabsf(visibleCenterPositionOfScrollView - cellCenter)
            if distance < closestDistance {
                closestDistance = distance
                closestCellIndex = imageCollectionView.indexPath(for: cell)!.section
            }
        }
        
//        if closestCellIndex == 0 {
//            closestCellIndex = 1
//        }
        
        if closestCellIndex != -1 {
            self.imageCollectionView.scrollToItem(at: IndexPath(row: 0, section: closestCellIndex), at: .centeredHorizontally, animated: true)
            pictureSnapped(index: closestCellIndex)
        }
    }
}


