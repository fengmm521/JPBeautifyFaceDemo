//
//  ViewController.m
//  BeautifyFaceDemo
//
//  Created by guikz on 16/4/27.
//  Copyright © 2016年 guikz. All rights reserved.
//

#import "ViewController.h"
#import <GPUImage/GPUImage.h>
#import "GPUImageBeautifyFilter.h"
#import <Masonry/Masonry.h>


//默认摄像头丢掉的帧数
#define kRecorderDropFramesInCamera           (2)

static int dropped = 0;

@interface ViewController ()

@property (nonatomic, strong) GPUImageVideoCamera *videoCamera;
@property (nonatomic, strong) GPUImageView *filterView;
@property (nonatomic, strong) UIButton *beautifyButton;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _started = NO;
    
    self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionFront];
    self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    self.videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    self.filterView = [[GPUImageView alloc] initWithFrame:self.view.frame];
    self.filterView.center = self.view.center;
    
    [self.view addSubview:self.filterView];
    [self.videoCamera addTarget:self.filterView];
    [self.videoCamera startCameraCapture];
    
    self.beautifyButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.beautifyButton.backgroundColor = [UIColor whiteColor];
    [self.beautifyButton setTitle:@"开启" forState:UIControlStateNormal];
    [self.beautifyButton setTitle:@"关闭" forState:UIControlStateSelected];
    [self.beautifyButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [self.beautifyButton addTarget:self action:@selector(beautify) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.beautifyButton];
    [self.beautifyButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view).offset(-20);
        make.width.equalTo(@100);
        make.height.equalTo(@40);
        make.centerX.equalTo(self.view);
    }];

}

- (void)beautify {
    if (self.beautifyButton.selected) {
        self.beautifyButton.selected = NO;
        [self.videoCamera removeAllTargets];
        [self.videoCamera addTarget:self.filterView];
    }
    else {
        self.beautifyButton.selected = YES;
        [self.videoCamera removeAllTargets];
        GPUImageBeautifyFilter *beautifyFilter = [[GPUImageBeautifyFilter alloc] init];
        __weak typeof(self) weakSelf = self;
        [beautifyFilter setFrameProcessingCompletionBlock:^(GPUImageOutput * imageOutput, CMTime presentTime) {
            [weakSelf filterOutputImage:imageOutput presenttime:presentTime];
            //[self filterOutputImage:imageOutput presenttime:presentTime];
        }];
        [self.videoCamera addTarget:beautifyFilter];
        [beautifyFilter addTarget:self.filterView];
    }
}


#pragma mark - Process Camera Buffer
- (void)filterOutputImage:(GPUImageOutput *) filterImage presenttime:(CMTime) presentTime {
    if (dropped++ < kRecorderDropFramesInCamera) {
        return;
    }
    
    GPUImageFramebuffer *frameBuffer = filterImage.framebufferForOutput;
    CVPixelBufferLockBaseAddress(_imagePixelBuffer, 0);
    GLubyte *pixBufferData= (GLubyte *)CVPixelBufferGetBaseAddress(_imagePixelBuffer);//获取_imagePixelBuffer的指针地址，准备填入数据
    //    GLubyte *pixBufferData = frameBuffer.byteBuffer;
    CGImageRef cgimg = [filterImage newCGImageFromCurrentlyProcessedOutput];
    
    CGColorSpaceRef genericRGBColorspace = CGColorSpaceCreateDeviceRGB();
    CGContextRef imageContext = CGBitmapContextCreate(pixBufferData,
                                                      frameBuffer.size.width,
                                                      frameBuffer.size.height,
                                                      8,
                                                      frameBuffer.bytesPerRow,
                                                      genericRGBColorspace,
                                                      kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGContextDrawImage(imageContext, CGRectMake(0.0, 0.0, frameBuffer.size.width, frameBuffer.size.height), cgimg);
    CGContextRelease(imageContext);
    CGColorSpaceRelease(genericRGBColorspace);
    CVPixelBufferUnlockBaseAddress(_imagePixelBuffer, 0);
    _started = YES;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
