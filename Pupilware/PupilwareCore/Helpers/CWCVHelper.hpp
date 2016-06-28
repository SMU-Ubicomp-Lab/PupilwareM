//
//  cvUtility.hpp
//
//  Created by Chatchai Wangwiwattana on 5/25/16.
//  Copyright © 2016 Chatchai Wangwiwattana. All rights reserved.
//

#ifndef cvUtility_hpp
#define cvUtility_hpp

#include <opencv2/opencv.hpp>

#include "simpleGraph/GraphUtils.h"

namespace cw {
    
    void erosion( const cv::Mat& src, cv::Mat& dst, int erosionSize=2, int erosionType=cv::MORPH_ELLIPSE );


    /*!
     * Inline Functions
     * ---------------------------------------------------------------- */
    inline int randomRange(int from, int to){
        return rand() % to + from;
    }

    inline float calDistanceSq( cv::Point2f p1, cv::Point2f p2 ){
        return float( ((p1.x - p2.x) * (p1.x - p2.x)) + ( (p1.y - p2.y) * (p1.y - p2.y) ) ) ;
    }

    inline float calDistance( cv::Point2f p1, cv::Point2f p2 ){
        return sqrt( calDistanceSq(p1, p2));
    }

    /*!
     * Morphological Operations
     * ----------------------------------------------------------------- */
    void openOperation( const cv::Mat& src, cv::Mat& dst, int size=2, int type=cv::MORPH_ELLIPSE );
    void closeOperation( const cv::Mat& src, cv::Mat& dst, int size=2, int type=cv::MORPH_ELLIPSE );


    /*!
    * Histogram
    * ----------------------------------------------------------------- */
    std::vector<unsigned int> calHistogram( const cv::Mat& srcGrayImage );
    std::vector<float> calProgressiveSum( const std::vector<unsigned int>& histogram );
    std::vector<float> calProgressiveSum( const cv::Mat& srcGrayImage );
    int calDynamicThreshold( const cv::Mat& srcGray, float value  );


    /*!
    * Conversion
    * ----------------------------------------------------------------- */
    void cvtFloatMatToUChar(const cv::Mat& src, cv::Mat &dist);

    double resize( const cv::Mat& src, cv::Mat& dst, int targetWidth );

    /*!
    * ETCs
    * ----------------------------------------------------------------- */
    cv::Point calCenterOfMass( const cv::Mat& binaryMat );

}


#endif /* cvUtility_hpp */
