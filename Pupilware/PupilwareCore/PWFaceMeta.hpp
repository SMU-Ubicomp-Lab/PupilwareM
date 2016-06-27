//
//  PWFaceMeta.hpp
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 6/26/16.
//  Copyright © 2016 Raymond Martin. All rights reserved.
//

#ifndef PWFaceMeta_hpp
#define PWFaceMeta_hpp

namespace pw{
    
    struct PWFaceMeta
    {
        cv::Rect faceRect;
        cv::Rect leftEyeRect;
        cv::Rect rightEyeRect;
        cv::Point leftEyeCenter;
        cv::Point rightEyeCenter;
        bool leftEyeClosed;
        bool rightEyeClosed;
    };
}

#endif /* PWFaceMeta_hpp */
