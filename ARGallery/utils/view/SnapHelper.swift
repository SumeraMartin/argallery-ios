import UIKit

class SnapHelper {
    
    func snap(_ collectionView: UICollectionView) {
        let halfWidth = collectionView.bounds.size.width / 2
        let visibleCenterPositionOfScrollView = Float(collectionView.contentOffset.x + halfWidth)
        var closestSectionIndex = -1
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
        if closestSectionIndex != -1 {
            let index = IndexPath(row: 0, section: closestSectionIndex)
            collectionView.scrollToItem(at: index, at: .centeredHorizontally, animated: true)
        }
    }
    
    func getFocusedItemSection(_ collectionView: UICollectionView) -> Int {
        let halfWidth = collectionView.bounds.size.width / 2
        let visibleCenterPositionOfScrollView = Float(collectionView.contentOffset.x + halfWidth)
        var closestSectionIndex = -1
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
