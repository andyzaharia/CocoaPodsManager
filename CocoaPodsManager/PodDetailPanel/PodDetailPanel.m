//
//  PodDetailPanel.m
//  CocoaPodsManager
//
//  Created by Andy on 04.04.2013.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import "PodDetailPanel.h"
#import "DSClickableURLTextField.h"
#import "PodSpec+StdOutParser.h"
#import "PodSpec+YAML.h"

@interface PodDetailPanel ()

@property (weak) IBOutlet NSTextField       *tfPodName;
@property (weak) IBOutlet NSPopUpButton     *puVersion;

@property (weak) IBOutlet NSTextField               *tfVersionLabel;
@property (weak) IBOutlet NSTextField               *tfSummaryLabel;
@property (weak) IBOutlet NSTextField               *tfDescriptionLabel;
@property (weak) IBOutlet NSTextField               *tfAuthorsLabel;
@property (weak) IBOutlet DSClickableURLTextField   *tfHomePage;

@property (weak) IBOutlet NSTextField *tfSummary;
@property (weak) IBOutlet NSTextField *tfDescription;
@property (weak) IBOutlet NSTextField *tfAuthors;


@property (nonatomic, strong) PodSpec       *pod;

@end

@implementation PodDetailPanel

- (void)awakeFromNib
{
    // Initialize here
    [super awakeFromNib];
    
    if(self.pod) [self fetchContent];
}

- (IBAction)dismissAction:(id)sender {
    if(self.onDone) self.onDone();
}

#pragma mark - Fetching Content

-(void) fetchAuthorsFromYAML: (NSMutableArray *) yaml
{
    NSDictionary *authors = [self.pod authorsFromYAML: yaml];
    if ([authors isKindOfClass:[NSDictionary class]]) {
        __block NSMutableString *_HTML = [NSMutableString string];
        NSArray *authorKeys = [authors allKeys];
        [authorKeys enumerateObjectsUsingBlock:^(NSString *authorName, NSUInteger idx, BOOL *stop) {
            NSString *email = [authors objectForKey: authorName];
            if ([_HTML length] == 0) {
                [_HTML appendFormat:@"<a href='%@'>%@</a>", email, authorName];
            } else
                [_HTML appendFormat:@", <a href='%@'>%@</a>", email, authorName];
        }];
        NSString *html = [NSString stringWithFormat:@"<div width='100%%' align='left' style=\"font-family:'%@'; font-size:%dpx;\">%@</div>",
                          [self.tfAuthors.font fontName],
                          (int)[self.tfAuthors.font pointSize],
                          _HTML];
        NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
        NSAttributedString* string = [[NSAttributedString alloc] initWithHTML:data documentAttributes:nil];
        [self.tfAuthors setAttributedStringValue: string];
    }
    else
    if ([authors isKindOfClass:[NSString class]]) {
        NSString *authorString = (NSString *)authors;
        [self.tfSummary setStringValue: ([authorString length]) ? authorString : @""];
    }
}

-(void) setHomePage: (NSString *) homePage
{
    if ([homePage length]) {
        NSString *_HTML = [NSString stringWithFormat:@"<a href='%@'>%@</a>", homePage, homePage];
        NSString *html = [NSString stringWithFormat:@"<div width='100%%' align='left' style=\"font-family:'%@'; font-size:%dpx;\">%@</div>",
                          [self.tfHomePage.font fontName],
                          (int)[self.tfHomePage.font pointSize],
                          _HTML];
        
        NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
        NSAttributedString* string = [[NSAttributedString alloc] initWithHTML:data documentAttributes:nil];
        [self.tfHomePage setAttributedStringValue: string];
        
    } else {
        [self.tfHomePage setStringValue:@""];
    }    
}

-(void) fetchContent {
    
    [self.tfPodName setStringValue: self.pod.name];
    
    if (self.puVersion) {
        [self.puVersion removeAllItems];
        
        NSMutableArray *items = [self.pod versionsArray];
        for (NSString *item in items) {
            [self.puVersion addItemWithTitle: item];
        }
    }
    
    NSMutableArray *yaml = [self.pod fetchPropertiesInContext:nil withVersion: [self.puVersion.itemTitles objectAtIndex: 0]];
    NSLog(@"YAML %@", yaml);
    
    // Set the attributed text for the Authors Label
    [self fetchAuthorsFromYAML: yaml];
    
    // Set the description text
    
    // Set the summary text
    NSString *summary = [self.pod summaryFromYAML: yaml];
    [self.tfSummary setStringValue: ([summary length]) ? summary : @""];
    
    NSString *homepage = [self.pod homepageFromYAML: yaml];
    [self setHomePage: homepage];
}

-(void) displayPodSpec: (PodSpec *) value
{
    self.pod = value;
    [self fetchContent];
}

#pragma mark - Actions

- (IBAction)versionDidChange:(id)sender {
}

#pragma mark - NSTextFieldDelegate

-(BOOL) textField:(NSTextField *) textField  openURL:(NSURL *) anURL
{
    if(textField == self.tfAuthorsLabel) {
        NSString *toAddress = [anURL lastPathComponent];
        NSString *mailtoAddress = [[NSString stringWithFormat:@"mailto:%@?Subject=%@&body=%@",toAddress, @"Hi From CocoaPods", @""] stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:mailtoAddress]];
    } else if (textField == self.tfHomePage) {
        [[NSWorkspace sharedWorkspace] openURL: anURL];
    }
    
    return YES;
}

@end
