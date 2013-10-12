//
//  NSApplication+ESSApplicationCategory.m
//
//  Created by Matthias Gansrigler on 01.10.12.
//  Copyright (c) 2012 Eternal Storms Software. All rights reserved.
//

#import "NSApplication+ESSApplicationCategory.h"

@implementation NSApplication (ESSApplicationCategory)

void ESSBeginAlertSheet(NSString *title,
						NSString *defaultButton,
						NSString *alternateButton,
						NSString *otherButton,
						NSWindow *window,
						void (^didEndBlock)(void *contextInf,
											NSInteger returnCode),
						void (^didDismissBlock)(void *contextInf,
												NSInteger returnCode),
						void *contextInfo,
						NSString *formattedString)
{
	NSMutableDictionary *contextInf = [NSMutableDictionary dictionary];
	if (didEndBlock != nil)
		[contextInf setObject:[[didEndBlock copy] autorelease] forKey:@"didEndBlock"];
	if (didDismissBlock != nil)
		[contextInf setObject:[[didDismissBlock copy] autorelease] forKey:@"didDismissBlock"];
	if (contextInfo != nil)
		[contextInf setObject:contextInfo forKey:@"contextInfo"];
	NSBeginAlertSheet(title, defaultButton, alternateButton, otherButton, window, NSApp, @selector(_esswin:didEndWithCode:context:), @selector(_esswin:didDismissWithCode:context:), [contextInf retain], formattedString,nil);
}

void ESSBeginInformationalAlertSheet(NSString *title,
									 NSString *defaultButton,
									 NSString *alternateButton,
									 NSString *otherButton,
									 NSWindow *window,
									 void (^didEndBlock)(void *contextInf,
														 NSInteger returnCode),
									 void (^didDismissBlock)(void *contextInf,
															 NSInteger returnCode),
									 void *contextInfo,
									 NSString *formattedString)
{
	NSMutableDictionary *contextInf = [NSMutableDictionary dictionary];
	if (didEndBlock != nil)
		[contextInf setObject:[[didEndBlock copy] autorelease] forKey:@"didEndBlock"];
	if (didDismissBlock != nil)
		[contextInf setObject:[[didDismissBlock copy] autorelease] forKey:@"didDismissBlock"];
	if (contextInfo != nil)
		[contextInf setObject:contextInfo forKey:@"contextInfo"];
	NSBeginInformationalAlertSheet(title, defaultButton, alternateButton, otherButton, window, NSApp, @selector(_esswin:didEndWithCode:context:), @selector(_esswin:didDismissWithCode:context:), [contextInf retain], formattedString,nil);
}

void ESSBeginCriticalAlertSheet(NSString *title,
								NSString *defaultButton,
								NSString *alternateButton,
								NSString *otherButton,
								NSWindow *window,
								void (^didEndBlock)(void *contextInf,
													NSInteger returnCode),
								void (^didDismissBlock)(void *contextInf,
														NSInteger returnCode),
								void *contextInfo,
								NSString *formattedString)
{
	NSMutableDictionary *contextInf = [NSMutableDictionary dictionary];
	if (didEndBlock != nil)
		[contextInf setObject:[[didEndBlock copy] autorelease] forKey:@"didEndBlock"];
	if (didDismissBlock != nil)
		[contextInf setObject:[[didDismissBlock copy] autorelease] forKey:@"didDismissBlock"];
	if (contextInfo != nil)
		[contextInf setObject:contextInfo forKey:@"contextInfo"];
	NSBeginCriticalAlertSheet(title, defaultButton, alternateButton, otherButton, window, NSApp, @selector(_esswin:didEndWithCode:context:), @selector(_esswin:didDismissWithCode:context:), [contextInf retain], formattedString,nil);
}

- (void)_esswin:(NSPanel *)panel didEndWithCode:(NSInteger)code context:(void *)context
{
	NSDictionary *dict = (NSDictionary *)context;
	void (^didEndBlock)(void *contextInf, NSInteger returnCode) = [dict objectForKey:@"didEndBlock"];
	void *contextInf = [dict objectForKey:@"contextInfo"];
	
	if (didEndBlock != nil)
		didEndBlock(contextInf,code);
}

- (void)_esswin:(NSPanel *)panel didDismissWithCode:(NSInteger)code context:(void *)context
{
	NSDictionary *dict = (NSDictionary *)context;
	void (^didDismissBlock)(void *contextInf, NSInteger returnCode) = [dict objectForKey:@"didDismissBlock"];
	void *contextInf = [dict objectForKey:@"contextInfo"];
	
	if (didDismissBlock != nil)
		didDismissBlock(contextInf,code);
	[dict autorelease];
}

@end
