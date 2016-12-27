//
//  SendingFileClient.m
//  ImageTransfer
//
//  Created by LongHenry on 2016/12/7.
//  Copyright © 2016年 qisda. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SendingFileClient.h"
#import "SendingViewController.h"


NSString *description = @"";

@implementation SendingFileClient

- (void)setview : (SendingViewController *) viewController{
    self.mViewController = viewController;
}


-(void) initNetworkCommunication {
    CFWriteStreamRef writeStream;
    NSString *ip = @"192.168.49.1";
    UInt32 sendPort = 8988;
    
    byteIndex = 0;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)ip, sendPort, NULL , &writeStream);
    
    outputStream = (__bridge NSOutputStream *)writeStream;
    [outputStream setDelegate:self];
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream open];
}


- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent
{
    //NSLog(@"stream event %i", streamEvent);
    switch (streamEvent) {
        case NSStreamEventOpenCompleted:
        {
            NSLog(@"Stream opened!");
            self.mViewController.result.text = @"Stream opened!";
            isHeader = true;
            break;
        }
        case NSStreamEventHasBytesAvailable:
        {
            break;
        }
        case NSStreamEventErrorOccurred:
        {
            NSLog(@"Can not connect to the host!");
            self.mViewController.result.text = @"Can not connect to the host!";
            
            
            NSError *theError = [theStream streamError];
            NSLog(@"Error: %@",theError);
            [theStream close];
            
            UIAlertController *alertController =
            [UIAlertController alertControllerWithTitle:@"Send Fail"
                                                message:[theError description]
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *cancelAction =[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
            [alertController addAction:cancelAction];
            [self.mViewController presentViewController:alertController animated:YES completion:nil];
            break;
        }
        case NSStreamEventEndEncountered:
        {
            NSLog(@"NSStreamEventEndEncountered!");
            self.mViewController.result.text = @"NSStreamEventEndEncountered!";
            if(theStream == outputStream){
                [outputStream close];
                [outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
                outputStream = nil; // stream is ivar, so reinit it
            }
            description = [NSString stringWithFormat:@"%@%@\n", description, self.mViewController.fileName.text];
            
            NSUInteger mCount = [self.mViewController processImageList]; //To process others if exist
            NSLog(@"mCount: %ld",mCount);
            if(mCount == 0){
                NSLog(@"Process finished");
                UIAlertController *alertController =
                [UIAlertController alertControllerWithTitle:@"Sent File"
                                                    message:description
                                             preferredStyle:UIAlertControllerStyleAlert];
                
                
                UIAlertAction *okAction =[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
                [alertController addAction:okAction];
                description = @"";  //reset
                [self.mViewController presentViewController:alertController animated:YES completion:nil];
            }
            break;
        }
        case NSStreamEventHasSpaceAvailable:
        {
            if (theStream == outputStream){
                //NSLog(@"NSStreamEventHasSpaceAvailable!");
                self.mViewController.result.text = @"NSStreamEventHasSpaceAvailable!";
                
                if(isHeader){   //everytime transfer packet header first, 1024 bytes for length + filename
                    uint8_t headerBuf[1024];
                    NSUInteger headerLen = 1024;
                    NSData* filename = [[self.mViewController.fileName text] dataUsingEncoding:NSUTF8StringEncoding];
                    uint8_t * filebytes = (uint8_t *)[filename bytes];
                    headerBuf[0] = filename.length;
                    for (int i = 0 ; i < filename.length; i ++){
                        headerBuf[i+1] = filebytes[i];
                    }
                    [outputStream write:(const uint8_t *)headerBuf maxLength:headerLen];
                    NSLog(@"outputStream write header %ld\n", headerLen);
                    isHeader = false;
                }
                
                uint8_t *readBytes = (uint8_t *)[self.mViewController.imageData bytes];
                readBytes += byteIndex; // instance variable to move pointer
                NSUInteger data_len = [self.mViewController.imageData length];
                NSUInteger len = ((data_len - byteIndex >= 1024) ?
                                  1024 : (data_len - byteIndex));
                uint8_t buf[len];
                (void)memcpy(buf, readBytes, len);
                len = [outputStream write:(const uint8_t *)buf maxLength:len];
                //NSLog(@"outputStream write %ld\n", len);
                byteIndex += len;
            }
            break;
        }
        default:
            NSLog(@"Unknown event");
            self.mViewController.result.text = @"Unknown event";
    }
    
}
@end

