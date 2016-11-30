//
//  MessagesTableViewController.h
//  MyTeleMed
//
//  Created by SolutionBuilt on 10/31/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MessagesViewController;

@protocol MessagesDelegate <NSObject>

@optional
- (void)setSelectedMessages:(NSArray *)theSelectedMessages;

@end

@interface MessagesTableViewController : UITableViewController

@property (weak) id delegate;

- (void)initMessagesWithType:(int)newMessagesType;
- (void)filterActiveMessages:(int)newPriorityFilter;
- (void)filterArchiveMessages:(NSNumber *)accountID startDate:(NSDate *)startDate endDate:(NSDate *)endDate;
- (void)hideSelectedMessages:(NSArray *)messages;
- (void)reloadMessages;
- (void)removeSelectedMessages:(NSArray *)messages;
- (void)resetMessages;
- (void)unHideSelectedMessages:(NSArray *)messages;

@end
