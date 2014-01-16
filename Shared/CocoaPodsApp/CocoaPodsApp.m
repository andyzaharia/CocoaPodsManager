//
//  CocoaPodsApp.m
//  CocoaPodsManager
//
//  Created by Admin on 17.02.2013.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import "CocoaPodsApp.h"
#import "CPProject.h"
#import "NSString+Misc.h"
#import "AppConstants.h"
#import "STPrivilegedTask.h"

@interface CocoaPodsApp (){
    BOOL _isInstalled;
}

@end

@implementation CocoaPodsApp

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
        _response = [message stringByTrimmingCharactersInSet: [NSCharacterSet newlineCharacterSet]];
    }];
    return _response;
}

-(void) getOnlineVersionFromGithub: (OnSuccess) onSuccess
                           onError: (OnError) onError
{
    NSString *currentVersion = @"";
    
    CocoaPodsApp *app = [CocoaPodsApp sharedCocoaPodsApp];
    if ([app isInstalled]) {
        currentVersion = [app cocoaPodVersion];
    }
    
//    [[NSURLCache sharedURLCache] setMemoryCapacity:0];
//    [[NSURLCache sharedURLCache] setDiskCapacity:0];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    NSURL *url = [NSURL URLWithString:@"https://raw.github.com/CocoaPods/Specs/master/CocoaPods-version.yml"];
    NSURLRequest *request = [NSURLRequest requestWithURL: url];    
    [NSURLConnection sendAsynchronousRequest: request
                                       queue: queue
                           completionHandler: ^(NSURLResponse *response, NSData *data, NSError *error) {
                               if (error) {
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                       onError(error);
                                   });
                               } else {
                                   __block NSString *_version = nil;
                                    NSString *listStr = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding: NSUTF8StringEncoding];
                                    if ([listStr length]) {
                                        NSMutableArray *lines = [listStr componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]].mutableCopy;
                                        if ([lines count]) [lines removeObjectAtIndex: 0];

                                        if ([lines count]){
                                            NSString *lastLabel = @"last: ";
                                            [lines enumerateObjectsUsingBlock:^(NSString *versionLine, NSUInteger idx, BOOL *stop) {
                                                if ([versionLine isSameLeftSideWithCaseInsensitive: lastLabel]) {
                                                    NSString *lastVersion = [versionLine stringByReplacingOccurrencesOfString:lastLabel withString: @""];
                                                    _version = lastVersion;
                                                    *stop = YES;
                                                }
                                            }];
                                        }
                                    }
                                   
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                       if (_version) {
                                           if (onSuccess) {
                                               onSuccess(_version);
                                           }
                                       } else {
                                           if (error) {
                                               // Well, we will return a normal NSError, in the distant future.
                                               onError(nil);
                                           }
                                       }

                                   });
                               }
                           }];
}

-(void) installGem: (OnSuccess) onSuccess
           onError: (OnError) onError
{
    int status = 0;
    
    NSArray *args = @[@"sudo", @"gem", @"install", @"cocoapods"];
    
    @try {
        NSPipe *pipe = [[NSPipe alloc] init];
        STPrivilegedTask *task = [[STPrivilegedTask alloc] initWithLaunchPath: @"/usr/bin/env"
                                                                    arguments: args];
        [task setCurrentDirectoryPath: [[NSFileManager defaultManager] currentDirectoryPath]];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:NSFileHandleDataAvailableNotification
                                                          object:[pipe fileHandleForReading]
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification *note) {
                                                          NSLog(@"Available data");
                                                      }];
        
        NSFileHandle *outputHandle = [task outputFileHandle];
        [outputHandle waitForDataInBackgroundAndNotify];
        [task launch];
        [task waitUntilExit];

        NSData *data = [outputHandle availableData];
        NSString *output = [[NSString alloc] initWithBytes: [data bytes]
                                                    length: [data length]
                                                  encoding: NSUTF8StringEncoding] ;
        NSLog(@"Log: %@", output);
        NSLog(@"Termination status %d", [task terminationStatus]);
        NSLog(@"Task description: %@", [task description]);
                                        
//        NSTask *task = [[NSTask alloc] init];
//        
//        NSPipe *pipe = [[NSPipe alloc] init];
//        NSFileHandle *handle;
//        NSString *outputString;
//        
//        NSMutableDictionary *environment = [[[NSProcessInfo processInfo] environment] mutableCopy];
//        environment[@"CP_STDOUT_SYNC"] = @"TRUE";
//        environment[@"LC_ALL"] = @"UTF-8";
//        
//        [task setLaunchPath:@"/usr/bin/env"];
//        [task setEnvironment: environment];
//        [task setArguments:args];
//        [task setStandardInput:[NSPipe pipe]];
//        [task setStandardOutput:pipe];
//        [task setStandardError:[NSPipe pipe]];
//        [task setCurrentDirectoryPath: [[NSFileManager defaultManager] currentDirectoryPath]];
//        
//        handle = [pipe fileHandleForReading];
//        [task setTerminationHandler:^(NSTask *task) {
//            
//        }];
//        
//        [task launch];
//        [task waitUntilExit];
//        
//        outputString = [[NSString alloc] initWithData:[handle readDataToEndOfFile] encoding:NSASCIIStringEncoding];
//        NSLog(@"LOG: %@", outputString);
//        
//        status = [task terminationStatus];
//        
//        NSLog(@"Status %d", [task terminationStatus]);
    }
    @catch (NSException *exception) {
        status = -1;
        //failBlock([NSError errorWithDomain:[exception debugDescription] code:status userInfo:nil]);
    }
    @finally {
        
    }
}

#pragma mark - Class Methods

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
        environment[@"LC_ALL"] = @"UTF-8";
        
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
                                responseBlock: responseBlock
                               andOnFailBlock: failBlock];
}

+(int) executeWithArguments: (NSArray *) items andResponseBlock: (PodExecOnSucceedBlock) responseBlock{
    
    return [CocoaPodsApp executeWithArguments: items
                         withCurrentDirectory: [[NSFileManager defaultManager] currentDirectoryPath]
                                responseBlock:responseBlock
                               andOnFailBlock: NULL];
}


+(void) updateProject: (CPProject *) project
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
        NSString *projectDirectory = [project.projectFilePath stringByDeletingLastPathComponent];
        if (![projectDirectory length]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Project directory is invalid %@", projectDirectory]};
                errorBlock([NSError errorWithDomain: @""
                                               code: NSFileNoSuchFileError
                                           userInfo: userInfo]);
            });
        }
        
        int status = [CocoaPodsApp executeWithArguments:args
                                   withCurrentDirectory:projectDirectory
                                          responseBlock:^(NSString *outputMessage) {
                                              respOutput = outputMessage;
                                          }
                                         andOnFailBlock:^(NSError *error) {
                                            
                                         }];
        
        if (status == 1) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey: respOutput};
                errorBlock([NSError errorWithDomain:@"" code:status userInfo:userInfo]);
            });
        }else {
            dispatch_async(dispatch_get_main_queue(), ^{
                onSuccess(respOutput);
            });
        }
    });
}

+(void) installCocoaPodsInProject: (CPProject *) project
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
                      withCurrentDirectory:[project.projectFilePath stringByDeletingLastPathComponent]
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


@end
