//
//  Model.h
//  TeleMed
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
- (void)hideActivityIndicator:(void (^)(void))callback;
- (NSError *)buildError:(NSError *)error usingData:(NSData *)data withGenericMessage:(NSString *)message andTitle:(NSString *)title;
- (void)showError:(NSError *)error;
- (void)showError:(NSError *)error withRetryCallback:(void (^)(void))callback;
- (void)showError:(NSError *)error withRetryCallback:(void (^)(void))retryCallback cancelCallback:(void (^)(void))cancelCallback;

@end
