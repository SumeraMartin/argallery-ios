import UIKit
import RxSwift

class PictureDetailCell: BaseCollectionViewCell {
    
    static let identifier = "picture_detail_cell"
    
    @IBOutlet weak var pictureScrollViewContainer: UIScrollView!
    
    @IBOutlet weak var pictureView: UIImageView!
    @IBOutlet weak var popularView: UIImageView!
    var dTapGR: UITapGestureRecognizer!
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
        
        dTapGR = UITapGestureRecognizer(target: self, action: #selector(doubleTap(gr:)))
        dTapGR.numberOfTapsRequired = 2
        addGestureRecognizer(dTapGR)
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

extension PictureDetailCell: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return pictureView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerIfNeeded()
    }
}
