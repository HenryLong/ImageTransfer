//
//  SendingViewController.m
//  ImageTransfer
//
//  Created by LongHenry on 2016/3/15.
//  Copyright © 2016年 qisda. All rights reserved.
//

#import "SendingViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>


@implementation SendingViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString * path = [[NSBundle mainBundle] pathForResource: @"Qisda" ofType: @"jpg"];   //default picture
    NSURL * url = [NSURL fileURLWithPath: path];
    self.fileName.text = [url lastPathComponent];
    self.imageData = [NSData dataWithContentsOfURL:url];  //construct imageData
    
    //Initiate SendingClent
    mSendingClient = [[SendingFileClient alloc] init];
    [mSendingClient setview: self];
    
    //Initiate ReceivingFileServer
    mReceivingFileServer = [[ReceivingFileServer alloc] init];
    [mReceivingFileServer setview: self];
    [mReceivingFileServer setup];
}

- (IBAction)dismissViewController:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)hideKeyboard:(UITextField *)sender
{
    [sender resignFirstResponder];
}

- (IBAction) sendAndroid:(id)sender{
    [mSendingClient initNetworkCommunication];
}

/* chose from gallery */
- (IBAction)chooseImage:(id)sender
{
    [self presentViewController:self.imagePicker animated:YES completion:nil];
    self.send.enabled = true;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [self.imagePicker dismissViewControllerAnimated:YES completion:nil];
    self.imageView.image = [info objectForKey:UIImagePickerControllerOriginalImage];;
    self.imageData = UIImageJPEGRepresentation(self.imageView.image, 1.0);  //we have raw data here
    //self.imageData = UIImagePNGRepresentation(self.imageView.image);
    
    ALAssetsLibrary *assetLibray = [[ALAssetsLibrary alloc] init];
    [assetLibray assetForURL:[info objectForKey:UIImagePickerControllerReferenceURL] resultBlock:^(ALAsset *asset){
        self.fileName.text = asset.defaultRepresentation.filename; //we have name here
        self.path = [asset.defaultRepresentation.url path]; //we have path here
        NSLog(@"image name is %@", self.fileName.text);
        NSLog(@"image path is %@", self.path);
        [mSendingClient initNetworkCommunication]; //send it directly
    } failureBlock:^(NSError *err){
        NSLog(@"err:%@",err);
    }];
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


- (NSUInteger) processImageList{
    NSLog(@"imageArrayData count: %tu", self.imageArrayData.count);
    NSUInteger mCount = self.imageArrayData.count;
    if(self.imageArrayData.count != 0){
        //deliver first index
        [self openImageURL: [NSURL fileURLWithPath: [self.imageArrayUrl objectAtIndex:0]]];
        [self openImageData: [self.imageArrayData objectAtIndex:0]];
        
        [mSendingClient initNetworkCommunication];
        
        [self.imageArrayUrl removeObjectAtIndex:0];
        [self.imageArrayData removeObjectAtIndex:0];
    }
    return mCount;
}

- (void)openImageURL: (NSURL*)url
{
    NSLog(@"openImageURL: %@",url);
    self.path = [url path]; //we have path here
    self.fileName.text = [url lastPathComponent];
}


- (void)openImageData: (NSData*)image
{
    NSLog(@"openImageData: %@",image);
    self.imageData = image;   //construct imageData
    self.imageView.image = [[UIImage alloc] initWithData:image];
}

@end
