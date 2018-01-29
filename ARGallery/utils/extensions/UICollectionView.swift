import UIKit

extension UICollectionView {    
    func getDummyReusableCell(ofKind kind: String, forIndex index: IndexPath) -> UICollectionReusableView {
        return self.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: DummyReusableView.identifier, for: index)
    }
}
