import UIKit

class TableViewWithTransparentHeader: UITableView {
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return point.y >= 0 && super.point(inside: point, with: event)
    }
}
