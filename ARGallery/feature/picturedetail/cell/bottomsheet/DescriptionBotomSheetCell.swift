import UIKit
import RxSwift

class DescriptionBottomSheetCell: BaseTableViewCell {
    
    static let identifier = "bottom_sheet_description_cell"

    @IBOutlet weak var descriptionText: UILabel!
    
    func bind(_ picture: Picture) {
        descriptionText.text = "Lorem ipsum dolor sit amet. Cras tincidunt lobortis feugiat vivamus at augue eget. Eu lobortis elementum nibh tellus molestie nunc non blandit massa. Et pharetra pharetra massa massa ultricies mi quis hendrerit. Varius sit amet mattis vulputate enim. Nisi lacus sed viverra tellus in hac habitasse platea. Facilisis sed odio morbi quis commodo odio. Condimentum mattis pellentesque id nibh. Cursus risus at ultrices mi tempus. Id interdum velit laoreet id donec ultrices tincidunt. Amet consectetur adipiscing elit ut aliquam purus sit amet. Netus et malesuada fames ac. Tincidunt praesent semper feugiat nibh sed pulvinar. Suspendisse potenti nullam ac tortor vitae purus. Ut sem nulla pharetra diam. Bibendum neque egestas congue quisque egestas diam in arcu. Eu lobortis elementum nibh tellus molestie nunc non blandit massa. Et pharetra pharetra massa massa ultricies mi quis hendrerit. Varius sit amet mattis vulputate enim. Nisi lacus sed viverra tellus in hac habitasse platea. Facilisis sed odio morbi quis commodo odio. Condimentum mattis pellentesque id nibh. Cursus risus at ultrices mi tempus. Id interdum velit laoreet id donec ultrices tincidunt. Amet consectetur adipiscing elit ut aliquam purus sit amet. Netus et malesuada fames ac. Tincidunt praesent semper feugiat nibh sed pulvinar. Suspendisse potenti nullam ac tortor vitae purus. Ut sem nulla pharetra diam. Bibendum neque egestas congue quisque egestas diam in arcu Eu lobortis elementum nibh tellus molestie nunc non blandit massa. Et pharetra pharetra massa massa ultricies mi quis hendrerit. Varius sit amet mattis vulputate enim. Nisi lacus sed viverra tellus in hac habitasse platea. Facilisis sed odio morbi quis commodo odio. Condimentum mattis pellentesque id nibh. Cursus risus at ultrices mi tempus. Id interdum velit laoreet id donec ultrices tincidunt. Amet consectetur adipiscing elit ut aliquam purus sit amet. Netus et malesuada fames ac. Tincidunt praesent semper feugiat nibh sed pulvinar. Suspendisse potenti nullam ac tortor vitae purus. Ut sem nulla pharetra diam. Bibendum neque egestas congue quisque egestas diam in arcu"
    }
}
