import AWSDynamoDB

class HikeRecord: AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    @objc var hike_id: String?
    @objc var user_uuid: String?
    @objc var hike_name: String?
    @objc var start_time: NSNumber?
    @objc var distance: NSNumber?
    @objc var notes: String?
    @objc var location: String?

    class func dynamoDBTableName() -> String {
        return "hikes"
    }

    class func hashKeyAttribute() -> String {
        return "hike_id"
    }
}
