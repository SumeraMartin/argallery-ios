extension CloudPicture  {
   
    func toPicture() -> Picture {
        return Picture(
            id: id,
            title: title,
            author: author,
            pictureUrl: pictureUrl,
            description: description,
            price: price,
            year: year
        )
    }
}
