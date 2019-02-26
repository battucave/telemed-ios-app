//
//  CallModel.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "Model.h"

@interface CallModel : Model

@property (weak) id delegate;

- (void)callTeleMed;
- (void)callSenderForMessage:(NSNumber *)messageID recordCall:(NSString *)recordCall; // NOTE: recordCall option is no longer used

@end


@protocol CallDelegate <NSObject>

@optional
- (void)callTeleMedPending;
- (void)callTeleMedSuccess;
- (void)callTeleMedError:(NSError *)error;
- (void)callSenderPending;
- (void)callSenderSuccess;
- (void)callSenderError:(NSError *)error;

@end
