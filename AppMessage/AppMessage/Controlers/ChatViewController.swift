//
//  ChatViewController.swift
//
//  Created by Edwin Vermeer on 11/14/14.
//  Copyright (c) 2014. All rights reserved.
//

import Foundation
import CloudKit

class ChatViewController : JSQMessagesViewController, UIActionSheetDelegate {
    
    var chatWith : CKDiscoveredUserInfo!
    var dataID : String = ""
    func setContact(contact: CKDiscoveredUserInfo) {
        chatWith = contact
        dataID =  "Message_\(chatWith.userRecordID.recordName)"
        initializeCommunication()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.senderId = EVCloudKitDao.instance.activeUser?.userRecordID.recordName
        self.senderDisplayName = "\(EVCloudKitDao.instance.activeUser?.firstName)  \(EVCloudKitDao.instance.activeUser?.lastName)"
        
        // configure JSQMessagesViewController
        var defaultAvatarSize: CGSize = CGSizeMake(kJSQMessagesCollectionViewAvatarSizeDefault, kJSQMessagesCollectionViewAvatarSizeDefault)
        self.collectionView.collectionViewLayout.incomingAvatarViewSize = defaultAvatarSize //CGSizeZero
        self.collectionView.collectionViewLayout.outgoingAvatarViewSize = defaultAvatarSize //CGSizeZero
        self.showLoadEarlierMessagesHeader = false
        
    }
        
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.collectionView.collectionViewLayout.springinessEnabled = true
    }

    
    func initializeCommunication() {
        var recordIdMe = EVCloudKitDao.instance.activeUser.userRecordID.recordName
        var recordIdOther = chatWith.userRecordID.recordName
        EVCloudData.instance.connect(Message()
            , predicate: NSPredicate(format: "From_ID in %@ AND To_ID in %@", [recordIdMe, recordIdOther], [recordIdOther, recordIdMe])!
            , filterId: dataID
            , configureNotificationInfo:{ notificationInfo in
                notificationInfo.alertBody = "New Message record"
                notificationInfo.shouldSendContentAvailable = true
            }, completionHandler: { results in
                NSLog("results = \(results.count)")
                self.collectionView.reloadData()
                self.scrollToBottomAnimated(true)
            }, insertedHandler: { item in
                NSLog("inserted \(item)")
                self.showTypingIndicator = true
                self.scrollToBottomAnimated(true)
                JSQSystemSoundPlayer.jsq_playMessageReceivedSound();
                self.finishReceivingMessage();
            }, updatedHandler: { item in
                NSLog("updated \(item)")
            }, deletedHandler: { recordId in
                NSLog("deleted : \(recordId)")
            }, errorHandler: { error in
                Helper.showError("Could not load messages: \(error.description)")
        })
    }
    deinit {
        EVCloudData.instance.disconnect(dataID)
    }
    

    // ------------------------------------------------------------------------
    // MARK: - User interaction
    // ------------------------------------------------------------------------
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        //var message = JSQMessage(senderId: "Z", senderDisplayName: "From Z", date: date, text: text)
        //[self.demoData.messages addObject:message];
        var message = Message()
        message.setFrom(EVCloudKitDao.instance.activeUser.userRecordID.recordName)
        message.setTo(chatWith.userRecordID.recordName)
        message.Text = text
        EVCloudData.instance.saveItem(message, completionHandler: { message in
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
    
    func actionSheet(actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int) {
        if buttonIndex == actionSheet.cancelButtonIndex {
            return;
        }
        switch buttonIndex {
        case 0:
            NSLog("Add photo")
        case 1:
            NSLog("Add location")
        case 2:
            NSLog("Add video")
        default:
            NSLog("Can not happen")
        }
        JSQSystemSoundPlayer.jsq_playMessageSentSound()        
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
    
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        var message = getMessageForId(indexPath.row)
        var initials : String = ""
        if message.senderId == self.senderId {
            var l = Array(EVCloudKitDao.instance.activeUser.lastName)[0]
            initials = "\(Array(EVCloudKitDao.instance.activeUser.firstName)[0]) \(Array(EVCloudKitDao.instance.activeUser.lastName)[0])"
        } else {
            initials = "\(Array(chatWith.firstName)[0]) \(Array(chatWith.lastName)[0])"
        }
        var size:CGFloat = 14
        var avatar = JSQMessagesAvatarImageFactory.avatarImageWithUserInitials(initials, backgroundColor: UIColor.lightGrayColor(), textColor: UIColor.whiteColor(), font: UIFont.systemFontOfSize(size), diameter: 30)
        return avatar
    }
    
    // CellBottomLabel
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        return nil
    }
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        return 0
    }
    

    // ------------------------------------------------------------------------
    // MARK: - Standard CollectionView handling
    // ------------------------------------------------------------------------

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if EVCloudData.instance.data[dataID] == nil {
            return 0
        }
        return EVCloudData.instance.data[dataID]!.count
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
        var data:Message = EVCloudData.instance.data[dataID]![EVCloudData.instance.data[dataID]!.count - id - 1] as Message
        var message: JSQMessage!
        if data.From_ID == self.senderId {
            message = JSQMessage(senderId: self.senderId, displayName: self.senderDisplayName , text: data.Text)
        } else {
            message = JSQMessage(senderId: self.chatWith.userRecordID.recordName, displayName: self.chatWith.firstName + " " + self.chatWith.lastName , text: data.Text)
        }

        return message;
    }
}
