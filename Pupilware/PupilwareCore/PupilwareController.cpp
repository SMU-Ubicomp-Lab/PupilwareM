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
        isStarted(false),
        currentFrameNumber(0){}
        
        virtual ~PupilwareControllerImpl(){}
        
        virtual void setFaceSegmentationAlgoirhtm( std::shared_ptr<IImageSegmenter> imgSegAlgo ) override;
        virtual void setPupilSegmentationAlgorihtm( std::shared_ptr<IPupilAlgorithm> pwSegAlgo ) override;
        
        
        /*
         * Users need to call this function if they do not provide a face segmenter algorithm.
         * If they've already had a segmenter algorithm, it will be replaced with data in this function.
         */
        virtual void setFaceMeta( const PWFaceMeta& faceMeta ) override;
    
        
        /*!
         * Start Pupilware processing.
         */
        virtual void start() override;
        
        
        /*!
         * Stop Pupilware processing
         */
        virtual void stop() override;
        
        /*!
         * Stop Pupilware processing
         */
        virtual bool hasStarted() const override;
        
        
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
        
        
        unsigned int currentFrameNumber;                // Store current frame number

        
        PWDataModel         storage;                    // Store left and right pupil size signals
        std::vector<float>  eyeDistancePx;              // Store eye distance signal
        
        std::shared_ptr<IImageSegmenter> imgSegAlgo;    // This algorithm is not required if
                                                        // providing manally providing a face meta
        
        std::shared_ptr<IPupilAlgorithm> pwSegAlgo;     // This pupil segmentation is required.

        cv::Mat             debugImg;                   // Use for debuging
        
        PWFaceMeta          faceMeta;
        
        bool                isStarted;                  // Use for controlling stages
        
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
    
    bool PupilwareControllerImpl::hasStarted() const{
        return isStarted;
    }
    
    
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
        
        REQUIRES(pwSegAlgo != nullptr, "PupilSegmentor must be not null.");
        
        if(isStarted) return;
        isStarted = true;
        
        // Init and clearn up
        currentFrameNumber = 0;
        
        // Init algorithms
        pwSegAlgo->init();
        
    }
    

    void PupilwareControllerImpl::stop(){
        
        if(!isStarted) return;
        
        
        // Clean up
        pwSegAlgo->exit();
        
        currentFrameNumber = 0;
        debugImg = cv::Mat();
        
        isStarted = false;
        
        // stop the machine
        // process signal
        // classify cognitive load
        // store cognitive load result
        
    }
    
    
    void PupilwareControllerImpl::setFaceMeta( const PWFaceMeta& faceMeta ){
        this->faceMeta = faceMeta;
    }
    
    
    void PupilwareControllerImpl::processFrame( const cv::Mat& srcFrame, unsigned int frameNumber ){
        
        REQUIRES(pwSegAlgo != nullptr, "PupilSegmentor must be not null.");
        REQUIRES(!srcFrame.empty(), "Source Frame must not be empty.");
        
        if(!isStarted) return;
            
        Mat grayFrame;
        cvtColor(srcFrame, grayFrame, CV_BGR2GRAY);    // Please change to Red channal
        
        float eyeDist = 0;
        
        if (imgSegAlgo == nullptr) {
            
            if(!faceMeta.hasFace()){
                // There is no face detected.
                return;
            }

            
        }
        else{
            
            // segment face
            auto faceRect = faceMeta.getFaceRect();
            if(!imgSegAlgo->findFace(grayFrame, faceRect))
            {
                //Face is not in the frame, then return... :(
                return;
            }
            
            
            // segment eye
            cv::Rect leftEyeRect;
            cv::Rect rightEyeRect;
            imgSegAlgo->extractEyes(faceRect,
                                    leftEyeRect,
                                    rightEyeRect );
            
            cv::Mat faceGray = grayFrame(faceRect);
            
            auto leftEyeCenter = imgSegAlgo->fineEyeCenter(faceGray(leftEyeRect));
            auto rightEyeCenter =imgSegAlgo->fineEyeCenter(faceGray(rightEyeRect));
            
            //Convert to Frame coordinate
            auto leftEyeFrameCoorRect = cv::Rect(leftEyeRect.x + faceRect.x,
                                                 leftEyeRect.y + faceRect.y,
                                                 leftEyeRect.width, leftEyeRect.height);
            auto rightEyeFrameCoorRect = cv::Rect(rightEyeRect.x + faceRect.x,
                                                 rightEyeRect.y + faceRect.y,
                                                  rightEyeRect.width, rightEyeRect.height);
            
            faceMeta.setFaceRect(faceRect);
            faceMeta.setLeftEyeRect(leftEyeFrameCoorRect);
            faceMeta.setRightEyeRect(rightEyeFrameCoorRect);
            faceMeta.setLeftEyeCenter( cv::Point( leftEyeCenter.x + leftEyeFrameCoorRect.x,
                                                  leftEyeCenter.y + leftEyeFrameCoorRect.y) );
            faceMeta.setRightEyeCenter(cv::Point( rightEyeCenter.x + rightEyeFrameCoorRect.x,
                                                  rightEyeCenter.y + rightEyeFrameCoorRect.y) );
            
            
            
        }
        
        
        eyeDist = cw::calDistance( faceMeta.getLeftEyeCenter(),
                                   faceMeta.getRightEyeCenter() );
        

        faceMeta.setFrameNumber(currentFrameNumber);
        faceMeta.setEyeDistancePx(eyeDist);
        
        auto result = pwSegAlgo->process( srcFrame, faceMeta );
        
        //! Store data to lists
        //
        storage.setPupilSizeAt( currentFrameNumber, result );
        
        eyeDistancePx.push_back( eyeDist );
        
        
        
        // DEBUG -----------------------------------------------------------------------------
        debugImg = srcFrame.clone();
        
        cv::rectangle(debugImg, faceMeta.getFaceRect(), cv::Scalar(255,0,0));
        
        cv::circle(debugImg,
                   faceMeta.getLeftEyeCenter(),
                   20,
                   cv::Scalar(255,255,0));
        
        
        cv::circle(debugImg,
                   faceMeta.getRightEyeCenter(),
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
        
        throw_assert(false, "This function has not been implemented");
        
        return storage.getLeftPupilSizes();
        
    }
    
    
}