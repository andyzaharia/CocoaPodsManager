//
//  ProjectCell.m
//  CocoaPodsManager
//
//  Created by Admin on 12.02.2013.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import "ProjectCell.h"

@implementation ProjectCell

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        
    }
    
    return self;
}

- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle {
    NSColor *textColor = (backgroundStyle == NSBackgroundStyleDark) ? [NSColor windowBackgroundColor] : [NSColor colorWithDeviceRed:0.231 green:0.286 blue:0.345 alpha:1.000];
    
    NSTextField *tf = [self viewWithTag: 1];
    if(tf){
        tf.textColor = textColor; //[NSColor whiteColor];
    }
    
    [super setBackgroundStyle:backgroundStyle];
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
    if (self.backgroundStyle == NSBackgroundStyleDark) {
        //[yourTextFieldIVar setTextColor:[NSColor whiteColor]];
    } else if(self.backgroundStyle == NSBackgroundStyleLight) {
        //[yourTextFieldIVar setTextColor:[NSColor blackColor]];
    }
}

@end
