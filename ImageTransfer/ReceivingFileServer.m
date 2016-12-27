//
//  RecevingFileServer.m
//  ImageTransfer
//
//  Created by LongHenry on 2016/11/18.
//  Copyright © 2016年 qisda. All rights reserved.
//

/*
 Core Foundation is the C-level API, which provides CFString, CFDictionary and the like.
 Foundation is Objective-C, which provides NSString, NSDictionary, etc.
 */
#import "ReceivingFileServer.h"
#import "SendingViewController.h"
#import <CoreFoundation/CoreFoundation.h>
#import "AssetsLibrary/AssetsLibrary.h"
#import <Photos/Photos.h>
#import <sys/socket.h>
#import <netinet/in.h>

/* Port to listen on */
#define PORT 8989

CFReadStreamRef readStream;

@implementation ReceivingFileServer

- (void)setview : (SendingViewController *) viewController{
    self.mViewController = viewController;
}

- (int)setup {
     /* The server socket */
     CFSocketRef TCPServer;
    
     /* Used by setsockopt */
     int yes = 1;
     
     /* Build our socket context; */
     CFSocketContext CTX = { 0, (__bridge void *)(self), NULL, NULL, NULL };
     
     /* Create the server socket as a TCP IPv4 socket and set a callback */
     /* for calls to the socket's lower-level accept() function */
     TCPServer = CFSocketCreate(NULL, PF_INET, SOCK_STREAM, IPPROTO_TCP,
                                kCFSocketAcceptCallBack, (CFSocketCallBack)acceptCallBack, &CTX);
     if (TCPServer == NULL)
         return EXIT_FAILURE;
    
     /* Re-use local addresses, if they're still in TIME_WAIT */
     setsockopt(CFSocketGetNative(TCPServer), SOL_SOCKET, SO_REUSEADDR,
                (void *)&yes, sizeof(yes));
     
     /* Set the port and address we want to listen on */
     struct sockaddr_in addr;
     memset(&addr, 0, sizeof(addr));
     addr.sin_len = sizeof(addr);
     addr.sin_family = AF_INET;
     addr.sin_port = htons(PORT);
     addr.sin_addr.s_addr = htonl(INADDR_ANY);
     
     NSData *address = [ NSData dataWithBytes: &addr length: sizeof(addr) ];
     if (CFSocketSetAddress(TCPServer, (CFDataRef) address) != kCFSocketSuccess) {
         NSLog(@"CFSocketSetAddress() failed\n");
         CFRelease(TCPServer);
         return EXIT_FAILURE;
     }
     
     CFRunLoopSourceRef sourceRef = CFSocketCreateRunLoopSource(kCFAllocatorDefault, TCPServer, 0);
     CFRunLoopAddSource(CFRunLoopGetCurrent(), sourceRef, kCFRunLoopDefaultMode);
     CFRelease(sourceRef);
     
     NSLog(@"Socket listening on port %d\n", PORT);
    
     //Don't run the run loop yourself on the main thread. The main event loop will run it.
     //CFRunLoopRun();
     return 0;
}

