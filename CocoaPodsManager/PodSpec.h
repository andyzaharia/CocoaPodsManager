//
//  PodSpec.h
//  CocoaPodsManager
//
//  Created by Andrei Zaharia on 2/28/13.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface PodSpec : NSManagedObject

@property (nonatomic, retain) NSString * childDescription;
@property (nonatomic, retain) NSString * childHomePage;
@property (nonatomic, retain) NSString * childSourcePage;
@property (nonatomic, retain) NSString * childVersions;
@property (nonatomic, retain) NSString * desc;
@property (nonatomic, retain) NSNumber * fetchedDetails;
@property (nonatomic, retain) NSString * homePage;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * source;
@property (nonatomic, retain) NSString * versions;
@property (nonatomic, retain) NSNumber * childLoading;

@end
