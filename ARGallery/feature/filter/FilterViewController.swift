import UIKit
import Hero
import RxSwift
import RxGesture
import ReactorKit
import TTRangeSlider

class FilterViewController: BaseViewController, ReactorKit.View  {
    
    static let sequeIdentifier = "show_filter_seque"
    
    let priceFilterSubject = PublishSubject<PriceRange>()
    
    @IBOutlet weak var priceFilter: TTRangeSlider!
    
    @IBOutlet weak var closeButton: UIBarButtonItem!
    
    @IBOutlet weak var resetButton: UIBarButtonItem!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let coverDown: HeroDefaultAnimationType = .cover(direction: .down)
        let coverUp: HeroDefaultAnimationType = .uncover(direction: .up)
        heroModalAnimationType = .selectBy(presenting: coverDown, dismissing: coverUp)
        
        priceFilter.delegate = self
        
        reactor = assembler.reactorProvider.createFilterReactor()
    }
    
    func bind(reactor: FilterReactor) {
        priceFilterSubject
            .debounce(RxTimeInterval(0.2), scheduler: MainScheduler.instance)
            .map { .priceRangeChanged(minPrice: $0.minPrice, maxPrice: $0.maxPrice) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        closeButton.rx.tap
            .subscribe(onNext: { self.dismiss(animated: true, completion: nil) })
            .disposed(by: disposeBag)
        
        resetButton.rx.tap
            .map { .reset }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        reactor.state
            .take(1)
            .subscribe(onNext: { state in
                self.priceFilter.minValue = Float(state.defaultFilter.minPrice)
                self.priceFilter.maxValue = Float(state.defaultFilter.maxPrice)
            })
            .disposed(by: disposeBag)
        
        reactor.state
            .getChange { state in state.currentFilter }
            .subscribe(onNext: { filter in
                if self.priceFilter.selectedMinimum != Float(filter.minPrice) {
                    self.priceFilter.selectedMinimum = Float(filter.minPrice)
                }
                if self.priceFilter.selectedMaximum != Float(filter.maxPrice) {
                    self.priceFilter.selectedMaximum = Float(filter.maxPrice)
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
    
    func rangeSlider(_ sender: TTRangeSlider!, didChangeSelectedMinimumValue selectedMinimum: Float, andMaximumValue selectedMaximum: Float) {
        let price = PriceRange(minPrice: Int(selectedMinimum), maxPrice: Int(selectedMaximum))
        priceFilterSubject.on(.next(price))
    }
    
}
