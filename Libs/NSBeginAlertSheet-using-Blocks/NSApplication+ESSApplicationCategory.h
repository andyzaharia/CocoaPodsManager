//
//  NSApplication+ESSApplicationCategory.h
//
//  Created by Matthias Gansrigler on 01.10.12.
//  Copyright (c) 2012 Eternal Storms Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSApplication (ESSApplicationCategory)

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
						NSString *formattedString);

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
									 NSString *formattedString);

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
								NSString *formattedString);

@end
