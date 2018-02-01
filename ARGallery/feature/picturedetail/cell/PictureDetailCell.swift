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
    
    var blurVisualEffect = UIVisualEffectView(effect: UIBlurEffect(style: .light))
    
    var descriptionDataSource: RxTableViewSectionedReloadDataSource<BottomSheetSection>!
    
    var doubleTapGestureRecognizer: UITapGestureRecognizer!
    
    var initialBottomSheetOffset: CGPoint?
    
    var blurAnimator: UIViewPropertyAnimator?
    
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
        
        doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(doubleTap(gr:)))
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTapGestureRecognizer)
    }
    
    func bind() {
        centerIfNeeded()
        
        descriptionTableView.separatorStyle = .none
        descriptionTableView.allowsSelection = false
        
        blurVisualEffect.effect = UIBlurEffect(style: .light)
        blurVisualEffect.frame = bounds
        pictureView.addSubview(blurVisualEffect)
        
        blurAnimator = UIViewPropertyAnimator(duration: 1, curve: .linear) {
            self.blurVisualEffect.effect = nil
        }
        blurAnimator?.pauseAnimation()
        
        blurAnimator?.fractionComplete = 1
        blurAnimator?.addCompletion({ [unowned self] (_) in
            self.blurAnimator = nil
        })
        
        descriptionTableView.rowHeight = 60;
        
        descriptionDataSource = DescriptionDataSource(configureCell: { (dataSource, tableView, index, item) in
            switch dataSource[index] {
                case .title:
                    let cell = tableView.dequeueReusableCell(withIdentifier: TitleBottomSheetCell.identifier, for: index) as! TitleBottomSheetCell
                    cell.title.text = "dsa dsdsa das da dasdsa d"
                    return cell
                case .details:
                    let cell = tableView.dequeueReusableCell(withIdentifier: DetailsBottomSheetCell.identifier, for: index) as! DetailsBottomSheetCell
                    cell.year.text = "2015"
                    return cell
                case .description:
                    let cell = tableView.dequeueReusableCell(withIdentifier: DescriptionBottomSheetCell.identifier, for: index) as! DescriptionBottomSheetCell
                    cell.descriptionText.text = "Lorem ipsum dolor sit amet. Cras tincidunt lobortis feugiat vivamus at augue eget. Eu lobortis elementum nibh tellus molestie nunc non blandit massa. Et pharetra pharetra massa massa ultricies mi quis hendrerit. Varius sit amet mattis vulputate enim. Nisi lacus sed viverra tellus in hac habitasse platea. Facilisis sed odio morbi quis commodo odio. Condimentum mattis pellentesque id nibh. Cursus risus at ultrices mi tempus. Id interdum velit laoreet id donec ultrices tincidunt. Amet consectetur adipiscing elit ut aliquam purus sit amet. Netus et malesuada fames ac. Tincidunt praesent semper feugiat nibh sed pulvinar. Suspendisse potenti nullam ac tortor vitae purus. Ut sem nulla pharetra diam. Bibendum neque egestas congue quisque egestas diam in arcu."
                    return cell
            }

        })
        
        Observable.just([
            BottomSheetSection(model: "title", items: [BottomSheetSectionItem.title]),
            BottomSheetSection(model: "details", items: [BottomSheetSectionItem.details]),
            BottomSheetSection(model: "description", items: [BottomSheetSectionItem.description]),
            ])
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
    
    @objc func doubleTap(gr: UITapGestureRecognizer) {
        if pictureScrollViewContainer.zoomScale == 1 {
            print(pictureScrollViewContainer.maximumZoomScale)
            pictureScrollViewContainer.zoom(to: zoomRectForScale(scale: pictureScrollViewContainer.maximumZoomScale, center: gr.location(in: gr.view)), animated: true)
        } else {
            pictureScrollViewContainer.setZoomScale(1, animated: true)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        descriptionTableView.contentInset = UIEdgeInsets(top: self.bounds.size.height - descriptionTableView.rowHeight, left: 0, bottom: 0, right: 0)
        descriptionTableView.contentOffset = CGPoint(x: 0, y: -descriptionTableView.contentInset.top)
        
        initialBottomSheetOffset = CGPoint(x: 0, y: -descriptionTableView.contentInset.top)
        
        pictureScrollViewContainer.frame = bounds
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
        centerIfNeeded()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        pictureScrollViewContainer.setZoomScale(1, animated: false)
        blurAnimator?.stopAnimation(true)
        blurVisualEffect.removeFromSuperview()
        initialBottomSheetOffset = nil
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
}

extension PictureDetailCell: UIScrollViewDelegate, UITableViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == pictureScrollViewContainer {
            return
        }
        
        if scrollView == descriptionTableView {

            if let offset = initialBottomSheetOffset {
                let value = CGFloat((scrollView.contentOffset.y / (offset.y / 100)) / 100)
                blurAnimator?.fractionComplete = value
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
        if indexPath.section == 0 || indexPath.section == 1 {
            return 100 // the height you want
        } else {
            return UITableViewAutomaticDimension
        }
    }
}
