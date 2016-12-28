//
//  ShareViewController.m
//  ImageTransferExtension
//
//  Created by LongHenry on 2016/11/25.
//  Copyright © 2016年 qisda. All rights reserved.
//

#import "ShareViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface ShareViewController ()

@end


@implementation ShareViewController

- (void)loadView {
    [super loadView];
    
    arrayOfImageUrl = [[NSMutableArray alloc] init];
    arrayOfImageData = [[NSMutableArray alloc] init];
    // Insert code here to customize the view
    self.title = NSLocalizedString(@"ImageShare", @"Title of the Social Service");
    
    NSLog(@"Input Items = %@", self.extensionContext.inputItems);
    NSString *typeIdentifier = (NSString *)kUTTypeImage; //kUTTypeURL, kUTTypeImage;

    for (NSExtensionItem *item in self.extensionContext.inputItems){
        for (NSItemProvider *itemProvider in item.attachments){
            if ([itemProvider hasItemConformingToTypeIdentifier:typeIdentifier]) {
                [itemProvider loadItemForTypeIdentifier:typeIdentifier
                                                options:nil
                                      completionHandler:^(id<NSSecureCoding> item, NSError *error) {
                                          if(error){
                                              NSLog(@"Error retrieving: %@", error);
                                          }else {
                                              if([(NSObject*)item isKindOfClass:[NSURL class]]) {
                                                  NSURL* url = (NSURL*)item;
                                                  fileName = [url lastPathComponent];
                                                  NSLog(@"fileName: %@",fileName);
                                                  image = [NSData dataWithContentsOfURL:url];
                                                  [self inserDataToArray :[url path] : image];
                                              } //end if([(NSObject*)item isKindOfClass:[NSURL class]])
                                          }
                                      }];
            }
        }
    }
    
}

- (void) viewDidLoad {
    NSLog(@"viewDidLoad");
    [super viewDidLoad];
    //[self.textView setEditable:false];
}

- (void)didSelectPost {
    // Perform the post operation
    // When the operation is complete (probably asynchronously), the service should notify the success or failure as well as the items that were actually shared
    [self saveToExtension];
    [self invokeApp:NULL];
    [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
}

/*
 * It'a a workaround because extensionContext openURL always fail
 */
- ( void ) invokeApp: ( NSString * ) invokeArgs
{
    // Prepare the URL request
    // this will use the custom url scheme of your app
    // and the paths to the photos you want to share:
    NSLog(@"invokeApp");
    NSString * urlString = [ NSString stringWithFormat: @"%@://%@", @"ImageShare", ( NULL == invokeArgs ?  @"" : invokeArgs ) ];
    NSURL * url = [ NSURL URLWithString: urlString ];
    
    NSString *className = @"UIApplication";
    if ( NSClassFromString( className ) )
    {
        id object = [ NSClassFromString( className ) performSelector: @selector( sharedApplication ) ];
        [ object performSelector: @selector( openURL: ) withObject: url ];
    }
    
    // Now let the host app know we are done, so that it unblocks its UI:
    [ super didSelectPost ];
}


- (void)didSelectCancel {
    // Cleanup
    // Notify the Service was cancelled
    NSError *cancelError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];
    [self.extensionContext cancelRequestWithError:cancelError];
}


- (BOOL)isContentValid {
    NSLog(@"isContentValid");
    NSString * description =@"";
    NSString * extensions = @"jpg/jpeg/JPG/JPEG/png/PNG";
    NSArray * types = [extensions pathComponents];
    for (NSString *file in arrayOfImageUrl){
        description = [NSString stringWithFormat:@"%@%@\n", description, [file lastPathComponent]];
        BOOL isCorrectType = [types containsObject: [file pathExtension]];
        if (!isCorrectType){
            [self.textView setText:@"Format Not Allow! JPG/PNG Only"];
            return NO;
        }
    }
    [self.textView setText:description];
    return YES;
}


- (void)viewDidDisappear {
    NSLog(@"viewDidDisappear");
}

- (void) inserDataToArray: (NSString*)fileUrl : (NSData*)imageData {
    [arrayOfImageUrl addObject:fileUrl];
    [arrayOfImageData addObject:imageData];
}

- (void)saveToExtension {
    NSLog(@"saveToExtension");
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:@"group.ios.image.share"];
    [shared setObject:arrayOfImageUrl forKey:@"url"];
    [shared setObject:arrayOfImageData forKey:@"imageData"];
    [shared synchronize];
}


@end
