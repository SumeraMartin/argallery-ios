import UIKit
import Alamofire

func loadImage(fromUrl url:String, handler: @escaping (UIImage?) -> Void) {
    Alamofire.request(url, method: .get).responseImage { response in
        if let data = response.result.value {
            handler(data)
        } else {
            handler(nil)
        }
    }
}

