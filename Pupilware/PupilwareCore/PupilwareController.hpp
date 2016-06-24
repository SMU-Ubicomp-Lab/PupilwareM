//
//  PupilwareController.hpp
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 6/20/16.
//  Copyright © 2016 SMU Ubicomp Lab All rights reserved.
//

#ifndef PupilwareController_hpp
#define PupilwareController_hpp


namespace pw{
    
    class IImageSegmenter;
    class IPupilAlgorithm;
    
    typedef std::function< const cv::Mat&(int frameNumber) > ImageFrameDataSource;
    
    class PupilwareController{
    
    public:
        
        
        virtual void setFrameDataSource( ImageFrameDataSource dataSource );
        virtual void setMaxFrameNumber( int maxFrameNumber );
        
        /*!
         * Start Pupilware processing.
         */
        virtual void start(  std::shared_ptr<IImageSegmenter> imgSeg
                   , std::shared_ptr<IPupilAlgorithm> pwSeg  );
        
        
        /*!
         * Stop Pupilware processing
         */
        virtual void stop();
        
        
        
        /*!
         * Getter Functions
         */
        virtual int getCognitiveLoadLevel() const;
        virtual const cv::Mat& debugImage() const;
        virtual const std::vector<float>& getRawPupilSignal() const;
        virtual const std::vector<float>& getSmoothPupilSignal() const;
        
        
        /*!
         * Static Functions
         */
        static std::shared_ptr<PupilwareController> Create();
    
    
    };
    
    
    
}

#endif /* PupilwareController_hpp */
