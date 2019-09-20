//
//  MessagesTableViewController.h
//  TeleMed
//
//  Created by SolutionBuilt on 10/31/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MessagesViewController;

@interface MessagesTableViewController : UITableViewController

@property (weak) id delegate;

- (void)hideSelectedMessages:(NSArray *)messages;
- (void)removeSelectedMessages:(NSArray *)messages;
- (void)setMessagesType:(NSString *)messagesType; // Public setter; private getter
- (void)unhideSelectedMessages:(NSArray *)messages;

#ifdef MYTELEMED
	- (void)filterArchivedMessages:(NSNumber *)accountID startDate:(NSDate *)startDate endDate:(NSDate *)endDate;
	- (void)resetArchivedMessages;
#endif

@end


@protocol MessagesDelegate <NSObject>

@optional
- (void)setSelectedMessages:(NSArray *)theSelectedMessages;

@end
