//
//  ViewController.m
//  Filter
//
//  Created by Hsusue on 2019/5/26.
//  Copyright © 2019 Hsusue. All rights reserved.
//

#import "ViewController.h"
#import "CustomCameraViewController.h"

#import <AVFoundation/AVFoundation.h>


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)cameraBtnClick:(id)sender {
    
    if ([self isCameraAvailable]) { // 有摄像头
        NSString *mediaType = AVMediaTypeVideo;// 读取媒体类型
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];// 读取设备授权状态
        
        if(authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied){
            NSString *errorStr = @"应用相机权限受限,请在设置中启用";
            [self showAlertControllerWithMessage:errorStr];
            return;
        } else if (authStatus == AVAuthorizationStatusAuthorized) { // 有权限
            [self presentToCameraVC];
        } else if (authStatus == AVAuthorizationStatusNotDetermined) { // 获取权限
            [self alertPromptToAllowCameraAccessViaSetting];
        }
    } else { // 无摄像头
        [self showAlertControllerWithMessage:@"该设备无摄像头"];
    }
    
}

/**
 请求权限
 */
- (void)alertPromptToAllowCameraAccessViaSetting {
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (granted) {
                [self presentToCameraVC];
            } else {
                [self showAlertControllerWithMessage:@"未获得权限"];
            }
        });
    }];
}

- (void)presentToCameraVC {
    CustomCameraViewController *vc = [[CustomCameraViewController alloc] init];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)showAlertControllerWithMessage:(NSString *)message {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

/**
 设备是否有摄像头
 
 @return 设备是否有摄像头
 */
- (BOOL) isCameraAvailable{
    return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
}

@end