static void acceptCallBack(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info)
{
    NSLog(@"acceptCallBack");
    readStream = NULL;
    
    CFOptionFlags registeredEvents = (kCFStreamEventOpenCompleted | kCFStreamEventHasBytesAvailable |
                                      kCFStreamEventEndEncountered | kCFStreamEventErrorOccurred);
    CFStreamClientContext ctx = {0, info, NULL, NULL, NULL};
    
    
    /* The native socket, used for various operations */
    CFSocketNativeHandle sock = *(CFSocketNativeHandle *) data;
    
    
    /* Create the read and write streams for the socket */
    CFStreamCreatePairWithSocket(kCFAllocatorDefault, sock, &readStream, NULL);

    if (!readStream ) {
        close(sock);
        NSLog(@"CFStreamCreatePairWithSocket() failed\n");
        return;
    }
    
    // Schedule the stream on the run loop to enable callbacks
    if(CFReadStreamSetClient(readStream, registeredEvents, readCallback, &ctx))
    {
        CFReadStreamScheduleWithRunLoop(readStream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    }
    
    if (CFReadStreamOpen(readStream) == NO) {
        NSLog(@"Failed to open read stream");
        return;
    }
    
}

static void readCallback(CFReadStreamRef stream, CFStreamEventType event, void *myPtr)
{
    
    ReceivingFileServer *delegate = (__bridge ReceivingFileServer *)myPtr;
    int kBufferSize = 1024;
    switch(event) {
        case kCFStreamEventOpenCompleted:{
            NSLog(@"Stream opened!");
            delegate->isHeader = true;
            delegate->data = [NSMutableData new];
            break;
        }
            
        case kCFStreamEventHasBytesAvailable: {
            // Read bytes until there are no more
            //
            while (CFReadStreamHasBytesAvailable(stream)) {
                UInt8 buffer[kBufferSize];
                long numBytesRead = CFReadStreamRead(stream, buffer, kBufferSize);
                //NSLog(@"readStream read %ld\n", numBytesRead);
                if (numBytesRead > 0) {
                    if(delegate->isHeader){
                        uint8_t headerBuf[1024];
                        uint8_t len = buffer[0];
                        for (int i = 0 ; i < len; i ++){
                            headerBuf[i] = buffer[i+1];
                        }
                        delegate->fileName = [[NSString alloc] initWithBytes:headerBuf length:len encoding:NSASCIIStringEncoding];
                        NSLog(@"fileName %@\n", delegate->fileName);
                        delegate->isHeader = false;
                        break;
                    }
                    
                    [delegate->data appendBytes:(const void *)buffer  length:numBytesRead];
                }
            }

            break;
        }
            
        case kCFStreamEventErrorOccurred: {
            CFErrorRef error = CFReadStreamCopyError(stream);
            if (error != NULL) {
                if (CFErrorGetCode(error) != 0) {
                    NSString * errorInfo = [NSString stringWithFormat:@"Failed while reading stream; error '%@' (code %ld)", (__bridge NSString*)CFErrorGetDomain(error), CFErrorGetCode(error)];
                    NSLog(@"errorInfo %@\n", errorInfo);
                }
                
                CFRelease(error);
            }
            CFReadStreamClose(stream);
            break;
        }
            
        case kCFStreamEventEndEncountered:{
            // Finnish receiveing data
            //
            NSLog(@"kCFStreamEventEndEncountered");
            UIImage *image = [[UIImage alloc] initWithData:delegate->data];
            //NSString *home = NSHomeDirectory();
            //NSString *downloads = [NSString stringWithFormat:@"%@%@", home, @"/Downloads/"];
            //NSString *path = [NSString stringWithFormat:@"%@%@", downloads, delegate->fileName];
            [delegate saveImage:image];

            // Clean up
            //
            CFReadStreamClose(stream);
            CFReadStreamUnscheduleFromRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
            //CFRunLoopStop(CFRunLoopGetCurrent());
            
            break;
        }
        default:
            break;
    }
}

- (void)saveImage: (UIImage*)image
{
    if (image != nil)
    {
        //Save to NSDocumentDirectory
        /*
         NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
         NSUserDomainMask, YES);
         NSString *documentsDirectory = [paths objectAtIndex:0];
         NSString* path = [documentsDirectory stringByAppendingPathComponent:
         [NSString stringWithString: fileName] ];
         NSLog(@"path: %@", path);
         NSData* imageFile = UIImagePNGRepresentation(image);
         [imageFile writeToFile:path atomically:YES];
         */
        //Save to photo lib
        UIImageWriteToSavedPhotosAlbum(image, self, @selector(savedPhotoImage:didFinishSavingWithError:contextInfo:), nil);
        self.mViewController.imageView.image = image ;
        self.mViewController.fileName.text = fileName;
        
       /* we can't open photo app by url, so skip it
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        [library writeImageToSavedPhotosAlbum:[image CGImage] orientation:(ALAssetOrientation)[image imageOrientation] completionBlock:^(NSURL *assetURL, NSError *error){
            if (error) {
                NSLog(@"error");  // oops, error !
            } else {
                NSLog(@"url %@", assetURL);  // assetURL is the url you looking for
            }
            
             NSString *description = [NSString stringWithFormat:@"%@ %@", fileName, @"has saved to photo lib"];
             UIAlertController *alertController;
             UIAlertAction* defaultAction;
             
             if(error){
                 alertController =
                 [UIAlertController alertControllerWithTitle:@"FAIL"
                                                     message:[error description]
                                              preferredStyle:UIAlertControllerStyleAlert];
                 
             }else{
                 alertController =
                 [UIAlertController alertControllerWithTitle:@"Received File"
                                                     message:description
                                              preferredStyle:UIAlertControllerStyleAlert];
                 defaultAction = [UIAlertAction actionWithTitle:@"OPEN"
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * action)
                                  {
                                      [self checkpermission];
                                      [[UIApplication sharedApplication] openURL:assetURL options:@{} completionHandler:
                                       ^(BOOL success) {
                                           NSLog(@"Open %@: %d",assetURL,success);
                                       }];
                                      
                                      
                                      
                                  }];
                 [alertController addAction:defaultAction];
             }
             
             
             UIAlertAction *cancelAction =[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
             [alertController addAction:cancelAction];
             
             [self.mViewController presentViewController:alertController animated:YES completion:nil];
         }];
        */
    }
}
- (void)checkpermission{
    
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    
    if (status == PHAuthorizationStatusAuthorized) {
        // Access has been granted.
        NSLog(@"Access has been granted");
    }
    
    else if (status == PHAuthorizationStatusDenied) {
        // Access has been denied.
        NSLog(@"Access has been denied");
    }
    
    else if (status == PHAuthorizationStatusNotDetermined) {
        
        // Access has not been determined.
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            
            if (status == PHAuthorizationStatusAuthorized) {
                // Access has been granted.
                NSLog(@"Access has been Authorized");
            }
            
            else {
                // Access has been denied.
                NSLog(@"Access has been rejected");
            }
        }];
    }
    
    else if (status == PHAuthorizationStatusRestricted) {
        // Restricted access - normally won't happen.
    }
    
}
- (void)savedPhotoImage:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    
    
    NSString *description = [NSString stringWithFormat:@"%@ %@", fileName, @"has saved to photo lib"];
    UIAlertController *alertController;
    //UIAlertAction* defaultAction;
    
    if(error){
        alertController =
        [UIAlertController alertControllerWithTitle:@"FAIL"
                                            message:[error description]
                                     preferredStyle:UIAlertControllerStyleAlert];

    }else{
        alertController =
        [UIAlertController alertControllerWithTitle:@"Received File"
                                            message:description
                                     preferredStyle:UIAlertControllerStyleAlert];
        self.mViewController.send.enabled = false;  //avoid user send the received image
       /* we can't open photo app by url
        defaultAction = [UIAlertAction actionWithTitle:@"OPEN"
                                                 style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * action)
                         {
                             NSURL *url = [NSURL URLWithString:@"http://google.com"];
                             
                             if ([[UIApplication sharedApplication] canOpenURL:url])
                             {
                                 [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
                             }
                             
                         }];
        [alertController addAction:defaultAction];
        */
    }
    
   
    UIAlertAction *cancelAction =[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:cancelAction];
    
    [self.mViewController presentViewController:alertController animated:YES completion:nil];
}



@end
