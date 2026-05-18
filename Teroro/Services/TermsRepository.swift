import FirebaseAuth
import FirebaseFirestore
import Foundation

final class TermsRepository {
    static let shared = TermsRepository()

    private let db: Firestore
    private let auth: Auth

    init(db: Firestore = Firestore.firestore(), auth: Auth = Auth.auth()) {
        self.db = db
        self.auth = auth
    }

    func listenTerms(onChange: @escaping (Result<[Term], Error>) -> Void) -> ListenerRegistration? {
        guard let userID = auth.currentUser?.uid else {
            onChange(.success([]))
            return nil
        }

        return db.collection("terms")
            .whereField("participantIds", arrayContains: userID)
            .whereField("status", isEqualTo: TermStatus.active.rawValue)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error {
                    onChange(.failure(error))
                    return
                }

                guard let self, let documents = snapshot?.documents else {
                    onChange(.success([]))
                    return
                }

                Task {
                    do {
                        let terms = try await documents.asyncCompactMap { document in
                            try await self.term(from: document, currentUserID: userID)
                        }
                        onChange(.success(terms.sorted { $0.date < $1.date }))
                    } catch {
                        onChange(.failure(error))
                    }
                }
            }
    }

    func term(id: UUID) async throws -> Term? {
        guard let userID = auth.currentUser?.uid else {
            throw TermsRepositoryError.missingUser
        }

        let document = try await getDocument(db.collection("terms").document(id.uuidString))
        guard document.exists else { return nil }
        return try await term(from: document, currentUserID: userID)
    }

    func createTerm(title: String, details: String, date: Date, reminderDate: Date?) async throws -> UUID {
        guard let userID = auth.currentUser?.uid else {
            throw TermsRepositoryError.missingUser
        }

        let id = UUID()
        let now = Date()
        let termRef = db.collection("terms").document(id.uuidString)
        let memberRef = termRef.collection("members").document(userID)

        let batch = db.batch()
        batch.setData([
            "id": id.uuidString,
            "title": title,
            "details": details,
            "date": Timestamp(date: date),
            "createdAt": Timestamp(date: now),
            "updatedAt": Timestamp(date: now),
            "createdBy": userID,
            "participantIds": [userID],
            "status": TermStatus.active.rawValue
        ], forDocument: termRef)
        var memberData: [String: Any] = [
            "userId": userID,
            "role": TermMemberRole.owner.rawValue,
            "reminderEnabled": reminderDate != nil,
            "joinedAt": Timestamp(date: now)
        ]

        if let reminderDate {
            memberData["reminderDate"] = Timestamp(date: reminderDate)
        }

        batch.setData(memberData, forDocument: memberRef)

        try await commit(batch)
        return id
    }

    func updateTerm(_ term: Term) async throws {
        guard let userID = auth.currentUser?.uid else {
            throw TermsRepositoryError.missingUser
        }

        let termRef = db.collection("terms").document(term.id.uuidString)
        let memberRef = termRef.collection("members").document(userID)
        let batch = db.batch()

        var termData: [String: Any] = [
            "title": term.title,
            "details": term.details,
            "date": Timestamp(date: term.date),
            "updatedAt": Timestamp(date: Date()),
            "status": term.status.rawValue
        ]

        if let location = term.location {
            termData["location"] = [
                "geoPoint": location.geoPoint,
                "title": location.title as Any,
                "address": location.address as Any
            ]
        } else {
            termData["location"] = FieldValue.delete()
        }

        batch.updateData(termData, forDocument: termRef)
        var memberData: [String: Any] = [
            "userId": userID,
            "reminderEnabled": term.reminderDate != nil
        ]

        if let reminderDate = term.reminderDate {
            memberData["reminderDate"] = Timestamp(date: reminderDate)
        } else {
            memberData["reminderDate"] = FieldValue.delete()
        }

        batch.setData(memberData, forDocument: memberRef, merge: true)

        try await commit(batch)
    }

    func deleteTerm(_ term: Term) async throws {
        guard let userID = auth.currentUser?.uid else {
            throw TermsRepositoryError.missingUser
        }

        let termRef = db.collection("terms").document(term.id.uuidString)
        try await updateData([
            "status": TermStatus.deleted.rawValue,
            "updatedAt": Timestamp(date: Date()),
            "deletedBy": userID
        ], forDocument: termRef)
    }

    private func term(from document: QueryDocumentSnapshot, currentUserID: String) async throws -> Term? {
        try await term(from: document as DocumentSnapshot, currentUserID: currentUserID)
    }

    private func term(from document: DocumentSnapshot, currentUserID: String) async throws -> Term? {
        guard let data = document.data() else { return nil }
        guard let id = UUID(uuidString: data["id"] as? String ?? document.documentID) else { return nil }

        let member = try await getDocument(document.reference.collection("members").document(currentUserID)).data()
        let reminderEnabled = member?["reminderEnabled"] as? Bool ?? false
        let reminderDate = reminderEnabled ? (member?["reminderDate"] as? Timestamp)?.dateValue() : nil
        let location = location(from: data["location"] as? [String: Any])

        return Term(
            id: id,
            title: data["title"] as? String ?? "",
            details: data["details"] as? String ?? "",
            date: (data["date"] as? Timestamp)?.dateValue() ?? Date(),
            reminderDate: reminderDate,
            location: location,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date(),
            createdBy: data["createdBy"] as? String ?? "",
            participantIds: data["participantIds"] as? [String] ?? [],
            status: TermStatus(rawValue: data["status"] as? String ?? "") ?? .active
        )
    }

    private func location(from data: [String: Any]?) -> TermLocation? {
        guard let data, let geoPoint = data["geoPoint"] as? GeoPoint else { return nil }
        return TermLocation(
            geoPoint: geoPoint,
            title: data["title"] as? String,
            address: data["address"] as? String
        )
    }

    private func getDocument(_ reference: DocumentReference) async throws -> DocumentSnapshot {
        try await withCheckedThrowingContinuation { continuation in
            reference.getDocument { snapshot, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let snapshot {
                    continuation.resume(returning: snapshot)
                } else {
                    continuation.resume(throwing: TermsRepositoryError.emptySnapshot)
                }
            }
        }
    }

    private func updateData(_ data: [AnyHashable: Any], forDocument reference: DocumentReference) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            reference.updateData(data) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    private func commit(_ batch: WriteBatch) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            batch.commit { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}

enum TermsRepositoryError: LocalizedError {
    case missingUser
    case emptySnapshot

    var errorDescription: String? {
        switch self {
        case .missingUser:
            return "Користувач не авторизований."
        case .emptySnapshot:
            return "Firestore повернув порожню відповідь."
        }
    }
}

enum TermMemberRole: String {
    case owner
    case editor
    case viewer
}

private extension Sequence {
    func asyncCompactMap<T>(_ transform: (Element) async throws -> T?) async throws -> [T] {
        var values: [T] = []

        for element in self {
            if let value = try await transform(element) {
                values.append(value)
            }
        }

        return values
    }
}
