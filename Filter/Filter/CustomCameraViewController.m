//
//  CustomCameraViewController.m
//  LearningProject
//
//  Created by Hsusue on 2019/5/22.
//  Copyright © 2019 Hsusue. All rights reserved.
//

#import "CustomCameraViewController.h"

#import "FilterView.h"

#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>

#import <Masonry.h>

API_AVAILABLE(ios(10.0))
@interface CustomCameraViewController ()<AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, FilterViewDelegate>

// 音视频输入流
// 摄像头
@property(nonatomic, strong) AVCaptureDevice *device;
// 摄像头输入
@property(nonatomic, strong) AVCaptureDeviceInput *cameraDeviceInput;
// 麦克风输入
@property (nonatomic, strong) AVCaptureDeviceInput *microphoneDeviceInput;

// 音频、视频输出流
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioDataOutput;
@property (nonatomic, strong) dispatch_queue_t queue;

@property (nonatomic, strong) AVCaptureSession *session;

// 当前帧处理完的图片，实时更新
@property (nonatomic, strong) UIImage *outputImage;

// 视频录制用到的成员
@property (nonatomic, strong) AVAssetWriter *assetWriter;
// 录制文件临时保存路径
@property (nonatomic, strong) NSURL *fileUrl;
// 当前帧的尺寸，用于录制时设置尺寸
@property (nonatomic, assign) CMVideoDimensions currentVideoDimensions;
// 缓冲区
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *assetWriterInputPixelBufferInput;
@property (nonatomic, strong) AVAssetWriterInput *audioWriterInput;
@property (nonatomic, assign) CMTime currentSampleTime;

// 滤镜用到的
@property (nonatomic, strong) CIContext *ciContext;
@property (nonatomic, strong) CIFilter *filter;

// ------------- UI --------------
@property (nonatomic, strong) UIButton *photoButton;
@property (nonatomic, strong) UIButton *recordBtn;
// 聚焦显示框
@property (nonatomic, strong) UIView *focusView;
// 用来响应聚焦事件
@property (nonatomic, strong) UIView *clearView;
@property (nonatomic, strong) UIButton *changeModelBtn;
@property (nonatomic, strong) CALayer *previewLayer;

@property (nonatomic, assign) BOOL isShootStatus;
@property (nonatomic, assign) BOOL isRecording;

@end

@implementation CustomCameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    
    [self customCamera];
    [self initSubViews];
    
    [self focusAtPoint:CGPointMake(0.5, 0.5)];
    
    self.isShootStatus = YES;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if ([_session isRunning]) {
        [_session stopRunning];
    }
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)customCamera
{
    _ciContext = [[CIContext alloc]init];
    
    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    _cameraDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.device error:nil];
    
    _queue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
    _videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    _videoDataOutput.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInteger:kCVPixelFormatType_32BGRA]};
    _videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
    [_videoDataOutput setSampleBufferDelegate:self queue:_queue];


    _session = [[AVCaptureSession alloc] init];
    if ([_session canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
        [_session setSessionPreset:AVCaptureSessionPreset1280x720];
    }
    
    { // 把输入输出结合起来
        if ([_session canAddInput:_cameraDeviceInput]) {
            [_session addInput:_cameraDeviceInput];
        }
        if ([_session canAddOutput:_videoDataOutput]) {
            [_session addOutput:_videoDataOutput];
        }
    }
    
    
    //开始启动
    [_session startRunning];
    
    //修改设备的属性，先加锁
    if ([_device lockForConfiguration:nil]) {
        //自动白平衡
        if ([_device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance]) {
            [_device setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];
        }
        //解锁
        [_device unlockForConfiguration];
    }
}

