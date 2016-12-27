//
//  SendingFileClient.h
//  ImageTransfer
//
//  Created by LongHenry on 2016/12/7.
//  Copyright © 2016年 qisda. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Foundation/NSStream.h>


@class SendingViewController;

@interface SendingFileClient : NSObject <NSStreamDelegate> {
    NSUInteger byteIndex;
    BOOL isHeader;
    NSOutputStream *outputStream;
}

@property (nonatomic, weak) SendingViewController *mViewController;

- (void) initNetworkCommunication;
- (void) setview : (SendingViewController *)viewController;

@end


