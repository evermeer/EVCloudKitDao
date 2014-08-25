EVCloudKitDao
=============

## What is this
This is a library for simplified access to  Apple's CloudKit data
You can use the EVCloudKitDao.swift class if you want control over your in app data and notifications
The EVCloudKitData.swift class will let you handle CloudKit data as easy as possible

See TestsViewController.swift for a complete overview of the functionality
The AppMessage sample is a complete functional messaging sample based on CloudKit.

This is a work in progress. Both Shift and CloudKit are in beta (this is tested with beta 4)

## Main features of EVCloudKitDao:
- simple singleton access to your default database
- You do not have to parse from and to CKRecord (is based on reflection)
- Generic and simplified query handling
- Error handling (seperate completionHandler and errorHandler code blocs)
- Storing CKReference objects
- Storing CKAsset objects
- Organising subscription
- Handling incomming notifications

## Main features of EVCloudKitData:
- Use just one predicate for a query, subscription and processing incomming notifications.
- int's only one method call with a couple of callback events
- it will store the fetched data collection in memory.
- notificatons will update the data collections and call the appropriate events.
- local updates will also update the data collection and call the appropriate events

## Todo's'
- The object can not have nullable types because of a reflection problem (wait for Shift improvement or figure out a hack/workaround).
- Lots of testing
- No support for zone's yet. Do you think we need it? Just let me know.

## Building the AppMessage demo

1) Clone the repo to a working directory

2) [CocoaPods](http://cocoapods.org) is used to manage dependencies. Pods are setup easily and are distributed via a ruby gem. Follow the simple instructions on the website to setup. After setup, run the following command from the toplevel directory of AppMessage to download the dependencies for AppMessage:

```
pod install
```
If you are having build issues, first make sure your pods are up to date
```
pod update
pod install
```
occasionally, CocoaPods itself will need to be updated. Do this with
```
sudo gem update
```

3) Open the `AppMessage.xcworkspace` in Xcode.

4) Go to AppMessage target settings and fix the iCloud capabilities.

5) Build and Run and you are ready to go!

## How to use the EVCloudKitData
```swift
class News : NSObject {
    var Subject : String = ""
    var Text : String = ""
}

func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: NSDictionary?) -> Bool {
    var dao = EVCloudKitDao.instance
    EVCloudData.instance.connect(dao.swiftStringFromClass(News()), predicate: NSPredicate(value: true), filterId: "News_All", onCompletion: { results in
        // If news view is loaded, then refresh the data
        NSLog("There are \(results.count) existing news items")
    }, onError: {error in
        NSLog("<-- ERROR connect")
    }, onInserted: {item in
        NSLog("New News item received")
        // New item was inserted, if news view is loaded, then refresh the data
    }, onDeleted: {recordId in
        NSLog("News item removed")
        // New item was removed, if news view is loaded, then refresh the data
    })
}

func application(application: UIApplication!, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]!) {
    NSLog("Push received")
    EVCloudData.instance.didReceiveRemoteNotification(userInfo, {
        NSLog("Not a CloudKit Query notification.")            
    })
}
```



## How to use the EVCloudKitDao
```swift
class Message : NSObject {
    var From : String = ""
    var To : String = ""
    var Text : String = ""
}

var dao: EVCloudKitDao = EVCloudKitDao.instance

var message = Message()
message.From = "me@me.com"
message.To = "you@me.com"
message.Text = "This is the message text"

dao.saveItem(message, completionHandler: {record in
        createdId = record.recordID.recordName;
        NSLog("saveItem : \(createdId)");
    }, errorHandler: {error in
        NSLog("<--- ERROR saveItem");
    })

dao.query(dao.recordType(Message()), completionHandler: { results in
        NSLog("query : result count = \(results.count)")
    }, errorHandler: { error in
        NSLog("<--- ERROR query Message")
    })
```




## License

MIT License

Copyright (c) 2014 EVICT B.V.

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.