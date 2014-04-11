//
//  PodInfoTableCellView.m
//  CocoaPodsManager
//
//  Created by Andrei Zaharia on 4/11/14.
//  Copyright (c) 2014 Andy. All rights reserved.
//

#import "PodInfoTableCellView.h"

@interface PodInfoTableCellView ()

@end

@implementation PodInfoTableCellView

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame: frameRect];
    if (self) {
        
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    
}

- (void)layout
{
    [super layout];
    
    // Seriously must switch to Autolayout.
    
    if ([self.stPodDescription.stringValue length]) {

        [self.stPodDescription setHidden: NO];

        [self.tfPodName sizeToFit];
        [self.tfPodName setFrame: NSMakeRect(self.tfPodName.frame.origin.x,
                                             self.frame.size.height - self.tfPodName.frame.size.height - 3.0,
                                             self.tfPodName.frame.size.width,
                                             self.tfPodName.frame.size.height)];

        [self.stPodDescription sizeToFit];

        CGFloat descriptionHeight = self.frame.size.height - (self.tfPodName.frame.size.height + 6.0);
        NSRect descriptionRect = NSMakeRect(self.tfPodName.frame.origin.x,
                                            self.frame.size.height - (self.tfPodName.frame.size.height + self.tfPodName.frame.origin.y) - 3.0,
                                            self.frame.size.width - self.stPodDescription.frame.origin.x,
                                            descriptionHeight);

        [self.stPodDescription setFrame: descriptionRect];

    } else {
        [self.tfPodName sizeToFit];
        [self.tfPodName setFrame: NSMakeRect(self.tfPodName.frame.origin.x,
                                             self.frame.size.height * 0.5 - self.tfPodName.frame.size.height * 0.5,
                                             self.tfPodName.frame.size.width,
                                             self.tfPodName.frame.size.height)];

        [self.stPodDescription setHidden: YES];
    }
}

-(void) displayPodSpec: (PodSpec *) pod isInstalled: (BOOL) installed
{
    [self.tfPodName setStringValue: ([pod.name length]) ? pod.name : @""];
    
    if ([pod.desc length]) {
        [self.stPodDescription setStringValue: pod.desc];
    } else {
        [self.stPodDescription setStringValue: @""];
    }
    
    if (self.btnInstalled) {
        [self.btnInstalled setState: installed];
    }
    
    [self setNeedsLayout: YES];
}

@end
