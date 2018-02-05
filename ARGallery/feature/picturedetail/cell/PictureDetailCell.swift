import UIKit
import RxSwift
import RxDataSources

class PictureDetailCell: BaseCollectionViewCell {
    
    typealias BottomSheetSection = SectionModel<String, BottomSheetSectionItem>
    
    typealias DescriptionDataSource = RxTableViewSectionedReloadDataSource<BottomSheetSection>
    
    static let identifier = "picture_detail_cell"
    
    @IBOutlet weak var pictureScrollViewContainer: UIScrollView!
    
    @IBOutlet weak var descriptionTableView: UITableView!
    
    @IBOutlet weak var pictureView: UIImageView!
    
    @IBOutlet weak var popularView: UIImageView!
    
    let descriptionTitleHeight = CGFloat(80)
    
    var delegate: PictureDetailCellDelegate?
    
    var blurVisualEffect = UIVisualEffectView(effect: UIBlurEffect(style: .light))
    
    var descriptionDataSource: RxTableViewSectionedReloadDataSource<BottomSheetSection>!
    
    var doubleTapGestureRecognizer: UITapGestureRecognizer!
    
    var initialBottomSheetOffset: CGPoint?
    
    var blurAnimator: UIViewPropertyAnimator?
    
    var isDescriptionShown = false
    
    var image: UIImage? {
        get { return pictureView.image }
        set {
            pictureView.image = newValue
            setNeedsLayout()
        }
    }
    
    var topInset: CGFloat = 0 {
        didSet {
            centerIfNeeded()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        let selector = #selector(doubleTap(gestureRecognizer:))
        doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: selector)
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTapGestureRecognizer)
    }
    
    func bind(_ picture: Picture) {
        pictureView.heroID = picture.id
        if let url = picture.url {
            pictureView.af_setImage(withURL: url)
            setNeedsLayout()
        }
        
        pictureView.bounds = bounds
        pictureScrollViewContainer.bounds = bounds
        
        descriptionTableView.delegate = self
        
        pictureView.contentMode = .scaleAspectFill
        pictureScrollViewContainer.delegate = self
        pictureScrollViewContainer.maximumZoomScale = 3
        pictureScrollViewContainer.contentMode = .center
        pictureScrollViewContainer.showsHorizontalScrollIndicator = false
        pictureScrollViewContainer.showsVerticalScrollIndicator = false
        
        descriptionTableView.separatorStyle = .none
        descriptionTableView.allowsSelection = false
        descriptionTableView.bounces = false
        
        blurVisualEffect.effect = UIBlurEffect(style: .dark)
        blurVisualEffect.isHidden = true
        pictureView.addSubview(blurVisualEffect)
        
        descriptionTableView.rowHeight = 60;
        
        isDescriptionShown = false
        
        descriptionDataSource = createDescriptionDataSource(forPicture: picture)
        
        let descriptionModels = [
            BottomSheetSection(model: "title", items: [BottomSheetSectionItem.title]),
            BottomSheetSection(model: "details", items: [BottomSheetSectionItem.details]),
            BottomSheetSection(model: "description", items: [BottomSheetSectionItem.description]),
        ]
    
        Observable.just(descriptionModels)
            .bind(to: descriptionTableView.rx.items(dataSource: descriptionDataSource))
            .disposed(by: self.disposeBagCell)
    }
    
    func bindWithPopularObservable(isPopular: Observable<Bool>) {
        isPopular
            .subscribe(onNext: { isPopular in
                if isPopular {
                    self.popularView.backgroundColor = UIColor.green
                } else {
                    self.popularView.backgroundColor = UIColor.red
                }
            })
            .disposed(by: disposeBagCell)
    }
    
    func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.height = pictureView.frame.size.height / scale
        zoomRect.size.width  = pictureView.frame.size.width  / scale
        let newCenter = pictureView.convert(center, from: pictureScrollViewContainer)
        zoomRect.origin.x = newCenter.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = newCenter.y - (zoomRect.size.height / 2.0)
        return zoomRect
    }
    
    @objc func doubleTap(gestureRecognizer: UITapGestureRecognizer) {
        if pictureScrollViewContainer.zoomScale == 1 {
            setZoomedState(gestureRecognizer)
        } else {
            setNormalZoomState(gestureRecognizer)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        descriptionTableView.contentInset = UIEdgeInsets(top: self.bounds.size.height - descriptionTitleHeight, left: 0, bottom: 0, right: 0)
        descriptionTableView.contentOffset = CGPoint(x: 0, y: -descriptionTableView.contentInset.top)
        
        initialBottomSheetOffset = CGPoint(x: 0, y: -descriptionTableView.contentInset.top)
        
        pictureScrollViewContainer.frame = bounds
        
        blurVisualEffect.frame = CGRect(origin: .zero, size: CGSize(width: bounds.width, height: bounds.width))
        blurVisualEffect.bounds = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
        
        let size: CGSize
        if let image = pictureView.image {
            let containerSize = CGSize(width: bounds.width, height: bounds.height - topInset)
            if containerSize.width / containerSize.height < image.size.width / image.size.height {
                size = CGSize(width: containerSize.width, height: containerSize.width * image.size.height / image.size.width )
            } else {
                size = CGSize(width: containerSize.height * image.size.width / image.size.height, height: containerSize.height )
            }
        } else {
            size = CGSize(width: bounds.width, height: bounds.width)
        }
        pictureView.frame = CGRect(origin: .zero, size: size)
        pictureScrollViewContainer.contentSize = size
        
        layoutIfNeeded()
        centerIfNeeded()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        pictureScrollViewContainer.setZoomScale(1, animated: false)
        blurAnimator?.stopAnimation(true)
        blurAnimator = nil
        blurVisualEffect.removeFromSuperview()
        initialBottomSheetOffset = nil
        descriptionTableView.isHidden = false
        descriptionTableView.alpha = 1
        popularView.isHidden = false
        popularView.alpha = 1
    }
    
    func centerIfNeeded() {
        var inset = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
        if pictureScrollViewContainer.contentSize.height < pictureScrollViewContainer.bounds.height - topInset {
            let insetV = (pictureScrollViewContainer.bounds.height - topInset - pictureScrollViewContainer.contentSize.height)/2
            inset.top += insetV
            inset.bottom = insetV
        }
        if pictureScrollViewContainer.contentSize.width < pictureScrollViewContainer.bounds.width {
            let insetV = (pictureScrollViewContainer.bounds.width - pictureScrollViewContainer.contentSize.width)/2
            inset.left = insetV
            inset.right = insetV
        }
        pictureScrollViewContainer.contentInset = inset
    }
    
    func setDescriptionScrollProgress(value: CGFloat) {
        if blurAnimator == nil && value < 1 {
            blurAnimator = UIViewPropertyAnimator(duration: 1, curve: .linear) {
                self.blurVisualEffect.effect = nil
            }
            blurAnimator?.fractionComplete = 1
            blurAnimator?.addCompletion({ [unowned self] (_) in
                self.blurAnimator = nil
            })
        }
        
        blurAnimator?.fractionComplete = value
    }
    
    func setDescriptionShownState() {
        delegate?.descriptionIsShown()
        
        blurVisualEffect.isHidden = false
        
        hideViewWithAnimation(popularView)
    }
    
    func setDescriptionHiddenState() {
        delegate?.descriptionIsHidden()
        
        blurVisualEffect.isHidden = true
        
        showViewWithAnimation(popularView)
    }
    
    private func setNormalZoomState(_ gestureRecognizer: UITapGestureRecognizer) {
        delegate?.pictureIsUnzoomed()
        
        pictureScrollViewContainer.setZoomScale(1, animated: true)
        
        showViewWithAnimation(descriptionTableView)
        showViewWithAnimation(popularView)
    }
    
    private func setZoomedState(_ gestureRecognizer: UITapGestureRecognizer) {
         delegate?.pictureIsZoomed()
        
        let maxZoomScale = pictureScrollViewContainer.maximumZoomScale
        let center = gestureRecognizer.location(in: gestureRecognizer.view)
        let zoom = zoomRectForScale(scale: maxZoomScale, center: center)
        pictureScrollViewContainer.zoom(to: zoom, animated: true)
        
        hideViewWithAnimation(descriptionTableView)
        hideViewWithAnimation(popularView)
    }
    
    private func showViewWithAnimation(_ view: UIView) {
        view.isHidden = false
        view.layer.removeAllAnimations()
        UIView.animate(withDuration: 0.5, delay: 0, options: [], animations: {
            view.alpha = 1
        })
    }
    
    private func hideViewWithAnimation(_ view: UIView) {
        view.layer.removeAllAnimations()
        UIView.animate(withDuration: 0.5, delay: 0, options: [], animations: {
            view.alpha = 0
        }, completion: { _ in
            view.isHidden = true
        })
    }
}

