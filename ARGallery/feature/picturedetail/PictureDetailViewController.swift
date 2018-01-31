import UIKit
import Hero
import RxSwift
import ReactorKit
import RxDataSources

class PictureDetailViewController: BaseViewController, ReactorKit.View  {
    
    typealias Section = AnimatableSectionModel<String, PictureDetailSectionItem>
    
    static let sequeIdentifier = "show_picture_detail_seque"
    
    @IBOutlet weak var picturesCollectionView: UICollectionView!
    
    @IBOutlet weak var backButton: UIImageView!
    
    @IBOutlet weak var popularView: UIImageView!
    var panGestureRecognizer = UIPanGestureRecognizer()
    
    var rxDataSource: RxCollectionViewSectionedAnimatedDataSource<Section>!
    
    var initialPicture: Picture!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        rxDataSource = createDataSource()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        picturesCollectionView.delegate = self
        
        panGestureRecognizer.addTarget(self, action: #selector(pan))
        panGestureRecognizer.delegate = self
        picturesCollectionView.addGestureRecognizer(panGestureRecognizer)
        
        reactor = assembler.reactorProvider.createPictureDetailReactor(initialPicture: initialPicture)
    }
    
    func bind(reactor: PictureDetailReactor) {
        reactor.state
            .getChange { $0.pictures }
            .map { $0.map { PictureDetailSectionItem.pictureDetail(picture: $0) } }
            .map { [Section(model: "First section", items: $0)] }
            .bind(to: self.picturesCollectionView.rx.items(dataSource: self.rxDataSource))
            .disposed(by: disposeBag)
        
        let initialIndexObservable = reactor.state
            .getChange { state -> Int in state.initialPictureIndex }
        
        let willDisplayCellObservable = picturesCollectionView.rx.willDisplayCell
        
        Observable.zip(initialIndexObservable, willDisplayCellObservable) { index, event in index }
            .subscribe(onNext: { (index) in
                let indexPath = IndexPath(row: index, section: 0)
                self.picturesCollectionView.scrollToItem(at: indexPath, at: .right, animated: false)
            })
            .disposed(by: disposeBag)
    
        picturesCollectionView.rx.didScroll
            .map { _ -> Int in
                let scrollView = self.picturesCollectionView!
                let centerX = scrollView.contentOffset.x + (scrollView.frame.width / 2)
                let centerY = scrollView.frame.height / 2
                let centerPoint = CGPoint(x: centerX, y: centerY)
                print(centerPoint)
                let index = self.picturesCollectionView.indexPathForItem(at: centerPoint)
                return index?.row ?? -1
            }
            .filter { $0 != -1 }
            .withLatestFrom(reactor.state.map { $0.pictures }) { index, picture in picture[index] }
            .map { PictureDetailReactor.Action.focusedItemChanged(picture: $0) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        backButton.rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { _ in
                self.dismiss(animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
        
        rx.viewWillAppear
            .take(1)
            .map { _ in PictureDetailReactor.Action.initialize }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
    }
}

extension PictureDetailViewController {
    func createDataSource() -> RxCollectionViewSectionedAnimatedDataSource<Section> {
        return RxCollectionViewSectionedAnimatedDataSource<Section>(configureCell: { (dataSource, collectionView, indexPath, sectionItem) in
            switch sectionItem {
                case let .pictureDetail(picture):
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PictureDetailCell.identifier, for: indexPath) as! PictureDetailCell
                    cell.pictureView.heroID = picture.id
                    if let url = picture.url {
                        cell.pictureView.af_setImage(withURL: url)
                    }
                    
                    cell.pictureView.bounds = cell.bounds
                    cell.pictureScrollViewContainer.bounds = cell.bounds
                    
                    cell.descriptionTableView.delegate = cell
                    cell.bind()
                    
                    cell.pictureView.contentMode = .scaleAspectFill
                    cell.pictureScrollViewContainer.delegate = cell
                    cell.pictureScrollViewContainer.maximumZoomScale = 3
                    cell.pictureScrollViewContainer.contentMode = .center
                    cell.pictureScrollViewContainer.showsHorizontalScrollIndicator = false
                    cell.pictureScrollViewContainer.showsVerticalScrollIndicator = false
                    
                    cell.popularView.rx.tapGesture()
                        .when(.recognized)
                        .map { _ in PictureDetailReactor.Action.popularItemChanged(picture: picture) }
                        .bind(to: self.reactor!.action)
                        .disposed(by: cell.disposeBagCell)
                    
                    let isPopularObservable = self.reactor!.state
                        .getChange { $0.popularPictures }
                        .map { popularPictures in popularPictures.contains(picture) }
                    
                    cell.bindWithPopularObservable(isPopular: isPopularObservable)
                    
                    return cell
            }
        }, configureSupplementaryView: { (dataSource, collectionView, kind, indexPath) in
            return collectionView.getDummyReusableCell(ofKind: kind, forIndex: indexPath)
        })
    }
    
    @objc func pan() {
        let translation = panGestureRecognizer.translation(in: nil)
        let progress = translation.y / 2 / picturesCollectionView.bounds.height
        switch panGestureRecognizer.state {
            case .began:
                hero_dismissViewController()
            case .changed:
                Hero.shared.update(progress)
                if let cell = picturesCollectionView.visibleCells[0]  as? PictureDetailCell {
                    let currentPos = CGPoint(x: translation.x + view.center.x, y: translation.y + view.center.y)
                    Hero.shared.apply(modifiers: [.position(currentPos)], to: cell.pictureView)
                }
            default:
                if progress + panGestureRecognizer.velocity(in: nil).y / picturesCollectionView.bounds.height > 0.3 {
                    Hero.shared.finish()
                } else {
                    Hero.shared.cancel()
                }
            }
    }
}

extension PictureDetailViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return view.frame.size
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

extension PictureDetailViewController: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let cell = picturesCollectionView.visibleCells[0] as? PictureDetailCell,
            cell.pictureScrollViewContainer.zoomScale == 1 {
            let v = panGestureRecognizer.velocity(in: nil)
            return v.y > abs(v.x)
        }
        return false
    }
}
