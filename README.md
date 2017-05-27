# CShortVideo
A short video recording of the project, imitate WeChat small video.


Simple to use, first,add the **CShortVide** folder to your project.

 next，you need to _#import “CRecordViewController.h”_ ，and next：


```
       CRecordViewController * vc = [CRecordViewController recordWithDuration:10
                                                                     TargetSize:AVAssetExportPreset960x540
                                                                  InerViewColor:[UIColor colorWithWhite:0.5f alpha:1.0f]
                                                               ProgressBarWidth:5
                                                              ProgressBackColor:[UIColor colorWithWhite:1.0f alpha:0.6f]
                                                                  ProgressColor:[UIColor greenColor]
                                                                  LandscapeMode:NO];
        vc.finishBlock = ^(NSString * filePath){
            NSLog(@"upload!, path is ： %@",filePath);
        };
        [self presentViewController:vc animated:YES completion:nil];
```
Or you can use the default style, just like this：


```
        CRecordViewController * vc = [[CRecordViewController alloc]init];
        [self presentViewController:vc animated:YES completion:nil];
```

Maybe you have any questions, you need to ask me or find bug. You can send me a brief letter from Jane. Thank you very much.
Jane address : http://www.jianshu.com/u/bd29a2cb4b4d
