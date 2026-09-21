//
//  TermModelTests.swift
//  TeroroUnitTests
//
//  Created by Chmil Oleksandr on 21.09.26.
//

import Foundation
import Testing
import FirebaseFirestore
@testable import Teroro

struct TermModelTests {

    @Test("Term initializes with correct default values")
    func termDefaultInitialization() {
        let termId = UUID()
        let targetDate = Date().addingTimeInterval(3600)

        let term = Term(
            id: termId,
            title: "Submit project",
            details: "Final code review",
            date: targetDate
        )

        #expect(term.id == termId)
        #expect(term.title == "Submit project")
        #expect(term.details == "Final code review")
        #expect(term.date == targetDate)
        #expect(term.reminderDate == nil)
        #expect(term.location == nil)
        #expect(term.status == .active)
        #expect(term.participantIds.isEmpty)
        #expect(term.createdBy.isEmpty)
    }

    @Test("Term initializes correctly with a full configuration")
    func termFullInitialization() {
        let termId = UUID()
        let targetDate = Date().addingTimeInterval(86400)
        let reminderDate = Date().addingTimeInterval(43200)
        let location = TermLocation(latitude: 50.4501, longitude: 30.5234, title: "Kyiv", address: "Khreshchatyk")
        let createdAt = Date().addingTimeInterval(-1000)
        let updatedAt = Date().addingTimeInterval(-500)

        let term = Term(
            id: termId,
            title: "Meeting",
            details: "Release discussion",
            date: targetDate,
            reminderDate: reminderDate,
            location: location,
            createdAt: createdAt,
            updatedAt: updatedAt,
            createdBy: "user123",
            participantIds: ["user123", "user456"],
            status: .archived
        )

        #expect(term.id == termId)
        #expect(term.title == "Meeting")
        #expect(term.details == "Release discussion")
        #expect(term.date == targetDate)
        #expect(term.reminderDate == reminderDate)
        #expect(term.location?.latitude == 50.4501)
        #expect(term.location?.longitude == 30.5234)
        #expect(term.location?.title == "Kyiv")
        #expect(term.location?.address == "Khreshchatyk")
        #expect(term.createdBy == "user123")
        #expect(term.participantIds.count == 2)
        #expect(term.status == .archived)
    }

    @Test("TermLocation converts correctly between coordinates and GeoPoint")
    func termLocationGeoPointConversion() {
        let location = TermLocation(latitude: 48.9226, longitude: 24.7111, title: "Ivano-Frankivsk", address: "Shevchenko Ave")

        #expect(location.latitude == 48.9226)
        #expect(location.longitude == 24.7111)
        #expect(location.geoPoint.latitude == 48.9226)
        #expect(location.geoPoint.longitude == 24.7111)

        let geoPoint = GeoPoint(latitude: 49.8397, longitude: 24.0297)
        let locationFromGeo = TermLocation(geoPoint: geoPoint, title: "Lviv", address: "Rynok Square")

        #expect(locationFromGeo.latitude == 49.8397)
        #expect(locationFromGeo.longitude == 24.0297)
        #expect(locationFromGeo.title == "Lviv")
        #expect(locationFromGeo.address == "Rynok Square")
    }

    @Test("TermStatus raw values match expected strings")
    func termStatusRawValues() {
        #expect(TermStatus.active.rawValue == "active")
        #expect(TermStatus.archived.rawValue == "archived")
        #expect(TermStatus.deleted.rawValue == "deleted")
    }
}
