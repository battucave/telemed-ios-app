//
//  NewMessageModel.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

// This file is exact duplicate of Med2Med's NewMessageModel.h

#import "Model.h"

@interface NewMessageModel : Model

@property (weak) id delegate;

// Header files are shared by all targets so have to include the method signatures used by both MyTeleMed and Med2Med.

#if MYTELEMED
	- (void)sendNewMessage:(NSString *)message accountID:(NSNumber *)accountID messageRecipientIDs:(NSArray *)messageRecipientIDs;
#endif

#if MED2MED
	- (void)sendNewMessage:(NSDictionary *)data withOrder:(NSArray *)sortedKeys;
#endif

@end


@protocol NewMessageDelegate <NSObject>

@optional
- (void)sendNewMessagePending;
- (void)sendNewMessageSuccess;
- (void)sendNewMessageError:(NSError *)error;

@end
