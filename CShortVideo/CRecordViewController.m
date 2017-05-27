//
//  CRecordViewController.m
//  videoRecordingDemo
//
//  Created by apple on 2017/5/6.
//  Copyright © 2017年 qibo. All rights reserved.
//

#import "CRecordViewController.h"
#import "CRecordToolView.h"
#import "CRecordButton.h"
#import "CPlayerView.h"
#import "AppDelegate.h"


@interface CRecordViewController ()<AVCaptureFileOutputRecordingDelegate,AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate,CRecordViewDelegate>
{
    int recordLongTime; /**< 录制时长 */
    NSString * finalVedioPath; /**< 最终文件路径 */
}

typedef void(^PropertyChangeBlock)(AVCaptureDevice *captureDevice);


// AVCaptureMovieFileOutput
@property (nonatomic) dispatch_queue_t sessionQueue;
/**< 输入设备和输出设备之间的数据传递 */
@property (nonatomic, strong) AVCaptureSession *captureSession;
/**< 视频输入 */
@property (nonatomic, strong) AVCaptureDeviceInput *videoDeviceInput;
/**< 声音输入 */
@property (nonatomic, strong) AVCaptureDeviceInput *audioDeviceInput;
/**< 视频输出流 */
@property (nonatomic,strong)AVCaptureMovieFileOutput *captureMovieFileOutput;
/**< 预览图层 */
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
/**< 预览视图 */
@property (nonatomic, strong) UIView *preView;
/**< 镜头翻转按钮 */
@property (nonatomic,strong)UIButton * cameraBtn;
/**< 记录录制时间 */
@property (nonatomic, strong) NSTimer *timer;

@property (atomic,assign) BOOL isRecording; /**< 是否正在录制 */
@property (nonatomic,assign)BOOL isCanceled;/**< 是否取消录制 */

@property (nonatomic,strong) CPlayerView *playerView; /**< 回放 */
@property (nonatomic,strong) AppDelegate * appdelegate; /**< 设置横屏 */





/**
 video duration
 */
@property (nonatomic,assign)CGFloat videoDuration;

/**
 Target resolution for video files (data output used)，default is 320*240
 */
@property (nonatomic,strong,nonnull)NSString * targetSize;

/**
 Video aspect ratio (file output usage)，default is 1.75
 */
@property (nonatomic,assign)CGFloat widthHeightScale;

/**
 Horizontal screen ， default is NO
 */
@property (nonatomic,assign)BOOL landscapeMode;

/**
 video duration
 */
@property (nonatomic,assign)CGFloat progressBarWidth;

/**
 record iner View color
 */
@property (nonatomic,strong)UIColor *inerViewColor;

/**
 progress bar background color
 */
@property (nonatomic,strong)UIColor *progressBackColor;

/**
 Progress completed color
 */
@property (nonatomic,strong)UIColor *progressColor;



@end

@implementation CRecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self makeUI];
    [self initRecord];
    
}

#pragma mark - UI 初始化
-(void)makeUI
{
    self.view.backgroundColor = [UIColor grayColor];
    recordLongTime = 0;
    
    
    if (_landscapeMode) {
        // 转屏
        _appdelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
        self.appdelegate.allowRotate = 1;
        [self setNewOrientation:YES];//调用转屏代码
    }
    
    
    // 预览视图
    _preView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    _preView.backgroundColor = [UIColor blackColor];
    _preView.layer.masksToBounds = YES;
    [self.view addSubview:_preView];
    
    // 摄像头翻转按钮
    _cameraBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_cameraBtn setFrame:CGRectMake(SCREEN_WIDTH-50, 10, 30, 30)];
    [_cameraBtn setBackgroundImage:[UIImage imageNamed:@"flipCamera"]
                          forState:UIControlStateNormal];
    [_cameraBtn addTarget:self
                   action:@selector(switchCamera)
         forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.cameraBtn];
    
    // 底部按钮视图
    CRecordToolView *toolView = [CRecordToolView creatWithDuration:_videoDuration
                                                     InerViewColor:_inerViewColor
                                                  ProgressBarWidth:_progressBarWidth
                                                 ProgressBackColor:_progressBackColor
                                                     ProgressColor:_progressColor];
    toolView.delegate  = self;
    [self.view addSubview:toolView];
}

