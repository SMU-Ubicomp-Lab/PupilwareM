//
//  PupilwareController.cpp
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 6/20/16.
//  Copyright © 2016 SMU Ubicomp Lab All rights reserved.
//

#include "PupilwareController.hpp"

#include "preHeader.hpp"

#include "Algorithm/PWDataModel.hpp"
#include "ImageProcessing/IImageSegmenter.hpp"
#include "Algorithm/IPupilAlgorithm.hpp"

#include "Helpers/CWCVHelper.hpp"

using namespace cv;

namespace pw{
    
    class PupilwareControllerImpl: public PupilwareController{
        
    public:
        PupilwareControllerImpl():
        hasStarted(false),
        currentFrameNumber(0){}
        
        virtual ~PupilwareControllerImpl(){}
        
        virtual void setFaceSegmentationAlgoirhtm( std::shared_ptr<IImageSegmenter> imgSegAlgo ) override;
        virtual void setPupilSegmentationAlgorihtm( std::shared_ptr<IPupilAlgorithm> pwSegAlgo ) override;
    
        
        /*!
         * Start Pupilware processing.
         */
        virtual void start() override;
        
        
        /*!
         * Stop Pupilware processing
         */
        virtual void stop() override;
        
        
        /*!
         * Process frame
         */
        virtual void processFrame( const cv::Mat& srcFrame,
                                   unsigned int frameNumber = 0 ) override;
        
        
        /*!
         * Getter Functions
         */
        virtual int getCognitiveLoadLevel() const override;
        virtual const cv::Mat& getDebugImage() const override;
        virtual const std::vector<float>& getRawPupilSignal() const override;
        virtual const std::vector<float>& getSmoothPupilSignal() const override;
        
        
        /*! --------------------------------------------------------------------------------
         * Member Variables
         */
        
        bool hasStarted;                    // Use for controlling stages
        unsigned int currentFrameNumber;

        
        PWDataModel storage;                // Store left and right pupil size signals
        std::vector<float> eyeDistancePx;   // Store eye distance signal
        
        std::shared_ptr<IImageSegmenter> imgSegAlgo;
        std::shared_ptr<IPupilAlgorithm> pwSegAlgo;

        cv::Mat debugImg;                   // Use for debuging
        
    };
    
    
    
    
    /*! --------------------------------------------------------------------------------
     * Static Functions
     */
    std::shared_ptr<PupilwareController> PupilwareController::Create(){
        return std::make_shared<PupilwareControllerImpl>();
    }
    
    
    /*! --------------------------------------------------------------------------------
     * Implementation Functions
     */
    
    void PupilwareControllerImpl::setFaceSegmentationAlgoirhtm( std::shared_ptr<IImageSegmenter> imgSegAlgo ){
        REQUIRES(imgSegAlgo != nullptr, "FaceSegmenter algorithm must not be null.");
        
        this->imgSegAlgo = imgSegAlgo;
        
        PROMISES(this->imgSegAlgo != nullptr, "FaceSegmenter algorithm must not be null.");
    }
    
    
    void PupilwareControllerImpl::setPupilSegmentationAlgorihtm( std::shared_ptr<IPupilAlgorithm> pwSegAlgo ){
        REQUIRES(pwSegAlgo != nullptr, "Pupilware algorithm must not be null.");
        
        this->pwSegAlgo = pwSegAlgo;
        
        REQUIRES(this->pwSegAlgo != nullptr, "Pupilware algorithm must not be null.");
    }
    
    
    void PupilwareControllerImpl::start() {
        
        REQUIRES(imgSegAlgo != nullptr, "ImageSegmenter must be not null.");
        REQUIRES(pwSegAlgo != nullptr, "PupilSegmentor must be not null.");
        
        if(hasStarted) return;
        hasStarted = true;
        
        // Init and clearn up
        currentFrameNumber = 0;
        
        // Init algorithms
        pwSegAlgo->init();
        
    }
    

