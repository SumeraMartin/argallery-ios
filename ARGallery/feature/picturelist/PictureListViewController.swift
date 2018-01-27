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
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        refresher = UIRefreshControl()
        refresher.tintColor = UIColor.blue
        
        rxDataSource = dataSource()
        
        imageCollectionView.delegate = self
        imageCollectionView.decelerationRate = UIScrollViewDecelerationRateFast
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
                return dataItems + [model]
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
            }
        }, configureSupplementaryView: { (dataSource, collectionView, kind, indexPath) in
            switch dataSource[indexPath] {
                case .DataItem(_):
                    return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: PictureReusableView.identifier, for: indexPath) as! PictureReusableView
                case .FooterItem(_, _):
                    return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: LoadingMoreReusableView.identifier, for: indexPath) as! LoadingMoreReusableView
            }
        })
    }
}

extension PictureListViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 300, height: collectionView.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

extension PictureListViewController: UIScrollViewDelegate {
    
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
        if closestCellIndex != -1 {
            self.imageCollectionView.scrollToItem(at: IndexPath(row: 0, section: closestCellIndex), at: .centeredHorizontally, animated: true)
            pictureSnapped(index: closestCellIndex)
        }
    }
}