#pragma mark - 初始化录像
-(void)initRecord
{
    // 初始化会话//这里根据需要设置  可以设置4K
    
    _captureSession = [[AVCaptureSession alloc]init];
    if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {//设置分辨率
        [_captureSession setSessionPreset:AVCaptureSessionPreset1280x720];
    }
    
    // 获取视频输入设备,后置摄像头
    AVCaptureDevice *captureDevice = [self getCameraDeviceWithPositon:AVCaptureDevicePositionBack];
    if (!captureDevice) {
        NSLog(@"获取摄像头失败");
        _captureSession = nil;
        return;
    }
    
    // 初始化视频输入对象
    NSError *error = nil;
    _videoDeviceInput = [[AVCaptureDeviceInput alloc]initWithDevice:captureDevice error:&error];
    if (error) {
        NSLog(@"获取设备输入对象失败，error:%@",error.localizedDescription);
        return;
    }
    
    // 获取音频输入设备
    AVCaptureDevice *audiocaptureDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio]firstObject];
    if (!audiocaptureDevice) {
        NSLog(@"获取音频设备失败");
        return;
    }
    
    // 初始化音频输入对象
    _audioDeviceInput = [[AVCaptureDeviceInput alloc]initWithDevice:audiocaptureDevice error:&error];
    if (error) {
        NSLog(@"获取音频输入对象失败，error:%@",error.localizedDescription);
        return;
    }
    
    //将设备输入添加到会话中
    if ([_captureSession canAddInput:_videoDeviceInput]) {
        [_captureSession addInput:_videoDeviceInput];
        [_captureSession addInput:_audioDeviceInput];
    }
    
    //创建视频预览层
    _captureVideoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    _captureVideoPreviewLayer.frame = _preView.bounds;
    _captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    //_captureVideoPreviewLayer.orientation =AVCaptureVideoOrientationLandscapeRight;
    if (_captureVideoPreviewLayer.connection.supportsVideoOrientation) {
        _captureVideoPreviewLayer.connection.videoOrientation = [self interfaceOrientationToVideoOrientation:[UIApplication sharedApplication].statusBarOrientation];
    }
    [_preView.layer  insertSublayer:_captureVideoPreviewLayer atIndex:0];
    
    
    _captureMovieFileOutput = [[AVCaptureMovieFileOutput alloc]init];
    AVCaptureConnection *captureConnection = [_captureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    if ([captureConnection isVideoStabilizationSupported]) {
        captureConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
    }
    //将设备输出添加到会话中
    if ([_captureSession canAddOutput:_captureMovieFileOutput]) {
        [_captureSession addOutput:_captureMovieFileOutput];
    }
    
    
}

#pragma mark - 开启 session
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if (_captureSession) {
        [_captureSession startRunning];
    }
}

#pragma mark - 关闭 session
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    if (_captureSession && [_captureSession isRunning]) {
        [_captureSession stopRunning];
    }
    // 转屏回来
    self.appdelegate.allowRotate = NO;
    [self setNewOrientation:NO];
}

#pragma mark - record button delegate
// 长按开始录制
-(void)onTouchDown
{
    NSURL * fileURL = [NSURL fileURLWithPath:[self tempFilePath]];
    
    self.isCanceled = NO;
    self.isRecording = YES;
    //根据设备输出获得连接
    AVCaptureConnection *captureConnection = [_captureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    //根据连接取得设备输出的数据
    if (!_captureMovieFileOutput.isRecording) {
        //预览图层和视频方向保持一致
        captureConnection.videoOrientation = _landscapeMode ? AVCaptureVideoOrientationLandscapeRight :AVCaptureVideoOrientationPortrait;
        [_captureMovieFileOutput startRecordingToOutputFileURL:fileURL recordingDelegate:self];
        [self setupTimer];
    } else {
        //停止保存
        [_captureMovieFileOutput stopRecording];
    }
}

// 点击
-(void)onTap
{
    
}

// 手指上移
-(void)onMoveUp
{
    self.isCanceled = YES;
}
// 手指移回
-(void)onMoveBack
{
    self.isCanceled = NO;
}

// 松开结束录制
-(void)onTouchUp
{
    if (!_captureSession.isRunning) {
        return;
    }
    
    [_captureSession stopRunning];
    //结束定时器
    [self removeTimer];
    
    if (self.isCanceled) {

        [self reMakeVideo];
    }
    
}

// 点击对号保存并上传录制
-(void)finishTakeVideo
{
    if (self.finishBlock) {
        self.finishBlock(finalVedioPath);
    }
}

// 点击撤销重新录制
-(void)reMakeVideo
{
    // 移除回放
    [_playerView removeFromSuperview];
    _playerView = nil;
    //结束定时器
    [self removeTimer];
    
    if (!_captureSession.isRunning) {
         [_captureSession startRunning];
    }
}

// 退出视图
-(void)onDismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - AVCaptureFileOutput delegate
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
    NSLog(@"---- 开始录制 URL = %@",fileURL);
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    if (outputFileURL.absoluteString.length == 0 && captureOutput.outputFileURL.absoluteString.length == 0 ) {
        return;
    }
    NSLog(@"---- 录制结束 ---%@-%@ ",outputFileURL,captureOutput.outputFileURL);
    
    if (self.isCanceled) {
        
        [self deleteVideoFileWithFileURL:outputFileURL];
    } else {
        // 压缩
        [self cropVideoWithFilrURL:outputFileURL];

    }
    
}


