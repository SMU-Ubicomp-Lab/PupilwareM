//
//  PupilwareController.cpp
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 6/20/16.
//  Copyright © 2016 SMU Ubicomp Lab All rights reserved.
//

#include "PupilwareController.hpp"

#include "Core/ThrowAssert.hpp"

#include "Algorithm/PWDataModel.hpp"
#include "ImageProcessing/IImageSegmenter.hpp"
#include "Algorithm/IPupilAlgorithm.hpp"

#include "Helpers/CWCVHelper.hpp"

#define REQUIRES throw_assert
#define PROMISES throw_assert

using namespace cv;

namespace pw{
    
    class PupilwareControllerImpl: public PupilwareController{
        
    public:
        PupilwareControllerImpl():
        hasStarted(false){}
        
        
        virtual void setFrameDataSource( ImageFrameDataSource dataSource ) override;
        virtual void setMaxFrameNumber( int maxFrameNumber ) override;
        
        
        /*!
         * Start Pupilware processing.
         */
        virtual void start(  std::shared_ptr<IImageSegmenter> imgSeg
                           , std::shared_ptr<IPupilAlgorithm> pwSeg  ) override;
        
        
        /*!
         * Stop Pupilware processing
         */
        virtual void stop() override;
        
        
        
        /*!
         * Getter Functions
         */
        virtual int getCognitiveLoadLevel() const override;
        virtual const cv::Mat& debugImage() const override;
        virtual const std::vector<float>& getRawPupilSignal() const override;
        virtual const std::vector<float>& getSmoothPupilSignal() const override;
        
        
        /*! --------------------------------------------------------------------------------
         * Member Variables
         */
        
        bool hasStarted;        // Use for controlling stages
        PWDataModel storage;    // Store Pupuil Signals
        cv::Mat debugImg;       // Use for debuging
        
        ImageFrameDataSource dataSource;
        int maxFrameNumber;
        
        unsigned int currentFrameNumber;
        
        std::vector<float> eyeDistancePx;
        
        
    };
    
    void PupilwareControllerImpl::setFrameDataSource( ImageFrameDataSource dataSource ){
    
        
        this->dataSource = dataSource;
        
    }
    
    void PupilwareControllerImpl::setMaxFrameNumber( int maxFrameNumber ){
        
        REQUIRES(maxFrameNumber >=0, "maxFrameNumber must be more than 0." );
        
        this->maxFrameNumber = maxFrameNumber;
    }
    
    
    /*! --------------------------------------------------------------------------------
     * Static Functions
     */
    std::shared_ptr<PupilwareController> PupilwareController::Create(){
        return std::make_shared<PupilwareControllerImpl>();
    }
    
    
    /*! --------------------------------------------------------------------------------
     * Implementation Functions
     */
    void PupilwareControllerImpl::start(  std::shared_ptr<IImageSegmenter> imgSeg
                                        , std::shared_ptr<IPupilAlgorithm> pwSeg  ) {
        
        throw_assert(imgSeg != nullptr, "ImageSegmenter must be not null.");
        throw_assert(pwSeg != nullptr, "PupilSegmentor must be not null.");
        
        if(hasStarted) return;
        hasStarted = true;
        
        currentFrameNumber = 0;
        
        while( true ){
            
            // get the frame
            Mat srcFrame = dataSource(currentFrameNumber).clone();
            if (srcFrame.empty()) {
                // throw some erro~
                break;
            }
            
            Mat grayFrame;
            cvtColor(srcFrame, grayFrame, CV_BGR2GRAY);    // Please change to Red channal
            
            // segment face
            Rect faceRect;
            imgSeg->findFace(srcFrame, faceRect);
            
            
            // segment eye
            Rect leftEyeRect;
            Rect rightEyeRect;
            imgSeg->extractEyes(faceRect, leftEyeRect, rightEyeRect);
            
            
            // locate eye center
            Point leftEyeCenter = imgSeg->fineEyeCenter(grayFrame(leftEyeRect));
            Point rightEyeCenter = imgSeg->fineEyeCenter(grayFrame(rightEyeRect));
            
            
            // !!! Remember that these eye center location is in the eye coordinate
            // We have to convert to face coordinate first!
            float eyeDist = cw::calDistance(  Point(leftEyeCenter.x + leftEyeRect.x, leftEyeCenter.y + leftEyeRect.y)
                                            , Point(rightEyeCenter.x + rightEyeRect.x, rightEyeCenter.y + rightEyeRect.y ));
            
            
            
            // find pupil size
            PupilMeta eyeMeta;
            eyeMeta.setEyeCenter(leftEyeCenter, rightEyeCenter);
            eyeMeta.setEyeImages(srcFrame(leftEyeRect),
                                 srcFrame(rightEyeRect));
            eyeMeta.setFrameNumber(currentFrameNumber);
            eyeMeta.setEyeDistancePx(eyeDist);
            
            auto result = pwSeg->process( eyeMeta );
            
            //! Store data to lists
            //
            storage.setPupilSizeAt( currentFrameNumber, result );
            
            eyeDistancePx.push_back( eyeDist );

        }

        
    }
    

    void PupilwareControllerImpl::stop(){
        
        if(!hasStarted) return;
        hasStarted = false;
        
        // stop the machine
        // process signal
        // classify cognitive load
        // store cognitive load result
        
    }
    

    int   PupilwareControllerImpl::getCognitiveLoadLevel() const{
        
        throw_assert(false, "This function has not been impremented");
        
        return 0;
    }
    
    
    const cv::Mat& PupilwareControllerImpl::debugImage() const{
        
        throw_assert(false, "This function has not been impremented");
        
        return debugImg;
    }
    
    
    const std::vector<float>& PupilwareControllerImpl::getRawPupilSignal() const{
        
        throw_assert(false, "This function has not been impremented");
        
        return std::vector<float>();
    }
    
    
    const std::vector<float>& PupilwareControllerImpl::getSmoothPupilSignal() const{
        
        throw_assert(false, "This function has not been impremented");
        
        return std::vector<float>();
        
    }
    
    
}