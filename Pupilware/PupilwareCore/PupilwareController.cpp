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
            
            if(faceMeta.faceRect.width == 0){
                // There is no face detected.
                return;
            }

            
        }
        else{
            
            // segment face
            if(!imgSegAlgo->findFace(grayFrame, faceMeta.faceRect))
            {
                //Face is not in the frame, then return... :)
                return;
            }
            
            
            // segment eye
            imgSegAlgo->extractEyes(faceMeta.faceRect,
                                    faceMeta.leftEyeRect,
                                    faceMeta.rightEyeRect);
            
            
            // locate eye center
            faceMeta.leftEyeCenter  = imgSegAlgo->fineEyeCenter(grayFrame(faceMeta.leftEyeRect));
            faceMeta.rightEyeCenter = imgSegAlgo->fineEyeCenter(grayFrame(faceMeta.rightEyeRect));
            

            
            
        }
        
        // !!! Remember that these eye center location is in the eye coordinate
        // We have to convert to face coordinate first!
        eyeDist = cw::calDistance(  Point(faceMeta.leftEyeCenter.x + faceMeta.leftEyeRect.x,
                                          faceMeta.leftEyeCenter.y + faceMeta.leftEyeRect.y)
                                  , Point(faceMeta.rightEyeCenter.x + faceMeta.rightEyeRect.x,
                                          faceMeta.rightEyeCenter.y + faceMeta.rightEyeRect.y ));
        
        // Find pupil size
        Mat colorFace = srcFrame(faceMeta.faceRect);
        
        PupilMeta eyeMeta;
        eyeMeta.setEyeCenter(faceMeta.leftEyeCenter, faceMeta.rightEyeCenter);
        eyeMeta.setEyeImages(colorFace(faceMeta.leftEyeRect),
                             colorFace(faceMeta.rightEyeRect));
        eyeMeta.setFrameNumber(currentFrameNumber);
        eyeMeta.setEyeDistancePx(eyeDist);
        
        auto result = pwSegAlgo->process( eyeMeta );
        
        //! Store data to lists
        //
        storage.setPupilSizeAt( currentFrameNumber, result );
        
        eyeDistancePx.push_back( eyeDist );
        
        
        
        // DEBUG -----------------------------------------------------------------------------
        debugImg = srcFrame.clone();
        
        cv::rectangle(debugImg, faceMeta.faceRect, cv::Scalar(255,0,0));
        
        cv::circle(debugImg(faceMeta.faceRect),
                   Point(faceMeta.leftEyeCenter.x + faceMeta.leftEyeRect.x,
                         faceMeta.leftEyeCenter.y + faceMeta.leftEyeRect.y),
                   20,
                   cv::Scalar(255,255,0));
        
        
        cv::circle(debugImg(faceMeta.faceRect),
                   Point(faceMeta.rightEyeCenter.x + faceMeta.rightEyeRect.x,
                         faceMeta.rightEyeCenter.y + faceMeta.rightEyeRect.y ),
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