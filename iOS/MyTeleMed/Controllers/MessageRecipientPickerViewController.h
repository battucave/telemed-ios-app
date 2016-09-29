//
//  MessageRecipientPickerViewController.h
//  MyTeleMed
//
//  Created by SolutionBuilt on 11/7/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreViewController.h"
#import "AccountModel.h"
#import "MessageModel.h"

@interface MessageRecipientPickerViewController : CoreViewController <UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) MessageModel *message;
@property (nonatomic) AccountModel *selectedAccount;
@property (nonatomic) NSMutableArray *selectedMessageRecipients;
@property (nonatomic) NSString *messageRecipientType;

- (void)updateChatParticipants:(NSMutableArray *)newRecipients;
- (void)updateChatParticipantsError:(NSError *)error;
- (void)updateMessageRecipients:(NSMutableArray *)newMessageRecipients;
- (void)updateMessageRecipientsError:(NSError *)error;

@end
