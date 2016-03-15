//
//  SendingViewController.m
//  ImageTransfer
//
//  Created by LongHenry on 2016/3/15.
//  Copyright © 2016年 qisda. All rights reserved.
//

#import "SendingViewController.h"

@interface SendingViewController () <UIImagePickerControllerDelegate,UINavigationControllerDelegate>
@property (strong, nonatomic) UIImagePickerController *imagePicker;
@end


@implementation SendingViewController
@synthesize inputStream, outputStream;
@synthesize imageData;
@synthesize result;

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void) initNetworkCommunication {
    
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    NSString *ip = @"192.168.49.1";
    UInt32 port = 8988;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)ip, port, &readStream, &writeStream);
    
    inputStream = (__bridge NSInputStream *)readStream;
    outputStream = (__bridge NSOutputStream *)writeStream;
    [inputStream setDelegate:self];
    [outputStream setDelegate:self];
    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [inputStream open];
    [outputStream open];
     byteIndex =0;
    
}

- (IBAction)dismissViewController:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [inputStream close];
    [outputStream close];
}

- (IBAction)hideKeyboard:(UITextField *)sender
{
    [sender resignFirstResponder];
}


- (IBAction) sendAndroid{
    [self initNetworkCommunication];
     //NSData *imageData = UIImagePNGRepresentation(self.imageView.image);
     imageData = UIImageJPEGRepresentation(self.imageView.image, 1.0);
}

/* chose from gallery */
- (IBAction)chooseImage:(id)sender
{
    [self presentViewController:self.imagePicker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
{
    self.imageView.image = image;
    [self.imagePicker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Getter
- (UIImagePickerController *)imagePicker
{
    if ( _imagePicker == nil )
    {
        if ( [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum] )
        {
            _imagePicker = [[UIImagePickerController alloc] init];
            _imagePicker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
            _imagePicker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeSavedPhotosAlbum];
            _imagePicker.delegate = self;
        }
    }
    return _imagePicker;
}

- (NSData *)prepareData:(NSData *)data
{
    NSUInteger length = [data length];
    NSMutableData *sendingData = [[NSMutableData alloc] init];
    NSUInteger size = sizeof(NSUInteger);   //be carefule it, before iphone 5/iPad 4 (included), NSUInteger size of is 4
    [sendingData appendBytes:&length length:size];
    [sendingData appendData:data];
    return sendingData;
}

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
    
    //NSLog(@"stream event %i", streamEvent);
    
    switch (streamEvent) {
            
        case NSStreamEventOpenCompleted:
            NSLog(@"Stream opened!");
            result.text = @"Stream opened!";
            break;
        case NSStreamEventHasBytesAvailable:
            
            if (theStream == inputStream) {  //response from server , but not be used in the prj now
                uint8_t buffer[1024];
                NSUInteger len;
                
                while ([inputStream hasBytesAvailable]) {
                    len = [inputStream read:buffer maxLength:sizeof(buffer)];
                    if (len > 0) {
                        
                        NSString *output = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
                        
                        if (nil != output) {
                            NSLog(@"server said: %@", output);
                            result.text = output;
                            
                        }
                    }
                }
            }
            break;
            
            
        case NSStreamEventErrorOccurred:
            
            NSLog(@"Can not connect to the host!");
            result.text = @"Can not connect to the host!";
            break;
            
        case NSStreamEventEndEncountered:
            NSLog(@"NSStreamEventEndEncountered!");
            result.text = @"NSStreamEventEndEncountered!";
            if(theStream == outputStream){
               [inputStream close];
               [outputStream close];
            }
            
            break;
        case NSStreamEventHasSpaceAvailable:
            if (theStream == outputStream){
                NSLog(@"NSStreamEventHasSpaceAvailable!");
                result.text = @"NSStreamEventHasSpaceAvailable!";
                
                uint8_t *readBytes = (uint8_t *)[imageData bytes];
                readBytes += byteIndex; // instance variable to move pointer
                NSUInteger data_len = [imageData length];
                NSUInteger len = ((data_len - byteIndex >= 1024) ?
                                    1024 : (data_len - byteIndex));
                uint8_t buf[len];
                (void)memcpy(buf, readBytes, len);
                len = [outputStream write:(const uint8_t *)buf maxLength:len];
                byteIndex += len;
                break;
            }
            
            break;
        default:
            NSLog(@"Unknown event");
            result.text = @"Unknown event";
    }
    
}





@end
