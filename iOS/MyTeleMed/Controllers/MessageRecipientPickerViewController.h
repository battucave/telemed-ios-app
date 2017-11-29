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
#import "MessageProtocol.h"

@interface MessageRecipientPickerViewController : CoreViewController <UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) id <MessageProtocol> message;
@property (nonatomic) AccountModel *selectedAccount;
@property (nonatomic) NSMutableArray *selectedMessageRecipients;
@property (nonatomic) NSString *messageRecipientType;
@property (nonatomic) BOOL isGroupChat; // Only used for chat participants

@end
