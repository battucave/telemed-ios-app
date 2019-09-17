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
- (void)initMessagesWithType:(NSString *)newMessagesType;
- (void)reloadMessages;
- (void)removeSelectedMessages:(NSArray *)messages;
- (void)unHideSelectedMessages:(NSArray *)messages;

#ifdef MYTELEMED
	- (void)filterArchiveMessages:(NSNumber *)accountID startDate:(NSDate *)startDate endDate:(NSDate *)endDate;
	- (void)resetMessages;
#endif

@end


@protocol MessagesDelegate <NSObject>

@optional
- (void)setSelectedMessages:(NSArray *)theSelectedMessages;

@end
