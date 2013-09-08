//
//  CocoaPodsApp.m
//  CocoaPodsManager
//
//  Created by Admin on 17.02.2013.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import "CocoaPodsApp.h"
#import "CocoaProject.h"
#import "NSString+Misc.h"
#import "AppConstants.h"

@interface CocoaPodsApp (){
    BOOL _isInstalled;
}

@end

@implementation CocoaPodsApp

+ (id)sharedCocoaPodsApp{
    static dispatch_once_t onceQueue;
    static CocoaPodsApp *cocoaPodsApp = nil;
    
    dispatch_once(&onceQueue, ^{ cocoaPodsApp = [[self alloc] init]; });
    return cocoaPodsApp;
}

+(int) executeWithArguments: (NSArray *) items
       withCurrentDirectory: (NSString *) currentDirectory
              responseBlock: (PodExecOnSucceedBlock) responseBlock
             andOnFailBlock: (PodExecOnFailBlock) failBlock{
    
    int status = 0;
    
    NSArray *args = [@[@"pod", @"--no-color"] arrayByAddingObjectsFromArray: items];
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/pod"]){
        // Pods executable not found
        return CocoaPodsAppExecutableNotFound;
    }
    
    @try {
        NSTask *task = [[NSTask alloc] init];
        
        NSPipe *pipe = [[NSPipe alloc] init];
        NSFileHandle *handle;
        NSString *outputString;
        
        NSMutableDictionary *environment = [[[NSProcessInfo processInfo] environment] mutableCopy];
        environment[@"CP_STDOUT_SYNC"] = @"TRUE";
        [task setLaunchPath:@"/usr/bin/env"];
        [task setEnvironment: environment];
        [task setArguments:args];
        [task setStandardInput:[NSPipe pipe]];
        [task setStandardOutput:pipe];
        [task setStandardError:[NSPipe pipe]];
        [task setCurrentDirectoryPath:currentDirectory];
        
        handle = [pipe fileHandleForReading];
        [task setTerminationHandler:^(NSTask *task) {
            
        }];
        
        [task launch];
        [task waitUntilExit];
        
        outputString = [[NSString alloc] initWithData:[handle readDataToEndOfFile] encoding:NSASCIIStringEncoding];
        responseBlock(outputString);
        
        status = [task terminationStatus];
    }
    @catch (NSException *exception) {
        status = -1;
        failBlock([NSError errorWithDomain:[exception debugDescription] code:status userInfo:nil]);
    }
    @finally {
        
    }
    return status;
}

+(int) executeWithArguments: (NSArray *) items responseBlock: (PodExecOnSucceedBlock) responseBlock failBlock: (PodExecOnFailBlock) failBlock{
    
    return [CocoaPodsApp executeWithArguments: items
                         withCurrentDirectory: [[NSFileManager defaultManager] currentDirectoryPath]
                                responseBlock:responseBlock
                               andOnFailBlock: failBlock];
}

+(int) executeWithArguments: (NSArray *) items andResponseBlock: (PodExecOnSucceedBlock) responseBlock{
    
    return [CocoaPodsApp executeWithArguments: items
                         withCurrentDirectory: [[NSFileManager defaultManager] currentDirectoryPath]
                                responseBlock:responseBlock
                               andOnFailBlock: NULL];
}


+(void) updateProject: (CocoaProject *) project
          withOptions: (NSArray *) options
            onSuccess: (PodExecOnSucceedBlock) onSuccess
              onError: (PodExecOnFailBlock) errorBlock{
    
    if (![[CocoaPodsApp sharedCocoaPodsApp] isInstalled]) {
        NSError *error = [NSError errorWithDomain:PODS_NOT_INSTALLED_MESSAGE code:11 userInfo: nil];
        errorBlock(error);
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSArray *args = @[@"update"];
        if ([options count] > 0) {
            args = [args arrayByAddingObjectsFromArray: options];
        }
        
        __block NSString *respOutput = @"";
        int status = [CocoaPodsApp executeWithArguments:args
                                   withCurrentDirectory:[project.xcodeProject.projectFilePath stringByDeletingLastPathComponent]
                                          responseBlock:^(NSString *outputMessage) {
                                              respOutput = outputMessage;
                                          }
                                         andOnFailBlock:^(NSError *error) {
                                         }];
        
        if (status == 1) {
            dispatch_async(dispatch_get_main_queue(), ^{
                errorBlock([NSError errorWithDomain:respOutput code:status userInfo:nil]);
            });
        }else {
            dispatch_async(dispatch_get_main_queue(), ^{
                onSuccess(respOutput);
            });
        }
    });
}

+(void) installCocoaPodsInProject: (CocoaProject *) project
                        onSuccess: (PodExecOnSucceedBlock) onSuccess
                      withOnError: (PodExecOnFailBlock) errorBlock{
    
    if (![[CocoaPodsApp sharedCocoaPodsApp] isInstalled]) {
        NSError *error = [NSError errorWithDomain:PODS_NOT_INSTALLED_MESSAGE code:11 userInfo: nil];
        errorBlock(error);
        return;
    }
    
    [project writeProjectToPodFile];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSArray *args = @[@"install"];
        
        __block NSString *respOutput = @"";
        [CocoaPodsApp executeWithArguments:args
                      withCurrentDirectory:[project.xcodeProject.projectFilePath stringByDeletingLastPathComponent]
                             responseBlock:^(NSString *outputMessage) {
                                 respOutput = [outputMessage trimWhiteSpaceAndNewline];
                             }
                            andOnFailBlock:^(NSError *error) {
                                
                            }];
        
        // If anyone has a better Idea, I'm listening :-)
        // TODO: Do more research, as this is a stupid method
        
        NSString *errorConst = @"[!]";
        NSString *installConfirmationString = @"From now on use";
        
        NSRange errRange = [respOutput rangeOfString: errorConst];
        NSRange confRange = [respOutput rangeOfString: installConfirmationString];
        //NSLog(@"Install log: %@", respOutput);
        
        if ((errRange.location != NSNotFound) && (confRange.location == NSNotFound)) {
            NSError *error = [NSError errorWithDomain:respOutput code:10 userInfo: nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                errorBlock(error);
            });
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                onSuccess(respOutput);
            });
        }
        //            return confRange.location != NSNotFound;
    });
}

#pragma mark -

-(BOOL) isInstalled
{
    __block NSString *_response = nil;
    int status = [CocoaPodsApp executeWithArguments:@[@"--version"] andResponseBlock:^(NSString *message) {
        _response = message;
    }];
    
    if (status > 1) {
        _isInstalled = NO;
    } else {
        NSRange range = [_response rangeOfString:@"not found"];
        _isInstalled = (range.location == NSNotFound);
    }
    
    return _isInstalled;
}

-(NSString *) cocoaPodVersion{
    
    __block NSString *_response = nil;
    [CocoaPodsApp executeWithArguments:@[@"--version"] andResponseBlock:^(NSString *message) {
        _response = message;
    }];
    return _response;
}

@end