- (void)initSubViews
{
    self.view.backgroundColor = [UIColor blackColor];
    
    _previewLayer = [[CALayer alloc] init];
    _previewLayer.anchorPoint = CGPointZero;
    _previewLayer.frame = CGRectMake(0, kTopMargin + 50, KScreenWidth, KScreenHeight - 100 - kBottomMargin - 50);
    [self.view.layer addSublayer:_previewLayer];
    
    FilterView *filterView = [[FilterView alloc] initWithFrame:CGRectMake(0, 0, KScreenWidth, 50 + kTopMargin)];
    filterView.delegate = self;
    [self.view addSubview:filterView];
    
    UIView *bottomBlackView = [[UIView alloc] init];
    bottomBlackView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:bottomBlackView];
    [bottomBlackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.bottom.right.equalTo(self.view);
        make.height.equalTo(@(100 + kBottomMargin));
    }];
    
    self.photoButton = [UIButton new];
    [self.photoButton setBackgroundImage:[UIImage imageNamed:@"shoot"] forState:UIControlStateNormal];
    [self.photoButton addTarget:self action:@selector(shutterCamera) forControlEvents:UIControlEventTouchUpInside];
    [bottomBlackView addSubview:self.photoButton];
    [self.photoButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(bottomBlackView);
        make.top.equalTo(bottomBlackView).offset(20);
        make.width.height.equalTo(@60);
    }];
    
    self.recordBtn = [UIButton new];
    [self.recordBtn setBackgroundImage:[UIImage imageNamed:@"record"] forState:UIControlStateNormal];
    [self.recordBtn setBackgroundImage:[UIImage imageNamed:@"stop"] forState:UIControlStateSelected];
    [self.recordBtn addTarget:self action:@selector(recordBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [bottomBlackView addSubview:self.recordBtn];
    [self.recordBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(bottomBlackView);
        make.top.equalTo(bottomBlackView).offset(20);
        make.width.height.equalTo(@60);
    }];
    self.recordBtn.hidden = YES;
    
    UIButton *changeCameraBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [changeCameraBtn setBackgroundImage:[UIImage imageNamed:@"changeCamera"] forState:UIControlStateNormal];
    changeCameraBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
    [changeCameraBtn sizeToFit];
    [changeCameraBtn addTarget:self action:@selector(changeCamera) forControlEvents:UIControlEventTouchUpInside];
    [bottomBlackView addSubview:changeCameraBtn];
    [changeCameraBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view).offset(-(20 + kBottomMargin));
        make.width.height.equalTo(@40);
        make.right.equalTo(self.view).offset(-20);
    }];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(focusGesture:)];
    UIView *clearView = [[UIView alloc] init];
    clearView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:clearView];
    [clearView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(filterView.mas_bottom);
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(bottomBlackView.mas_top);
    }];
    [clearView addGestureRecognizer:tapGesture];
    self.clearView = clearView;
    
    self.focusView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 80, 80)];
    self.focusView.layer.borderWidth = 1.0;
    self.focusView.layer.borderColor = [UIColor greenColor].CGColor;
    [self.clearView addSubview:self.focusView];
    self.focusView.hidden = YES;
    
    self.changeModelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.changeModelBtn setTitle:@"录制视频" forState:UIControlStateNormal];
    [self.changeModelBtn setTitle:@"拍摄照片" forState:UIControlStateSelected];
    [bottomBlackView addSubview:self.changeModelBtn];
    [self.changeModelBtn addTarget:self action:@selector(changeModeBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.changeModelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(bottomBlackView).offset(20);
        make.width.equalTo(@100);
        make.height.equalTo(@40);
        make.bottom.equalTo(self.view).offset(-(20 + kBottomMargin));
    }];
}

- (void)focusGesture:(UITapGestureRecognizer*)gesture{
    CGPoint point = [gesture locationInView:gesture.view];

    [self focusAtPoint:point];
}

