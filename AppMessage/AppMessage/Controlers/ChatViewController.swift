//
//  ChatViewController.swift
//
//  Created by Edwin Vermeer on 11/14/14.
//  Copyright (c) 2014. All rights reserved.
//

import Foundation
import CloudKit

class ChatViewController : JSQMessagesViewController {
    
    var chatWith : CKDiscoveredUserInfo!
    func setContact(contact: CKDiscoveredUserInfo) {
        chatWith = contact
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
        self.collectionView.collectionViewLayout.springinessEnabled = true
    }

    
    func initializeCommunication() {
        EVCloudData.instance.connect(Message()
            , predicate: NSPredicate(format: "(From == %@ AND To = %@) OR (From == %@ AND To = %@)", chatWith.userRecordID, EVCloudKitDao.instance.activeUser.userRecordID, EVCloudKitDao.instance.activeUser.userRecordID, chatWith.userRecordID)!
            , filterId: "Message_all"
            , configureNotificationInfo:{ notificationInfo in
                notificationInfo.alertBody = "New Message record"
                notificationInfo.shouldSendContentAvailable = true
            }, completionHandler: { results in
                NSLog("results = \(results.count)")
            }, insertedHandler: { item in
                NSLog("inserted \(item)")
            }, updatedHandler: { item in
                NSLog("updated \(item)")
            }, deletedHandler: { recordId in
                NSLog("deleted : \(recordId)")
            }, errorHandler: { error in
                Helper.showError("Could not load messages: \(error.description)")
        })
    }

    deinit {
        EVCloudData.instance.disconnect("Message_\(chatWith.userRecordID.recordName)")
    }
    
    func incommingMessage() {
        self.showTypingIndicator = true
        
        scrollToBottomAnimated(true)
        JSQSystemSoundPlayer.jsq_playMessageReceivedSound();

        var message = JSQMessage(senderId: chatWith.userRecordID.recordName, displayName: chatWith.firstName + " " + chatWith.lastName , text: "Message")
        //[self.demoData.messages addObject:newMessage];

        finishReceivingMessage();
    }

    
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        var message = JSQMessage(senderId: "Z", senderDisplayName: "From Z", date: date, text: text)
        //[self.demoData.messages addObject:message];
        finishSendingMessage()
    }
    
    override func didPressAccessoryButton(sender: UIButton!) {
    
    }
}