#pragma mark -- crop video （压缩视频）
//crop video
- (void)cropVideoWithFilrURL:(NSURL *)fileURL {
    if (![[NSFileManager defaultManager] fileExistsAtPath:[fileURL.absoluteString substringFromIndex:7]]){
        return;
    }
    
    NSLog(@"开始压缩,压缩前大小 %f MB",[self fileSize:fileURL]);
    // input file
    AVAsset *asset = [AVAsset assetWithURL:fileURL];
    AVMutableVideoComposition *videoComposition;
/*
//    // input clip
//    AVAssetTrack *clipVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    
    // make it square
//    videoComposition = [AVMutableVideoComposition videoComposition];
//    videoComposition.renderSize = CGSizeMake(clipVideoTrack.naturalSize.height, clipVideoTrack.naturalSize.height * 1.5f);
//    videoComposition.frameDuration = CMTimeMake(1, 30);
//    
//    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
//    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(60, 30) );
//    
//    // rotate to portrait
//    AVMutableVideoCompositionLayerInstruction *transformer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:clipVideoTrack];
//    CGAffineTransform t1 = CGAffineTransformMakeTranslation(clipVideoTrack.naturalSize.height, -(clipVideoTrack.naturalSize.width - clipVideoTrack.naturalSize.height * _widthHeightScale) /2 );
//    CGAffineTransform t2 = CGAffineTransformRotate(t1, M_PI_2);
//    
//    CGAffineTransform finalTransform = t2;
//    [transformer setTransform:finalTransform atTime:kCMTimeZero];
//    instruction.layerInstructions = [NSArray arrayWithObject:transformer];
//    videoComposition.instructions = [NSArray arrayWithObject:instruction];
    
*/
    NSLog(@"视频分辨率 ： %@",_targetSize);
    // export
    NSString *outputFilePath = [self outputFilePath];
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:asset
                                                                      presetName:_targetSize];
    //优化网络
    exporter.shouldOptimizeForNetworkUse = true;
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.videoComposition = videoComposition;
    exporter.outputURL = [NSURL fileURLWithPath:outputFilePath];
    
    [exporter exportAsynchronouslyWithCompletionHandler:^(void){
        // 如果导出的状态为完成
        if ([exporter status] == AVAssetExportSessionStatusCompleted) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                // 回放 , 回放的时候总是不播放，最后发现手机原因，重启或者换个手机就好了
                [self prepareToPublishWithFileURL:[NSURL fileURLWithPath:outputFilePath]];
                finalVedioPath = outputFilePath;
                NSLog(@"压缩完毕,压缩后大小 %f MB",[self fileSize:[NSURL fileURLWithPath:outputFilePath]]);
            });
            [self deleteVideoFileWithFileURL:fileURL];
            NSLog(@"Export done!");
        }
        
    }];
}


#pragma mark - 文件大小
- (CGFloat)fileSize:(NSURL *)path
{
    return [[NSData dataWithContentsOfURL:path] length]/1024.00 /1024.00;
}


#pragma mark - 回放
- (void)prepareToPublishWithFileURL:(NSURL *)fileURL{
    
    _playerView = [[CPlayerView alloc]initWithFrame:self.preView.frame];
    _playerView.muted = YES;
    [self.view insertSubview:_playerView atIndex:1];
    _playerView.URL = fileURL;
}

