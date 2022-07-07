//
//  CameraPreview.m
//  camerawesome
//
//  Created by Dimitri Dessus on 23/07/2020.
//

#import "CameraPreview.h"
#import "UIDevice+Extension.h"
#import "CameraEnum.h"

API_AVAILABLE(ios(10.0))
@interface PhotoCaptureOutputAdaptee : NSObject

@property (nonatomic, strong) AVCapturePhotoOutput *photoOutput;

@end

@implementation PhotoCaptureOutputAdaptee
{
    NSDictionary<AVCaptureDeviceType,AVCaptureDevice *> *availableRearDeviceMap;
    NSDictionary<AVCaptureDeviceType,AVCaptureDevice *> *availableFrontDeviceMap;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        availableRearDeviceMap = [self availableDevicesForPostion:AVCaptureDevicePositionBack];
        availableFrontDeviceMap = [self availableDevicesForPostion:AVCaptureDevicePositionFront];
    }
    return self;
}

- (NSDictionary<AVCaptureDeviceType,AVCaptureDevice *> *)availableDevicesForPostion:(AVCaptureDevicePosition)postion
{
    NSMutableArray *queryDeviceTypes = [NSMutableArray arrayWithObjects:AVCaptureDeviceTypeBuiltInWideAngleCamera, AVCaptureDeviceTypeBuiltInTelephotoCamera,nil];
    if (@available(iOS 10.2, *)) {
        [queryDeviceTypes addObject:AVCaptureDeviceTypeBuiltInDualCamera];
    }
    
    if (@available(iOS 13, *)) {
        [queryDeviceTypes addObject:AVCaptureDeviceTypeBuiltInUltraWideCamera];
        [queryDeviceTypes addObject:AVCaptureDeviceTypeBuiltInDualWideCamera];
        [queryDeviceTypes addObject:AVCaptureDeviceTypeBuiltInTripleCamera];
    }
    
    AVCaptureDeviceDiscoverySession * session = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:queryDeviceTypes mediaType:AVMediaTypeVideo position:postion];
    
    NSMutableDictionary<AVCaptureDeviceType,AVCaptureDevice *> * deviceMap = [NSMutableDictionary dictionary];
    
    for (AVCaptureDevice * device in session.devices) {
        [deviceMap setObject:device forKey:device.deviceType];
    }
    
    return deviceMap;
}

- (NSArray<AVCaptureDeviceType> *)availableDeviceTypesForPostion: (AVCaptureDevicePosition)postion
{
    NSMutableArray<AVCaptureDeviceType> * deviceTypes = [NSMutableArray array];
    switch (postion) {
        case AVCaptureDevicePositionFront:
            for (AVCaptureDeviceType deviceType in availableFrontDeviceMap.allKeys) {
                [deviceTypes addObject:deviceType];
            }
            break;
        case AVCaptureDevicePositionUnspecified:
            for (AVCaptureDeviceType deviceType in availableFrontDeviceMap.allKeys) {
                [deviceTypes addObject:deviceType];
            }
            break;
        case AVCaptureDevicePositionBack:
            for (AVCaptureDeviceType deviceType in availableRearDeviceMap.allKeys) {
                [deviceTypes addObject:deviceType];
            }
            break;
        default:
            return [NSArray array];
            break;
    }
    return [NSArray arrayWithArray:deviceTypes];
}

- (NSArray<NSNumber *> *)cameraSwitchOverZoomFactorsForPostion:(AVCaptureDevicePosition)postion {
    NSDictionary<AVCaptureDeviceType,AVCaptureDevice *> * deviceMap = postion == AVCaptureDevicePositionFront ? availableFrontDeviceMap : availableRearDeviceMap;
    
    if (@available(iOS 13, *)) {
        AVCaptureDevice * multiCameraDevice = deviceMap[AVCaptureDeviceTypeBuiltInDualWideCamera];
        if (multiCameraDevice == nil) {
            multiCameraDevice = deviceMap[AVCaptureDeviceTypeBuiltInTripleCamera];
        }
        if (multiCameraDevice == nil) {
            multiCameraDevice = deviceMap[AVCaptureDeviceTypeBuiltInDualCamera];
        }
        
        NSArray<NSNumber *> *factors = multiCameraDevice.virtualDeviceSwitchOverVideoZoomFactors;
        return factors;
    }else {
        if (@available(iOS 10.2, *)) {
            if (deviceMap[AVCaptureDeviceTypeBuiltInDualCamera] != nil) {
                return [[UIDevice currentDevice] isPlusSizePhone] ? @[@(2.5)] : @[@(2)];
            }
        } else {
            return @[];
        }
    }
    return @[];
}

