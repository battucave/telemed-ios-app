//
//  HospitalModel.h
//  Med2Med
//
//  Created by Shane Goodwin on 11/29/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Model.h"

@protocol HospitalDelegate <NSObject>

@required
- (void)updateHospitals:(NSArray *)hospitals;

@optional
- (void)updateHospitalsError:(NSError *)error;

@end

@interface HospitalModel : Model

@property (weak) id delegate;

@property (nonatomic) NSNumber *ID;
@property (nonatomic) NSString *Name;
@property (nonatomic) NSString *AbbreviatedName;
@property (nonatomic) NSString *MyAuthenticationStatus; // Possible values: NONE, Requested, OK, Admin, Denied, Blocked

- (void)getHospitals;
- (void)getHospitalsWithCallback:(void (^)(BOOL success, NSArray *hospitals, NSError *error))callback;
- (BOOL)isAdmin;
- (BOOL)isAuthenticated;
- (BOOL)isBlocked;
- (BOOL)isDenied;
- (BOOL)isRequested;

@end
