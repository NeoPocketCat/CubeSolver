//
//  ViewController.m
//  CubeSolver
//
//  Created by neo on 2018/4/1.
//  Copyright © 2018 neo. All rights reserved.
//

#import "ViewController.h"
#import <ARKit/ARKit.h>
#import <Vision/Vision.h>

const static CGFloat ButtonHeight = 40;

@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, ARSessionDelegate, ARSCNViewDelegate>

@property(nonatomic, strong) UIImageView *imageView;

@property(nonatomic, strong) UIButton *cameraButton;

@property(nonatomic, strong) UIButton *photoPickerButton;

@property(nonatomic, strong) ARSCNView *sceneView;

@property(nonatomic, strong) CAShapeLayer *shapeLayer;

@property(nonatomic, assign) BOOL processingVersion;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - ButtonHeight)];

    _sceneView = [[ARSCNView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - ButtonHeight)];
//    _sceneView.delegate = self;
    _sceneView.session.delegate = self;

    _shapeLayer = [[CAShapeLayer alloc] init];
    _shapeLayer.lineWidth = 5;
    _shapeLayer.fillColor = [UIColor clearColor].CGColor;
    _shapeLayer.strokeColor = [UIColor greenColor].CGColor;

    _cameraButton = [[UIButton alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - ButtonHeight, self.view.bounds.size.width / 2, ButtonHeight)];
    _cameraButton.backgroundColor = [UIColor grayColor];
    [_cameraButton setTitle:@"Camera" forState:UIControlStateNormal];
    [_cameraButton addTarget:self action:@selector(openCamera) forControlEvents:UIControlEventTouchUpInside];
    _photoPickerButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width / 2, self.view.bounds.size.height - ButtonHeight, self.view.bounds.size.width / 2, ButtonHeight)];
    _photoPickerButton.backgroundColor = [UIColor blueColor];
    [_photoPickerButton addTarget:self action:@selector(selectImage) forControlEvents:UIControlEventTouchUpInside];
    [_photoPickerButton setTitle:@"Photo" forState:UIControlStateNormal];
    [self.view addSubview:_cameraButton];
    [self.view addSubview:_photoPickerButton];
}

- (void)openCamera {
    [_imageView removeFromSuperview];
    _sceneView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - ButtonHeight);
    [self.view addSubview:_sceneView];
    _sceneView.showsStatistics = YES;
    _sceneView.debugOptions = ARSCNDebugOptionShowFeaturePoints;

    _shapeLayer.frame = _sceneView.bounds;
    [_sceneView.layer addSublayer:_shapeLayer];


    ARWorldTrackingConfiguration *configuration = [ARWorldTrackingConfiguration new];
    //configuration.planeDetection = .horizontal

    [_sceneView.session runWithConfiguration:configuration];
}

- (void)selectImage {
//    [_sceneView removeFromSuperview];
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *, id> *)info {

}

#pragma mark - ARSessionDelegate

- (void)session:(ARSession *)session didUpdateFrame:(ARFrame *)frame {

    if (!_processingVersion) {
        _processingVersion = YES;
        CGAffineTransform transform = [frame displayTransformForOrientation:UIInterfaceOrientationPortrait viewportSize:_sceneView.bounds.size];
        transform = CGAffineTransformConcat(CGAffineTransformMake(1, 0, 0, -1, 0, 1), transform);
        transform = CGAffineTransformConcat(transform, CGAffineTransformMake(_sceneView.bounds.size.width, 0, 0, _sceneView.bounds.size.height, 0, 0));
        VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCVPixelBuffer:frame.capturedImage options:@{}];
        VNDetectRectanglesRequest *request = [[VNDetectRectanglesRequest alloc] initWithCompletionHandler:^(VNRequest *request, NSError *error) {
            NSArray *results = request.results;
            if (!results.count) {
                _shapeLayer.path = nil;
                _processingVersion = NO;
                return;
            }
            UIBezierPath *path = [UIBezierPath bezierPath];
            for (VNRectangleObservation *result in results) {
                [path moveToPoint:result.topLeft];
                [path addLineToPoint:result.topRight];
                [path addLineToPoint:result.bottomRight];
                [path addLineToPoint:result.bottomLeft];
                [path applyTransform:transform];
                [path closePath];
            }

            _shapeLayer.path = [path CGPath];


            _processingVersion = NO;
        }];

        void (^blockFunc)(VNDetectRectanglesRequest *)=^(VNDetectRectanglesRequest *request) {
            NSError *error;
            [handler performRequests:@[request] error:&error];
            if (error) {
                NSLog(@"error: %@", error);
            }

        };

        if ([[NSThread currentThread] isMainThread]) {
            blockFunc(request);
        } else {
            dispatch_async(dispatch_get_main_queue(), ^() {
                blockFunc(request);
            });
        }
    }
}

@end
