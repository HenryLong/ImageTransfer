//
//  SendingViewController.h
//  ImageTransfer
//
//  Created by LongHenry on 2016/3/15.
//  Copyright © 2016年 qisda. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SendingViewController : UIViewController <NSStreamDelegate> {
    NSInputStream	*inputStream;
    NSOutputStream	*outputStream;
    NSData *imageData;
    NSUInteger byteIndex;
    UITextField		*result;
}

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic, retain) NSInputStream *inputStream;
@property (nonatomic, retain) NSOutputStream *outputStream;
@property (nonatomic, retain) NSData *imageData;
@property (nonatomic, retain) IBOutlet UITextField	*result;
- (void) initNetworkCommunication;


@end
