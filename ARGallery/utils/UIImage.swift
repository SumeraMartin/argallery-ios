import UIKit
import Alamofire

func loadImage(fromUrl imageUrl: String, handler: @escaping (UIImage?) -> Void) {
    let url = URL(string: imageUrl)!
    UIImageView().af_setImage(withURL: url) { response in
        if let image = response.result.value {
            handler(image)
        }
    }
}

