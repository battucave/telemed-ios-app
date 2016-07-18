//
//  Model.h
//  MyTeleMed
//
//  Created by SolutionBuilt on 11/13/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TeleMedHTTPRequestOperationManager.h"

@interface Model : NSObject

@property (nonatomic) TeleMedHTTPRequestOperationManager *operationManager;


- (void)showActivityIndicator;
- (void)showActivityIndicator:(NSString *)message;
- (void)hideActivityIndicator;
- (NSError *)buildError:(NSError *)error usingData:(NSData *)data withGenericMessage:(NSString *)message;
- (void)showOfflineError;

@end
