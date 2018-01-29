extension PopularPicture {

    func toPicture() -> Picture {
        return Picture(
            id: id,
            title: title,
            author: author,
            pictureUrl: pictureUrl,
            description: description,
            price: price
        )
    }
    
    static func from(picture: Picture) -> PopularPicture {
        let popular = PopularPicture()
        popular.id = picture.id
        popular.title = picture.title
        popular.author = picture.author
        popular.pictureUrl = picture.pictureUrl
        popular.pictureDescription = picture.description
        popular.price = picture.price
        return popular
    }
}

