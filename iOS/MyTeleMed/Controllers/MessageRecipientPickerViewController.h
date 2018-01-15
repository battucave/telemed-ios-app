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
#import "MessageStub.h"

@interface MessageRecipientPickerViewController : CoreViewController <UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) MessageStub *message;
@property (nonatomic) AccountModel *selectedAccount;
@property (nonatomic) NSMutableArray *selectedMessageRecipients;
@property (nonatomic) NSString *messageRecipientType;
@property (nonatomic) BOOL isGroupChat; // Only used for Chat Participants

@end
