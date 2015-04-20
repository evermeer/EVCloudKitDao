//
//  ChatViewController.swift
//
//  Created by Edwin Vermeer on 11/14/14.
//  Copyright (c) 2014. All rights reserved.
//

import Foundation
import CloudKit
import JSQMessagesViewController
import UzysAssetsPickerController
import WhereAmI
import VIPhotoView
import MapKit

class ChatViewController : JSQMessagesViewController, UIActionSheetDelegate, UzysAssetsPickerControllerDelegate, MKMapViewDelegate {
    
    var chatWithId : String = ""
    var chatWithDisplayName : String = ""
    var chatWithFirstName : String = ""
    var chatWithLastName : String = ""
    var dataID : String = ""
    var senderFirstName : String = ""
    var senderLastName : String = ""
    
    var localData : [JSQMessage?] = []
    
    var picker :UzysAssetsPickerController = UzysAssetsPickerController()
    
    var recordIdMeForConnection: String = ""
    var recordIdOtherForConnection: String = ""
    var viewAppeared = false
    
    
    // Start the conversation
    func setContact(recordId:String, firstName:String, lastName:String) {
        chatWithId = recordId
        chatWithFirstName = firstName
        chatWithLastName = lastName
        chatWithDisplayName = "\(firstName) \(lastName)"
        if dataID != "" {
            EVCloudData.publicDB.disconnect(dataID)
        }
        dataID =  "Message_\(chatWithId)"
        
        initializeCommunication()
    }
    
    
    // Setting up the components
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // configure JSQMessagesViewController
        var defaultAvatarSize: CGSize = CGSizeMake(kJSQMessagesCollectionViewAvatarSizeDefault, kJSQMessagesCollectionViewAvatarSizeDefault)
        self.collectionView.collectionViewLayout.incomingAvatarViewSize = defaultAvatarSize //CGSizeZero
        self.collectionView.collectionViewLayout.outgoingAvatarViewSize = defaultAvatarSize //CGSizeZero
        self.collectionView.collectionViewLayout.springinessEnabled = false
        self.showLoadEarlierMessagesHeader = false
        //self.inputToolbar.contentView.leftBarButtonItem
        
        // configure UzysAssetsPickerController
        var config = UzysAppearanceConfig()
        config.finishSelectionButtonColor = UIColor.greenColor()
        UzysAssetsPickerController.setUpAppearanceConfig(config)
        
