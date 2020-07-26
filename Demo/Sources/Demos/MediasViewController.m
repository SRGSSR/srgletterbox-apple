//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MediasViewController.h"

#import "DemoSection.h"
#import "NSBundle+LetterboxDemo.h"
#import "UIViewController+LetterboxDemo.h"

@import SRGLetterbox;

@implementation MediasViewController

#pragma mark Object lifecycle

- (instancetype)init
{
    return [self initWithStyle:UITableViewStyleGrouped];
}

#pragma mark Getters and setters

- (NSString *)title
{
    return NSLocalizedString(@"Medias", nil);
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
#if TARGET_OS_TV
    if (@available(tvOS 13, *)) {
        self.navigationController.tabBarObservedScrollView = self.tableView;
    }
#endif
}

#pragma mark Custom URN entry

- (void)openCustomURNEntryAlertWithCompletionBlock:(void (^)(NSString * _Nullable URN))completionBlock
{
    NSParameterAssert(completionBlock);
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Enter media URN", nil)
                                                                             message:NSLocalizedString(@"For example: urn:[BU]:[video|audio]:[uid]", nil)
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = LetterboxDemoNonLocalizedString(@"urn:swi:video:41981254");
    }];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleDefault handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Play", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *text = alertController.textFields.firstObject.text;
        completionBlock(text.length != 0 ? text : nil);
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark UITableViewDataSource protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return DemoSection.sections.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return DemoSection.sections[section].name;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return DemoSection.sections[section].summary;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return DemoSection.sections[section].medias.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * const kCellIdentifier = @"BasicCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    if (! cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifier];
    }
    
    return cell;
}

#pragma mark UITableViewDelegate protocol

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    Media *media = DemoSection.sections[indexPath.section].medias[indexPath.row];
    cell.textLabel.text = media.name;
}

#pragma mark UITableViewDelegate protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    Media *media = DemoSection.sections[indexPath.section].medias[indexPath.row];
    if ([media.URN isEqualToString:@"OTHER"]) {
        [self openCustomURNEntryAlertWithCompletionBlock:^(NSString * _Nullable URN) {
            [self openPlayerWithURN:URN serviceURL:media.serviceURL];
        }];
    }
    else {
        [self openPlayerWithURN:media.URN serviceURL:media.serviceURL];
    }
}

@end
