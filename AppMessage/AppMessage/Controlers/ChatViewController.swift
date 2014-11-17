//
//  ChatViewController.swift
//
//  Created by Edwin Vermeer on 11/14/14.
//  Copyright (c) 2014. All rights reserved.
//

import Foundation

class ChatViewController : JSQMessagesViewController {
    
    var chatWith : AnyObject!
    func setContact(contact: AnyObject) {
        chatWith = contact
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.senderId = "edwin@evict.nl"
        self.senderDisplayName = "Edwin Vermeer"
        
        // configure JSQMessagesViewController
        self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero
        self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero
        self.showLoadEarlierMessagesHeader = true
    }
    
    override func viewDidAppear(animated: Bool) {
        self.collectionView.collectionViewLayout.springinessEnabled = true
    }
    
    func incommingMessage() {
        self.showTypingIndicator = true
        
        scrollToBottomAnimated(true)
        JSQSystemSoundPlayer.jsq_playMessageReceivedSound();

        var message = JSQMessage(senderId: "x", displayName: "From X", text: "Message")
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