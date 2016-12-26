# Typed Notifications

[![Swift](https://img.shields.io/badge/Swift-3.0-orange.svg)](https://swift.org)
[![Xcode](https://img.shields.io/badge/Xcode-8.2-blue.svg)](https://developer.apple.com/xcode)

## What ##

I recently watched some of the excellent [**Swift Talk**](https://talk.objc.io)
episodes and two, in particular, got me thinking in a different direction than
what they suggest in those talks. I'm speaking of **typed notifications**.

If you haven't watched them, you should. Actually, you should watch the entire
series because there's a lot of good stuff there.

[Swift Talk #27: Typed Notifications (Part 1)](https://talk.objc.io/episodes/S01E27-typed-notifications-part-1)
[Swift Talk #28: Typed Notifications (Part 2)](https://talk.objc.io/episodes/S01E28-typed-notifications-part-2)

## The problem ##

If you have done much iOS development, especially in the olden days of
Objective-C, you'll have noticed that a lot of it is very much "stringly" typed,
that is, a lot of things are determined by strings (`NSString` instances).
Notifications are no exception and, in fact, is one of the more annoying
examples. Not only the notification names are strings that you could
accidentally mistype but the user-info dictionary is, well, a dictionary that
can contain anything, of any object type. Upon receiving a notification, you
have to make sure that everything in it has the expected type and then you do a
lot of casting. That's very error prone and there has to be a better, more
**swifty**, way to handle all that.

## My solution ##

I propose that you can define your custom notifications (and even wrap the
system ones) as cases of an enumerated type satisfying a particular protocol.
Here's an example of how you'd go about defining and using some silly custom
notifications:

```Swift
// Defining your custom notifications:
enum MyAppNotifs: NotificationEnum {

    case appHasLaunched(launchDate: Date)
    case appDownloadedData(title: String, index: Int)
    case appWillCrash(error: Error)

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

    static let appHasLaunchedNotif    = Notification.Name(rawValue: "MyAppNotifs.appHasLaunched")
    static let appDownloadedDataNotif = Notification.Name(rawValue: "MyAppNotifs.appDownloadedData")
    static let appWillCrashNotif      = Notification.Name(rawValue: "MyAppNotifs.appWillCrash")

}


// This is how an interested party would subscribe to receive notifications of a particular kind and case:
// (The token is an object you store, say, in your view controller so that when the view controller goes
//  out of scope, the observer gets automatically removed from the notification center)
var token = center.addObserver(name: MyAppNotifs.appDownloadedDataNotif) {
    (notification: MyAppNotifs, object: Any?) in

    switch notification {
    case .appDownloadedData(let title, let index):
        print("title: \(title), index: \(index)")
    default:
        break
    }

}

// This is how a notification is posted. I think this reads particularly nicely.
let notif = MyAppNotifs.appDownloadedData(title: "Test", index: 5)
center.post(notification: notif)
```

For details and the full implementation of the necessary extensions, take a look at the [playground]() in this repository.

## Author ##

Wagner Truppel, trupwl@gmail.com

## License ##

The playground file is available under the MIT license. See the LICENSE
file for more info.
