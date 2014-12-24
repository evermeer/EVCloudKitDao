EVCloudKitDao
=============


[![CI Status](http://img.shields.io/travis/Edwin Vermeer/EVCloudKitDao.svg?style=flat)](https://travis-ci.org/Edwin Vermeer/EVCloudKitDao)
[![Version](https://img.shields.io/cocoapods/v/EVCloudKitDao.svg?style=flat)](http://cocoadocs.org/docsets/EVCloudKitDao)
[![License](https://img.shields.io/cocoapods/l/EVCloudKitDao.svg?style=flat)](http://cocoadocs.org/docsets/EVCloudKitDao)
[![Platform](https://img.shields.io/cocoapods/p/EVCloudKitDao.svg?style=flat)](http://cocoadocs.org/docsets/EVCloudKitDao)

## Author

Edwin Vermeer, edwin@evict.nl

## What is this
This is a library for simplified access to  Apple's CloudKit data. You can use the EVCloudKitDao.swift class if you want control over your in app data and notifications. The EVCloudKitData.swift class will let you handle CloudKit data as easy as possible. As a bonus you can use the EVReflection.swift class if you want easy to use reflection methods.

See TestsViewController.swift for a complete overview of the functionality. See the Quick Help info for method descriptions. The AppMessage demo will be a complete functional messaging app based on CloudKit.

This is still a work in progress. The Dao, Data and Reflection classes are complete, the demo is progressing. The news items are fully functional. Just try adding, deleting and updating newsitems from the CloudKit dashboard. Also the contact list is functional. I'm now working on the chat window.

## A picture says more than 1000 words
Here is a screenshot of the included demo app chat functionality. It's already functional but there is still some work to do. 

![Screenshot0][img0]

## Main features of EVCloudKitDao:
- simple singleton access to your default database
- You do not have to parse from and to CKRecord (is based on reflection)
- Generic and simplified query handling
- Error handling (separate completionHandler and errorHandler code blocs)
- Storing CKReference objects
- Storing CKAsset objects
- Organising subscription
- Handling incoming notifications
- (Re)setting the badge

## Main features of EVCloudKitData:
- Use just one predicate for a query, subscription and processing incoming notifications.
- it's only one method call with a couple of callback events
- it will store the fetched data collection in memory.
- notifications will update the data collections and call the appropriate events.
- local updates will also update the data collection and call the appropriate events
- since all data is processed all callback events will be executed on the mainQueue

## Todo's'
- The object can not have nullable types because of a reflection problem (wait for Shift improvement or figure out a hack/workaround).
- Completing the AppMessage demo

## External components for the demo
The AppMessage demo is using the following components which can be installed using CocoaPods. See instructions below.

- [ResideMenu](https://github.com/romaonthego/RESideMenu) - iOS 7/8 style side menu with parallax effect.
- [JSQMessagesViewController](https://github.com/jessesquires/JSQMessagesViewController) - An elegant messages UI library
- [JSQSystemSoundPlayer](https://github.com/jessesquires/JSQSystemSoundPlayer) - A fancy Obj-C wrapper for iOS System Sound Services
- [CRToast](https://github.com/cruffenach/CRToast) - A modern iOS toast view that can fit your notification needs

Unfortunately there is also a great library that can not be included using CocoaPods. The code for this has been added to this project.

- [ExSwift](https://github.com/pNre/ExSwift) - A set of Swift extensions for standard types and classes

## Using EVCloudKitDao or EVCloudKitData in your own App 
EVCloudKitDao is available through [CocoaPods](http://cocoapods.org). 
At this moment cocoapods written in Swift can not be used. 
According to the forum support for Swift will come soon.
If that is released, then to install this, simply add the following line to your Podfile:

pod "EVCloudKitDao"


As long as Swift cocoapods don't work yet, you can just copy the Cloudkit folder containing the 4 classes EVCloudKitDao, EVCloudKitData, EVReflection and EVCloudKitDataObject to your app. Then have a look at the ApMessage code for how to implement push notifications and how to connect to CloudKit data (see AppDelegate.swift and LeftMenuViewController.swift) For contacts see the RightMenuViewController.swift and for other usage see the TestsViewController.swift

When adding a property to your object of type CKReference, then also add a property of type String for the RecordID.recordName. You could add a setter that would populate both properties. Then if you query this using a NSPredicate, then query the string field and not the CKReference field. You have to do this because a NSPredicate works difrently for NSCloudkit than for an object. The EVCloudData class needs them to function in the same way. For a sample, see the Message class.

## Building the AppMessage demo

1) Clone the repo to a working directory

2) [CocoaPods](http://cocoapods.org) is used to manage dependencies. Pods are setup easily and are distributed via a ruby gem. Follow the simple instructions on the website to setup. After setup, run the following command from the toplevel directory of AppMessage to download the dependencies for AppMessage:

```sh
pod install
```

3) Open the `AppMessage.xcworkspace` in Xcode.

4) Go to AppMessage target settings and update the:

- bundle name (usually your own reversed domain)
- Change the team settings (your own certificate that is enabled for push notifications)
- fix the iCloud capabilities. (check key-value store and CloudKit with a default container)
- fix the capabilities for Background Modes 'Background fetch' and 'Remote notifications'

5) Build and Run the app. In the AppDelegate there is a call to initiate all objects (createRecordTypes). All required CloudKit objects will be created.

6) Open the CloudKit dashboard, select all recordtypes and enable all 'Metadata Indexes'

7) Disable the call to .createRecordTypes in AppDelegate and run the app again.


and you are ready to go!

## How to use the EVCloudKitData
Below is all the code you need to setup a news feed including push notification handling for any changes.


```
class News : EVCloudKitDataObject {
    var Subject : String = ""
    var Text : String = ""
}

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: NSDictionary?) -> Bool {
        // Make sure we receive subscription notifications
        application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: .Alert | .Badge | .Sound, categories: nil))
        application.registerForRemoteNotifications()
        return true
    }

    func application(application: UIApplication!, didReceiveRemoteNotification userInfo: [NSObject : NSObject]!) {
        NSLog("Push received")
        EVCloudData.instance.didReceiveRemoteNotification(userInfo, {
            NSLog("Not a CloudKit Query notification.")            
        })
    }
}


class LeftMenuViewController: UIViewController {
    var newsController: NewsViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        connectToNews()
        // Only already setup CloudKit connect's will receive these notifications (like the News above)
        EVCloudData.instance.fetchChangeNotifications()        
    }

    deinit {
        EVCloudData.instance.disconnect("News_All")
    }

    func connectToNews() {
        EVCloudData.instance.connect(News()
        , predicate: NSPredicate(value: true)
        , filterId: "News_All"
        , configureNotificationInfo: { notificationInfo in
            notificationInfo.alertBody = "New news item"
            notificationInfo.shouldSendContentAvailable = true }
        , completionHandler: { results in
            NSLog("There are \(results.count) existing news items")
            self.newsController.tableView.reloadData()
        }, insertedHandler: {item in
            Helper.showStatus("New News item: '\((item as News).Subject)'")
            self.newsController.tableView.reloadData()
        }, updatedHandler: {item in
            Helper.showStatus("Updated News item:'\((item as News).Subject)'")
            self.newsController.tableView.reloadData()
        }, deletedHandler: {recordId in
            Helper.showStatus("News item was removed")
            self.newsController.tableView.reloadData()
        }, errorHandler: {error in
            Helper.showError("Could not load news: \(error.description)")
        })
    }
}


class NewsViewController : UIViewController, UITableViewDataSource, UITableViewDelegate, RESideMenuDelegate {
	...
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell:UITableViewCell! = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as? UITableViewCell
        ...
        //This line all you need to get the correct data for the cell
        var news:News = EVCloudData.instance.data["News_All"]![indexPath.row] as News

        cell.textLabel?.text = news.Subject
        cell.detailTextLabel?.text = news.Body
        return cell;
    }
}

```



## How to use the EVCloudKitDao
```
class Message : EVCloudKitDataObject {
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

dao.query(Message()
    , completionHandler: { results in
        NSLog("query : result count = \(results.count)")
    }, errorHandler: { error in
        NSLog("<--- ERROR query Message")
    })
```



## License

EVCloudKitDao is available under the MIT license. See the LICENSE file for more info.


[img0]:https://github.com/evermeer/EVCloudKitDao/blob/master/Screenshot.png