extension PictureDetailCell {
    func createDescriptionDataSource(forPicture picture: Picture) -> DescriptionDataSource {
        return DescriptionDataSource(configureCell: { (dataSource, tableView, index, item) in
            switch dataSource[index] {
            case .title:
                let cell = tableView.dequeueReusableCell(withIdentifier: TitleBottomSheetCell.identifier, for: index) as! TitleBottomSheetCell
                cell.bind(picture)
                return cell
            case .details:
                let cell = tableView.dequeueReusableCell(withIdentifier: DetailsBottomSheetCell.identifier, for: index) as! DetailsBottomSheetCell
                cell.bind(picture)
                return cell
            case .description:
                let cell = tableView.dequeueReusableCell(withIdentifier: DescriptionBottomSheetCell.identifier, for: index) as! DescriptionBottomSheetCell
                cell.bind(picture)
                return cell
            }
        })
    }
}

extension PictureDetailCell: UIScrollViewDelegate, UITableViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == pictureScrollViewContainer {
            return
        }
        
        if scrollView == descriptionTableView {
            if let offset = initialBottomSheetOffset {
                let value = CGFloat((scrollView.contentOffset.y / (offset.y / 100)) / 100)
                
                if value <= 1 {
                    setDescriptionScrollProgress(value: value)
                }
                
                if value >= 0.95 {
                    if isDescriptionShown == true {
                        isDescriptionShown = false
                        setDescriptionHiddenState()
                    }
                }
                
                if value < 0.95 {
                    if isDescriptionShown == false {
                        isDescriptionShown = true
                        setDescriptionShownState()
                    }
                }
            }
            return
        }
        
        fatalError("Unknown scroll view")
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        if scrollView == pictureScrollViewContainer {
            return pictureView
        }
        return nil
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        if scrollView == pictureScrollViewContainer {
            centerIfNeeded()
            return
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return descriptionTitleHeight
        } else if indexPath.section == 1 {
            return UITableViewAutomaticDimension
        } else {
            return UITableViewAutomaticDimension
        }
    }
}

protocol PictureDetailCellDelegate {
    
    func descriptionIsShown()
    
    func descriptionIsHidden()
    
    func pictureIsZoomed()
    
    func pictureIsUnzoomed()
}
