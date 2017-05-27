//
//  ViewController.m
//  videoRecordingDemo
//
//  Created by apple on 2017/5/4.
//  Copyright © 2017年 . All rights reserved.
//

#import "ViewController.h"
#import "CRecordViewController.h"


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    UIButton * startBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    startBtn.frame = CGRectMake((SCREEN_WIDTH - 150)/2, SCREEN_HEIGHT/2, 150, 80);
    [startBtn setTitle:@"Click on me" forState:UIControlStateNormal];
    startBtn.backgroundColor = [UIColor redColor];
    startBtn.layer.cornerRadius = 5;
    [self.view addSubview:startBtn];
    [startBtn addTarget:self action:@selector(setupAVCaptureInfo) forControlEvents:UIControlEventTouchUpInside];
}


-(void)setupAVCaptureInfo
{
    if ([self checkAuthorization]) {
        CRecordViewController * vc = [CRecordViewController recordWithDuration:10
                                                                     TargetSize:nil
                                                                  InerViewColor:nil
                                                               ProgressBarWidth:5
                                                              ProgressBackColor:[UIColor colorWithWhite:1.0 alpha:0.6]
                                                                  ProgressColor:nil
                                                                  LandscapeMode:NO];
        vc.finishBlock = ^(NSString * filePath){
            NSLog(@"开始上传,路径为 ： %@",filePath);
        };
        [self presentViewController:vc animated:YES completion:nil];
        
//        this is default setting
//        CRecordViewController * vc = [[CRecordViewController alloc]init];
//        
//        [self presentViewController:vc animated:YES completion:nil];
    }
}

// 检测权限
- (BOOL)checkAuthorization{
    BOOL allowed = NO;
    AVAuthorizationStatus videoAuthorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    AVAuthorizationStatus audioAuthorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if ((videoAuthorizationStatus == AVAuthorizationStatusAuthorized || videoAuthorizationStatus == AVAuthorizationStatusNotDetermined)
        && (audioAuthorizationStatus == AVAuthorizationStatusAuthorized || audioAuthorizationStatus == AVAuthorizationStatusNotDetermined)) {
        allowed = YES;
    }
    if (!allowed) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"请在iPhone的\"设置-隐私\"选项中，允许访问你的摄像头和麦克风。" message:@"" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alert show];
    }
    return allowed;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
