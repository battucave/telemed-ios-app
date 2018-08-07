//
//  NewMessageModel.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

// This file is exact duplicate of MyTeleMed's NewMessageModel.h

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

// Header files are shared by all targets so have to include the method signatures used by both MyTeleMed and Med2Med.

#ifdef MYTELEMED
	- (void)sendNewMessage:(NSString *)message accountID:(NSNumber *)accountID messageRecipientIDs:(NSArray *)messageRecipientIDs;
#endif

#ifdef MED2MED
	- (void)sendNewMessage:(NSDictionary *)data;
#endif

@end
