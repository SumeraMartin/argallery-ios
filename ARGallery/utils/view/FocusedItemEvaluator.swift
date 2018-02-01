import UIKit

class FocusedItemEvaluator {
    
    func snapToFocusedItem(_ collectionView: UICollectionView, withAnimation: Bool = true) {
        let sectionIndex = getFocusedItemSection(collectionView)
        if let section = sectionIndex {
            let index = IndexPath(row: 0, section: section)
            collectionView.scrollToItem(at: index, at: .centeredHorizontally, animated: withAnimation)
        }
    }
    
    func getFocusedItemSection(_ collectionView: UICollectionView) -> Int? {
        let halfWidth = collectionView.bounds.size.width / 2
        let visibleCenterPositionOfScrollView = Float(collectionView.contentOffset.x + halfWidth)
        var closestSectionIndex: Int? = nil
        var closestDistance = Float.greatestFiniteMagnitude
        for cell in collectionView.visibleCells {
            if cell is SnappableCell {
                let cellWidth = cell.bounds.size.width
                let cellCenter = Float(cell.frame.origin.x + cellWidth / 2)
                let distance: Float = fabsf(visibleCenterPositionOfScrollView - cellCenter)
                if distance < closestDistance {
                    closestDistance = distance
                    closestSectionIndex = collectionView.indexPath(for: cell)!.section
                }
            }
        }
        return closestSectionIndex
    }
}

protocol SnappableCell {
 
}
