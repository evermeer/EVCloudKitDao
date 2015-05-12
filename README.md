EVCloudKitDao
=============

Version 0.7.0 and later are for Xcode 6.3. Travis-ci build is failing because it's running Xcode 6.1.1 Have to wait for the build to pass again when Travis-ci adds Xcode 6.3 as an option (planned for end May?)

[![Build Status](https://travis-ci.org/evermeer/EVCloudKitDao.svg?style=flat)](https://travis-ci.org/evermeer/EVCloudKitDao)
[![Issues](https://img.shields.io/github/issues-raw/evermeer/EVCloudKitDao.svg?style=flat)](https://github.com/evermeer/EVCloudKitDao/issues)
[![Stars](https://img.shields.io/github/stars/evermeer/EVCloudKitDao.svg?style=flat)](https://github.com/evermeer/EVCloudKitDao/stargazers)
[![Version](https://img.shields.io/cocoapods/v/EVCloudKitDao.svg?style=flat)](http://cocoadocs.org/docsets/EVCloudKitDao)
[![License](https://img.shields.io/cocoapods/l/EVCloudKitDao.svg?style=flat)](http://cocoadocs.org/docsets/EVCloudKitDao)
[![Platform](https://img.shields.io/cocoapods/p/EVCloudKitDao.svg?style=flat)](http://cocoadocs.org/docsets/EVCloudKitDao)
[![Documentation](https://img.shields.io/badge/documented-99%-brightgreen.svg?style=flat)](http://cocoadocs.org/docsets/EVCloudKitDao)

[![Git](https://img.shields.io/badge/GitHub-evermeer-blue.svg?style=flat)](https://github.com/evermeer)
[![Twitter](https://img.shields.io/badge/twitter-@evermeer-blue.svg?style=flat)](http://twitter.com/evermeer)
[![LinkedIn](https://img.shields.io/badge/linkedin-Edwin Vermeer-blue.svg?style=flat)](http://nl.linkedin.com/in/evermeer/en)
[![Website](https://img.shields.io/badge/website-evict.nl-blue.svg?style=flat)](http://evict.nl)
[![eMail](https://img.shields.io/badge/email-edwin@evict.nl-blue.svg?style=flat)](mailto:edwin@evict.nl?SUBJECT=About EVCloudKitDao)



## What is this
With Apple CloudKit, you can focus on your client-side app development and let iCloud eliminate the need to write server-side application logic. CloudKit provides you with Authentication, private and public database, structured and asset storage services - all for free with very high [limits](https://developer.apple.com/icloud/documentation/cloudkit-storage/). For more information see [Apple CloudKit documentation](https://developer.apple.com/icloud/index.html)

This is a library to simplify the access to Apple's CloudKit data and notifications (see a more detailed description below)
 
- EVCloudKitDao.swift for if you want control over your in app data and notifications. 
- EVCloudData.swift will let you handle CloudKit data as easy as possible. 
- EVglobal.swift for a couple of easy to use global bridging functions (EVLog and EVtry)

There is a dependency with [EVReflection](https://github.com/evermeer/EVReflection) and [SwiftTryCatch](https://github.com/williamFalcon/SwiftTryCatch). Those will automatically be setup if you are using cocoapods.
- [EVReflection](https://github.com/evermeer/EVReflection) for if you want easy to use reflection methods. (not only for CloudKit)
- [SwiftTryCatch](https://github.com/williamFalcon/SwiftTryCatch) - Adds try-catch support for Swift

See the Quick Help info for method descriptions or the documentation at [cocoadocs.org](http://cocoadocs.org/docsets/EVCloudKitDao/)

The AppMessage demo is a complete functional messaging app based on CloudKit:

- News items are fully functional. Just try adding, deleting and updating newsitems from the CloudKit dashboard. 
- The Contacts list based on your phone contacts that also have installed the app. 
- Chat with someone using text messages, pictures and sending your location
- A search window (async autocomplete) where you can search all chat messages using a tokenized or begiswith query
- It also has TestViewController.swift for an overview of the functionality

I'm looking for feedback. Please let me know if you want something changed or added to the library or the demo.


## A picture says more than 1000 words
Here are screenshots of the included demo app chat functionality:

![Screenshot0](https://github.com/evermeer/EVCloudKitDao/blob/master/Screenshot.png?raw=true)
![Screenshot1](https://github.com/evermeer/EVCloudKitDao/blob/master/Screenshot2.png?raw=true)


![Screenshot2](https://github.com/evermeer/EVCloudKitDao/blob/master/Screenshot3.PNG?raw=true)
![Screenshot3](https://github.com/evermeer/EVCloudKitDao/blob/master/Screenshot4.PNG?raw=true)

## Documentation ##
Documentation is now available at [cocoadocs.org](http://cocoadocs.org/docsets/EVCloudKitDao/)


## Main features of EVCloudKitDao:
- simple singleton access to your public or private database and containers (default and named)
- Object mapping: You do not have to parse from and to CKRecord (mapping is based on reflection, including system fields)
- Generic and simplified query handling
- Error handling (separate completionHandler and errorHandler code blocks)
- Storing CKReference objects
- Storing CKAsset objects
- Optionally auto continue reading from cursor (batch query)
- Organising subscription
- Handling incoming notifications
- (Re)setting the badge

## Main features of EVCloudKitData:
- Use just one predicate for a query, subscription and processing incoming notifications.
- it's only one method call with a couple of callback events (optional which to use)
- it will store the fetched data collection in memory.
- notifications will update the data collections and call the appropriate events.
- local updates will also update the data collection and call the appropriate events
- since all data is processed all callback events will be executed on the mainQueue
- caching of the results to a file for speedy app restart. (You can set the caching strategy) 

## Main features of EVglobal
- EVLog as a replacement for NSLog which will also output the file, function and line number.
- EVtry as a bridge function to the SwiftTryCatch library

## Known issues (Swift limitations) ##
- If you add a property to your object of type CKReference, then also add a property of type String for the RecordID.recordName. You could add a setter for populating both properties. Then if you query this using a NSPredicate, then query the string field and not the CKReference field. You have to do this because a NSPredicate works difrently for NSCloudkit than for an object. The EVCloudData class needs them to function in the same way. For a sample, see the Message class.

- Optional objects properties can now be used. Optional type properties not. Swift is not able to do a .setValue forKey on an optional like Int? or Double? As a workaround for this you could use a NSNumber? This limitation is part of [EVReflection](https://github.com/evermeer/EVReflection)

## External components for the demo
The AppMessage demo is using the following components which can be installed using CocoaPods. See instructions below.
Because of dependency compatibility the AppMessage demo requires Xcode 6.2 or later.

- [EVReflection](https://github.com/evermeer/EVReflection) - Swift helper library with reflection functions
- [SSASideMenu](https://github.com/SSA111/SSASideMenu) - A Swift implementation of RESideMenu
- [JSQMessagesViewController](https://github.com/jessesquires/JSQMessagesViewController) - An elegant messages UI library
- [JSQSystemSoundPlayer](https://github.com/jessesquires/JSQSystemSoundPlayer) - A fancy Obj-C wrapper for iOS System Sound Services
- [CRToast](https://github.com/cruffenach/CRToast) - A modern iOS toast view that can fit your notification needs
- [UIImage-Resize](https://github.com/AliSoftware/UIImage-Resize) - Category to add some resizing methods to the UIImage class, to resize it to a given CGSize — or fit in a CGSize keeping aspect ratio
- [WhereAmI](https://github.com/lypiut/WhereAmI) - Easy to use Core Location library in Swift
- [UzysAssetsPickerController](https://github.com/uzysjung/UzysAssetsPickerController) - Alternative UIImagePickerController , You can take a picture with camera and choose multiple photos and videos
- [VIPhotoView](https://github.com/vitoziv/VIPhotoView) - View a photo with simple and basic interactive gesture
- [SwiftTryCatch](https://github.com/williamFalcon/SwiftTryCatch) - Adds try-catch support for Swift

Besides these the dependency to EVCloudKitDao has been skipped by just using the classes directly
- [EVCloudKitDao](https://github.com/evermeer/EVCloudKitDao) - Simplified access to Apple's CloudKit


## Using EVCloudKitDao or EVCloudKitData in your own App 

'EVCloudKitDao' is now available through the dependency manager [CocoaPods](http://cocoapods.org). 
You do have to use cocoapods version 0.36. At this moment this can be installed by executing:

```
[sudo] gem install cocoapods
```

If you have installed cocoapods version 0.36 or later, then you can just add EVCloudKitDao to your workspace by adding the folowing 2 lines to your Podfile:

```
use_frameworks!
pod "EVCloudKitDao"
```

Version 0.36 of cocoapods will make a dynamic framework of all the pods that you use. Because of that it's only supported in iOS 8.0 or later. When using a framework, you also have to add an import at the top of your swift file like this:

```
import EVCloudKitDao
```

If you want support for older versions than iOS 8.0, then you can also just copy the Cloudkit folder containing the 5 classes EVCloudKitDao, EVCloudKitData, EVReflection, EVCloudKitDataObject and EVglobal to your app. besides that you also have to embed the [SwiftTryCatch](https://github.com/williamFalcon/SwiftTryCatch) class 

When you have added EVCloudKitDao to your project, then have a look at the AppMessage code for how to implement push notifications and how to connect to CloudKit data (see AppDelegate.swift and LeftMenuViewController.swift) For contacts see the RightMenuViewController.swift and for other usage see the TestsViewController.swift


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
        EVLog("Push received")
        EVCloudData.publicDB.didReceiveRemoteNotification(userInfo, {
            EVLog("Not a CloudKit Query notification.")            
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
            EVLog("There are \(results.count) existing news items")
            self.newsController.tableView.reloadData()
            return results.count < 200 // Continue reading if we have less than 200 records and if there are more.
        }, insertedHandler: {item in
            Helper.showStatus("New News item: '\(item.Subject)'")
            self.newsController.tableView.reloadData()
        }, updatedHandler: {item in
            Helper.showStatus("Updated News item:'\(item.Subject)'")
            self.newsController.tableView.reloadData()
        }, deletedHandler: {recordId in
            Helper.showStatus("News item was removed")
            self.newsController.tableView.reloadData()
        }, dataChangedHandler : {
            EVLog("Some News data was changed")
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

let dao: EVCloudKitDao = EVCloudKitDao.publicDB
let dao2 = EVCloudKitDao.publicDBForContainer("iCloud.nl.evict.myapp")

var message = Message()
message.From = "me@me.com"
message.To = "you@me.com"
message.Text = "This is the message text"

dao.saveItem(message, completionHandler: {record in
        createdId = record.recordID.recordName;
        EVLog("saveItem : \(createdId)");
    }, errorHandler: {error in
        EVLog("<--- ERROR saveItem");
    })

dao.query(Message()
    , completionHandler: { results in
        EVLog("query : result count = \(results.count)")
    }, errorHandler: { error in
        EVLog("<--- ERROR query Message")
    })
```

## All you need for a keyword search (async autocomplete)
```
var queryRunning:Int = 0
var data:[Message] = []

func searchDisplayController(controller: UISearchDisplayController!, shouldReloadTableForSearchString searchString: String!) -> Bool {
    self.filterContentForSearchText(searchString)
    return false
}

func searchDisplayController(controller: UISearchDisplayController!, shouldReloadTableForSearchScope searchOption: Int) -> Bool {
    self.filterContentForSearchText(self.searchDisplayController!.searchBar.text)
    return false
}

func filterContentForSearchText(searchText: String) {
    EVLog("Filter for \(searchText)")
    networkSpinner(1)
    EVCloudKitDao.publicDB.query(Message(), tokens: searchText, completionHandler: { results in
        EVLog("query for tokens '\(searchText)' result count = \(results.count)")
        self.data = results
        NSOperationQueue.mainQueue().addOperationWithBlock {
            self.searchDisplayController!.searchResultsTableView.reloadData()
            self.tableView.reloadData()
            self.networkSpinner(-1)
        }
    }, errorHandler: { error in
        EVLog("ERROR: query Message for words \(searchText)")
        self.networkSpinner(-1)
    })
}

func networkSpinner(adjust: Int) {
    self.queryRunning = self.queryRunning + adjust
    UIApplication.sharedApplication().networkActivityIndicatorVisible = self.queryRunning > 0
}

override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return data.count
}

override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cellIdentifier = "Folowin_Search_Cell";
    var cell:UITableViewCell! = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as? UITableViewCell
    if cell == nil {
        cell = UITableViewCell(style: .Subtitle, reuseIdentifier: cellIdentifier)
    }

    var item:Message = data[indexPath.row]
    cell.textLabel?.text = item.Text
    return cell;
}

```


## License

EVCloudKitDao is available under the MIT license. See the LICENSE file for more info.

