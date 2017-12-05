//
//  SSOProviderModel.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 6/18/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SSOProviderModel : NSObject

@property (weak) id delegate;

@property (nonatomic) NSString *Name;

- (void)validate:(NSString *)newName withCallback:(void(^)(BOOL success, NSError *error))callback;

@end
