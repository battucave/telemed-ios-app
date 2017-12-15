//
//  NewMessageModel.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Model.h"

@protocol NewMessageDelegate <NSObject>

@optional
- (void)sendMessagePending;
- (void)sendMessageSuccess;
- (void)sendMessageError:(NSError *)error;

@end

@interface NewMessageModel : Model

@property (weak) id delegate;
@property (nonatomic) BOOL Success;
@property (nonatomic) NSString *Message;

- (void)sendNewMessage:(NSDictionary *)data;

// Header files are shared by both MedToMed and MyTeleMed targets so have to include MyTeleMed's method as well.
#ifdef MYTELEMED
	- (void)sendNewMessage:(NSString *)message accountID:(NSNumber *)accountID messageRecipientIDs:(NSArray *)messageRecipientIDs;
#endif

@end
