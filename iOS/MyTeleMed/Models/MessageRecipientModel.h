//
//  MessageRecipientModel.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Model.h"

@protocol MessageRecipientDelegate <NSObject>

@required
- (void)updateMessageRecipients:(NSMutableArray *)newRecipients;
- (void)updateMessageRecipientsError:(NSError *)error;

@end

@interface MessageRecipientModel : Model

@property (weak) id delegate;

@property (nonatomic) NSNumber *ID;
@property (nonatomic) NSString *Name;
@property (nonatomic) NSString *FirstName;
@property (nonatomic) NSString *LastName;

- (void)getNewMessageRecipients:(NSNumber *)accountID;
- (void)getForwardMessageRecipients:(NSNumber *)messageID;

@end