- (AVCaptureDevice * _Nullable)videoDeviceForDeviceType:(AVCaptureDeviceType)deviceType position:(AVCaptureDevicePosition)postion {
    switch (postion) {
        case AVCaptureDevicePositionBack:
            return availableRearDeviceMap[deviceType];
        case AVCaptureDevicePositionUnspecified:
        case AVCaptureDevicePositionFront:
            return availableFrontDeviceMap[deviceType];
        default:
            return [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
    }
}

@end

const CGFloat MAX_ZOOM_FACTOR = 6.0;

API_AVAILABLE(ios(10.0))
@interface CameraHelper : NSObject

@end

@implementation CameraHelper

+ (NSArray<NSNumber *> *)availableCamerasForPostion:(AVCaptureDevicePosition)position photoCaptureOutput: (PhotoCaptureOutputAdaptee *) photoCaptureOutput {
    NSArray<AVCaptureDeviceType> * avTypes = [photoCaptureOutput availableDeviceTypesForPostion:position];
    NSMutableArray * cameras = [NSMutableArray array];
    if (@available(iOS 13, *)) {
        if ([avTypes containsObject:AVCaptureDeviceTypeBuiltInUltraWideCamera]) {
            [cameras addObject: @(CameraTypeUltraWide)];
        }
    }
    
    if ([avTypes containsObject:AVCaptureDeviceTypeBuiltInWideAngleCamera]) {
        [cameras addObject: @(CameraTypeWideAngle)];
    }
    if ([avTypes containsObject:AVCaptureDeviceTypeBuiltInTelephotoCamera]) {
        [cameras addObject: @(CameraTypeTelephoto)];
    }
    return cameras;
}

+ (CameraSystem)bestAvailableCameraSystemForPostion:(AVCaptureDevicePosition)position photoCaptureOutput:(PhotoCaptureOutputAdaptee *) photoCaptureOutput{
    NSArray<AVCaptureDeviceType> * avTypes = [photoCaptureOutput availableDeviceTypesForPostion:position];
    if (@available(iOS 13, *)) {
        if ([avTypes containsObject: AVCaptureDeviceTypeBuiltInUltraWideCamera]) {
            return CameraSystemTriple;
        }
        if ([avTypes containsObject: AVCaptureDeviceTypeBuiltInDualWideCamera]) {
            return CameraSystemDualWide;
        }
    }
    if (@available(iOS 10.2, *)) {
        if ([avTypes containsObject: AVCaptureDeviceTypeBuiltInDualCamera]) {
            return CameraSystemDual;
        }
    }
    return CameraSystemWide;
}

+ (AVCaptureDeviceType)avCaptureDeviceTypeForCameraSystem:(CameraSystem) cameraSystem {
    switch (cameraSystem) {
        case CameraSystemWide:
            return AVCaptureDeviceTypeBuiltInWideAngleCamera;
        case CameraSystemDual:
            if (@available(iOS 10.2, *)) {
                return AVCaptureDeviceTypeBuiltInDualCamera;
            } else {
                return AVCaptureDeviceTypeBuiltInWideAngleCamera;
            }
        case CameraSystemDualWide:
            if (@available(iOS 13.0, *)) {
                return AVCaptureDeviceTypeBuiltInDualWideCamera;
            } else {
                return AVCaptureDeviceTypeBuiltInWideAngleCamera;
            }
        case CameraSystemTriple:
            if (@available(iOS 13.0, *)) {
                return AVCaptureDeviceTypeBuiltInTripleCamera;
            } else {
                return AVCaptureDeviceTypeBuiltInWideAngleCamera;
            }
        default:
            return AVCaptureDeviceTypeBuiltInWideAngleCamera;
    }
}

+ (CGFloat)minVisibleVideoZoomForDevice:(AVCaptureDevice *)device photoCaptureOutput: (PhotoCaptureOutputAdaptee *) photoCaptureOutput{
    NSArray<NSNumber *> *cameras = [self availableCamerasForPostion:device.position photoCaptureOutput:photoCaptureOutput];
    if ([cameras containsObject:@(CameraTypeUltraWide)]) {
        return 0.5;
    }
    return 1;
}

// 6x of the "zoom factor" of the camera with the longest focal length
+ (CGFloat)maximumZoomFactorForDevice:(AVCaptureDevice *)device  photoCaptureOutput:(PhotoCaptureOutputAdaptee *) photoCaptureOutput{
    AVCaptureDevicePosition position = device.position;
    NSDictionary<NSNumber *, NSNumber *> * cameraZoomFactorMap = [self cameraZoomFactorMapForPostion:position photoCaptureOutput:photoCaptureOutput];
    NSArray<NSNumber *> * allValues = cameraZoomFactorMap.allValues;
    CGFloat factor = 1;
    for (NSNumber * value in allValues) {
        if (value.doubleValue > factor) {
            factor = value.doubleValue;
        }
    }
    CGFloat maxVisibleZoomFactor = MAX_ZOOM_FACTOR * factor;
    return maxVisibleZoomFactor / [self cameraZoomFactorMultiplierForPostion:position photoCaptureOutput:photoCaptureOutput];
}

+ (NSDictionary<NSNumber *, NSNumber *> *)cameraZoomFactorMapForPostion:(AVCaptureDevicePosition)position photoCaptureOutput:(PhotoCaptureOutputAdaptee *) photoCaptureOutput {
    NSArray<NSNumber *> *zoomFactors = [photoCaptureOutput cameraSwitchOverZoomFactorsForPostion:position];
    NSArray<AVCaptureDeviceType> *avTypes = [photoCaptureOutput availableDeviceTypesForPostion:position];
    CGFloat cameraZoomFactorMultiplier = [self cameraZoomFactorMultiplierForPostion:position photoCaptureOutput:photoCaptureOutput];
    NSMutableDictionary<NSNumber *, NSNumber *> *cameraMap = [NSMutableDictionary dictionary];
    if (@available(iOS 13, *)) {
        if ([avTypes containsObject:AVCaptureDeviceTypeBuiltInUltraWideCamera]) {
            cameraMap[@(CameraTypeWideAngle)] = @(cameraZoomFactorMultiplier);
        }
    }
    if ([avTypes containsObject:AVCaptureDeviceTypeBuiltInTelephotoCamera] && zoomFactors.lastObject) {
        cameraMap[@(CameraTypeTelephoto)] = @(cameraZoomFactorMultiplier * zoomFactors.lastObject.doubleValue);
    }
    
    cameraMap[@(CameraTypeWideAngle)] = @(1);
    
    return cameraMap;
}

// If device has an ultra-wide camera then API zoom factor of "1" means
// full FOV of the ultra-wide camera which is "0.5" in the UI.
+ (CGFloat)cameraZoomFactorMultiplierForPostion:(AVCaptureDevicePosition)position photoCaptureOutput: (PhotoCaptureOutputAdaptee *) photoCaptureOutput {
    NSArray<NSNumber *> *cameras = [self availableCamerasForPostion:position photoCaptureOutput:photoCaptureOutput];
    if ([cameras containsObject:@(CameraTypeUltraWide)]) {
        return 0.5;
    }
    return 1;
}

+ (CameraType)cameraTypeForValue:(NSNumber *)value  {
    switch (value.intValue) {
        case 0:
            return CameraTypeUltraWide;
        case 1:
            return CameraTypeWideAngle;
        default:
            return CameraTypeTelephoto;
    }
}

@end

@interface CameraPreview ()
@property (nonatomic,strong) PhotoCaptureOutputAdaptee * photoCaptureAdaptee;
@property (assign, nonatomic) CGFloat maxZoomFactor;
@end

@implementation CameraPreview {
    dispatch_queue_t _dispatchQueue;
}

- (instancetype)initWithCameraSensor:(CameraSensor)sensor
                        streamImages:(BOOL)streamImages
                         captureMode:(CaptureModes)captureMode
                              result:(nonnull FlutterResult)result
                       dispatchQueue:(dispatch_queue_t)dispatchQueue
                           messenger:(NSObject<FlutterBinaryMessenger> *)messenger
                    orientationEvent:(FlutterEventSink)orientationEventSink
                 videoRecordingEvent:(FlutterEventSink)videoRecordingEventSink
                    imageStreamEvent:(FlutterEventSink)imageStreamEventSink {
    self = [super init];
    
    _result = result;
    _messenger = messenger;
    _dispatchQueue = dispatchQueue;
    
    // Creating capture session
    _captureSession = [[AVCaptureSession alloc] init];
    _captureVideoOutput = [AVCaptureVideoDataOutput new];
    _captureVideoOutput.videoSettings = @{(NSString*)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
    [_captureVideoOutput setAlwaysDiscardsLateVideoFrames:YES];
    [_captureVideoOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    [_captureSession addOutputWithNoConnections:_captureVideoOutput];
    
    [self initCameraPreview:sensor];
    
    [_captureConnection setAutomaticallyAdjustsVideoMirroring:NO];
    
    _captureMode = captureMode;
    _maxZoomFactor = MAX_ZOOM_FACTOR;
    // By default enable auto flash mode
    _flashMode = AVCaptureFlashModeOff;
    _torchMode = AVCaptureTorchModeOff;
    
    _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_captureSession];
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    _cameraSensor = sensor;
    
    // Controllers init
    _videoController = [[VideoController alloc] initWithEventSink:videoRecordingEventSink result:result];
    _imageStreamController = [[ImageStreamController alloc] initWithEventSink:imageStreamEventSink];
    _motionController = [[MotionController alloc] initWithEventSink:orientationEventSink];
    
    [_motionController startMotionDetection];

    return self;
}

- (AVCapturePhotoOutput *)capturePhotoOutput {
    return _photoCaptureAdaptee.photoOutput;
}

/// Init camera preview with Front or Rear sensor
- (void)initCameraPreview:(CameraSensor)sensor {
    // Here we set a preset which wont crash the device before switching to front or back
    [_captureSession setSessionPreset:AVCaptureSessionPresetPhoto];
    
    NSError *error;
    _captureDevice = [AVCaptureDevice deviceWithUniqueID:[self selectAvailableCamera:sensor]];
    _captureVideoInput = [AVCaptureDeviceInput deviceInputWithDevice:_captureDevice error:&error];
    
    if (error != nil) {
        _result([FlutterError errorWithCode:@"CANNOT_OPEN_CAMERA" message:@"can't attach device to input" details:[error localizedDescription]]);
        return;
    }
    
    // Create connection
    _captureConnection = [AVCaptureConnection connectionWithInputPorts:_captureVideoInput.ports
                                                                output:_captureVideoOutput];
    
    // Attaching to session
    [_captureSession addInputWithNoConnections:_captureVideoInput];
    [_captureSession addConnection:_captureConnection];
    
    // Creating photo output
    _photoCaptureAdaptee = [[PhotoCaptureOutputAdaptee alloc] init];
    _photoCaptureAdaptee.photoOutput = [[AVCapturePhotoOutput alloc] init];
    [_photoCaptureAdaptee.photoOutput setLivePhotoCaptureEnabled:NO];
    [_photoCaptureAdaptee.photoOutput setHighResolutionCaptureEnabled:YES];
    [_captureSession addOutput:_photoCaptureAdaptee.photoOutput];
   
    
    // Mirror the preview only on portrait mode
    [_captureConnection setAutomaticallyAdjustsVideoMirroring:NO];
    [_captureConnection setVideoMirrored:(_cameraSensor == Back)];
    [_captureConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    
    [self setCameraPresset:CGSizeMake(0, 0)];
}

- (void)dealloc {
  if (_latestPixelBuffer) {
    CFRelease(_latestPixelBuffer);
  }
  [_motionController startMotionDetection];
}

/// Set camera preview size
- (void)setCameraPresset:(CGSize)currentPreviewSize {
    NSString *presetSelected;
    if (!CGSizeEqualToSize(CGSizeZero, currentPreviewSize)) {
        // Try to get the quality requested
        presetSelected = [CameraQualities selectVideoCapturePresset:currentPreviewSize session:_captureSession];
    } else {
        // Compute the best quality supported by the camera device
        presetSelected = [CameraQualities selectVideoCapturePresset:_captureSession];
    }
    [_captureSession setSessionPreset:presetSelected];
    _currentPresset = presetSelected;
    
    // Get preview size according to presset selected
    _currentPreviewSize = [CameraQualities getSizeForPresset:presetSelected];
    [_videoController setPreviewSize:currentPreviewSize];
}

/// Get current video prewiew size
- (CGSize)getEffectivPreviewSize {
    return _currentPreviewSize;
}

// Get max zoom level
- (CGFloat)getMaxZoom {
    return _captureDevice.activeFormat.videoMaxZoomFactor;
}

/// Set Flutter results
- (void)setResult:(FlutterResult _Nonnull)result {
    _result = result;
    
    // Spread resul in controllers
    [_videoController setResult:result];
}

/// Dispose camera inputs & outputs
- (void)dispose {
    [self stop];
    
    for (AVCaptureInput *input in [_captureSession inputs]) {
        [_captureSession removeInput:input];
    }
    for (AVCaptureOutput *output in [_captureSession outputs]) {
        [_captureSession removeOutput:output];
    }
}

/// Set preview size resolution
- (void)setPreviewSize:(CGSize)previewSize {
    if (_videoController.isRecording) {
        _result([FlutterError errorWithCode:@"PREVIEW_SIZE" message:@"impossible to change preview size, video already recording" details:@""]);
        return;
    }
    
    [self setCameraPresset:previewSize];
}

/// Start camera preview
- (void)start {
    [_captureSession startRunning];
}

/// Stop camera preview
- (void)stop {
    [_captureSession stopRunning];
}

/// Set sensor between Front & Rear camera
- (void)setSensor:(CameraSensor)sensor {
    // First remove all input & output
    [_captureSession beginConfiguration];
    
    // Only remove camera channel but keep audio
    for (AVCaptureInput *input in [_captureSession inputs]) {
        for (AVCaptureInputPort *port in input.ports) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
                [_captureSession removeInput:input];
                break;
            }
        }
    }
    [_videoController setAudioIsDisconnected:YES];

    [_captureSession removeOutput:_photoCaptureAdaptee.photoOutput];
    [_captureSession removeConnection:_captureConnection];
    
    // Init the camera preview with the selected sensor
    [self initCameraPreview:sensor];
    
    [_captureSession commitConfiguration];
    
    _cameraSensor = sensor;
}

//最小缩放值
- (CGFloat)minZoomFactor
{
    CGFloat minZoomFactor = 1.0;
    if (@available(iOS 11.0, *)) {
        minZoomFactor = _captureDevice.minAvailableVideoZoomFactor;
    }
    return minZoomFactor;
}

//最大缩放值
- (CGFloat)_maxZoomFactor
{
    CGFloat maxZoomFactor = _captureDevice.activeFormat.videoMaxZoomFactor;
    if (@available(iOS 11.0, *)) {
        maxZoomFactor = _captureDevice.maxAvailableVideoZoomFactor;
    }
    if (_maxZoomFactor <= 0) {
        _maxZoomFactor = MAX_ZOOM_FACTOR;
    }
    if (maxZoomFactor > _maxZoomFactor) {
        maxZoomFactor = MAX_ZOOM_FACTOR;
    }
    return maxZoomFactor;
}

- (void)setMaxZoomFactor:(double)factor {
    _maxZoomFactor = factor;
}

/// Set zoom level
- (void)setZoom:(float)value
{
    CGFloat maxZoom = self._maxZoomFactor;
    CGFloat scaledZoom = value * (maxZoom - 1.0f) / (maxZoom - 1.0f) + 1.0f;
    if (_captureDevice.videoZoomFactor == maxZoom && value > maxZoom) {
        return;
    }
    
    if (_captureDevice.videoZoomFactor == [self minZoomFactor] && value <= 0) {
        return;
    }
    
    [self updateZoomFactor:scaledZoom];
}

- (void)updateZoomFactor:(CGFloat)zoomFactor {
    
    NSError *error;
    if ([_captureDevice lockForConfiguration:&error]) {
        CGFloat zoomFactorMultiplier = [CameraHelper cameraZoomFactorMultiplierForPostion:_captureDevice.position photoCaptureOutput:_photoCaptureAdaptee];
        CGFloat minimumZoomFactor = [CameraHelper minVisibleVideoZoomForDevice:_captureDevice photoCaptureOutput:_photoCaptureAdaptee] / zoomFactorMultiplier;
        CGFloat maxinumZoomFactor = [CameraHelper maximumZoomFactorForDevice:_captureDevice photoCaptureOutput:_photoCaptureAdaptee];
        
        CGFloat clampedZoomFactor = 1;
        if (zoomFactor > maxinumZoomFactor) {
            clampedZoomFactor = maxinumZoomFactor;
        }
        else if (zoomFactor < minimumZoomFactor) {
            clampedZoomFactor = minimumZoomFactor;
        }else {
            clampedZoomFactor = zoomFactor;
        }
        CGFloat videoZoomFactor = MIN(clampedZoomFactor, [self maxZoomFactor]);
        _captureDevice.videoZoomFactor = videoZoomFactor;
//        [_captureDevice rampToVideoZoomFactor:videoZoomFactor withRate:16];
        [_captureDevice unlockForConfiguration];
    } else {
        _result([FlutterError errorWithCode:@"ZOOM_NOT_SET" message:@"can't set the zoom value" details:[error localizedDescription]]);
    }
}

/// Set flash mode
- (void)setFlashMode:(CameraFlashMode)flashMode {
    if (![_captureDevice hasFlash]) {
        _result([FlutterError errorWithCode:@"FLASH_UNSUPPORTED" message:@"flash is not supported on this device" details:@""]);
        return;
    }
    
    if (_cameraSensor == Front) {
        _result([FlutterError errorWithCode:@"FLASH_UNSUPPORTED" message:@"can't set flash for portrait mode" details:@""]);
        return;
    }
    
    NSError *error;
    [_captureDevice lockForConfiguration:&error];
    if (error != nil) {
        _result([FlutterError errorWithCode:@"FLASH_ERROR" message:@"impossible to change configuration" details:@""]);
        return;
    }
    
    switch (flashMode) {
        case None:
            _torchMode = AVCaptureTorchModeOff;
            _flashMode = AVCaptureFlashModeOff;
            break;
        case On:
            _torchMode = AVCaptureTorchModeOff;
            _flashMode = AVCaptureFlashModeOn;
            break;
        case Auto:
            _torchMode = AVCaptureTorchModeAuto;
            _flashMode = AVCaptureFlashModeAuto;
            break;
        case Always:
            _torchMode = AVCaptureTorchModeOn;
            _flashMode = AVCaptureFlashModeOn;
            break;
        default:
            _torchMode = AVCaptureTorchModeAuto;
            _flashMode = AVCaptureFlashModeAuto;
            break;
    }
    [_captureDevice setTorchMode:_torchMode];
    [_captureDevice unlockForConfiguration];
    
    _result(nil);
}

/// Trigger focus on device at the center of the preview
- (void)instantFocus {
    NSError *error;
    
    // Get center point of the preview size
    double focus_x = _currentPreviewSize.width / 2;
    double focus_y = _currentPreviewSize.height / 2;
    
    CGPoint thisFocusPoint = [_previewLayer captureDevicePointOfInterestForPoint:CGPointMake(focus_x, focus_y)];
    if ([_captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus] && [_captureDevice isFocusPointOfInterestSupported]) {
        if ([_captureDevice lockForConfiguration:&error]) {
            if (error != nil) {
                _result([FlutterError errorWithCode:@"FOCUS_ERROR" message:@"impossible to set focus point" details:@""]);
                return;
            }
            
            [_captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
            [_captureDevice setFocusPointOfInterest:thisFocusPoint];
            
            [_captureDevice unlockForConfiguration];
        }
    }
}

/// Get the first available camera on device (front or rear)
- (NSString *)selectAvailableCamera:(CameraSensor)sensor {
    NSArray<AVCaptureDevice *> *devices = [[NSArray alloc] init];
    if (@available(iOS 10.0, *)) {
        AVCaptureDeviceDiscoverySession *discoverySession = [AVCaptureDeviceDiscoverySession
                                                             discoverySessionWithDeviceTypes:@[ AVCaptureDeviceTypeBuiltInWideAngleCamera ]
                                                             mediaType:AVMediaTypeVideo
                                                             position:AVCaptureDevicePositionUnspecified];
        devices = discoverySession.devices;
    } else {
        // Fallback on earlier versions
    }
    
    NSInteger cameraType = (sensor == Front) ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
    for (AVCaptureDevice *device in devices) {
        if ([device position] == cameraType) {
            return [device uniqueID];
        }
    }
    return nil;
}

/// Set capture mode between Photo & Video mode
- (void)setCaptureMode:(CaptureModes)captureMode {
    if (_videoController.isRecording) {
        _result([FlutterError errorWithCode:@"CAPTURE_MODE" message:@"impossible to change capture mode, video already recording" details:@""]);
        return;
    }
    
    _captureMode = captureMode;
    
    if (captureMode == Video) {
        [self setUpCaptureSessionForAudio];
    }
}

- (void)refresh {
    if ([_captureSession isRunning]) {
        [self stop];
    }
    [self start];
}

# pragma mark - Camera picture

/// Take the picture into the given path
- (void)takePictureAtPath:(NSString *)path {
    
    // Instanciate camera picture obj
    CameraPictureController *cameraPicture = [[CameraPictureController alloc] initWithPath:path
                                                                               orientation:_motionController.deviceOrientation
                                                                                    sensor:_cameraSensor
                                                                                    result:_result
                                                                                  callback:^{
        // If flash mode is always on, restore it back after photo is taken
        if (self->_torchMode == AVCaptureTorchModeOn) {
            [self->_captureDevice lockForConfiguration:nil];
            [self->_captureDevice setTorchMode:AVCaptureTorchModeOn];
            [self->_captureDevice unlockForConfiguration];
        }
    }];
    
    // Create settings instance
    if (@available(iOS 10.0, *)) {
        AVCapturePhotoSettings *settings = [AVCapturePhotoSettings photoSettings];
        [settings setFlashMode:_flashMode];
        
        [_photoCaptureAdaptee.photoOutput capturePhotoWithSettings:settings
                                             delegate:cameraPicture];
    } else {
        // Fallback on earlier versions
    }
}

# pragma mark - Camera video
/// Record video into the given path
- (void)recordVideoAtPath:(NSString *)path {
    if (_imageStreamController.streamImages) {
        _result([FlutterError errorWithCode:@"VIDEO_ERROR" message:@"can't record video when image stream is enabled" details:@""]);
    }
    
    if (!_videoController.isRecording) {
        [_videoController recordVideoAtPath:path audioSetupCallback:^{
            [self setUpCaptureSessionForAudio];
        } videoWriterCallback:^{
            if (self->_videoController.isAudioEnabled) {
                [self->_audioOutput setSampleBufferDelegate:self queue:self->_dispatchQueue];
            }
            [self->_captureVideoOutput setSampleBufferDelegate:self queue:self->_dispatchQueue];
        }];
    } else {
        _result([FlutterError errorWithCode:@"VIDEO_ERROR" message:@"already recording video" details:@""]);
    }
}

/// Stop recording video
- (void)stopRecordingVideo {
    if (_videoController.isRecording) {
        [_videoController stopRecordingVideo];
    } else {
        _result([FlutterError errorWithCode:@"VIDEO_ERROR" message:@"video is not recording" details:@""]);
    }
}

/// Set audio recording mode
- (void)setRecordingAudioMode:(bool)isAudioEnabled {
    if (_videoController.isRecording) {
        _result([FlutterError errorWithCode:@"CHANGE_AUDIO_MODE" message:@"impossible to change audio mode, video already recording" details:@""]);
        return;
    }
    
    [_captureSession beginConfiguration];
    [_videoController setIsAudioEnabled:isAudioEnabled];
    [_videoController setIsAudioSetup:NO];
    [_videoController setAudioIsDisconnected:YES];
    
    // Only remove audio channel input but keep video
    for (AVCaptureInput *input in [_captureSession inputs]) {
        for (AVCaptureInputPort *port in input.ports) {
            if ([[port mediaType] isEqual:AVMediaTypeAudio]) {
                [_captureSession removeInput:input];
                break;
            }
        }
    }
    // Only remove audio channel output but keep video
    [_captureSession removeOutput:_audioOutput];
    
    if (_videoController.isRecording) {
        [self setUpCaptureSessionForAudio];
    }
    
    
    [_captureSession commitConfiguration];
}

# pragma mark - Audio
/// Setup audio channel to record audio
- (void)setUpCaptureSessionForAudio {
    NSError *error = nil;
    // Create a device input with the device and add it to the session.
    // Setup the audio input.
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice
                                                                             error:&error];
    if (error) {
        _result([FlutterError errorWithCode:@"VIDEO_ERROR" message:@"error when trying to setup audio capture" details:error.description]);
    }
    // Setup the audio output.
    _audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    
    if ([_captureSession canAddInput:audioInput]) {
        [_captureSession addInput:audioInput];
        
        if ([_captureSession canAddOutput:_audioOutput]) {
            [_captureSession addOutput:_audioOutput];
            [_videoController setIsAudioSetup:YES];
        } else {
            [_videoController setIsAudioSetup:NO];
        }
    }
}

# pragma mark - Camera Delegates

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (output == _captureVideoOutput) {
        CVPixelBufferRef newBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CFRetain(newBuffer);
        CVPixelBufferRef old = _latestPixelBuffer;
        while (!OSAtomicCompareAndSwapPtrBarrier(old, newBuffer, (void **)&_latestPixelBuffer)) {
            old = _latestPixelBuffer;
        }
        if (old != nil) {
            CFRelease(old);
        }
        if (_onFrameAvailable) {
            _onFrameAvailable();
        }
    }
    
    // Process image stream controller
    if (_imageStreamController.streamImages) {
        [_imageStreamController captureOutput:output didOutputSampleBuffer:sampleBuffer fromConnection:connection];
    }
    
    if (_videoController.isRecording) {
        [_videoController captureOutput:output didOutputSampleBuffer:sampleBuffer fromConnection:connection captureVideoOutput:_captureVideoOutput];
    }
}

# pragma mark - Data manipulation

/// Used to copy pixels to in-memory buffer
- (CVPixelBufferRef _Nullable)copyPixelBuffer {
    CVPixelBufferRef pixelBuffer = _latestPixelBuffer;
    while (!OSAtomicCompareAndSwapPtrBarrier(pixelBuffer, nil, (void **)&_latestPixelBuffer)) {
        pixelBuffer = _latestPixelBuffer;
    }
    
    return pixelBuffer;
}

@end

