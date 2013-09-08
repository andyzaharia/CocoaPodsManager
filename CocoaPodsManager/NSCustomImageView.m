//
//  NSCustomImageView.m
//  CocoaPodsManager
//
//  Created by Admin on 12.02.2013.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import "NSCustomImageView.h"

@implementation NSCustomImageView

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    if ((NSDragOperationGeneric & [sender draggingSourceOperationMask]) == NSDragOperationGeneric){
        return NSDragOperationCopy;
    }else{
        return NSDragOperationNone;
    }
}



- (void)draggingExited:(id <NSDraggingInfo>)sender{
    //
}


- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender{
    
	NSPasteboard *pboard = [sender draggingPasteboard];
	
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
		//  NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        //NSLog(@"%@", files);
        // Perform operation using the list of files
    }
	
	
    NSPasteboard *paste = [sender draggingPasteboard];
	
	//gets the dragging-specific pasteboard from the sender
    NSArray *types = [NSArray arrayWithObjects:NSTIFFPboardType,
					  NSFilenamesPboardType, nil];
	//a list of types that we can accept
    NSString *desiredType = [paste availableTypeFromArray:types];
    NSData *carriedData = [paste dataForType:desiredType];
	
    if (nil == carriedData)
    {
        //the operation failed for some reason
        NSRunAlertPanel(@"Paste Error", @"Sorry, but the past operation failed",
						nil, nil, nil);
        return NO;
    }else{
        //the pasteboard was able to give us some meaningful data
        if ([desiredType isEqualToString:NSTIFFPboardType]){
            //we have TIFF bitmap data in the NSData object
			NSImage *newImage = [[NSImage alloc] initWithData:carriedData];
			[self setImage:newImage];
			//we are no longer interested in this so we need to release it
        }else if ([desiredType isEqualToString:NSFilenamesPboardType]){
            NSArray *fileArray = [paste propertyListForType:@"NSFilenamesPboardType"];
            NSString *path = [fileArray objectAtIndex:0];
            self.onFileDropBlock(path);
            
            return YES;
        }else{
            //this can't happen
            NSAssert(NO, @"This can't happen");
            return NO;
        }
    }
    [self setNeedsDisplay:YES];    //redraw us with the new image
    return YES;
}


@end
