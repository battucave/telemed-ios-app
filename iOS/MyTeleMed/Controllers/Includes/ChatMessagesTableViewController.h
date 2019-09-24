//
//  ChatMessagesTableViewController.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 6/29/16.
//  Copyright © 2016 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ChatMessagesViewController;

@interface ChatMessagesTableViewController : UITableViewController

@property (weak) id delegate;
@property (nonatomic) NSArray *chatMessages;

- (void)hideSelectedChatMessages:(NSArray *)chatMessages;
- (void)removeSelectedChatMessages:(NSArray *)chatMessages;
- (void)unhideSelectedChatMessages:(NSArray *)chatMessages;

@end


@protocol ChatMessagesDelegate <NSObject>

@optional
- (void)setSelectedChatMessages:(NSArray *)selectedChatMessages;

@end
