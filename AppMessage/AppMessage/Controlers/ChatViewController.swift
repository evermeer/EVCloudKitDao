//
//  ChatViewController.swift
//
//  Created by Edwin Vermeer on 11/14/14.
//  Copyright (c) 2014. All rights reserved.
//

import Foundation
import CloudKit
import JSQMessagesViewController
import CTAssetsPickerController
import WhereAmI

class ChatViewController : JSQMessagesViewController, UIActionSheetDelegate, CTAssetsPickerControllerDelegate {
    
    var chatWithId : String = ""
    var chatWithDisplayName : String = ""
    var chatWithFirstName : String = ""
    var chatWithLastName : String = ""
    var dataID : String = ""
    var senderFirstName : String = ""
    var senderLastName : String = ""
    
    var localData : [JSQMessage?] = []
    
    func setContact(recordId:String, firstName:String, lastName:String) {
        chatWithId = recordId
        chatWithFirstName = firstName
        chatWithLastName = lastName
        chatWithDisplayName = "\(firstName) \(lastName)"
        dataID =  "Message_\(chatWithId)"
        if EVCloudData.publicDB.data[dataID] != nil {
            self.localData = [JSQMessage?](count:EVCloudData.publicDB.data[dataID]!.count, repeatedValue:nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.senderId = EVCloudData.publicDB.dao.activeUser?.userRecordID.recordName
        senderFirstName = "\(EVCloudData.publicDB.dao.activeUser?.firstName)"
        senderLastName = "\(EVCloudData.publicDB.dao.activeUser?.lastName)"
        self.senderDisplayName = "\(senderFirstName)  \(senderLastName)"
        
        // configure JSQMessagesViewController
        var defaultAvatarSize: CGSize = CGSizeMake(kJSQMessagesCollectionViewAvatarSizeDefault, kJSQMessagesCollectionViewAvatarSizeDefault)
        self.collectionView.collectionViewLayout.incomingAvatarViewSize = defaultAvatarSize //CGSizeZero
        self.collectionView.collectionViewLayout.outgoingAvatarViewSize = defaultAvatarSize //CGSizeZero
        self.showLoadEarlierMessagesHeader = false
        //self.inputToolbar.contentView.leftBarButtonItem
    }
        
    override func viewDidAppear(animated: Bool) {
        if EVCloudData.publicDB.data[dataID] != nil {
            self.localData = [JSQMessage?](count:EVCloudData.publicDB.data[dataID]!.count, repeatedValue:nil)
        }
        super.viewDidAppear(animated)
        self.collectionView.collectionViewLayout.springinessEnabled = true

        self.collectionView.reloadData()
        self.scrollToBottomAnimated(true)
        initializeCommunication()
    }

    
    // ------------------------------------------------------------------------
    // MARK: - Handle Message data plus attached Assets
    // ------------------------------------------------------------------------
   
    func initializeCommunication() {
        var recordIdMe = EVCloudData.publicDB.dao.activeUser.userRecordID.recordName
        var recordIdOther = chatWithId
        EVCloudData.publicDB.connect(Message()
            , predicate: NSPredicate(format: "From_ID in %@ AND To_ID in %@", [recordIdMe, recordIdOther], [recordIdOther, recordIdMe])!
            , filterId: dataID
            , configureNotificationInfo:{ notificationInfo in
                notificationInfo.alertBody = "%1$@ %2$@ : %3$@"
                notificationInfo.alertLocalizationArgs = ["FromFirstName", "FromLastName", "Text"]
            }, completionHandler: { results in
                NSLog("Conversation message results = \(results.count)")
                self.localData = [JSQMessage?](count:results.count, repeatedValue:nil)
                self.checkAttachedAssets(results)
                self.collectionView.reloadData()
                self.scrollToBottomAnimated(true)
            }, insertedHandler: { item in
                NSLog("Conversation message inserted \(item)")
                self.localData.insert(nil, atIndex: 0)
                if (item as Message).MessageType == MessageTypeEnum.Picture.rawValue {
                    self.getAttachment((item as Message).Asset_ID)
                }
                self.showTypingIndicator = true
                JSQSystemSoundPlayer.jsq_playMessageReceivedSound();
                self.finishReceivingMessage();
            }, updatedHandler: { item, dataIndex in
                NSLog("Conversation message updated \(item)")
                self.localData[dataIndex] = nil
            }, deletedHandler: { recordId, dataIndex in
                NSLog("Conversation message deleted : \(recordId)")
                self.localData.removeAtIndex(dataIndex)
            }, errorHandler: { error in
                Helper.showError("Could not load messages: \(error.description)")
        })
    }
    deinit {
        EVCloudData.publicDB.disconnect(dataID)
    }
    
    // Make sure that all Message attachments are saved in a local file
    func checkAttachedAssets(results:[Message]) {
        let filemanager = NSFileManager.defaultManager()
        var docDirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString
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
            var docDirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString
            var filePath =  docDirPath.stringByAppendingPathComponent("\(id).png")
            var image = (item as Asset).image()
            var myData = UIImagePNGRepresentation(image)
            myData.writeToFile(filePath, atomically:true)
            NSLog("Image downloaded to \(id).png")
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
        message.setFrom(EVCloudData.publicDB.dao.activeUser.userRecordID.recordName)
        message.FromFirstName = self.senderFirstName
        message.FromLastName = self.senderLastName
        message.setTo(chatWithId)
        message.ToFirstName = chatWithFirstName
        message.ToLastName = chatWithLastName
        message.Text = text
        EVCloudData.publicDB.saveItem(message, completionHandler: { message in
                //Helper.showStatus("Message was send...")
                self.finishSendingMessage()
            }, errorHandler: { error in
                self.finishSendingMessage()
                Helper.showError("Could not send message!  \(error.description)")
        })
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
            NSLog("Can not happen")
        }
    }
    
    func addPhoto() {
        var picker: CTAssetsPickerController = CTAssetsPickerController()
        picker.delegate = self
        picker.assetsFilter = ALAssetsFilter.allPhotos()
        self.presentViewController(picker, animated:true, completion:nil)
    }
    
    func addVideo() {
        var picker: CTAssetsPickerController = CTAssetsPickerController()
        picker.delegate = self
        picker.assetsFilter = ALAssetsFilter.allVideos()
        self.presentViewController(picker, animated:true, completion:nil)
    }
    
    func addLocation() {
        WhereAmI.sharedInstance.whereAmI({ location in
            var message = Message()
            message.setFrom(EVCloudData.publicDB.dao.activeUser.userRecordID.recordName)
            message.FromFirstName = self.senderDisplayName
            message.setTo(self.chatWithId)
            message.ToFirstName = self.chatWithFirstName
            message.ToLastName = self.chatWithLastName
            message.Text = "<location>"
            message.MessageType = MessageTypeEnum.Location.rawValue
            message.Longitude = (location.coordinate.longitude as Double)
            message.Latitude = (location.coordinate.latitude as Double)
            EVCloudData.publicDB.saveItem(message, completionHandler: {record in
                NSLog("saveItem location Message: \(record.recordID!.recordName)");
                self.finishSendingMessage()
                }, errorHandler: {error in
                    NSLog("<--- ERROR saveItem location message");
                    Helper.showError("Could not send location message!  \(error.description)")
                    self.finishSendingMessage()
            })
        }, locationRefusedHandler: {
            Helper.showError("Location authorization has been refused, unable to  send location")
        });
    }
    
    func assetsPickerController(picker: CTAssetsPickerController!, didFinishPickingAssets assets: [AnyObject]!) {
        picker.dismissViewControllerAnimated(true, completion: nil)
        var i:Int = 0
        for asset in assets {
            i = i++
            let mediaType = (asset as ALAsset).valueForProperty("ALAssetPropertyType") as String
            if mediaType == "ALAssetTypePhoto" {
                JSQSystemSoundPlayer.jsq_playMessageSentSound()
                
                // make sure we have a file with url
                var docDirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString
                var filePath =  docDirPath.stringByAppendingPathComponent("Image_\(i).png")
                var image = getUIImageFromCTAsset(asset as ALAsset)
                var myData = UIImagePNGRepresentation(image)
                myData.writeToFile(filePath, atomically:true)
                
                
                // Create an asset object for the attached image
                var assetC = Asset()
                assetC.File = CKAsset(fileURL: NSURL(fileURLWithPath: filePath)!)
                assetC.FileName = "Image_\(i).png"
                assetC.FileType = "png"
                
                // Save the asset
                EVCloudData.publicDB.saveItem(assetC, completionHandler: {record in
                    NSLog("saveItem Asset: \(record.recordID!.recordName)");

                    // rename the image to recordId for a quick cache reference
                    let filemanager = NSFileManager.defaultManager()
                    var fromFilePath =  docDirPath.stringByAppendingPathComponent((record as Asset).FileName)
                    let toPath = docDirPath.stringByAppendingPathComponent(record.recordID!.recordName + ".png")
                    filemanager.moveItemAtPath(fromFilePath, toPath: toPath, error: nil)

                    // Create the message object that represents the asset
                    var message = Message()
                    message.setFrom(EVCloudData.publicDB.dao.activeUser.userRecordID.recordName)
                    message.FromFirstName = self.senderDisplayName
                    message.setTo(self.chatWithId)
                    message.ToFirstName = self.chatWithFirstName
                    message.ToLastName = self.chatWithLastName
                    message.Text = "<foto>"
                    message.MessageType = MessageTypeEnum.Picture.rawValue
                    message.setAsset(record.recordID!.recordName)

                    EVCloudData.publicDB.saveItem(message, completionHandler: {record in
                        NSLog("saveItem Message: \(record.recordID!.recordName)");
                        self.finishSendingMessage()
                    }, errorHandler: {error in
                        NSLog("<--- ERROR saveItem asset");
                        Helper.showError("Could not send picture message!  \(error.description)")
                        self.finishSendingMessage()
                    })
                    
                }, errorHandler: {error in
                    NSLog("<--- ERROR saveItem message");
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
    
    func getUIImageFromCTAsset(asset:ALAsset) -> UIImage {
        var representation:ALAssetRepresentation = (asset as ALAsset).defaultRepresentation();
        var img:CGImage = representation.fullResolutionImage().takeUnretainedValue()
        var scale:CGFloat = CGFloat(representation.scale())
        var orientation:UIImageOrientation = UIImageOrientation(rawValue: representation.orientation().rawValue)!
        var image:UIImage = UIImage(CGImage: img, scale: scale, orientation: orientation)!
        
        return image.resizedImageToFitInSize(CGSize(width: 640, height: 640), scaleIfSmaller: true)
    }
    
    
    // ------------------------------------------------------------------------
    // MARK: - JSQMessages CollectionView handling
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
    // MARK: - Standard CollectionView handling
    // ------------------------------------------------------------------------

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return localData.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var cell : JSQMessagesCollectionViewCell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as JSQMessagesCollectionViewCell
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
    // MARK: - CollectionView events
    // ------------------------------------------------------------------------

    override func collectionView(collectionView: JSQMessagesCollectionView!, header headerView: JSQMessagesLoadEarlierHeaderView!, didTapLoadEarlierMessagesButton sender: UIButton!) {
        NSLog("Should load earlier messages.")
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, didTapAvatarImageView avatarImageView: UIImageView!, atIndexPath indexPath: NSIndexPath!) {
        NSLog("Tapped avatar!")
    }
    override func collectionView(collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAtIndexPath indexPath: NSIndexPath!) {
        NSLog("Tapped message bubble!")
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, didTapCellAtIndexPath indexPath: NSIndexPath!, touchLocation: CGPoint) {
        NSLog("Tapped cel at \(indexPath.row)")
    }
    
    // ------------------------------------------------------------------------
    // MARK: - Data parsing: Message to JSQMessage
    // ------------------------------------------------------------------------
    
    func getMessageForId(id:Int) -> JSQMessage {
        var data:Message!
        var count : Int = 0
        let lockQueue = dispatch_queue_create("nl.evict.AppMessage.ChatLockQueue", nil)
        dispatch_sync(lockQueue) {
            count = EVCloudData.publicDB.data[self.dataID]!.count
            if self.localData.count != count {
                self.localData = [JSQMessage?](count:count, repeatedValue:nil)
            }
            if id < count {
                data = EVCloudData.publicDB.data[self.dataID]![count - id - 1] as Message
            }
        }
        if count <= id {
            return JSQMessage(senderId: self.senderId, displayName: self.senderDisplayName, text: "")
        }
        if let localMessage = self.localData[count - id - 1]  {
            return localMessage
        }
        
        var message: JSQMessage!

        // receiving or sending..
        var sender = self.senderId
        var senderName = self.senderDisplayName
        if data.From_ID != self.senderId {
            sender = self.chatWithId
            senderName = self.chatWithFirstName + " " + self.chatWithLastName
        }
        // normal or media message
        if data.MessageType == MessageTypeEnum.Text.rawValue {
            message = JSQMessage(senderId: sender, senderDisplayName: senderName,date: data.creationDate, text: data.Text)
        } else if data.MessageType == MessageTypeEnum.Location.rawValue {
            var location = CLLocation(latitude: CLLocationDegrees(data.Latitude), longitude: CLLocationDegrees(data.Longitude))
            var locationItem = JSQLocationMediaItem()
            locationItem.setLocation(location, withCompletionHandler: {
                self.collectionView.reloadData()
            })
            message = JSQMessage(senderId: sender, senderDisplayName: senderName, date:data.creationDate, media: locationItem)
        } else if data.MessageType == MessageTypeEnum.Picture.rawValue {
            var docDirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString
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
