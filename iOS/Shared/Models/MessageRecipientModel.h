//
//  MessageRecipientModel.h
//  TeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Model.h"

@interface MessageRecipientModel : Model

@property (weak) id delegate;

@property (nonatomic) NSNumber *ID;
@property (nonatomic) NSString *Name;
@property (nonatomic) NSString *FirstName; // Not passed from web service (generated during parsing)
@property (nonatomic) NSString *LastName; // Not passed from web service (generated during parsing)


#pragma mark - MyTeleMed

#ifdef MYTELEMED
@property (nonatomic) NSString *Type;

- (void)getMessageRecipientsForAccountID:(NSNumber *)accountID withCallback:(void (^)(BOOL success, NSArray *messageRecipients, NSError *error))callback;
- (void)getMessageRecipientsForMessageDeliveryID:(NSNumber *)messageDeliveryID withCallback:(void (^)(BOOL success, NSArray *messageRecipients, NSError *error))callback;
- (void)getMessageRecipientsForMessageID:(NSNumber *)messageID withCallback:(void (^)(BOOL success, NSArray *messageRecipients, NSError *error))callback;
#endif


#pragma mark - Med2Med

#ifdef MED2MED
- (void)getMessageRecipientsForAccountID:(NSNumber *)accountID slotID:(NSNumber *)slotID withCallback:(void (^)(BOOL success, NSArray *messageRecipients, NSError *error))callback;
#endif

@end
