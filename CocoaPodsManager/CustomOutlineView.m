//
//  CustomOutlineView.m
//  CocoaPodsManager
//
//  Created by Andy on 01.03.2013.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import "CustomOutlineView.h"

@implementation CustomOutlineView

- (void)mouseDown:(NSEvent *)theEvent {
    [super mouseDown:theEvent];
    
    // Only take effect for double clicks; remove to allow for single clicks
    if (theEvent.clickCount < 2) return;
    
    
    // Get the row on which the user clicked
    NSPoint localPoint = [self convertPoint:theEvent.locationInWindow fromView:nil];
    NSInteger row = [self rowAtPoint:localPoint];
    
    // If the user didn't click on a row, we're done
    if (row < 0) return;
    
    
    // Get the view clicked on
    NSTableCellView *view = [self viewAtColumn:0 row:row makeIfNecessary:NO];
    
    // If the field can be edited, pop the editor into edit mode
    if (view.textField.isEditable) {
        [[view window] makeFirstResponder:view.textField];
    }
}

@end
