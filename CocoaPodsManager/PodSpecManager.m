//
//  PodManager.m
//  CocoaPodsManager
//
//  Created by Andy on 06.02.2013.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import "PodSpecManager.h"
#import "TAppDelegate.h"
#import "Taskit.h"
#import "PodSpecTaskOperation.h"
#import "AppConstants.h"

@interface PodSpecManager()
{
    NSOperationQueue    *_operationQueue;
    NSInteger           _workingOperations;
    
    BOOL _isWorking;
}

@end

@implementation PodSpecManager

-(id) init{
    self = [super init];
    if(self){
        _workingOperations = 0;
        _operationQueue = [[NSOperationQueue alloc] init];
        [_operationQueue setMaxConcurrentOperationCount: 1];
    }
    return self;
}

+ (id)sharedPodSpecManager{
    
    static dispatch_once_t onceQueue;
    static PodSpecManager *podSpecManager = nil;
    
    dispatch_once(&onceQueue, ^{ podSpecManager = [[self alloc] init]; });
    return podSpecManager;
}

-(NSArray *) getCurrentPodNames{
    
    __block NSMutableArray *podNames = [NSMutableArray array];
    
    // we will just grab the contents of the ~/.cocoapods/master
    //    NSDate *methodStart = [NSDate date];
    //    [CocoaPodsApp executeWithArguments:@[@"list"]
    //                         responseBlock:^(NSString *response) {
    //                             NSMutableArray *lines = [response componentsSeparatedByString:@"\n"].mutableCopy;
    //                             [lines removeObjectsInRange: NSMakeRange(0, 2)];
    //                             [lines removeObjectsInRange: NSMakeRange([lines count] - 4, 4)];
    //
    //                             for (NSString *name in lines) {
    //                                 NSString *podName = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    //                                 if([podName length] > 0) {
    //                                     [podNames addObject: podName];
    //                                 }
    //                             }
    //                         }
    //                             failBlock:^(NSError *error) {
    //
    //                             }
    //     ];
    
    NSError *error = nil;
    NSString *masterFolderPath = [NSHomeDirectory() stringByAppendingPathComponent: PODS_MASTER_FOLDER];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *items = [fileManager contentsOfDirectoryAtPath:masterFolderPath error: &error];
    [items enumerateObjectsUsingBlock:^(NSString *path, NSUInteger idx, BOOL *stop) {
        BOOL isDirectory = NO;
        if ([fileManager fileExistsAtPath:[masterFolderPath stringByAppendingPathComponent:path] isDirectory:&isDirectory]) {
            if ((isDirectory) && ([path rangeOfString:@"."].location == NSNotFound)) {
                [podNames addObject: path];
            }
        }
    }];
    
    //    NSDate *methodFinish = [NSDate date];
    //    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
    //    NSLog(@"Execution Time: %f", executionTime);
    
    if (error) {
        NSLog(@"Error: %@", error);
    }
    return podNames;
}

-(void) addOperationWithPodNames: (NSArray *) items{
    
    _workingOperations ++;
    
    PodSpecManager *__weak weakSelf = self;
    PodSpecTaskOperation *operation = [[PodSpecTaskOperation alloc] initWithPodNames: items];
    [operation setOnDoneBlock: ^{
        //[_delegate podManagerUpdateCompleted: weakSelf];
        [weakSelf operationDidFinish: nil];
    }];
    [operation setOnProgressBlock:^(CGFloat progress){
        // [_delegate podManager:weakSelf isUpdatingWithProgress: progress];
    }];
    [operation setOnFailureBlock: ^(NSString *errorMessage){
        NSError *error = [NSError errorWithDomain:errorMessage code:1 userInfo:nil];
        [weakSelf operationDidFailed:nil withError: error];
    }];
    [_operationQueue addOperation: operation];
}

-(void) splitAndPushOperations: (NSArray *) podNames{
    
    NSInteger operations = 7;
    NSInteger currentLocation = 0;
    NSInteger arrayLength = [podNames count] / operations;
    PodSpecManager *__weak weakSelf = self;
    for (int i = 0; i < operations; i++) {
        NSRange range = NSMakeRange(currentLocation, arrayLength);
        if (i == operations - 1) {
            range.length += [podNames count] % operations;
        }
        
        if (range.length > 0) {
            NSArray *subArray = [podNames subarrayWithRange: range];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf addOperationWithPodNames: subArray];
            });
        }
        currentLocation += arrayLength;
    }
}

-(void) updateAllPodProperties {
    
    if (_isWorking) {
        [_operationQueue cancelAllOperations];
    }
    
    NSArray *pods = [PodSpec findAllWithPredicate:[NSPredicate predicateWithFormat:@"fetchedDetails == NO"]];
    if ([pods count] > 0) {
        // Lets continues with the properties update
        __block NSMutableArray *podNames = [NSMutableArray array];
        [pods enumerateObjectsUsingBlock:^(PodSpec *obj, NSUInteger idx, BOOL *stop) {
            [podNames addObject: obj.name];
        }];
        
        [self splitAndPushOperations: podNames];
    }else{
        _isWorking = YES;
    }
    
    PodSpecManager *__weak weakSelf = self;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        __block NSMutableArray *podNames = [weakSelf getCurrentPodNames].mutableCopy;
        
        // We will go thought the pod names an create for each new pod, a new PodSpec item
        [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
            
            NSArray *_names = [podNames copy];
            for (NSString *name in _names) {
                if([name length] > 0) {
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name = %@", name];
                    PodSpec *pod = [PodSpec findFirstWithPredicate:predicate inContext: localContext];
                    if (!pod) {
                        pod = [PodSpec createInContext: localContext];
                        pod.name = name;
                        pod.fetchedDetails = @NO;
                    }else if (pod.fetchedDetails) {
                        [podNames removeObject: name];
                    }
                }
            }
            
            if([localContext hasChanges]) {
                [localContext saveToPersistentStoreAndWait];
            }
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            // Launch operations for fetching properties for these pods
            [weakSelf splitAndPushOperations: podNames];
            
            [weakSelf.delegate podManagerUpdateCompleted: weakSelf];
        });
    });

}

-(void) cancelUpdate{
    
    [_operationQueue cancelAllOperations];
}

#pragma mark -

-(void) operationDidFinish: (PodSpecTaskOperation *) operation{
    
    _workingOperations--;
    
    if (_workingOperations == 0) {
        [_delegate podManagerUpdateCompleted: self];
    }
}

-(void) operationDidFailed: (PodSpecTaskOperation *) operation withError: (NSError *) error{
    
    _workingOperations--;
    [_delegate podManager:self didFailedWithError: error];
    
    if (_workingOperations == 0) {
        [_delegate podManagerUpdateCompleted: self];
    }
}

#pragma mark -

-(void) fetchPropertiesForPodSpec: (PodSpec *) pod
                           onDone: (OnDone) onDone
                        onFailure: (OnFailure) onFailure{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
        });
    });
    
}

@end
