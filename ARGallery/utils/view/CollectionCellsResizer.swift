import UIKit

class CollectionViewResizer {
    
    let resizeLimit = 1 / CGFloat(4)
    
    func resizeCenteredItems(in collectionView: UICollectionView) {
        let halfCollectionWidth = collectionView.bounds.size.width / 2
        let visibleCenterPositionOfScrollView = Float(collectionView.contentOffset.x + halfCollectionWidth)
        for cell in collectionView.visibleCells {
            let cellWidth = cell.bounds.size.width
            let cellCenter = Float(cell.frame.origin.x + cellWidth / 2)
            let distance = fabsf(visibleCenterPositionOfScrollView - cellCenter)
            let resize = CGFloat(distance) / collectionView.bounds.width / 2 * 0.95
            var resizePercentage = Float(resizeLimit)
            if resize < resizeLimit {
                resizePercentage = Float(resize)
            }
        
            if let transformableCell = cell as? TransformableCell {
                transformableCell.applyTransform(resizePercentage: resizePercentage)
            }
        }
    }
}

protocol TransformableCell {
    
    func applyTransform(resizePercentage: Float)
}
