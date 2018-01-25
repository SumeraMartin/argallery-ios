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
    typealias RxDataSource = RxTableViewSectionedAnimatedDataSource<SectionType>
    
    @IBOutlet weak var retryButton: UIButton!
    
    @IBOutlet weak var errorContainer: UIView!
    
    @IBOutlet weak var loadingView: NVActivityIndicatorView!
    
    @IBOutlet weak var loadingContainer: UIView!
    
    @IBOutlet weak var tableView: UITableView!
    
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
        
        tableView.delegate = self
        
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
            .bind(to: tableView.rx.items(dataSource: self.rxDataSource))
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

        refresher.rx.controlEvent(.valueChanged)
            .map { .refresh }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        tableView.rx
            .reachedBottom()
            .withLatestFrom(reactor.state.map { $0.isLoadMoreEnabled })
            .filter { $0 }
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
        
        if var destinationViewController = segue.destination as? PictureDetailViewController {
            if let index = sender as? IndexPath {
                 destinationViewController.initialPictureIndex = index.section
            }
        }
    }
}

extension PictureListViewController {
    func dataSource() -> RxDataSource {
        return RxDataSource(configureCell: { dataSource, tableView, indexPath, _ in
            switch dataSource[indexPath] {
                case let .DataItem(picture):
                    let cell = tableView.dequeueReusableCell(withIdentifier: PictureCell.identifier, for: indexPath) as! PictureCell
                    cell.title.text = picture.title.value
                    if cell.title.text == "" {
                        cell.title.text = "Default"
                    }
                    
                    cell.picture.heroID = picture.id
                    
                    if let url = picture.pictureURL {
                        cell.picture.af_setImage(withURL: url )
                        cell.background.af_setImage(withURL: url )
                        
                        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.dark)
                        let blurEffectView = UIVisualEffectView(effect: blurEffect)
                        blurEffectView.alpha = 1
                        blurEffectView.frame = cell.background.bounds
                        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                        cell.background.addSubview(blurEffectView)
                    }
                    
                    cell.picture.rx
                        .tapGesture()
                        .when(.recognized)
                        .subscribe(onNext: { _ in self.performSegue(withIdentifier: PictureDetailViewController.sequeIdentifier, sender: indexPath) })
                        .disposed(by: cell.disposeBagCell)
                    
                    cell.selectionStyle = UITableViewCellSelectionStyle.none
                    
                    return cell
                case let .FooterItem(isLoading, isError):
                    let cell = tableView.dequeueReusableCell(withIdentifier: LoadingCell.identifier, for: indexPath) as! LoadingCell
                    
                    if isLoading {
                        cell.setLoadingState()
                    } else if isError {
                        cell.setErrorState()
                    }
                    
                    cell.errorButton.rx.tapGesture()
                        .when(.recognized)
                        .map { _ in .loadMore }
                        .debug("TAP")
                        .bind(to: self.reactor!.action)
                        .disposed(by: cell.disposeBagCell)
                    
                    cell.selectionStyle = UITableViewCellSelectionStyle.none

                    return cell
            }
        })
    }
}

extension PictureListViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch self.rxDataSource[indexPath] {
            case .DataItem(_):
                return 300
            case .FooterItem(_, _):
                return 128
        }
    }
}



