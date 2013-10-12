//
//  PodSpec+YAML.m
//  CocoaPodsManager
//
//  Created by Andrei Zaharia on 4/4/13.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import "PodSpec+YAML.h"

static NSString *YAML_AUTHORS = @"authors";
static NSString *YAML_DESCRIPTION = @"descrption";
static NSString *YAML_SUMMARY = @"summary";
static NSString *YAML_HOMEPAGE = @"homepage";

@implementation PodSpec (YAML)

-(NSDictionary *) authorsFromYAML: (NSMutableArray *) yaml{
    return [[yaml lastObject] objectForKey: YAML_AUTHORS];
}

-(NSString *) nameFromYAML: (NSMutableArray *) yaml{
    return nil;
}

-(NSString *) platformsFromYAML: (NSMutableArray *) yaml{
    return nil;
}

-(NSString *) licenseFromYAML: (NSMutableArray *) yaml{
    return nil;
}

-(NSString *) sourceFromYAML: (NSMutableArray *) yaml{
    return nil;

}

-(NSString *) summaryFromYAML: (NSMutableArray *) yaml{
    return [[yaml lastObject] objectForKey: YAML_SUMMARY];
}

-(NSString *) descriptionFromYAML: (NSMutableArray *) yaml{
    return [[yaml lastObject] objectForKey: YAML_DESCRIPTION];
}

-(NSString *) homepageFromYAML: (NSMutableArray *) yaml{
    return [[yaml lastObject] objectForKey: YAML_HOMEPAGE];;

}

@end
