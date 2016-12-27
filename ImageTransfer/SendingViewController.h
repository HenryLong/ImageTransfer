//
//  SendingViewController.h
//  ImageTransfer
//
//  Created by LongHenry on 2016/3/15.
//  Copyright © 2016年 qisda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SendingFileClient.h"
#import "ReceivingFileServer.h"

@interface SendingViewController : UIViewController <UIImagePickerControllerDelegate,UINavigationControllerDelegate>{
    NSUInteger byteIndex;
    SendingFileClient *mSendingClient;
    ReceivingFileServer *mReceivingFileServer;
}

/*
 * @Property是声明属性的语法，它可以快速方便的为实例变量创建存取器，并允许我们通过点语法使用存取器。
 */
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UITextField *result;
@property (nonatomic, weak) IBOutlet UITextField *fileName;
@property (nonatomic, weak) IBOutlet UIButton *send;
@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSData *imageData;
@property (nonatomic, strong) UIImagePickerController *imagePicker;

@property (nonatomic, strong)NSMutableArray *imageArrayUrl;  //from share extension
@property (nonatomic, strong)NSMutableArray *imageArrayData; //from share extension

- (NSUInteger) processImageList;

@end