- (void)focusAtPoint:(CGPoint)point{
    CGSize size = self.clearView.bounds.size;
    // focusPoint 函数后面Point取值范围是取景框左上角（0，0）到取景框右下角（1，1）之间,按这个来但位置就是不对，只能按上面的写法才可以。前面是点击位置的y/PreviewLayer的高度，后面是1-点击位置的x/PreviewLayer的宽度
    CGPoint focusPoint = CGPointMake( point.y /size.height ,1 - point.x/size.width );
    
    if ([self.device lockForConfiguration:nil]) {
        
        if ([self.device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            [self.device setFocusPointOfInterest:focusPoint];
            [self.device setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        
        if ([self.device isExposureModeSupported:AVCaptureExposureModeAutoExpose]) {
            [self.device setExposurePointOfInterest:focusPoint];
            //曝光量调节
            [self.device setExposureMode:AVCaptureExposureModeAutoExpose];
        }
        
        [self.device unlockForConfiguration];
        
        _focusView.center = point;
        _focusView.hidden = NO;
        [UIView animateWithDuration:0.3 animations:^{
            self->_focusView.transform = CGAffineTransformMakeScale(1.25, 1.25);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.5 animations:^{
                self->_focusView.transform = CGAffineTransformIdentity;
            } completion:^(BOOL finished) {
                self->_focusView.hidden = YES;
            }];
        }];
    }
    
}

#pragma mark- 按钮事件
- (void)shutterCamera
{
    [self.session stopRunning];
    [self saveImageWithImage:self.outputImage];
    [self.session startRunning];
}

- (void)recordBtnClick {
    if (self.isRecording) {// 退回不录制状态
        // 关闭音频输入和输出
        [self setAudioSwitchStatus:NO];
        
        self.recordBtn.selected = NO;
        self.changeModelBtn.hidden = NO;
        self.isRecording = NO;
        
        { // 保存视频
            self.assetWriterInputPixelBufferInput = nil;
            [self.recordBtn setEnabled:NO];
            [self.assetWriter finishWritingWithCompletionHandler:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"record complete!");
                });
                UISaveVideoAtPathToSavedPhotosAlbum(self.fileUrl.path, self, nil, nil);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.recordBtn setEnabled:YES];
                });
            }];
        }
    } else { // 进入录制
        // 启动音频输入和输出
        [self setAudioSwitchStatus:YES];
        
        self.recordBtn.selected = YES;
        self.changeModelBtn.hidden = YES;
        self.isRecording = YES;
        
        { // assetWriter 初始化及录制
            [self createHandler];
            [self.assetWriter startWriting];
            [self.assetWriter startSessionAtSourceTime:self.currentSampleTime];
        }
    }
}

- (void)changeCamera {
    AVCaptureDeviceDiscoverySession *deviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionUnspecified];
    
    //摄像头小于等于1的时候直接返回
    if (deviceDiscoverySession.devices.count <= 1) return;
    
    // 获取当前相机的方向(前还是后)
    AVCaptureDevicePosition position = [[self.cameraDeviceInput device] position];
    
    //为摄像头的转换加转场动画
    CATransition *animation = [CATransition animation];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.duration = 0.5;
    animation.type = @"oglFlip";
    
    AVCaptureDevice *newCamera = nil;
    if (position == AVCaptureDevicePositionFront) {
        //获取后置摄像头
        newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
        animation.subtype = kCATransitionFromLeft;
    } else {
        //获取前置摄像头
        newCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
        animation.subtype = kCATransitionFromRight;
    }
    
    [self.previewLayer addAnimation:animation forKey:nil];
    
    //输入流
    AVCaptureDeviceInput *newInput = [AVCaptureDeviceInput deviceInputWithDevice:newCamera error:nil];
    
    if (newInput != nil) {
        [self.session beginConfiguration];
        //先移除原来的input
        [self.session removeInput:self.cameraDeviceInput];
        if ([self.session canAddInput:newInput]) {
            [self.session addInput:newInput];
            self.cameraDeviceInput = newInput;
            
        } else {
            [self.session addInput:self.cameraDeviceInput];
        }
        [self.session commitConfiguration];
    }
}

- (void)changeModeBtnClick:(UIButton *)btn {
    if (btn.selected) {// 切换回拍摄照片
        self.isShootStatus = YES;
        self.isRecording = NO;
        self.photoButton.hidden = NO;
        self.recordBtn.hidden = YES;
    } else {// 切换到录制视频
        self.isShootStatus = NO;
        self.isRecording = NO;
        self.photoButton.hidden = YES;
        self.recordBtn.hidden = NO;
    }
    
    btn.selected = !btn.selected;
}

