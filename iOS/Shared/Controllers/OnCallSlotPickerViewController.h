//
//  OnCallSlotPickerViewController.h
//  Med2Med
//
//  Created by Shane Goodwin on 4/16/18.
//  Copyright © 2018 SolutionBuilt. All rights reserved.
//

#import "CoreViewController.h"
#import "OnCallSlotModel.h"

#if MED2MED
	#import "AccountModel.h"
#endif

@interface OnCallSlotPickerViewController : CoreViewController <UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating, UITableViewDataSource, UITableViewDelegate>

@property (weak) id delegate;

@property (nonatomic) NSArray *onCallSlots;
@property (nonatomic) OnCallSlotModel *selectedOnCallSlot;

#if MED2MED
	@property (nonatomic) AccountModel *selectedAccount;

	@property (nonatomic) NSMutableDictionary *formValues; // Store form values to be passed to next screen
	@property (nonatomic) NSMutableArray *selectedMessageRecipients; // Only used if user returns back to this screen after selecting message recipients

#elif defined MYTELEMED
	@property (nonatomic) NSArray *messageRecipients;
#endif

@end


#if MYTELEMED
	@protocol MessageRedirectOnCallSlotDelegate <NSObject>

	@optional
	- (void)redirectMessageToOnCallSlot:(OnCallSlotModel *)onCallSlot;

	@end
#endif
