//
//  MessageRecipientModel.h
//  TeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Model.h"

@protocol MessageRecipientDelegate <NSObject>

@required
- (void)updateMessageRecipients:(NSMutableArray *)newMessageRecipients;

@optional
- (void)updateMessageRecipientsError:(NSError *)error;

@end

@interface MessageRecipientModel : Model

@property (weak) id delegate;

@property (nonatomic) NSNumber *ID;
@property (nonatomic) NSString *Name;
@property (nonatomic) NSString *FirstName; // Not passed from web service (generated during parsing)
@property (nonatomic) NSString *LastName; // Not passed from web service (generated during parsing)


#pragma mark - MyTeleMed

#ifdef MYTELEMED
	- (void)getMessageRecipientsForAccountID:(NSNumber *)accountID;
	- (void)getMessageRecipientsForMessageDeliveryID:(NSNumber *)messageDeliveryID;
	- (void)getMessageRecipientsForMessageID:(NSNumber *)messageID;
#endif


#pragma mark - MedToMed

#ifdef MEDTOMED
	- (void)getMessageRecipientsForAccountID:(NSNumber *)accountID slotID:(NSNumber *)slotID;
#endif

@end
