import Foundation

let center = NotificationCenter.default


// This is the same as proposed in https://talk.objc.io/episodes/S01E28-typed-notifications-part-2,
// only with a change in the name because I thought Token is a bit too general a name for a type.
class NotificationToken {

    let token: NSObjectProtocol
    let center: NotificationCenter

    init(token: NSObjectProtocol, center: NotificationCenter) {
        self.token = token
        self.center = center
    }

    deinit { center.removeObserver(token) }
}


// In my solution, notifications are cases of enumerated types conforming to this protocol.
protocol NotificationEnum {
    var name: Notification.Name { get }
}


extension NotificationCenter {

    // Not even fileprivate, because it really is intended to be scoped only to this extension.
    private static let _$key$_ = "_$key$_"

    // The trick is to pass the instance of the enumerated notification as the data
    // in the user info dictionary and then extract it back, preserving its type.
    func post(notification: NotificationEnum, object: Any? = nil) {

        let userInfo = [NotificationCenter._$key$_: notification]
        post(name: notification.name, object: object, userInfo: userInfo)
        
    }

    // Here we extract the enumerated notification from the user info dictionary and cast it
    // back to its original type. The cast should be safe as long as the recipient passes a
    // block with a matching type.
    func addObserver<A: NotificationEnum>(name: Notification.Name,
                     object: Any? = nil, queue: OperationQueue? = nil,
                     using block: @escaping (A, Any?) -> ()) -> NotificationToken {

        let token = addObserver(forName: name, object: object, queue: queue, using: { note in
            guard let note = note.userInfo?[NotificationCenter._$key$_] as? A else { assert(false) }
            block(note, object)
        })

        return NotificationToken(token: token, center: self)

    }

}


// ========================================================== //


// A silly example. Part of the reason why I like my solution is that any ugliness is almost
// entirely contained here, at the point where the notifications are defined.
enum MyAppNotifs: NotificationEnum {

    case appHasLaunched(launchDate: Date)
    case appDownloadedData(title: String, index: Int)
    case appWillCrash(error: Error)

    // This is a bit ugly but at least it's all in one place.
    var name: Notification.Name {
        switch self {
        case .appHasLaunched(_):
            return MyAppNotifs.appHasLaunchedNotif
        case .appDownloadedData(_, _):
            return MyAppNotifs.appDownloadedDataNotif
        case .appWillCrash(_):
            return MyAppNotifs.appWillCrashNotif
        }
    }

    // This is also a bit ugly. Again, though, it's all in one place. The enumeration cases
    // are prefixed with the enumeration type for clarity when debugging since these names
    // are visible.
    static let appHasLaunchedNotif    = Notification.Name(rawValue: "MyAppNotifs.appHasLaunched")
    static let appDownloadedDataNotif = Notification.Name(rawValue: "MyAppNotifs.appDownloadedData")
    static let appWillCrashNotif      = Notification.Name(rawValue: "MyAppNotifs.appWillCrash")

}


// Subscriber code wants to observe a particular notification. Note that it needs to pass
// the matching type as the first argument in the completion block. That is a weakness in
// my solution that I'm still trying to solve. Any ideas?
var token = center.addObserver(name: MyAppNotifs.appDownloadedDataNotif) {
    (notification: MyAppNotifs, object: Any?) in

    switch notification {
    case .appDownloadedData(let title, let index):
        print("title: \(title), index: \(index)")
    default:
        break
    }

}

// Provider code posts a notification. I think this reads particularly nicely.
let notif = MyAppNotifs.appDownloadedData(title: "Test", index: 5)
center.post(notification: notif)


// ========================================================== //


// Another example, to show the failing case.
enum MyAppOtherNotifs: NotificationEnum {

    case somethingIsWrong

    var name: Notification.Name {
        switch self {
        case .somethingIsWrong:
            return MyAppOtherNotifs.somethingIsWrongNotif
        }
    }

    static let somethingIsWrongNotif = Notification.Name(rawValue: "MyAppOtherNotifs.somethingIsWrong")

}

// Note the mismatched types. Hard to find a bug like this, which is why I added the assertion
// back at the top.
var token2 = center.addObserver(name: MyAppNotifs.appDownloadedDataNotif) {
    (notification: MyAppOtherNotifs, object: Any?) in

    switch notification {
    case .somethingIsWrong:
        print("where's the output??")
    }
    
}

// This will crash on the assertion.
// let notif2 = MyAppNotifs.appDownloadedData(title: "Test", index: 5)
// center.post(notification: notif2)