#pragma mark -- AVCaptureVideoDataOutputSampleBufferDelegate
// 在这里处理获取的图像，并且保存每一帧到self.outputImg
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    @autoreleasepool {
        if (output == _audioDataOutput && [_audioWriterInput isReadyForMoreMediaData]) {// 处理音频
            [_audioWriterInput appendSampleBuffer:sampleBuffer];
        }
        
        if (output == self.videoDataOutput) { // 处理视频帧
            // 处理图片，保存到self.outputImg中
            [self imageFromSampleBuffer:sampleBuffer];
        }
    }
}

#pragma mark -- FilterViewDelegate
- (void)filterView:(FilterView *)filterView chooseFilterName:(NSString *)filterName {
    if (filterName != nil) {
        self.filter = [CIFilter filterWithName:filterName];
    } else {
        self.filter = nil;
    }
}

- (void)filterView:(FilterView *)filterView cancelBtnClick:(UIButton *)cancelBtn {
    [self dismiss];
}

#pragma mark -- 处理图片
/**
 通过抽样缓存数据处理图像

 @param sampleBuffer 缓冲区
 @return 处理后的图片
 */
- (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer

{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CMVideoFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
    self.currentVideoDimensions = CMVideoFormatDescriptionGetDimensions(formatDescription);
    self.currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer);
    CIImage *result = [CIImage imageWithCVPixelBuffer:(CVPixelBufferRef)imageBuffer options:nil];
    
    // 添加滤镜
    if (self.filter) {
        [_filter setValue:result forKey:kCIInputImageKey];
        result = _filter.outputImage;
    }
    
    if (self.isRecording) {
        if (self.assetWriterInputPixelBufferInput.assetWriterInput.isReadyForMoreMediaData) {
            CVPixelBufferRef newPixelBuffer = nil;
            CVPixelBufferPoolCreatePixelBuffer(nil, self.assetWriterInputPixelBufferInput.pixelBufferPool, &newPixelBuffer);
            [self.ciContext render:result toCVPixelBuffer:newPixelBuffer bounds:result.extent colorSpace:nil];
            [self.assetWriterInputPixelBufferInput appendPixelBuffer:newPixelBuffer withPresentationTime:self.currentSampleTime];
            CVPixelBufferRelease(newPixelBuffer);
        }
    }
    
    // 处理设备旋转问题
    UIDeviceOrientation orientation = UIDevice.currentDevice.orientation;
    CGAffineTransform transform;
    if (orientation == UIDeviceOrientationPortrait) {
        transform = CGAffineTransformMakeRotation(-M_PI_2);
    }
    else if (orientation == UIDeviceOrientationPortraitUpsideDown) {
        transform = CGAffineTransformMakeRotation(M_PI_2);
    }
    else if (orientation == UIDeviceOrientationLandscapeRight) {
        transform = CGAffineTransformMakeRotation(M_PI);
    }
    else {
        transform = CGAffineTransformMakeRotation(0.0);
    }
    result = [result imageByApplyingTransform:transform];
    CGImageRef cgImage = [_ciContext createCGImage:result fromRect:result.extent];
    
    self.outputImage = [[UIImage alloc] initWithCGImage:cgImage];
    
    // 回主线程更换处理后的图片
    dispatch_async(dispatch_get_main_queue(), ^{
        self.previewLayer.contents = (__bridge id)cgImage;
        // 因为CG 结构，要自己释放
        CGImageRelease(cgImage);
    });
    
    return self.outputImage;
    
}



/**
 * 保存图片到相册
 */
- (void)saveImageWithImage:(UIImage *)image {
    // 判断授权状态
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status != PHAuthorizationStatusAuthorized) {
            [self showAlertControllerWithMessage:@"保存失败,App无权限访问相册"];
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *error = nil;
            
            // 保存相片到相机胶卷
            __block PHObjectPlaceholder *createdAsset = nil;
            [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
                createdAsset = [PHAssetCreationRequest creationRequestForAssetFromImage:image].placeholderForCreatedAsset;
            } error:&error];
            
            if (error) {
                NSLog(@"保存失败：%@", error);
                return;
            }
        });
    }];
}