        self.senderId = "~"
        self.senderDisplayName = "~"
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.viewAppeared = true
        initializeCommunication()
    }

    
    // ------------------------------------------------------------------------
    // MARK: - Handle Message data plus attached Assets
    // ------------------------------------------------------------------------
   
    func initializeCommunication() {
        if !viewAppeared || (recordIdMeForConnection == EVCloudData.publicDB.dao.activeUser.userRecordID.recordName && recordIdOtherForConnection == chatWithId) {
            return //Already connected or not ready yet
        }

        // Setup conversation for
        recordIdMeForConnection = EVCloudData.publicDB.dao.activeUser.userRecordID.recordName
        recordIdOtherForConnection = chatWithId
        
        // Sender settings for the component
        self.senderId = EVCloudData.publicDB.dao.activeUser?.userRecordID.recordName
        senderFirstName = "\(EVCloudData.publicDB.dao.activeUser!.firstName)"
        senderLastName = "\(EVCloudData.publicDB.dao.activeUser!.lastName)"
        self.senderDisplayName = "\(senderFirstName)  \(senderLastName)"
        
        
        // The data connection to the conversation
        EVCloudData.publicDB.connect(Message()
            , predicate: NSPredicate(format: "From_ID in %@ AND To_ID in %@", [recordIdMeForConnection, recordIdOtherForConnection], [recordIdOtherForConnection, recordIdMeForConnection])
            , filterId: dataID
            , configureNotificationInfo:{ notificationInfo in
            }, completionHandler: { results in
                EVLog("Conversation message results = \(results.count)")
                self.localData = [JSQMessage?](count:results.count, repeatedValue:nil)
                self.checkAttachedAssets(results)
                self.collectionView.reloadData()
                self.scrollToBottomAnimated(true)
            }, insertedHandler: { item in
                EVLog("Conversation message inserted \(item)")
                self.localData.insert(nil, atIndex: 0)
                if item.MessageType == MessageTypeEnum.Picture.rawValue {
                    self.getAttachment((item as Message).Asset_ID)
                }
                JSQSystemSoundPlayer.jsq_playMessageReceivedSound();
                self.finishReceivingMessage();
            }, updatedHandler: { item, dataIndex in
                EVLog("Conversation message updated \(item)")
                self.localData[dataIndex] = nil
            }, deletedHandler: { recordId, dataIndex in
                EVLog("Conversation message deleted : \(recordId)")
                self.localData.removeAtIndex(dataIndex)
            }, dataChangedHandler : {
                EVLog("Some conversation data was changed")
            }, errorHandler: { error in
                Helper.showError("Could not load messages: \(error.description)")
        })
    }
    
    // Disconnect from the conversation
    deinit {
        EVCloudData.publicDB.disconnect(dataID)
    }
    
    // Make sure that all Message attachments are saved in a local file
    func checkAttachedAssets(results:[Message]) {
        let filemanager = NSFileManager.defaultManager()
        var docDirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! NSString
        for item in results {
            if item.MessageType == MessageTypeEnum.Picture.rawValue {
                var filePath =  docDirPath.stringByAppendingPathComponent("\(item.Asset_ID).png")
                if !filemanager.fileExistsAtPath(filePath) {
                    self.getAttachment(item.Asset_ID)
                }
            }
        }
    }

    // Get an asset and save it as a file
    func getAttachment(id : String) {
        EVCloudData.publicDB.getItem(id, completionHandler: {item in
            var docDirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! NSString
            var filePath =  docDirPath.stringByAppendingPathComponent("\(id).png")
            var image = (item as! Asset).image()
            var myData = UIImagePNGRepresentation(image)
            myData.writeToFile(filePath, atomically:true)
            EVLog("Image downloaded to \(id).png")
            for (index, element) in enumerate(self.localData) {
                if var data:Message = EVCloudData.publicDB.data[self.dataID]![index] as? Message {
                    if data.Asset_ID == id {
                        self.localData[index] = nil
                        self.collectionView.reloadItemsAtIndexPaths([NSIndexPath(forItem: index as Int, inSection: 0 as Int)])
                    }
                }
            }
        }, errorHandler: { error in
            Helper.showError("Could not load Asset: \(error.description)")
        })
    }


    // ------------------------------------------------------------------------
    // MARK: - User interaction
    // ------------------------------------------------------------------------
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        var message = Message()
        message.setFromFields(EVCloudData.publicDB.dao.activeUser.userRecordID.recordName)
        message.FromFirstName = self.senderFirstName
        message.FromLastName = self.senderLastName
        message.setToFields(chatWithId)
        message.ToFirstName = chatWithFirstName
        message.ToLastName = chatWithLastName
        message.Text = text
        EVCloudData.publicDB.saveItem(message, completionHandler: { message in
                self.finishSendingMessage()
            }, errorHandler: { error in
                self.finishSendingMessage()
                Helper.showError("Could not send message!  \(error.description)")
        })
        self.finishSendingMessage()
    }
    
    override func didPressAccessoryButton(sender: UIButton!) {
        var sheet = UIActionSheet(title: "Media", delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil, otherButtonTitles: "Send photo", "Send location", "Send video")
        sheet.showFromToolbar(self.inputToolbar)
    }
    
    // ------------------------------------------------------------------------
    // MARK: - Accessory button actions
    // ------------------------------------------------------------------------
    func actionSheet(actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int) {
        if buttonIndex == actionSheet.cancelButtonIndex {
            return;
        }
        switch buttonIndex {
        case 1:
            addPhoto()
        case 2:
            addLocation()
        case 3:
            addVideo()
        default:
            EVLog("Can not happen!")
        }
    }
    
    func addPhoto() {
        picker.delegate = self
        picker.maximumNumberOfSelectionVideo = 0;
        picker.maximumNumberOfSelectionPhoto = 5;
        self.presentViewController(picker, animated:true, completion:nil)
    }
    
    func addVideo() {
        picker.delegate = self
        picker.maximumNumberOfSelectionVideo = 1;
        picker.maximumNumberOfSelectionPhoto = 0;
        self.presentViewController(picker, animated:true, completion:nil)
    }
    
    func addLocation() {
        WhereAmI.sharedInstance.whereAmI({ location in
            var message = Message()
            message.setFromFields(EVCloudData.publicDB.dao.activeUser.userRecordID.recordName)
            message.FromFirstName = self.senderDisplayName
            message.setToFields(self.chatWithId)
            message.ToFirstName = self.chatWithFirstName
            message.ToLastName = self.chatWithLastName
            if location.course < 0 {
                message.Text = "±\(location.verticalAccuracy)m"
            } else {
                message.Text = "±\(location.verticalAccuracy)m, \(Int(location.speed/0.36)/10)kmh \(self.direction(Int(location.course))) \(location.course)°"
            }
            message.MessageType = MessageTypeEnum.Location.rawValue
            message.Longitude = (location.coordinate.longitude as Double)
            message.Latitude = (location.coordinate.latitude as Double)
            EVCloudData.publicDB.saveItem(message, completionHandler: {record in
                EVLog("saveItem location Message: \(record.recordID.recordName)");
                self.finishSendingMessage()
                }, errorHandler: {error in
                    EVLog("ERROR: saveItem location message.\n\(error.description)");
                    Helper.showError("Could not send location message!  \(error.description)")
                    self.finishSendingMessage()
            })
        }, locationRefusedHandler: {
            Helper.showError("Location authorization has been refused, unable to  send location")
        });
    }
    
    // Get the direction indicator for a degree
    func direction(degree : Int) -> String {
        switch(degree) {
        case 338...360:
            return "N"
        case 0...22:
            return "N"
        case 23...67:
            return "NO"
        case 68...112:
            return "O"
        case 113...158:
            return "ZO"
        case 159...202:
            return "Z"
        case 203...248:
            return "ZW"
        case 249...292:
            return "W"
        case 293...337:
            return "NW"
        default:
            return ""
        }
    }

    // Callback from the asset picker
    func uzysAssetsPickerController(picker: UzysAssetsPickerController!, didFinishPickingAssets assets: [AnyObject]!) {
        picker.dismissViewControllerAnimated(true, completion: nil)
        var i:Int = 0
        for asset in assets {
            i = i++
            let mediaType = (asset as! ALAsset).valueForProperty("ALAssetPropertyType") as! String
            if mediaType == "ALAssetTypePhoto" {
                JSQSystemSoundPlayer.jsq_playMessageSentSound()
                
                // make sure we have a file with url
                var docDirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! NSString
                var filePath =  docDirPath.stringByAppendingPathComponent("Image_\(i).png")
                var image = getUIImageFromCTAsset(asset as! ALAsset)
                var myData = UIImagePNGRepresentation(image)
                myData.writeToFile(filePath, atomically:true)
                
                
                // Create an asset object for the attached image
                var assetC = Asset()
                assetC.File = CKAsset(fileURL: NSURL(fileURLWithPath: filePath)!)
                assetC.FileName = "Image_\(i).png"
                assetC.FileType = "png"
                
                // Save the asset
                EVCloudData.publicDB.saveItem(assetC, completionHandler: {record in
                    EVLog("saveItem Asset: \(record.recordID.recordName)");

                    // rename the image to recordId for a quick cache reference
                    let filemanager = NSFileManager.defaultManager()
                    var fromFilePath =  docDirPath.stringByAppendingPathComponent(record.FileName)
                    let toPath = docDirPath.stringByAppendingPathComponent(record.recordID.recordName + ".png")
                    filemanager.moveItemAtPath(fromFilePath, toPath: toPath, error: nil)

                    // Create the message object that represents the asset
                    var message = Message()
                    message.setFromFields(EVCloudData.publicDB.dao.activeUser.userRecordID.recordName)
                    message.FromFirstName = self.senderDisplayName
                    message.setToFields(self.chatWithId)
                    message.ToFirstName = self.chatWithFirstName
                    message.ToLastName = self.chatWithLastName
                    message.Text = "<foto>"
                    message.MessageType = MessageTypeEnum.Picture.rawValue
                    message.setAssetFields(record.recordID.recordName)

                    EVCloudData.publicDB.saveItem(message, completionHandler: {record in
                        EVLog("saveItem Message: \(record.recordID.recordName)");
                        self.finishSendingMessage()
                    }, errorHandler: {error in
                        EVLog("ERROR: saveItem asset.\n\(error.description)");
                        Helper.showError("Could not send picture message!  \(error.description)")
                        self.finishSendingMessage()
                    })
                    
                }, errorHandler: {error in
                    EVLog("ERROR: saveItem message.\n\(error.description)");
                    Helper.showError("Could not send picture!  \(error.description)")
                    self.finishSendingMessage()
                })
                
            } else if mediaType == "ALAssetTypeVideo"  {
                Helper.showError("Sending video's is not supported yet")
            } else {
                Helper.showError("Unknown media type")
            }
        }
    }
    
    // The image picker will return an CTAsset. We need an UIImage.
    func getUIImageFromCTAsset(asset:ALAsset) -> UIImage {
        var representation:ALAssetRepresentation = (asset as ALAsset).defaultRepresentation();
        var img:CGImage = representation.fullResolutionImage().takeUnretainedValue()
        var scale:CGFloat = CGFloat(representation.scale())
        var orientation:UIImageOrientation = UIImageOrientation(rawValue: representation.orientation().rawValue)!
        var image:UIImage = UIImage(CGImage: img, scale: scale, orientation: orientation)!
        
        return image.resizedImageToFitInSize(CGSize(width: 640, height: 640), scaleIfSmaller: true)
    }
    
    
    // ------------------------------------------------------------------------
    // MARK: - Standard CollectionView handling
    // ------------------------------------------------------------------------
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return localData.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var cell : JSQMessagesCollectionViewCell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! JSQMessagesCollectionViewCell
        var message = getMessageForId(indexPath.row)
        if !message.isMediaMessage {
            if message.senderId == self.senderId {
                cell.textView.textColor = UIColor.blackColor()
            } else {
                cell.textView.textColor = UIColor.whiteColor()
            }
            cell.textView.linkTextAttributes = [NSForegroundColorAttributeName : cell.textView.textColor,
                NSUnderlineStyleAttributeName : NSUnderlineStyle.StyleSingle.rawValue]
        }
        return cell
    }
    
    
    // ------------------------------------------------------------------------
    // MARK: - JSQMessagesCollectionView handling
    // ------------------------------------------------------------------------
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return getMessageForId(indexPath.row)
    }
    
    //CellTopLabel
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        var message = getMessageForId(indexPath.row)
        return JSQMessagesTimestampFormatter.sharedFormatter().attributedTimestampForDate(message.date)
    }
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        return kJSQMessagesCollectionViewCellLabelHeightDefault
    }
    
    //messageBubbleImageDataForItemAtIndexPath
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        var message = getMessageForId(indexPath.row)
        var bubbleFactory = JSQMessagesBubbleImageFactory()
        if message.senderId == self.senderId {
            return bubbleFactory.outgoingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleLightGrayColor())
        }
        return bubbleFactory.incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleGreenColor())
    }
    
    // MessageBubbleTopLabel
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        var message = getMessageForId(indexPath.row)
        if message.senderId == self.senderId {
            return nil;
        }
        if indexPath.row > 1 {
            var previousMessage = getMessageForId(indexPath.row - 1)
            if previousMessage.senderId == message.senderId {
                return nil
            }
        }
        return NSAttributedString(string: message.senderDisplayName)
    }
    
    // MessageBubbleTopLabel height
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        var message = getMessageForId(indexPath.row)
        if message.senderId == self.senderId {
            return 0;
        }
        if indexPath.row > 1 {
            var previousMessage = getMessageForId(indexPath.row - 1)
            if previousMessage.senderId == message.senderId {
                return 0
            }
        }
        return kJSQMessagesCollectionViewCellLabelHeightDefault
    }
    
    // avatarImageData
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        var message = getMessageForId(indexPath.row)
        var initials : String = ""
        if message.senderId == self.senderId {
            var l = Array(EVCloudData.publicDB.dao.activeUser.lastName)[0]
            initials = "\(Array(EVCloudData.publicDB.dao.activeUser.firstName)[0]) \(Array(EVCloudData.publicDB.dao.activeUser.lastName)[0])"
        } else {
            initials = "\(Array(chatWithFirstName)[0]) \(Array(chatWithLastName)[0])"
        }
        var size:CGFloat = 14
        var avatar = JSQMessagesAvatarImageFactory.avatarImageWithUserInitials(initials, backgroundColor: UIColor.lightGrayColor(), textColor: UIColor.whiteColor(), font: UIFont.systemFontOfSize(size), diameter: 30)
        return avatar
    }
    
    // CellBottomLabel
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        return nil
    }
    
    // CellBottomLabel height
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        return 0
    }
    
    
    // ------------------------------------------------------------------------
    // MARK: - JSQMessagesCollectionView events
    // ------------------------------------------------------------------------

    override func collectionView(collectionView: JSQMessagesCollectionView!, header headerView: JSQMessagesLoadEarlierHeaderView!, didTapLoadEarlierMessagesButton sender: UIButton!) {
        EVLog("Should load earlier messages.")
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, didTapAvatarImageView avatarImageView: UIImageView!, atIndexPath indexPath: NSIndexPath!) {
        EVLog("Tapped avatar!")
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAtIndexPath indexPath: NSIndexPath!) {
        EVLog("Tapped message bubble!")
        var (data, count) = getDataForId(indexPath.row)
        
        var message = getMessageForId(indexPath.row)
        let viewController = UIViewController()
        viewController.view.backgroundColor = UIColor.whiteColor()

        if data.MessageType == MessageTypeEnum.Picture.rawValue {
            viewController.title = "Photo"
            let photoView = VIPhotoView(frame:self.navigationController!.view.bounds, andImage:(message.media as? JSQPhotoMediaItem)?.image)
            photoView.autoresizingMask = UIViewAutoresizing(1 << 6 - 1)
            viewController.view.addSubview(photoView)
            self.navigationController!.pushViewController(viewController, animated: true)
        } else if data.MessageType == MessageTypeEnum.Location.rawValue {
            viewController.title = "Map"
            let map = MKMapView(frame:self.navigationController!.view.bounds)
            map.delegate = self
            map.showsUserLocation = true
            
            let point = MKPointAnnotation()
            point.coordinate = CLLocationCoordinate2D(latitude: data.Latitude, longitude: data.Longitude)
            point.title = "\(data.FromFirstName) \(data.FromLastName)"
            point.subtitle = data.Text
            
            map.addAnnotation(point)
            viewController.view.addSubview(map)
            self.navigationController!.pushViewController(viewController, animated: true)
        }
    }
    
    func mapView(mapView: MKMapView!, didAddAnnotationViews views: [AnyObject]!) {
        mapView.setRegion(MKCoordinateRegionMakeWithDistance((views[0] as! MKAnnotationView).annotation.coordinate, 1000, 1000), animated: true)
    }
    
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, didTapCellAtIndexPath indexPath: NSIndexPath!, touchLocation: CGPoint) {
        EVLog("Tapped cel at \(indexPath.row)")
    }
    
    // ------------------------------------------------------------------------
    // MARK: - Data parsing: Message to JSQMessage
    // ------------------------------------------------------------------------
    
    func getDataForId(id:Int) -> (Message, Int) {
        var data:Message!
        var count : Int = 0
        let lockQueue = dispatch_queue_create("nl.evict.AppMessage.ChatLockQueue", nil)
        dispatch_sync(lockQueue) {
            count = EVCloudData.publicDB.data[self.dataID]!.count
            if self.localData.count != count {
                self.localData = [JSQMessage?](count:count, repeatedValue:nil)
            }
            if id < count {
                data = EVCloudData.publicDB.data[self.dataID]![count - id - 1] as! Message
            } else {
                data = Message()
            }
        }
        return (data, count)
    }
    
    func getMessageForId(id:Int) -> JSQMessage {
        // Get the CloudKit Message data plus count
        var (data, count) = getDataForId(id)
        
        // Should never happen... just here to prevent a crash if it does happen.
        if count <= id {
            return JSQMessage(senderId: self.senderId, displayName: self.senderDisplayName, text: "")
        }
        
        // The JSQMessage was already created before
        if let localMessage = self.localData[count - id - 1]  {
            return localMessage
        }
        
        // Create a JSQMessage based on the Message object from CloudKit
        var message: JSQMessage!
        
        // receiving or sending..
        var sender = self.senderId
        var senderName = self.senderDisplayName
        if data.From_ID != self.senderId {
            sender = self.chatWithId
            senderName = self.chatWithFirstName + " " + self.chatWithLastName
        }
        
        // normal, location or media message
        if data.MessageType == MessageTypeEnum.Text.rawValue {
            message = JSQMessage(senderId: sender, senderDisplayName: senderName,date: data.creationDate, text: data.Text)
        } else if data.MessageType == MessageTypeEnum.Location.rawValue {
            var location = CLLocation(latitude: CLLocationDegrees(data.Latitude), longitude: CLLocationDegrees(data.Longitude))
            var locationItem = JSQLocationMediaItem()
            locationItem.setLocation(location, withCompletionHandler: {
                self.collectionView.reloadData()
//                self.collectionView.reloadItemsAtIndexPaths([NSIndexPath(forItem: id as Int, inSection: 0 as Int)])
//                self.collectionView.reloadItemsAtIndexPaths(self.collectionView.indexPathsForVisibleItems())
                
            })
            message = JSQMessage(senderId: sender, senderDisplayName: senderName, date:data.creationDate, media: locationItem)
        } else if data.MessageType == MessageTypeEnum.Picture.rawValue {
            var docDirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! NSString
            var filePath =  docDirPath.stringByAppendingPathComponent(data.Asset_ID + ".png")
            var url = NSURL(fileURLWithPath: filePath)
            if var mediaData = NSData(contentsOfURL: url!) {
                var image = UIImage(data: mediaData)
                var photoItem = JSQPhotoMediaItem(image: image)
                message = JSQMessage(senderId: sender, senderDisplayName: senderName, date:data.creationDate, media: photoItem)
            } else {
                //url = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("image-not-available", ofType: "jpg")!)
                //mediaData = NSData(contentsOfURL: url!)
                message = JSQMessage(senderId: sender, senderDisplayName: senderName, date:data.creationDate, media: JSQPhotoMediaItem())
                
            }
        }
        localData[count - id - 1] = message
        return message;
    }


}