#pragma mark - 文件操作
// 获取保存路径
- (NSString *)tempFilePath{
    NSString *outputFileDir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"/Library/tempVideo"];
    BOOL isDir = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL existed = [fileManager fileExistsAtPath:outputFileDir isDirectory:&isDir];
    if (!(isDir == YES && existed == YES)){
        [fileManager createDirectoryAtPath:outputFileDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *filePath = [NSString stringWithFormat:@"%@/%@%@",outputFileDir,[[NSDate date].description stringByReplacingOccurrencesOfString:@" " withString:@"_"],@".mov"];
    return filePath;
}
// 文件输出路径
- (NSString *)outputFilePath{
    NSString *outputFileDir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"/Library/outputVideo"];
    BOOL isDir = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL existed = [fileManager fileExistsAtPath:outputFileDir isDirectory:&isDir];
    if (!(isDir == YES && existed == YES)){
        [fileManager createDirectoryAtPath:outputFileDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *filePath = [NSString stringWithFormat:@"%@/%@%@",outputFileDir,[[NSDate date].description stringByReplacingOccurrencesOfString:@" " withString:@"_"],@".mp4"];
    return filePath;
}
// 删除生成的文件
- (BOOL)deleteVideoFileWithFileURL:(NSURL *)fileURL{
    if ([[NSFileManager defaultManager] fileExistsAtPath:[fileURL.absoluteString substringFromIndex:7]]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:[fileURL.absoluteString substringFromIndex:7] error:&error];
        if (!error) {
            NSLog(@"delete success");
            return YES;
        } else {
            NSLog(@"delete error: %@",error);
            return NO;
        }
    }
    NSLog(@"delete file does not exist");
    return NO;
}

#pragma mark - 获得指定位置的摄像头
- (AVCaptureDevice *)getCameraDeviceWithPositon:(AVCaptureDevicePosition)positon{
    NSArray *cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in cameras) {
        if (device.position == positon) {
            return device;
        }
    }
    return nil;
}

#pragma mark - 属性改变操作
-(void)changeDeviceProperty:(PropertyChangeBlock)propertyChange{
    AVCaptureDevice *captureDevice = [self.videoDeviceInput device];
    NSError *error;
    //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁
    if ([captureDevice lockForConfiguration:&error]) {
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
    }else{
        NSLog(@"设置设备属性过程发生错误，错误信息：%@",error.localizedDescription);
    }
}

#pragma mark - 启动定时器
- (void)setupTimer{
    if (self.timer && self.timer.isValid) {
        return;
    }

    recordLongTime = 0;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                  target:self
                                                selector:@selector(countDown:)
                                                userInfo:nil
                                                 repeats:YES];
    
}

#pragma mark - 定时器执行
-(void)countDown:(NSTimer*)timerer{
    recordLongTime++;
    NSLog(@"录制时长 ： %d",recordLongTime);
}

#pragma mark - 移除定时器
- (void)removeTimer{
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

#pragma mark - 切换摄像头
-(void)switchCamera
{
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationOptionTransitionFlipFromRight
                     animations:^{
                         
        [self swapFrontAndBackCameras];
                         
    } completion:nil ];
}

#pragma mark - 摄像头翻转
- (void)swapFrontAndBackCameras {
    // Assume the session is already running
    
    NSArray *inputs =self.captureSession.inputs;
    for (AVCaptureDeviceInput *input in inputs ) {
        AVCaptureDevice *device = input.device;
        if ( [device hasMediaType:AVMediaTypeVideo] ) {
            AVCaptureDevicePosition position = device.position;
            AVCaptureDevice *newCamera =nil;
            AVCaptureDeviceInput *newInput =nil;
            
            if (position ==AVCaptureDevicePositionFront)
                newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
            else
                newCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
            newInput = [AVCaptureDeviceInput deviceInputWithDevice:newCamera error:nil];
            
            // beginConfiguration ensures that pending changes are not applied immediately
            [self.captureSession beginConfiguration];
            
            [self.captureSession removeInput:input];
            [self.captureSession addInput:newInput];
            
            // Changes take effect once the outermost commitConfiguration is invoked.
            [self.captureSession commitConfiguration];
            break;
        }
    }
}
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices )
        if ( device.position == position )
            return device;
    return nil;
}

