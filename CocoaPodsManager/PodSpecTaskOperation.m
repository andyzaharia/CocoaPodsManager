//
//  PodTaskOperation.m
//  CocoaPodsManager
//
//  Created by Andy on 11.02.2013.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import "PodSpecTaskOperation.h"
#import "Taskit.h"
#import "MagicalRecord+Actions.h"
#import "NSString+Misc.h"
#import "AppConstants.h"
#import "PodSpec+StdOutParser.h"

@implementation PodSpecTaskOperation

NSManagedObjectContext      *_context;


-(id) initWithPodNames: (NSArray *) podNames
{
    self = [super init];
    if (self) {
        _podNameList = podNames;
    }
    return self;
}

-(void) parseCocoaPodsListString: (NSString *) messageString{
    
    [MagicalRecord saveUsingCurrentThreadContextWithBlockAndWait:^(NSManagedObjectContext *localContext){
        NSMutableArray *lines = [messageString componentsSeparatedByString:@"\n"].mutableCopy;
        [lines removeObjectsInRange: NSMakeRange(0, 2)];
        [lines removeObjectsInRange: NSMakeRange([lines count] - 2, 2)];
        
        CGFloat _progress = 0.0;
        
        for (NSString *name in lines) {
            NSString *podName = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if([podName length] > 0) {
                PodSpec *pod = [PodSpec findFirstWithPredicate:[NSPredicate predicateWithFormat:@"name = %@", podName]];
                if (!pod) {
                    pod = [PodSpec createInContext: _context];
                }
                pod.name = podName;
                
                NSString *currentVersion = [[pod versionsArray] objectAtIndex: 0];
                [pod fetchPropertiesInContext: localContext withVersion: currentVersion];
                
                //[pod fetchPropertiesInContext: localContext];
            }
            CGFloat p = (CGFloat)([lines indexOfObject: name] + 1) / (CGFloat)[lines count];
            if (p - _progress > 0.005) {
                _progress = p;
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.onProgressBlock(_progress);
                });
            }
        }
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.onDoneBlock();
    });
}

// used only when self.podNameList is supplied
-(void) fetchPodsProperties
{
    [MagicalRecord saveUsingCurrentThreadContextWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        for (NSString *name in self.podNameList) {
            
            if (self.isCancelled) return;
            
            if([name length] > 0) {
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", name];
                PodSpec *pod = [PodSpec findFirstWithPredicate:predicate inContext: localContext];
                if (!pod) {
                    pod = [PodSpec createInContext: localContext];
                    pod.name = name;
                }
                
                NSString *currentVersion = [[pod versionsArray] objectAtIndex: 0];
                [pod fetchPropertiesInContext: localContext withVersion: currentVersion];
            }
        }
        
        if ([localContext hasChanges]) {
            [localContext saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (success) {
                        self.onDoneBlock();
                    }else if(error) {
                        self.onFailureBlock([error domain]);
                    }
                });
            }];
        }
    }];
}

-(void) main{
    
    if (self.isCancelled) return;
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/pod"]){
        dispatch_async(dispatch_get_main_queue(), ^{
            self.onFailureBlock(PODS_NOT_INSTALLED_MESSAGE);
        });
        
        return;
    }
    
    _context = [NSManagedObjectContext contextForCurrentThread];
    
    if ([self.podNameList count] == 0) {
        // Old code, might need to be removed
        NSTask *ls=[[NSTask alloc] init];
        NSPipe *pipe = [[NSPipe alloc] init];
        NSPipe *errorsPipe = [[NSPipe alloc] init];
        NSFileHandle *handle;
        NSFileHandle *errorHandle;
        NSString *outputString;
        
        [ls setLaunchPath:@"/usr/bin/pod"];
        [ls setArguments:[NSArray arrayWithObjects:@"list", nil]];
        [ls setStandardOutput:pipe];
        [ls setStandardError: errorsPipe];
        handle = [pipe fileHandleForReading];
        errorHandle = [pipe fileHandleForReading];
        
        [ls launch];
        
        outputString= [[NSString alloc] initWithData:[handle readDataToEndOfFile] encoding:NSASCIIStringEncoding];
        
        NSString *errorString = [[NSString alloc] initWithData:[errorHandle readDataToEndOfFile] encoding:NSASCIIStringEncoding];
        if([errorString length] > 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.onFailureBlock(errorString);
            });
        }else {
            [self parseCocoaPodsListString: outputString];
        }
    }else {
        [self fetchPodsProperties];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.onDoneBlock();
    });
}

@end
