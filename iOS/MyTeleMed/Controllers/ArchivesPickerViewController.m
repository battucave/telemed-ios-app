//
//  ArchivesPickerViewController.m
//  MyTeleMed
//
//  Created by SolutionBuilt on 11/4/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "ArchivesPickerViewController.h"
#import "AccountModel.h"

@interface ArchivesPickerViewController ()

@property (nonatomic) AccountModel *accountModel;

@property (weak, nonatomic) IBOutlet UIButton *buttonAccount;
@property (weak, nonatomic) IBOutlet UIButton *buttonDate;
@property (weak, nonatomic) IBOutlet UIPickerView *pickerViewDefault;

@property (nonatomic) int pickerType; // 0 = Dates, 1 = Accounts;
@property (nonatomic) NSMutableArray *accounts;
@property (nonatomic) NSArray *dates;

@end

@implementation ArchivesPickerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// Initialize date options
	[self setDates:[[NSArray alloc] initWithObjects:@"Last 7 Days", @"Last 15 Days", @"Last 30 Days", @"Last 60 Days", nil]];
	
	// Initialize accounts
	self.accounts = [[NSMutableArray alloc] init];
	
	// Initialize account model
	[self setAccountModel:[[AccountModel alloc] init]];
	[self.accountModel setDelegate:self];
	
	[self.pickerViewDefault selectRow:0 inComponent:0 animated:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self.pickerViewDefault setHidden:YES];
	
	if ([self.dates count] > self.selectedDateIndex)
	{
		// Set date button title to preselected row if any
		if (self.selectedDateIndex > 0)
		{
			[self.buttonDate setTitle:[self.dates objectAtIndex:self.selectedDateIndex] forState:UIControlStateNormal];
			[self.buttonDate setTitle:[self.dates objectAtIndex:self.selectedDateIndex] forState:UIControlStateSelected];
		}
		
		// Set selected date
		[self setSelectedDate:[self.dates objectAtIndex:self.selectedDateIndex]];
	}
	
	// Get list of accounts
	[self.accountModel getAccounts];
	
	// Note: Account button title set to preselected row in updateAccounts method
}

- (IBAction)selectAccounts:(id)sender
{
	[self setPickerType:1];
	[self.pickerViewDefault setHidden:NO];
	
	[self.pickerViewDefault reloadAllComponents];
	[self.pickerViewDefault selectRow:self.selectedAccountIndex inComponent:0 animated:NO];
}

- (IBAction)selectDates:(id)sender
{
	[self setPickerType:0];
	[self.pickerViewDefault setHidden:NO];
	
	[self.pickerViewDefault reloadAllComponents];
	[self.pickerViewDefault selectRow:self.selectedDateIndex inComponent:0 animated:NO];
}

// Return accounts from account model delegate
- (void)updateAccounts:(NSMutableArray *)accounts
{
	[self setAccounts:accounts];
	
	// Add all accounts option to beginning of array
	AccountModel *accountAll = [[AccountModel alloc] init];
	
	[accountAll setID:0];
	[accountAll setName:@"All Accounts"];
	[accountAll setPublicKey:@"0"];
	
	[accounts insertObject:accountAll atIndex:0];
	
	// Set account button title to preselected row if any
	if (self.selectedAccountIndex > 0 && [self.accounts count] > self.selectedAccountIndex)
	{
		// Set selected account if any
		[self setSelectedAccount:[self.accounts objectAtIndex:self.selectedAccountIndex]];
		
		[self.buttonAccount setTitle:self.selectedAccount.Name forState:UIControlStateNormal];
		[self.buttonAccount setTitle:self.selectedAccount.Name forState:UIControlStateSelected];
	}
}

// Return error from account model delegate
- (void)updateAccountsError:(NSError *)error
{
	// Customize error message if device not offline
	if (error.code != NSURLErrorNotConnectedToInternet)
	{
		error = [self.accountModel buildError:error usingData:nil withGenericMessage:@"There was a problem retrieving the Accounts. Will default to All Accounts." andTitle:error.localizedFailureReason];
	}
	
	// Show error message
	[self.accountModel showError:error];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	return (self.pickerType == 0 ? [self.dates count] : [self.accounts count]);
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	// Date row
	if (self.pickerType == 0)
	{
		return [self.dates objectAtIndex:row];
	}
	
	// Account row
	else
	{
		AccountModel *account = [self.accounts objectAtIndex:row];
		
		// If account is generic all accounts, then just return name
		if (account.ID == 0)
		{
			return account.Name;
		}
		
		return [NSString stringWithFormat:@"%@ - %@",
			account.PublicKey,
			account.Name];
	}
}

//If the user chooses from the picker view, it calls this function;
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
	// Set selected date
	if (self.pickerType == 0)
	{
		[self setSelectedDateIndex:row];
		[self setSelectedDate:[self.dates objectAtIndex:row]];
		
		// Set date button title to selected row
		[self.buttonDate setTitle:self.selectedDate forState:UIControlStateNormal];
		[self.buttonDate setTitle:self.selectedDate forState:UIControlStateSelected];
		
		NSString *dateRange = ([self.dates count] > self.selectedAccountIndex ? [self.dates objectAtIndex:self.selectedDateIndex] : @"Last 7 Days");
		NSString *numberOfDays;
		
		// Set end date
		[self setEndDate:[NSDate date]];
		NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
		[self setEndDate:[calendar dateFromComponents:[calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:self.endDate]]];
		
		// Set start date
		NSScanner *scanner = [NSScanner scannerWithString:dateRange];
		NSCharacterSet *numbers = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
		
		[scanner scanUpToCharactersFromSet:numbers intoString:nil];
		[scanner scanCharactersFromSet:numbers intoString:&numberOfDays];
		
		[self setStartDate:[self.endDate dateByAddingTimeInterval:60 * 60 * 24 * -[numberOfDays integerValue]]];
	}
	// Set selected account
	else
	{
		[self setSelectedAccountIndex:row];
		
		if ([self.accounts count] > row)
		{
			[self setSelectedAccount:[self.accounts objectAtIndex:row]];
			
			// Set account button title to selected row
			[self.buttonAccount setTitle:self.selectedAccount.Name forState:UIControlStateNormal];
			[self.buttonAccount setTitle:self.selectedAccount.Name forState:UIControlStateSelected];
		}
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
