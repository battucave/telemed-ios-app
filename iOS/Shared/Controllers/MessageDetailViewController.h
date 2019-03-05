//
//  MessageDetailViewController.h
//  TeleMed
//
//  Created by SolutionBuilt on 11/5/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#ifdef MYTELEMED
	#import "MessageDetailParentViewController.h"

	@interface MessageDetailViewController : MessageDetailParentViewController <UITableViewDelegate, UITableViewDataSource, UITextViewDelegate>

#else
	#import "CoreViewController.h"
	#import "MessageProtocol.h"

	@interface MessageDetailViewController : CoreViewController <UITableViewDelegate, UITableViewDataSource, UITextViewDelegate>

	@property (nonatomic) id <MessageProtocol> message;
	@property (nonatomic) NSNumber *messageID; // Sent message received from push notification
	@property (nonatomic) NSNumber *messageDeliveryID; // Not used; compatibility with MyTeleMed
	@property (nonatomic) NSString *messageType; // Active, Archived, Sent

	// Duplicate properties contained in MessageDetailParentViewController
	@property (nonatomic) NSArray *messageEvents;
	@property (nonatomic) NSMutableArray *filteredMessageEvents;

	@property (weak, nonatomic) IBOutlet UIButton *buttonArchive;
	@property (weak, nonatomic) IBOutlet UIButton *buttonForward;
	@property (weak, nonatomic) IBOutlet UIButton *buttonReturnCall;
	@property (weak, nonatomic) IBOutlet UIView *viewPriority;

	@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintButtonForwardLeadingSpace;
	@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintButtonForwardTrailingSpace;
	@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintButtonHistoryLeadingSpace;
	@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintButtonHistoryTrailingSpace;
#endif

@end

