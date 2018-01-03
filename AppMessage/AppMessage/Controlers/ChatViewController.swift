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
import SwiftLocation
import VIPhotoView
import MapKit
import UIImage_Resize
import EVCloudKitDao
import EVReflection

class ChatViewController: JSQMessagesViewController, UIActionSheetDelegate, UzysAssetsPickerControllerDelegate, MKMapViewDelegate {

    var chatWithId: String = ""
    var chatWithDisplayName: String = ""
    var chatWithFirstName: String = ""
    var chatWithLastName: String = ""
    var dataID: String = ""
    var senderFirstName: String = ""
    var senderLastName: String = ""

    var localData: [JSQMessage?] = []

    var picker: UzysAssetsPickerController = UzysAssetsPickerController()

    var recordIdMeForConnection: String = ""
    var recordIdOtherForConnection: String = ""
    var viewAppeared = false

    // Start the conversation
    func setContact(_ recordId: String, firstName: String, lastName: String) {
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
        let defaultAvatarSize: CGSize = CGSize(width: kJSQMessagesCollectionViewAvatarSizeDefault, height: kJSQMessagesCollectionViewAvatarSizeDefault)
        self.collectionView!.collectionViewLayout.incomingAvatarViewSize = defaultAvatarSize //CGSizeZero
        self.collectionView!.collectionViewLayout.outgoingAvatarViewSize = defaultAvatarSize //CGSizeZero
        self.collectionView!.collectionViewLayout.springinessEnabled = false
        self.showLoadEarlierMessagesHeader = false
        //self.inputToolbar.contentView.leftBarButtonItem

        // configure UzysAssetsPickerController
        let config = UzysAppearanceConfig()
        config.finishSelectionButtonColor = UIColor.green
        UzysAssetsPickerController.setUp(config)

        self.senderId = "~"
        self.senderDisplayName = "~"

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.viewAppeared = true
        initializeCommunication()
    }


    // ------------------------------------------------------------------------
    // MARK: - Handle Message data plus attached Assets
    // ------------------------------------------------------------------------

    func initializeCommunication(_ retryCount: Double = 1) {
        var recordIdMe: String?
        if #available(iOS 10.0, *) {
            recordIdMe = (EVCloudData.publicDB.dao.activeUser as? CKUserIdentity)?.userRecordID?.recordName
        } else {
            recordIdMe = (EVCloudData.publicDB.dao.activeUser as? CKDiscoveredUserInfo)?.userRecordID?.recordName
        }
        
        if !viewAppeared || (recordIdMeForConnection == recordIdMe && recordIdOtherForConnection == chatWithId) {
            return //Already connected or not ready yet
        }

        // Setup conversation for
        recordIdMeForConnection = recordIdMe ?? ""
        recordIdOtherForConnection = chatWithId

        // Sender settings for the component
        self.senderId = recordIdMe
        self.senderDisplayName = showNameFor(EVCloudData.publicDB.dao.activeUser)

