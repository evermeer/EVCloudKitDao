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
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.senderId = EVCloudKitDao.instance.activeUser?.userRecordID.recordName
        self.senderDisplayName = "\(EVCloudKitDao.instance.activeUser?.firstName)  \(EVCloudKitDao.instance.activeUser?.lastName)"
        
        // configure JSQMessagesViewController
        self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero
        self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero
        self.showLoadEarlierMessagesHeader = true
    }
        
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.collectionView.collectionViewLayout.springinessEnabled = true
    }

    
    func initializeCommunication() {
        EVCloudData.instance.connect(Message()
            , predicate: NSPredicate(format: "(From == %@ AND To = %@) OR (From == %@ AND To = %@)", chatWith.userRecordID, EVCloudKitDao.instance.activeUser.userRecordID, EVCloudKitDao.instance.activeUser.userRecordID, chatWith.userRecordID)!
            , filterId: dataID
            , configureNotificationInfo:{ notificationInfo in
                notificationInfo.alertBody = "New Message record"
                notificationInfo.shouldSendContentAvailable = true
            }, completionHandler: { results in
                NSLog("results = \(results.count)")
            }, insertedHandler: { item in
                NSLog("inserted \(item)")
                self.showTypingIndicator = true
                self.scrollToBottomAnimated(true)
                JSQSystemSoundPlayer.jsq_playMessageReceivedSound();
                var message = JSQMessage(senderId: self.chatWith.userRecordID.recordName, displayName: self.chatWith.firstName + " " + self.chatWith.lastName , text: "Message")
                //[self.demoData.messages addObject:newMessage];
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
        EVCloudData.instance.saveItem(message, completionHandler: { message in
                self.finishSendingMessage()
            }, errorHandler: { error in
            Helper.showError("Could not send message!  \(error.description)")
                self.finishSendingMessage()
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
    
    //CellTopLabel
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        var message = getMessageForId(indexPath.row)
        return JSQMessagesTimestampFormatter.sharedFormatter().attributedTimestampForDate(message.date)
    }
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        return kJSQMessagesCollectionViewCellLabelHeightDefault
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
    // MARK: - Data parsing
    // ------------------------------------------------------------------------
    
    func getMessageForId(id:Int) -> JSQMessage {
        var data:Message = EVCloudData.instance.data[dataID]![id] as Message
        var message = JSQMessage(senderId: self.chatWith.userRecordID.recordName, displayName: self.chatWith.firstName + " " + self.chatWith.lastName , text: data.Text)
        return message;
    }
}