    void PupilwareControllerImpl::stop(){
        
        if(!hasStarted) return;
        hasStarted = false;
        
        // Clean up
        pwSegAlgo->exit();
        
        // stop the machine
        // process signal
        // classify cognitive load
        // store cognitive load result
        
    }
    
    void PupilwareControllerImpl::processFrame( const cv::Mat& srcFrame, unsigned int frameNumber ){
        
        REQUIRES(imgSegAlgo != nullptr, "ImageSegmenter must be not null.");
        REQUIRES(pwSegAlgo != nullptr, "PupilSegmentor must be not null.");
        REQUIRES(!srcFrame.empty(), "Source Frame must not be empty.");
        
        
        Mat grayFrame;
        cvtColor(srcFrame, grayFrame, CV_BGR2GRAY);    // Please change to Red channal
        
        
        // segment face
        Rect faceRect;
        if(!imgSegAlgo->findFace(grayFrame, faceRect))
        {
            //Face is not in the frame, then return... :)
            return;
        }
        
        
        // segment eye
        Rect leftEyeRect;
        Rect rightEyeRect;
        imgSegAlgo->extractEyes(faceRect, leftEyeRect, rightEyeRect);
        
        
        // locate eye center
        Point leftEyeCenter = imgSegAlgo->fineEyeCenter(grayFrame(leftEyeRect));
        Point rightEyeCenter = imgSegAlgo->fineEyeCenter(grayFrame(rightEyeRect));
        
        
        // !!! Remember that these eye center location is in the eye coordinate
        // We have to convert to face coordinate first!
        float eyeDist = cw::calDistance(  Point(leftEyeCenter.x + leftEyeRect.x, leftEyeCenter.y + leftEyeRect.y)
                                        , Point(rightEyeCenter.x + rightEyeRect.x, rightEyeCenter.y + rightEyeRect.y ));
        
        
        
        // Find pupil size
        PupilMeta eyeMeta;
        eyeMeta.setEyeCenter(leftEyeCenter, rightEyeCenter);
        eyeMeta.setEyeImages(srcFrame(leftEyeRect),
                             srcFrame(rightEyeRect));
        eyeMeta.setFrameNumber(currentFrameNumber);
        eyeMeta.setEyeDistancePx(eyeDist);
        
        auto result = pwSegAlgo->process( eyeMeta );
        
        //! Store data to lists
        //
        storage.setPupilSizeAt( currentFrameNumber, result );
        
        eyeDistancePx.push_back( eyeDist );
        
        
        
        // DEBUG -----------------------------------------------------------------------------
        debugImg = srcFrame.clone();
        
        cv::rectangle(debugImg, faceRect, cv::Scalar(255,0,0));
        
        cv::circle(debugImg(faceRect),
                   Point(leftEyeCenter.x + leftEyeRect.x, leftEyeCenter.y + leftEyeRect.y),
                   20,
                   cv::Scalar(255,0,0));
        
        cv::circle(debugImg(faceRect),
                   Point(rightEyeCenter.x + rightEyeRect.x, rightEyeCenter.y + rightEyeRect.y ),
                   20,
                   cv::Scalar(255,0,0));

    }
    

    int PupilwareControllerImpl::getCognitiveLoadLevel() const{
        
        throw_assert(false, "This function has not been impremented");
        
        return 0;
    }
    
    
    const cv::Mat& PupilwareControllerImpl::getDebugImage() const{
        
        return debugImg;
    }
    
    
    const std::vector<float>& PupilwareControllerImpl::getRawPupilSignal() const{
        
        // warning: only return left eye???
        
        return storage.getLeftPupilSizes();
    }
    
    
    const std::vector<float>& PupilwareControllerImpl::getSmoothPupilSignal() const{
        
        throw_assert(false, "This function has not been impremented");
        
        return storage.getLeftPupilSizes();
        
    }
    
    
}