#pragma mark - 转屏设置
-(AVCaptureVideoOrientation)interfaceOrientationToVideoOrientation:(UIInterfaceOrientation)orientation {
    
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            return AVCaptureVideoOrientationPortrait;
        case UIInterfaceOrientationPortraitUpsideDown:
            return AVCaptureVideoOrientationPortraitUpsideDown;
        case UIInterfaceOrientationLandscapeLeft:
            return AVCaptureVideoOrientationLandscapeLeft ;
        case UIInterfaceOrientationLandscapeRight:
            return AVCaptureVideoOrientationLandscapeRight;
        default:
            break;
    }
    NSLog(@"Warning - Didn't recognise interface orientation (%ld)",orientation);
    return AVCaptureVideoOrientationPortrait;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    if (_captureVideoPreviewLayer.connection.supportsVideoOrientation) {
        _captureVideoPreviewLayer.connection.videoOrientation = [self interfaceOrientationToVideoOrientation:toInterfaceOrientation];
    }
}

#pragma mark - set screen orientation
- (void)setNewOrientation:(BOOL)fullscreen

{
    if (fullscreen) {
        
        NSNumber *resetOrientationTarget = [NSNumber numberWithInt:UIInterfaceOrientationUnknown];
        
        [[UIDevice currentDevice] setValue:resetOrientationTarget forKey:@"orientation"];
        
        NSNumber *orientationTarget = [NSNumber numberWithInt:UIInterfaceOrientationLandscapeRight];
        
        [[UIDevice currentDevice] setValue:orientationTarget forKey:@"orientation"];
        
    }else{
        
        NSNumber *resetOrientationTarget = [NSNumber numberWithInt:UIInterfaceOrientationUnknown];
        
        [[UIDevice currentDevice] setValue:resetOrientationTarget forKey:@"orientation"];
        
        NSNumber *orientationTarget = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
        
        [[UIDevice currentDevice] setValue:orientationTarget forKey:@"orientation"];
        
    }
}

#pragma mark - 初始化
+(instancetype)recordWithDuration:(CGFloat)duration
                       TargetSize:(NSString *)targetSize
                    InerViewColor:(UIColor *)inerViewColor
                 ProgressBarWidth:(CGFloat)progressBarWidth
                ProgressBackColor:(UIColor *)progressBackColor
                    ProgressColor:(UIColor *)progressColor
                    LandscapeMode:(BOOL)landscapeMode
{
    return [[self alloc]initWithWithDuration:duration
                                  TargetSize:targetSize
                               InerViewColor:inerViewColor
                            ProgressBarWidth:progressBarWidth
                           ProgressBackColor:progressBackColor
                               ProgressColor:progressColor
                               LandscapeMode:landscapeMode];
}

-(instancetype)initWithWithDuration:(CGFloat)duration
                         TargetSize:(NSString *)targetSize
                      InerViewColor:(UIColor *)inerViewColor
                   ProgressBarWidth:(CGFloat)progressBarWidth
                  ProgressBackColor:(UIColor *)progressBackColor
                      ProgressColor:(UIColor *)progressColor
                      LandscapeMode:(BOOL)landscapeMode
{
    self = [super init];
    if (self) {
        _videoDuration = duration;
        _targetSize = targetSize;
        _inerViewColor = inerViewColor;
        _progressBarWidth = progressBarWidth;
        _progressBackColor = progressBackColor;
        _progressColor = progressColor;
        _landscapeMode = landscapeMode;
        
        if (targetSize == nil || [targetSize isKindOfClass:[NSNull class]]) {
            _targetSize = AVAssetExportPreset640x480;
            NSLog(@"_targetSize “ %@",_targetSize);
        }
        if (inerViewColor == nil || [inerViewColor isKindOfClass:[NSNull class]]) {
            _inerViewColor = [UIColor redColor];
            NSLog(@"_progressBackColor “ %@",_inerViewColor);
        }
        if (progressBackColor == nil || [progressBackColor isKindOfClass:[NSNull class]]) {
            _progressBackColor = [UIColor colorWithWhite:0.8f alpha:0.7];
            
        }
        if (progressColor == nil || [progressColor isKindOfClass:[NSNull class]]) {
            _progressColor = [UIColor greenColor];
            NSLog(@"_progressColor “ %@",_progressColor);
        }
    }
    return self;
}


- (instancetype)init{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup{
    
    _widthHeightScale = 1.75f;
    _videoDuration = 15.0f;
    _targetSize = AVAssetExportPreset640x480;
    _inerViewColor = [UIColor redColor];
    _progressBarWidth = 5.0f;
    _progressBackColor = [UIColor colorWithWhite:0.8f alpha:0.7];
    _progressColor = [UIColor greenColor];
    _landscapeMode = NO;
}


#pragma mark - default set
- (void)dealloc{
    [self removeTimer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}


@end
