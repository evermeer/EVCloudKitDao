EVCloudKitDao
=============

[![Build Status](https://travis-ci.org/evermeer/EVCloudKitDao.svg)](https://travis-ci.org/evermeer/EVCloudKitDao)
[![Version](https://img.shields.io/cocoapods/v/EVCloudKitDao.svg?style=flat)](http://cocoadocs.org/docsets/EVCloudKitDao)
[![License](https://img.shields.io/cocoapods/l/EVCloudKitDao.svg?style=flat)](http://cocoadocs.org/docsets/EVCloudKitDao)
[![Platform](https://img.shields.io/cocoapods/p/EVCloudKitDao.svg?style=flat)](http://cocoadocs.org/docsets/EVCloudKitDao)

## What is this
This is a library for simplified access to  Apple's CloudKit data. You can use the EVCloudKitDao.swift class if you want control over your in app data and notifications. The EVCloudKitData.swift class will let you handle CloudKit data as easy as possible. As a bonus you can use the EVReflection.swift class if you want easy to use reflection methods.

See TestsViewController.swift for a complete overview of the functionality. See the Quick Help info for method descriptions. The AppMessage demo will be a complete functional messaging app based on CloudKit.

The Dao, Data and Reflection classes are complete, the demo is progressing. It has support for:
- News items are fully functional. Just try adding, deleting and updating newsitems from the CloudKit dashboard. 
- A Contacts list based on your contacts that also have installed the app. 
- Chat with someone using text messages, pictures and sending your location

## A picture says more than 1000 words
Here is a screenshot of the included demo app chat functionality. It's already functional but there is still some work to do. 

![Screenshot0][img0]
![Screenshot1][img1]

## Documentation ##
Documentation is now available at [cocoadocs.org](http://cocoadocs.org/docsets/EVCloudKitDao/)


## Main features of EVCloudKitDao:
- simple singleton access to your public or private database
- Object mapping: You do not have to parse from and to CKRecord (is based on reflection)
- Generic and simplified query handling
- Error handling (separate completionHandler and errorHandler code blocks)
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
- basic support for caching all data to file. 

## Main features of EVReflection:
- Parsing objects based on NSObject to a dictionary. (except for nullable fields)
- Parsing a dictionary back to an object.
- Creating a class from a string value and get the string value for a class.
- Support NSCoding methods encodeWithCoder and decodeObjectWithCoder

## Todo's'
- Add caching options (specify per connection caching types: None, Direct, EachMinute(X))

## Known issues (Swift limitations) ##
- If you add a property to your object of type CKReference, then also add a property of type String for the RecordID.recordName. You could add a setter that would populate both properties. Then if you query this using a NSPredicate, then query the string field and not the CKReference field. You have to do this because a NSPredicate works difrently for NSCloudkit than for an object. The EVCloudData class needs them to function in the same way. For a sample, see the Message class.

- Optional objects properties can now be used. Optional type properties not. Swift is not able to do a .setValue forKey on an optional like Int? or Double? As a workaround for this you could use a NSNumber?

## External components for the demo
The AppMessage demo is using the following components which can be installed using CocoaPods. See instructions below.

- [ResideMenu](https://github.com/romaonthego/RESideMenu) - iOS 7/8 style side menu with parallax effect.
- [JSQMessagesViewController](https://github.com/jessesquires/JSQMessagesViewController) - An elegant messages UI library
- [JSQSystemSoundPlayer](https://github.com/jessesquires/JSQSystemSoundPlayer) - A fancy Obj-C wrapper for iOS System Sound Services
- [CRToast](https://github.com/cruffenach/CRToast) - A modern iOS toast view that can fit your notification needs
- [UIImage-Resize](https://github.com/AliSoftware/UIImage-Resize) - Category to add some resizing methods to the UIImage class, to resize it to a given CGSize — or fit in a CGSize keeping aspect ratio
- [WhereAmI](https://github.com/lypiut/WhereAmI) - Easy to use Core Location library in Swift

Unfortunately there is also a great library that can not be included using CocoaPods. The code for this has been added to this project.

- [ExSwift](https://github.com/pNre/ExSwift) - A set of Swift extensions for standard types and classes

## Using EVCloudKitDao or EVCloudKitData in your own App 

'EVCloudKitDao' is now available through the dependency manager [CocoaPods](http://cocoapods.org). 
You do have to use cocoapods version 0.36. At this moment this can be installed as a pre release by executing:

```
[sudo] gem install cocoapods --pre
```

If you have installed cocoapods version 0.36 or later, then you can just add EVCloudKitDao to your workspace by adding the folowin linge to your Podfile:

```
pod "EVCloudKitDao"
```

Version 0.36 of cocoapods will make a dynamic framework of all the pods that you use. Because of that it's only supported in iOS 8.0 or later. When using a framework, you also have to add an import at the top of your swift file like this:

```
import EVCloudKitDao
```

If you want to wait for the official release of cocoapods 0.36 of if you want support for older versions than iOS 8.0, then you can also just copy the Cloudkit folder containing the 4 classes EVCloudKitDao, EVCloudKitData, EVReflection and EVCloudKitDataObject to your app. 

When you have added EVCloudKitDao to your project, then have a look at the ApMessage code for how to implement push notifications and how to connect to CloudKit data (see AppDelegate.swift and LeftMenuViewController.swift) For contacts see the RightMenuViewController.swift and for other usage see the TestsViewController.swift


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

8) Make sure you run the app on 2 devices, each using a diverent iCloud account and each device having the other account in it's contact list.


and you are ready to go!

## How to use the EVCloudKitData
Below is all the code you need to setup a news feed including push notification handling for any changes.


```
// Just enherit from EVCloudKitDataObject so that you have access to the CloudKit metadata
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
        EVCloudData.publicDB.didReceiveRemoteNotification(userInfo, {
            NSLog("Not a CloudKit Query notification.")            
        })
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // If you do a backup then this backup will be reloaded after app restart.
        EVCloudData.publicDB.backupData()        
    }
}


class LeftMenuViewController: UIViewController {
    var newsController: NewsViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        connectToNews()
        // Only already setup CloudKit connect's will receive these notifications (like the News above)
        EVCloudData.publicDB.fetchChangeNotifications()        
    }

    deinit {
        EVCloudData.publicDB.disconnect("News_All")
    }

    func connectToNews() {
        EVCloudData.publicDB.connect(News()
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
        var news:News = EVCloudData.publicDB.data["News_All"]![indexPath.row] as News

        cell.textLabel?.text = news.Subject
        cell.detailTextLabel?.text = news.Body
        return cell;
    }
}

```



## How to use the EVCloudKitDao
```
// Just enherit from EVCloudKitDataObject so that you have access to the CloudKit metadata
class Message : EVCloudKitDataObject {
    var From : String = ""
    var To : String = ""
    var Text : String = ""
}

var dao: EVCloudKitDao = EVCloudKitDao.publicDB

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
[img1]:https://github.com/evermeer/EVCloudKitDao/blob/master/Screenshot2.png
