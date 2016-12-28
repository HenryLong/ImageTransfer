//
//  ShareViewController.h
//  ImageTransferExtension
//
//  Created by LongHenry on 2016/11/25.
//  Copyright © 2016年 qisda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Social/Social.h>

@interface ShareViewController : SLComposeServiceViewController {
    NSData *image;
    NSString *fileName;
    NSMutableArray *arrayOfImageUrl;
    NSMutableArray *arrayOfImageData;
}

@end
