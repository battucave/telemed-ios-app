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

- (void)initMessagesWithType:(NSString *)newMessagesType;
- (void)filterArchiveMessages:(NSNumber *)accountID startDate:(NSDate *)startDate endDate:(NSDate *)endDate;
- (void)hideSelectedMessages:(NSArray *)messages;
- (void)reloadMessages;
- (void)removeSelectedMessages:(NSArray *)messages;
- (void)resetMessages;
- (void)unHideSelectedMessages:(NSArray *)messages;

@end


@protocol MessagesDelegate <NSObject>

@optional
- (void)setSelectedMessages:(NSArray *)theSelectedMessages;

@end
