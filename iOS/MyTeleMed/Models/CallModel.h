//
//  CallModel.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Model.h"

@protocol CallDelegate <NSObject>

@optional
- (void)callTeleMedSuccess;
- (void)callTeleMedError:(NSError *)error;
- (void)callSenderSuccess;
- (void)callSenderError:(NSError *)error;

@end

@interface CallModel : Model

@property (weak) id delegate;

- (void)callTeleMed;
- (void)callSenderForMessage:(NSNumber *)messageID recordCall:(NSString *)recordCall;

@end
