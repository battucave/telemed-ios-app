//
//  MessageRecipientPickerViewController.h
//  MyTeleMed
//
//  Created by SolutionBuilt on 11/7/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "CoreViewController.h"
#import "MessageProtocol.h"
#import "AccountModel.h"
#import "OnCallSlotModel.h"

#ifdef MYTELEMED
	#import "MessageRecipientModel.h"
#endif

@interface MessageRecipientPickerViewController : CoreViewController <UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating, UITableViewDataSource, UITableViewDelegate>

@property (weak) id delegate;

@property (nonatomic) AccountModel *selectedAccount;

@property (nonatomic) NSArray *messageRecipients;
@property (nonatomic) NSMutableArray *selectedMessageRecipients;
@property (nonatomic) OnCallSlotModel *selectedOnCallSlot;


#ifdef MED2MED
	@property (nonatomic) NSMutableDictionary *formValues; // Store form values to be passed to next screen

#else
	@property (nonatomic) BOOL isGroupChat; // Only used for chat participants
	@property (nonatomic) NSString *messageRecipientType; // Chat, Forward, New, or Redirect
#endif

@end


#ifdef MYTELEMED
	@protocol MessageRedirectRecipientDelegate <NSObject>

	@optional
	- (void)escalateMessageWithRecipient:(MessageRecipientModel *)messageRecipient;
	- (void)redirectMessageToRecipient:(MessageRecipientModel *)messageRecipient onCallSlot:(OnCallSlotModel *)onCallSlot;

	@end
#endif
