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
#import "OnCallSlotModel.h"

@interface MessageRecipientPickerViewController : CoreViewController <UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) AccountModel *selectedAccount;

@property (nonatomic) NSString *messageRecipientType;
@property (nonatomic) NSMutableArray *selectedMessageRecipients;


#ifdef MEDTOMED
	@property (weak) id delegate;

	@property (nonatomic) OnCallSlotModel *selectedOnCallSlot;

	@property (nonatomic) NSMutableDictionary *formValues; // Store form values to be passed to next screen

#else
	@property (nonatomic) id <MessageProtocol> message;

	@property (nonatomic) BOOL isGroupChat; // Only used for chat participants
#endif

@end
