import Foundation
import CoreData
import FirebaseFirestore

struct Term: Identifiable, Hashable {
    let id: UUID
    var title: String
    var details: String
    var date: Date
    var reminderDate: Date?
    var location: TermLocation?
    var createdAt: Date
    var updatedAt: Date
    var createdBy: String
    var participantIds: [String]
    var status: TermStatus

    init(from entity: TermEntity) {
        self.id = entity.id ?? UUID()
        self.title = entity.title ?? ""
        self.details = entity.details ?? ""
        self.date = entity.date ?? Date()
        self.reminderDate = entity.reminderDate
        self.location = nil
        self.createdAt = Date()
        self.updatedAt = Date()
        self.createdBy = ""
        self.participantIds = []
        self.status = .active
    }

    init(
        id: UUID = UUID(),
        title: String,
        details: String,
        date: Date,
        reminderDate: Date? = nil,
        location: TermLocation? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        createdBy: String = "",
        participantIds: [String] = [],
        status: TermStatus = .active
    ) {
        self.id = id
        self.title = title
        self.details = details
        self.date = date
        self.reminderDate = reminderDate
        self.location = location
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.createdBy = createdBy
        self.participantIds = participantIds
        self.status = status
    }
}

enum TermStatus: String, Hashable {
    case active
    case archived
    case deleted
}

struct TermLocation: Hashable {
    var latitude: Double
    var longitude: Double
    var title: String?
    var address: String?

    var geoPoint: GeoPoint {
        GeoPoint(latitude: latitude, longitude: longitude)
    }

    init(latitude: Double, longitude: Double, title: String? = nil, address: String? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.title = title
        self.address = address
    }

    init(geoPoint: GeoPoint, title: String? = nil, address: String? = nil) {
        self.latitude = geoPoint.latitude
        self.longitude = geoPoint.longitude
        self.title = title
        self.address = address
    }
}
