//
//  IOSFaceSegmentor.hpp
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 6/25/16.
//  Copyright © 2016 Raymond Martin. All rights reserved.
//

#ifndef IOSFaceSegmentor_hpp
#define IOSFaceSegmentor_hpp

#include "../ImageProcessing/IImageSegmenter.hpp"

namespace pw {
    class IOSFaceSegmenter: public IImageSegmenter {
        
        
    private:

    public:
        IOSFaceSegmenter( );
        IOSFaceSegmenter( const IOSFaceSegmenter &other );
        ~IOSFaceSegmenter();
        
        bool            findFace(const cv::Mat grayFrame,
                                 cv::Rect &outFaceRect) override;
        
        void            extractEyes(cv::Rect faceROI,
                                    cv::Rect &outLeftEyeRegion,
                                    cv::Rect &outRightEyeRegion) override;
        
        cv::Point2f     fineEyeCenter(const cv::Mat grayEyeROI) override;
        
    };
}

#endif /* IOSFaceSegmentor_hpp */
