import UIKit

class TableViewWithTransparentHeader: UITableView {
    
    var isTransparentHeaderTouchable = false
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if !isTransparentHeaderTouchable {
            return point.y >= 0 && super.point(inside: point, with: event)
        }
        return super.point(inside: point, with: event)
    }
}
