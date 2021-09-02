//
//  MessagesTableViewController.h
//  TeleMed
//
//  Created by SolutionBuilt on 10/31/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MessagesViewController;

@interface MessagesTableViewController : UITableViewController<UITableViewDataSourcePrefetching>

@property (weak) id delegate;

- (void)setMessagesType:(NSString *)messagesType; // Public setter; private getter

#if MYTELEMED
	- (void)filterArchivedMessages:(NSNumber *)accountID startDate:(NSDate *)startDate endDate:(NSDate *)endDate;
	- (void)reloadMessages;
	- (void)removeSelectedMessages:(NSArray *)messages isPending:(BOOL)isPending;
#endif

@end


#if MYTELEMED // Only implemented by MessagesViewController
	@protocol MessagesDelegate <NSObject>

	@optional
	- (void)setSelectedMessages:(NSArray *)theSelectedMessages;

	@end
#endif
