//
//  UIDevice+Extension.m
//  camerawesome
//
//  Created by chengbin on 2022/7/1.
//

#import "UIDevice+Extension.h"

@implementation UIDevice (Extension)

- (BOOL)isIPad {
    return UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad;
}

- (BOOL)isPlusSizePhone {
    if ([self isIPad]) {
        return false;
    }
    CGFloat height = UIScreen.mainScreen.nativeBounds.size.height;
    if (height == 2778 ||
        height == 2668 ||
        height == 1920 ||
        height == 2208 ||
        height == 1792) {
        return true;
    }
    return false;
}
@end
