import UIKit
import Hero
import RxSwift
import RxGesture
import ReactorKit
import TTRangeSlider
import BEMCheckBox

class FilterViewController: BaseViewController, ReactorKit.View  {
    
    static let sequeIdentifier = "show_filter_seque"
    
    let fontSize = CGFloat(16.0)
    
    let priceRangeSubject = PublishSubject<PriceRange>()
    
    let yearRangeSubject = PublishSubject<YearRange>()

    @IBOutlet weak var priceRange: TTRangeSlider!
    
    @IBOutlet weak var yearRange: TTRangeSlider!
    
    @IBOutlet weak var firstCategoryContainer: UIStackView!
    
    @IBOutlet weak var firstCategoryCheckbox: BEMCheckBox!
    
    @IBOutlet weak var secondCategoryCheckbox: BEMCheckBox!
    
    @IBOutlet weak var secondCategoryContainer: UIStackView!
    
    @IBOutlet weak var closeButton: UIBarButtonItem!
    
    @IBOutlet weak var resetButton: UIBarButtonItem!
    
    var panGestureRecognizer = UIPanGestureRecognizer()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let coverDown: HeroDefaultAnimationType = .cover(direction: .down)
        let coverUp: HeroDefaultAnimationType = .uncover(direction: .up)
        heroModalAnimationType = .selectBy(presenting: coverDown, dismissing: coverUp)
        
        panGestureRecognizer.addTarget(self, action: #selector(pan))
        panGestureRecognizer.delegate = self
        self.view.addGestureRecognizer(panGestureRecognizer)
        
        priceRange.delegate = self
        yearRange.delegate = self
        
        let currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .currency
        currencyFormatter.currencyCode = "EUR"
        currencyFormatter.currencySymbol = "€"
        currencyFormatter.maximumFractionDigits = 0
        priceRange.numberFormatterOverride = currencyFormatter
        priceRange.step = 25
        priceRange.enableStep = true
        priceRange.maxLabelFont = priceRange.maxLabelFont.withSize(fontSize)
        priceRange.minLabelFont = priceRange.minLabelFont.withSize(fontSize)
        
        let yearFormatter = NumberFormatter()
        yearFormatter.usesGroupingSeparator = false
        yearRange.numberFormatterOverride = yearFormatter
        yearRange.maxLabelFont = yearRange.maxLabelFont.withSize(fontSize)
        yearRange.minLabelFont = yearRange.minLabelFont.withSize(fontSize)
        
        reactor = assembler.reactorProvider.createFilterReactor()
    }
    
    func bind(reactor: FilterReactor) {
        // Price range changed
        priceRangeSubject
            .debounce(RxTimeInterval(0.2), scheduler: MainScheduler.instance)
            .map { .priceRangeChanged(minPrice: $0.minPrice, maxPrice: $0.maxPrice) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        // Year range changed
        yearRangeSubject
            .debounce(RxTimeInterval(0.2), scheduler: MainScheduler.instance)
            .map { .yearRangeChanged(minYear: $0.minYear, maxYear: $0.maxYear) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        // Close button was clicked
        closeButton.rx.tap
            .subscribe(onNext: { self.dismiss(animated: true, completion: nil) })
            .disposed(by: disposeBag)
        
        // Reset button was clicked
        resetButton.rx.tap
            .map { .reset }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        // first category was changed
        firstCategoryContainer.rx.tapGesture()
            .when(.recognized)
            .map { _ in .firstCategoryChanged }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        // Second category was changed
        secondCategoryContainer.rx.tapGesture()
            .when(.recognized)
            .map { _ in .secondCategoryChanged }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        // Notify reactor about viewWillDissappear event
        self.rx.viewWillDisappear
            .map { _ in .viewWillDissappear }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        // Set ranges once
        reactor.state
            .take(1)
            .map { $0.defaultFilter }
            .subscribe(onNext: { filter in
                self.priceRange.minValue = Float(filter.minPrice)
                self.priceRange.maxValue = Float(filter.maxPrice)
                self.yearRange.minValue = Float(filter.minYear)
                self.yearRange.maxValue = Float(filter.maxYear)
            })
            .disposed(by: disposeBag)
        
        // Change filter values if it will change
        reactor.state
            .getChange { state in state.currentFilter }
            .subscribe(onNext: { filter in
                if self.priceRange.selectedMinimum != Float(filter.minPrice) {
                    self.priceRange.selectedMinimum = Float(filter.minPrice)
                }
                if self.priceRange.selectedMaximum != Float(filter.maxPrice) {
                    self.priceRange.selectedMaximum = Float(filter.maxPrice)
                }
                if self.yearRange.selectedMinimum != Float(filter.minYear) {
                    self.yearRange.selectedMinimum = Float(filter.minYear)
                }
                if self.yearRange.selectedMaximum != Float(filter.maxYear) {
                    self.yearRange.selectedMaximum = Float(filter.maxYear)
                }
                if self.firstCategoryCheckbox.on != filter.firstCategoryEnabled {
                    self.firstCategoryCheckbox.setOn(filter.firstCategoryEnabled, animated: true)
                }
                if self.secondCategoryCheckbox.on != filter.secondCategoryEnabled {
                    self.secondCategoryCheckbox.setOn(filter.secondCategoryEnabled, animated: true)
                }
            })
            .disposed(by: disposeBag)
    }
}

extension FilterViewController: TTRangeSliderDelegate {
    
    struct PriceRange {
        var minPrice: Int
        var maxPrice: Int
    }
    
    struct YearRange {
        var minYear: Int
        var maxYear: Int
    }
    
    func rangeSlider(_ sender: TTRangeSlider!, didChangeSelectedMinimumValue selectedMinimum: Float, andMaximumValue selectedMaximum: Float) {
        if sender === priceRange {
            let price = PriceRange(minPrice: Int(selectedMinimum), maxPrice: Int(selectedMaximum))
            priceRangeSubject.on(.next(price))
        }
        
        if sender === yearRange {
            let year = YearRange(minYear: Int(selectedMinimum), maxYear: Int(selectedMaximum))
            yearRangeSubject.on(.next(year))
        }
    }
}

extension FilterViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let v = panGestureRecognizer.velocity(in: nil)
        return v.y * -1 > abs(v.x) && v.y * -1 > 100
    }
    
    @objc func pan() {
        let translation = panGestureRecognizer.translation(in: nil)
        let progress = translation.y / 2 / self.view.bounds.height
        switch panGestureRecognizer.state {
            case .began:
                hero_dismissViewController()
                break
            case .changed:
                Hero.shared.update(progress)
                let currentPos = CGPoint(x: view.center.x, y: view.center.y + translation.y)
                Hero.shared.apply(modifiers: [.position(currentPos)], to: self.view)
            default:
                if progress + panGestureRecognizer.velocity(in: nil).y / self.view.bounds.height < 0.1 {
                    Hero.shared.finish()
                } else {
                    Hero.shared.cancel(animate: true)
                }
            }
    }
}
