//
//  CameraEnum.h
//  Pods
//
//  Created by chengbin on 2022/7/1.
//

#ifndef CameraEnum_h
#define CameraEnum_h
typedef enum : NSUInteger {
    CameraTypeUltraWide = 0,
    CameraTypeWideAngle = 1,
    CameraTypeTelephoto = 2,
} CameraType;

typedef enum : NSUInteger {
    CameraSystemWide = 0, // Signle-Camera devices.
    CameraSystemDual = 1, // W + T
    CameraSystemDualWide = 2,// UW + W
    CameraSystemTriple = 3, // UW + W + T
} CameraSystem;

#endif /* CameraEnum_h */
