//
//  PupilwareController.hpp
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 6/20/16.
//  Copyright © 2016 SMU Ubicomp Lab All rights reserved.
//

#ifndef PupilwareController_hpp
#define PupilwareController_hpp

#include "PWFaceMeta.hpp"


namespace pw{
    
    class IImageSegmenter;
    class IPupilAlgorithm;

    
    class PupilwareController{
    
    public:
        
   
        virtual void setFaceSegmentationAlgoirhtm( std::shared_ptr<IImageSegmenter> imgSegAlgo )=0;
        virtual void setPupilSegmentationAlgorihtm( std::shared_ptr<IPupilAlgorithm> pwSeg )=0;
        
        virtual void setFaceMeta( const PWFaceMeta& faceMeta )=0;
        
        
        /*!
         * Start Pupilware processing.
         */
        virtual void start()=0;
        
        
        /*!
         * Stop Pupilware processing
         */
        virtual void stop()=0;
        
        
        
        /*!
         * Segmenting and Finding pupil size from the given color frame.
         */
        virtual void processFrame( const cv::Mat& srcFrame,
                                   unsigned int frameNumber = 0 )=0;
        
        
        /*!
         * Retrun true if the system has started.
         */
        virtual bool hasStarted() const =0;
        
        
        virtual cv::Mat getGraphImage() const=0;
        
        
        /*!--------------------------------------------------------------------
         * Getter Functions
         */
        virtual int getCognitiveLoadLevel()const=0;
        virtual const cv::Mat& getDebugImage()const =0;
        virtual const std::vector<float>& getRawPupilSignal()const =0;
        virtual const std::vector<float>& getSmoothPupilSignal() const =0;
        
        
        /*!--------------------------------------------------------------------
         * Static Functions
         */
        static std::shared_ptr<PupilwareController> Create();
    
    
    };
    
    
    
}

#endif /* PupilwareController_hpp */
