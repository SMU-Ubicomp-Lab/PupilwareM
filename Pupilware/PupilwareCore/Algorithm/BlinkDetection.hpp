//
//  mdStarbust.hpp
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 5/25/16.
//  Copyright © 2016 Chatchai Wangwiwattana. All rights reserved.
//

#ifndef BlinkDetection_hpp
#define BlinkDetection_hpp

#include "IPupilAlgorithm.hpp"

namespace pw {

    class BlinkDetection : public IPupilAlgorithm {
    
    public:
        BlinkDetection( const std::string& name);
        BlinkDetection( const BlinkDetection& other)=default;
        BlinkDetection( BlinkDetection&& other)=default;
        BlinkDetection& operator=( const BlinkDetection& other)=default;
        BlinkDetection& operator=( BlinkDetection&& other)=default;
        virtual ~BlinkDetection();
        
        virtual void init() override final;
        virtual PWPupilSize process( const cv::Mat& src, const PWFaceMeta &meta ) override final;
        virtual void exit() override final;
        
        const cv::Mat& getDebugImage() const;
        
    private:
        int th;

        // Just a window name for debuging
        std::shared_ptr<CVWindow> window;

        // Debug Image
        cv::Mat debugImage;
        
    };
}

#endif /* BlinkDetection_hpp */