        // The data connection to the conversation
        EVCloudData.publicDB.connect(Message(), predicate: NSPredicate(format: "From_ID in %@ AND To_ID in %@", [recordIdMeForConnection, recordIdOtherForConnection], [recordIdOtherForConnection, recordIdMeForConnection]), filterId: dataID, configureNotificationInfo: { notificationInfo in
            }, completionHandler: { results, status in
                EVLog("Conversation message results = \(results.count)")
                self.localData = [JSQMessage?](repeating: nil, count: results.count)
                self.checkAttachedAssets(results)
                self.collectionView!.reloadData()
                self.scrollToBottom(animated: true)
                return status == CompletionStatus.partialResult && results.count < 500 // Continue reading if we have less than 500 records and if there are more.
            }, insertedHandler: { item in
                EVLog("Conversation message inserted \(item)")
                self.localData.insert(nil, at: 0)
                if item.MessageType == MessageTypeEnum.Picture.rawValue {
                    self.getAttachment((item as Message).Asset_ID)
                }
                JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
                self.finishReceivingMessage()
            }, updatedHandler: { item, dataIndex in
                EVLog("Conversation message updated \(item)")
                self.localData[dataIndex] = nil
            }, deletedHandler: { recordId, dataIndex in
                EVLog("Conversation message deleted : \(recordId)")
                self.localData.remove(at: dataIndex)
            }, dataChangedHandler : {
                EVLog("Some conversation data was changed")
            }, errorHandler: { error in
                switch EVCloudKitDao.handleCloudKitErrorAs(error, retryAttempt: retryCount) {
                case .retry(let timeToWait):
                    Async.background(after: timeToWait) {
                        self.initializeCommunication(retryCount + 1)
                    }
                case .fail:
                    Helper.showError("Could not load messages: \(error.localizedDescription)")
                default: // For here there is no need to handle the .Success, and .RecoverableError
                    break
                }
        })
    }

    // Disconnect from the conversation
    deinit {
        EVCloudData.publicDB.disconnect(dataID)
    }

    // Make sure that all Message attachments are saved in a local file
    func checkAttachedAssets(_ results: [Message]) {
        let filemanager = FileManager.default
        let docDirPaths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        if docDirPaths.count > 0 {
            for item in results {
                if item.MessageType == MessageTypeEnum.Picture.rawValue {
                    let filePath =  (docDirPaths[0] as NSString).appendingPathComponent("\(item.Asset_ID).png")
                    if !filemanager.fileExists(atPath: filePath) {
                        self.getAttachment(item.Asset_ID)
                    }
                }
            }
        }
    }

    // Get an asset and save it as a file
    func getAttachment(_ id: String) {
        EVCloudData.publicDB.getItem(id, completionHandler: {item in
            let docDirPaths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
            if docDirPaths.count > 0 {
                let filePath =  (docDirPaths[0] as NSString).appendingPathComponent("\(id).png")
                if let asset = item as? Asset {
                    if let image = asset.File?.image() {
                        if let myData = UIImagePNGRepresentation(image) {
                            try? myData.write(to: URL(fileURLWithPath: filePath), options: [.atomic])
                        }
                    }
                }
            }
            EVLog("Image downloaded to \(id).png")
            for (index, _) in (self.localData).enumerated() {
                if let data: Message = EVCloudData.publicDB.data[self.dataID]![index] as? Message {
                    if data.Asset_ID == id {
                        self.localData[index] = nil
                        self.collectionView!.reloadItems(at: [IndexPath(item: index as Int, section: 0 as Int)])
                    }
                }
            }
        }, errorHandler: { error in
            Helper.showError("Could not load Asset: \(error.localizedDescription)")
        })
    }


    // ------------------------------------------------------------------------
    // MARK: - User interaction
    // ------------------------------------------------------------------------

    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        let message = Message()
        
        if #available(iOS 10.0, *) {
            message.setFromFields((EVCloudData.publicDB.dao.activeUser as? CKUserIdentity)?.userRecordID?.recordName ?? "")
        } else {
            message.setFromFields((EVCloudData.publicDB.dao.activeUser as? CKDiscoveredUserInfo)?.userRecordID?.recordName ?? "")
        }
        
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
                Helper.showError("Could not send message!  \(error.localizedDescription)")
        })
        self.finishSendingMessage()
    }

    func showActionSheet() {
        Async.main {
            let sheet = UIActionSheet(title: "Media", delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil, otherButtonTitles: "Send photo", "Send location", "Send video")
            sheet.show(from: self.inputToolbar!)
        }
    }

    // ------------------------------------------------------------------------
    // MARK: - Accessory button actions
    // ------------------------------------------------------------------------
    func actionSheet(_ actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int) {
        if buttonIndex == actionSheet.cancelButtonIndex {
            return
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
        picker.maximumNumberOfSelectionVideo = 0
        picker.maximumNumberOfSelectionPhoto = 5
        self.present(picker, animated:true, completion:nil)
    }

    func addVideo() {
        picker.delegate = self
        picker.maximumNumberOfSelectionVideo = 1
        picker.maximumNumberOfSelectionPhoto = 0
        self.present(picker, animated:true, completion:nil)
    }

    func addLocation() {
/*        do {
            try LocationManager.shared.currentLocation(.Room, timeout: 20, onSuccess: { (location) -> Void in
                if location == nil {
                    return
                }
                print("1. Location found \(location?.localizedDescription)")
                let message = Message()
                message.setFromFields(EVCloudData.publicDB.dao.activeUser.userRecordID!.recordName)
                message.FromFirstName = self.senderDisplayName
                message.setToFields(self.chatWithId)
                message.ToFirstName = self.chatWithFirstName
                message.ToLastName = self.chatWithLastName
                if location!.course < 0 {
                    message.Text = "±\(location!.verticalAccuracy)m"
                } else {
                    message.Text = "±\(location!.verticalAccuracy)m, \(Int(location!.speed/0.36)/10)kmh \(self.direction(Int(location!.course))) \(location!.course)°"
                }
                message.MessageType = MessageTypeEnum.Location.rawValue
                message.Longitude = (location!.coordinate.longitude as Double)
                message.Latitude = (location!.coordinate.latitude as Double)
                EVCloudData.publicDB.saveItem(message, completionHandler: {record in
                    EVLog("saveItem location Message: \(record.recordID.recordName)");
                    self.finishSendingMessage()
                    }, errorHandler: {error in
                        Helper.showError("Could not send location message!  \(error.localizedDescription)")
                        self.finishSendingMessage()
                })
            }, onFail: { (error) -> Void in
                Helper.showError("Location authorization has been refused, unable to  send location")
            })
        } catch {
            Helper.showError("Location authorization has been refused, unable to  send location")
        } */
    }

    // Get the direction indicator for a degree
    func direction(_ degree: Int) -> String {
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
    public func uzysAssetsPickerController(_ picker: UzysAssetsPickerController!, didFinishPickingAssets assets: [Any]!) {
        picker.dismiss(animated: true, completion: nil)
        var i: Int = 0
        for asset in assets {
            i += 1
            let mediaType = (asset as! ALAsset).value(forProperty: "ALAssetPropertyType") as! String
            if mediaType == "ALAssetTypePhoto" {
                JSQSystemSoundPlayer.jsq_playMessageSentSound()

                // make sure we have a file with url
                let docDirPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0] as NSString
                let filePath =  docDirPath.appendingPathComponent("Image_\(i).png")
                let image = getUIImageFromCTAsset(asset as! ALAsset)
                if let myData = UIImagePNGRepresentation(image) {
                    try? myData.write(to: URL(fileURLWithPath: filePath), options: [.atomic])
                }

                // Create an asset object for the attached image
                let assetC = Asset()
                assetC.File = CKAsset(fileURL: URL(fileURLWithPath: filePath))
                assetC.FileName = "Image_\(i).png"
                assetC.FileType = "png"

                // Save the asset
                EVCloudData.publicDB.saveItem(assetC, completionHandler: {record in
                    EVLog("saveItem Asset: \(record.recordID.recordName)")

                    // rename the image to recordId for a quick cache reference
                    let filemanager = FileManager.default
                    let fromFilePath =  docDirPath.appendingPathComponent(record.FileName)
                    let toPath = docDirPath.appendingPathComponent(record.recordID.recordName + ".png")
                    do {
                        try filemanager.moveItem(atPath: fromFilePath, toPath: toPath)
                    } catch {}

                    // Create the message object that represents the asset
                    let message = Message()
                    
                    if #available(iOS 10.0, *) {
                        message.setFromFields((EVCloudData.publicDB.dao.activeUser as? CKUserIdentity)?.userRecordID?.recordName ?? "")
                    } else {
                        message.setFromFields((EVCloudData.publicDB.dao.activeUser as? CKDiscoveredUserInfo)?.userRecordID?.recordName ?? "")
                    }
                   
                    message.FromFirstName = self.senderDisplayName
                    message.setToFields(self.chatWithId)
                    message.ToFirstName = self.chatWithFirstName
                    message.ToLastName = self.chatWithLastName
                    message.Text = "<foto>"
                    message.MessageType = MessageTypeEnum.Picture.rawValue
                    message.setAssetFields(record.recordID.recordName)

                    EVCloudData.publicDB.saveItem(message, completionHandler: {record in
                        EVLog("saveItem Message: \(record.recordID.recordName)")
                        self.finishSendingMessage()
                    }, errorHandler: {error in
                        Helper.showError("Could not send picture message!  \(error.localizedDescription)")
                        self.finishSendingMessage()
                    })

                }, errorHandler: {error in
                    Helper.showError("Could not send picture!  \(error.localizedDescription)")
                    self.finishSendingMessage()
                })
            } else if mediaType == "ALAssetTypeVideo" {
                Helper.showError("Sending video's is not supported yet")
            } else {
                Helper.showError("Unknown media type")
            }
        }
    }

    // The image picker will return an CTAsset. We need an UIImage.
    func getUIImageFromCTAsset(_ asset: ALAsset) -> UIImage {
        let representation: ALAssetRepresentation = (asset as ALAsset).defaultRepresentation()
        let img: CGImage = representation.fullResolutionImage().takeUnretainedValue()
        let scale: CGFloat = CGFloat(representation.scale())
        let orientation: UIImageOrientation = UIImageOrientation(rawValue: representation.orientation().rawValue)!
        let image: UIImage = UIImage(cgImage: img, scale: scale, orientation: orientation)

        return image.resizedImageToFit(in: CGSize(width: 640, height: 640), scaleIfSmaller: true)
    }

    // ------------------------------------------------------------------------
    // MARK: - Standard CollectionView handling
    // ------------------------------------------------------------------------

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return localData.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: JSQMessagesCollectionViewCell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        let message = getMessageForId((indexPath as NSIndexPath).row)
        if !message.isMediaMessage {
            if message.senderId == self.senderId {
                cell.textView!.textColor = UIColor.black
            } else {
                cell.textView!.textColor = UIColor.white
            }
            //cell.textView!.linkTextAttributes = [NSAttributedStringKey.foregroundColor.rawValue : cell.textView!.textColor!, NSAttributedStringKey.underlineStyle.rawValue : NSUnderlineStyle.styleSingle.rawValue]
        }
        return cell
    }

    // ------------------------------------------------------------------------
    // MARK: - JSQMessagesCollectionView handling
    // ------------------------------------------------------------------------

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return getMessageForId(indexPath.row)
    }

    //CellTopLabel
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        let message = getMessageForId(indexPath.row)
        return JSQMessagesTimestampFormatter.shared().attributedTimestamp(for: message.date)
    }
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAt indexPath: IndexPath!) -> CGFloat {
        return kJSQMessagesCollectionViewCellLabelHeightDefault
    }

    //messageBubbleImageDataForItemAtIndexPath
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = getMessageForId(indexPath.row)
        let bubbleFactory = JSQMessagesBubbleImageFactory()
        if message.senderId == self.senderId {
            return bubbleFactory!.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
        }
        return bubbleFactory!.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleGreen())
    }

    // MessageBubbleTopLabel
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        let message = getMessageForId(indexPath.row)
        if message.senderId == self.senderId {
            return nil
        }
        if indexPath.row > 1 {
            let previousMessage = getMessageForId(indexPath.row - 1)
            if previousMessage.senderId == message.senderId {
                return nil
            }
        }
        return NSAttributedString(string: message.senderDisplayName)
    }

    // MessageBubbleTopLabel height
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAt indexPath: IndexPath!) -> CGFloat {
        let message = getMessageForId(indexPath.row)
        if message.senderId == self.senderId {
            return 0
        }
        if indexPath.row > 1 {
            let previousMessage = getMessageForId(indexPath.row - 1)
            if previousMessage.senderId == message.senderId {
                return 0
            }
        }
        return kJSQMessagesCollectionViewCellLabelHeightDefault
    }

    
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        let message = getMessageForId(indexPath.row)
        var initials: String = ""

         if message.senderId == self.senderId {
            var firstName: String = ""
            var lastName: String = ""
            
            if #available(iOS 10.0, *) {
                firstName = (EVCloudData.publicDB.dao.activeUser as? CKUserIdentity)?.nameComponents?.givenName ?? ""
                lastName = (EVCloudData.publicDB.dao.activeUser as? CKUserIdentity)?.nameComponents?.familyName ?? ""
            } else {
                firstName = (EVCloudData.publicDB.dao.activeUser as? CKDiscoveredUserInfo)?.firstName ?? ""
                lastName    = (EVCloudData.publicDB.dao.activeUser as? CKDiscoveredUserInfo)?.lastName ?? ""
            }

            initials = "\(String(describing: firstName.characters.first)) \(String(describing: lastName.characters.first))"
            //initials = "\(Array(arrayLiteral: firstName)[0]) \(Array(arrayLiteral: lastName)[0])"
        } else {
            //initials = "\(Array(arrayLiteral: chatWithFirstName)[0]) \(Array(arrayLiteral: chatWithLastName)[0])"
            initials = "\(String(describing: chatWithFirstName.characters.first)) \(String(describing: chatWithLastName.characters.first))"
        }

        let size: CGFloat = 14
        let avatar = JSQMessagesAvatarImageFactory.avatarImage(withUserInitials: initials, backgroundColor: UIColor.lightGray, textColor: UIColor.white, font: UIFont.systemFont(ofSize: size), diameter: 30)
        return avatar
    }


    // CellBottomLabel
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        return nil
    }

    // CellBottomLabel height
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAt indexPath: IndexPath!) -> CGFloat {
        return 0
    }

    // ------------------------------------------------------------------------
    // MARK: - JSQMessagesCollectionView events
    // ------------------------------------------------------------------------

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, header headerView: JSQMessagesLoadEarlierHeaderView!, didTapLoadEarlierMessagesButton sender: UIButton!) {
        EVLog("Should load earlier messages.")
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapAvatarImageView avatarImageView: UIImageView!, at indexPath: IndexPath!) {
        EVLog("Tapped avatar!")
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAt indexPath: IndexPath!) {
        EVLog("Tapped message bubble!")
        let (data, _) = getDataForId(indexPath.row)

        let message = getMessageForId(indexPath.row)
        let viewController = UIViewController()
        viewController.view.backgroundColor = UIColor.white

        if data.MessageType == MessageTypeEnum.Picture.rawValue {
            viewController.title = "Photo"
            let photoView = VIPhotoView(frame:self.navigationController!.view.bounds, andImage:(message.media as? JSQPhotoMediaItem)?.image)
            photoView?.autoresizingMask = UIViewAutoresizing(rawValue:1 << 6 - 1)
            viewController.view.addSubview(photoView!)
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

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        mapView.setRegion(MKCoordinateRegionMakeWithDistance(view.annotation!.coordinate, 1000, 1000), animated: true)
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapCellAt indexPath: IndexPath!, touchLocation: CGPoint) {
        EVLog("Tapped cel at \(indexPath.row)")
    }

    // ------------------------------------------------------------------------
    // MARK: - Data parsing: Message to JSQMessage
    // ------------------------------------------------------------------------

    func getDataForId(_ id: Int) -> (Message, Int) {
        var data: Message!
        var count: Int = 0
        let lockQueue = DispatchQueue(label: "nl.evict.AppMessage.ChatLockQueue", attributes: [])
        lockQueue.sync {
            count = EVCloudData.publicDB.data[self.dataID]!.count
            if self.localData.count != count {
                self.localData = [JSQMessage?](repeating: nil, count: count)
            }
            if id < count {
                data = EVCloudData.publicDB.data[self.dataID]![count - id - 1] as! Message
            } else {
                data = Message()
            }
        }
        return (data, count)
    }

    func getMessageForId(_ id: Int) -> JSQMessage {
        // Get the CloudKit Message data plus count
        let (data, count) = getDataForId(id)

        // Should never happen... just here to prevent a crash if it does happen.
        if count <= id {
            return JSQMessage(senderId: self.senderId, displayName: self.senderDisplayName, text: "")
        }

        // The JSQMessage was already created before
        if let localMessage = self.localData[count - id - 1] {
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
            message = JSQMessage(senderId: sender, senderDisplayName: senderName, date: data.creationDate, text: data.Text)
        } else if data.MessageType == MessageTypeEnum.Location.rawValue {
            let location = CLLocation(latitude: CLLocationDegrees(data.Latitude), longitude: CLLocationDegrees(data.Longitude))
            let locationItem = JSQLocationMediaItem()
            locationItem.setLocation(location, withCompletionHandler: {
                self.collectionView!.reloadData()
//                self.collectionView.reloadItemsAtIndexPaths([NSIndexPath(forItem: id as Int, inSection: 0 as Int)])
//                self.collectionView.reloadItemsAtIndexPaths(self.collectionView.indexPathsForVisibleItems())

            })
            message = JSQMessage(senderId: sender, senderDisplayName: senderName, date:data.creationDate, media: locationItem)
        } else if data.MessageType == MessageTypeEnum.Picture.rawValue {
            let docDirPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0] as NSString
            let filePath =  docDirPath.appendingPathComponent(data.Asset_ID + ".png")
            let url = URL(fileURLWithPath: filePath)
            if let mediaData = try? Data(contentsOf: url) {
                let image = UIImage(data: mediaData)
                let photoItem = JSQPhotoMediaItem(image: image)
                message = JSQMessage(senderId: sender, senderDisplayName: senderName, date:data.creationDate, media: photoItem)
            } else {
                //url = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("image-not-available", ofType: "jpg")!)
                //mediaData = NSData(contentsOfURL: url!)
                message = JSQMessage(senderId: sender, senderDisplayName: senderName, date:data.creationDate, media: JSQPhotoMediaItem())

            }
        }
        localData[count - id - 1] = message
        return message
    }

}
