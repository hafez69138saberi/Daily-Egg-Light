
import Foundation
import FirebaseDatabase

struct FirebaseLogger {

    private static let dbRef = Database.database().reference()

    static func logSession(uuid: String, attToken: String?) {

        let sessionData: [String: Any] = [
            "uuid": uuid,
            "att_token": attToken ?? "",
            "timestamp": ServerValue.timestamp()
        ]

        dbRef.child("sessions").child(uuid).setValue(sessionData) { error, _ in
            if let error = error {
            } else {
            }
        }
    }

    static func logEvent(uuid: String, name: String, payload: [String: Any]? = nil) {

        var eventData: [String: Any] = [
            "event_name": name,
            "timestamp": ServerValue.timestamp()
        ]
        if let payload = payload {
            eventData["payload"] = payload
        }

        dbRef.child("sessions")
             .child(uuid)
             .child("events")
             .childByAutoId()
             .setValue(eventData) { error, _ in
                 if let error = error {
                     print("\(error.localizedDescription)")
                 } else {
                 }
             }
    }
}