#pragma mark -- private method
- (void)setAudioSwitchStatus:(BOOL)status {
    [_session beginConfiguration];
    
    if (status) {
        if ([_session canAddInput:self.microphoneDeviceInput]) {
            [_session addInput:self.microphoneDeviceInput];
        }
        if ([_session canAddOutput:self.audioDataOutput]) {
            [_session addOutput:self.audioDataOutput];
        }
    } else {
        [_session removeInput:self.microphoneDeviceInput];
        [_session removeOutput:self.audioDataOutput];
    }
    
    [_session commitConfiguration];
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position {
    AVCaptureDeviceDiscoverySession *deviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionUnspecified];
    for ( AVCaptureDevice *device in deviceDiscoverySession.devices )
        if ( device.position == position ) return device;
    return nil;
}

- (void)showAlertControllerWithMessage:(NSString *)message {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


/**
 assetWriter 初始化设置
 */
- (void)createHandler {
    { // 删除之前录制的临时文件
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:self.fileUrl.path]) {
            [fileManager removeItemAtURL:self.fileUrl error:nil];
        }
    }
    
    self.assetWriter = [[AVAssetWriter alloc] initWithURL:self.fileUrl fileType:AVFileTypeQuickTimeMovie error:nil];
    
    // 视频设置
    NSDictionary *outputSettings = @{
                                     AVVideoCodecKey : AVVideoCodecH264,
                                     AVVideoWidthKey : [NSNumber numberWithInt:self.currentVideoDimensions.width],
                                     AVVideoHeightKey : [NSNumber numberWithInt:self.currentVideoDimensions.height]
                                     };
    AVAssetWriterInput *videoWriterInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo
                                                                          outputSettings:outputSettings];
    videoWriterInput.expectsMediaDataInRealTime = YES;
    // 手机设备默认旋转了 90 度，设置回去
    videoWriterInput.transform = CGAffineTransformMakeRotation(M_PI_2);
    
    // 缓冲区设置
    NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                                           [NSNumber numberWithInt:kCVPixelFormatType_32BGRA], (NSString *)kCVPixelBufferPixelFormatTypeKey,
                                                           [NSNumber numberWithInt:self.currentVideoDimensions.width], (NSString *)kCVPixelBufferWidthKey,
                                                           [NSNumber numberWithInt:self.currentVideoDimensions.height], (NSString *)kCVPixelBufferHeightKey,
                                                           kCFBooleanTrue, (NSString *)kCVPixelFormatOpenGLESCompatibility,
                                                           nil];
    self.assetWriterInputPixelBufferInput = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:videoWriterInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    
    // 音频设置
    AudioChannelLayout acl;
    bzero(&acl, sizeof(acl));
    acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
    NSDictionary *audioOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [NSNumber numberWithInt:kAudioFormatMPEG4AAC], AVFormatIDKey,
                                         [NSNumber numberWithInt:64000], AVEncoderBitRateKey,
                                         [NSNumber numberWithFloat:44100.0], AVSampleRateKey,
                                         [NSNumber numberWithInt:1], AVNumberOfChannelsKey,
                                         [NSData dataWithBytes:&acl length:sizeof(acl)], AVChannelLayoutKey,
                                         nil ];
    _audioWriterInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:audioOutputSettings];
    _audioWriterInput.expectsMediaDataInRealTime = YES;
    
    { // 添加输入流
        if ([self.assetWriter canAddInput:videoWriterInput]) {
            [self.assetWriter addInput:videoWriterInput];
        }
        if ([self.assetWriter canAddInput:_audioWriterInput]) {
            [self.assetWriter addInput:_audioWriterInput];
        }
    }
}

#pragma mark -- 懒加载
- (NSURL *)fileUrl {
    if (!_fileUrl) {
        _fileUrl = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"tmp.mp4"]];
    }
    return _fileUrl;
}

- (AVCaptureAudioDataOutput *)audioDataOutput {
    if (!_audioDataOutput) {
        _audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
        [_audioDataOutput setSampleBufferDelegate:self queue:_queue];
    }
    return _audioDataOutput;
}

- (AVCaptureDeviceInput *)microphoneDeviceInput {
    if (!_microphoneDeviceInput) {
        AVCaptureDevice *micDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        _microphoneDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:micDevice error:nil];
    }
    return _microphoneDeviceInput;
}

@end
