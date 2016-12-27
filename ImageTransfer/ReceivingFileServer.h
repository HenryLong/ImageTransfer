//
//  RecevingFileServer.h
//  ImageTransfer
//
//  Created by LongHenry on 2016/11/18.
//  Copyright © 2016年 qisda. All rights reserved.
//

#import <Foundation/NSStream.h>
#import <UIKit/UIKit.h>

@class SendingViewController;

@interface ReceivingFileServer : NSObject <NSStreamDelegate> {
    NSMutableData *data;
    NSString *fileName;
    BOOL isHeader;
}

@property (nonatomic, weak) SendingViewController *mViewController;

- (int)setup;
- (void)setview : (SendingViewController *)viewController;
- (void)saveImage: (UIImage*)image;


@end
