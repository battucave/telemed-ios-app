//
//  ChatMessagesTableViewController.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 6/29/16.
//  Copyright © 2016 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ChatMessagesViewController;

@protocol ChatMessagesDelegate <NSObject>

@optional
- (void)setSelectedChatMessages:(NSArray *)theSelectedChatMessages;

@end

@interface ChatMessagesTableViewController : UITableViewController

@property (weak) id delegate;

- (void)reloadChatMessages;
- (void)removeSelectedChatMessages:(NSArray *)chatMessages;

@end
