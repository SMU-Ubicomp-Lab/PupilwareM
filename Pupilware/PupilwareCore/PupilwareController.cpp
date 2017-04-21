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
#include "SignalProcessing/BasicSignalProcessor.hpp"

#include "Helpers/CWCVHelper.hpp"
#include "Helpers/PWGraph.hpp"

#include "PWFaceLandmarkDetector.hpp"

using namespace cv;

namespace pw{
    
    class PupilwareControllerImpl: public PupilwareController{
        
    public:
        PupilwareControllerImpl():
        currentFrameNumber(0),
        isStarted(false),
        smoothWindowSize(31)
        {}
        
        virtual ~PupilwareControllerImpl(){}
        
        
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
                                   unsigned int frameNumber ) override;
        
    
        /*!
         * Clear all buffers including current frame number.
         */
        virtual void clearBuffer() override;
        
        
        /*!
         * Smooth and Normalize raw signal
         */
        virtual void processSignal() override;
        
        
        /*!
         * Setter Functions
         */
        
        virtual void setFaceSegmentationAlgoirhtm( std::shared_ptr<IImageSegmenter> imgSegAlgo ) override;
        virtual void setPupilSegmentationAlgorihtm( std::shared_ptr<IPupilAlgorithm> pwSegAlgo ) override;
        
        
        /*!
         * Users need to call this function if they do not provide a face segmenter algorithm.
         * If they've already had a segmenter algorithm, it will be replaced with data in this function.
         */
        virtual void setFaceMeta( const PWFaceMeta& faceMeta ) override;
        
        
        /*!
         * Window size must be > 0 and odd number.
         */
        virtual void setSmoothWindowSize( int windowSize ) override;
        
        virtual void setLandMarkFile( const std::string& landmarkFilename ) override;
        
        /*!
         * Getter Functions
         */
        virtual int getCognitiveLoadLevel() const override;
        virtual const cv::Mat& getDebugImage() const override;
        virtual const PWDataModel& getRawPupilSignal() const override;
        virtual const std::vector<float>& getSmoothPupilSignal() const override;
        virtual cv::Mat getGraphImage() const override;
        
        virtual const pw::PWFaceMeta& getFaceMeta() const override;
        
        
        /*! --------------------------------------------------------------------------------
         * Member Variables
         */
        
        unsigned int currentFrameNumber;                // Store current frame number

        
        PWDataModel         storage;                    // Store left and right pupil size signals
        std::vector<float>  smoothPupilSize;
        std::vector<float>  eyeDistancePx;              // Store eye distance signal
        std::vector<float>  leftEyeCloses;
        std::vector<float>  rightEyeCloses;
        
        std::shared_ptr<IImageSegmenter> imgSegAlgo;    // This algorithm is not required if
                                                        // providing manally providing a face meta
        
        std::shared_ptr<IPupilAlgorithm> pwSegAlgo;     // This pupil segmentation is required.
        
        cv::Mat             debugImg;                   // Use for debuging
        
        PWFaceMeta          faceMeta;
        
        bool                isStarted;                  // Use for controlling stages
        
        int                 smoothWindowSize;           // Use for smooth the pupil signal.
        
        KalmanFilter KF;
        Mat measurement = Mat::zeros(1, 1, CV_32F);
        
        
//        PWFaceLandmarkDetector landmark;
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
    
    void PupilwareControllerImpl::setLandMarkFile(const std::string &landmarkFilename){
//        landmark.loadLandmarkFile(landmarkFilename);
    }
    
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
    
    
    void PupilwareControllerImpl::setSmoothWindowSize(int windowSize){
        
        REQUIRES(windowSize > 0, "WindowSize must be more than zero");
        REQUIRES(windowSize%2 == 0 , "WindowSize must be odd number");
        
        smoothWindowSize = windowSize;
        
    }

    
    void PupilwareControllerImpl::start() {
        
        REQUIRES(pwSegAlgo != nullptr, "PupilSegmentor must be not null.");
        
        if(isStarted) return;
        isStarted = true;
    
        
        // Init algorithms
        pwSegAlgo->init();
    
        
    }
    

    void PupilwareControllerImpl::stop(){
        
        if(!isStarted) return;
        
        pwSegAlgo->exit();
        isStarted = false;
    }
    
    
    void PupilwareControllerImpl::processSignal(){
        BasicSignalProcessor sp;
        
        
        sp.process(storage.getLeftPupilSizes(),
                   storage.getRightPupilSizes(),
                   eyeDistancePx,
                   smoothPupilSize);
        
        
    }
    
    
    void PupilwareControllerImpl::clearBuffer(){
        
        currentFrameNumber = 0;
        
        debugImg = cv::Mat();
    
        storage.clear();
        eyeDistancePx.clear();
        smoothPupilSize.clear();
    }
    
    
    const pw::PWFaceMeta& PupilwareControllerImpl::getFaceMeta(  ) const{
        return this->faceMeta;
    }
    
    
    void PupilwareControllerImpl::setFaceMeta( const PWFaceMeta& faceMeta ){
        this->faceMeta = faceMeta;
    }
    
    
    void PupilwareControllerImpl::processFrame( const cv::Mat& srcFrame, unsigned int frameNumber ){

        if(!isStarted) return;
        
        REQUIRES(pwSegAlgo != nullptr, "PupilSegmentor must be not null.");
        REQUIRES(!srcFrame.empty(), "Source Frame must not be empty.");
        REQUIRES(srcFrame.channels() >= 3, "The source frame must be more than 3 channels.")
        
        /*---------- init ----------*/

        Mat srcBGR;
        
        if (srcFrame.channels() == 4) {
            cvtColor(srcFrame, srcBGR, CV_RGBA2BGR);
        }else{
             srcBGR = srcFrame.clone();
        }
        
        currentFrameNumber = frameNumber;
        float eyeDist = 0;
        
        
        
        /*------ Start Process -----*/
        
        if (imgSegAlgo == nullptr) {
            
            if(!faceMeta.hasFace()){
                // There is no face detected.
                storage.addPupilSize(PWPupilSize());
                eyeDistancePx.push_back( 0 );
                return;
            }

            
        }
        else{
            
            Mat grayFrame;
            cvtColor(srcBGR, grayFrame, CV_BGR2GRAY);
            
            /* segment face */
            cv::Rect faceRect;
            if(!imgSegAlgo->findFace(grayFrame, faceRect))
            {
                // Clear exiting face data, and return :)
                faceMeta = PWFaceMeta();
                faceMeta.setFrameNumber(currentFrameNumber);
                storage.addPupilSize(PWPupilSize());
                eyeDistancePx.push_back( 0 );
                return;
            }
            
            
            /* segment eyes */
            /* remember, it returns in face cooridnate */
            cv::Rect leftEyeRect;
            cv::Rect rightEyeRect;
            imgSegAlgo->extractEyes(faceRect,
                                    leftEyeRect,
                                    rightEyeRect );
            
            /* find center of those eyes */
            cv::Mat faceGray    = grayFrame(faceRect);
            auto leftEyeCenter  = imgSegAlgo->fineEyeCenter(faceGray(leftEyeRect));
            auto rightEyeCenter = imgSegAlgo->fineEyeCenter(faceGray(rightEyeRect));
            
            /* convert eyes to Frame coordinate */
            auto leftEyeFrameCoorRect   = cv::Rect( leftEyeRect.x + faceRect.x,
                                                    leftEyeRect.y + faceRect.y,
                                                    leftEyeRect.width, leftEyeRect.height);
            auto rightEyeFrameCoorRect  = cv::Rect( rightEyeRect.x + faceRect.x,
                                                    rightEyeRect.y + faceRect.y,
                                                    rightEyeRect.width, rightEyeRect.height);
            
            /* setup data, ready to go!*/
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
        

        PROMISES(eyeDist >= 0, "Eye distance less than or equle zero. Please check ");
        faceMeta.setEyeDistancePx(eyeDist);
        faceMeta.setFrameNumber(currentFrameNumber);
        
        PWPupilSize result;
//      result = pwSegAlgo->process( srcBGR, faceMeta );
        
        //-------------------------
        
        
        //! Store data to lists
        //
        storage.addPupilSize(result);
        eyeDistancePx.push_back( eyeDist );
        
        // DEBUG -----------------------------------------------------------------------------
        debugImg = srcBGR.clone();
        
//        landmark.searchLandMark(srcBGR, debugImg, faceMeta.getFaceRect());

        cv::rectangle(debugImg, faceMeta.getFaceRect(), cv::Scalar(255,0,0));
        
        cv::circle(debugImg,
                   faceMeta.getLeftEyeCenter(),
                   20,
                   cv::Scalar(255,255,0));
        
        cv::circle(debugImg,
                   faceMeta.getRightEyeCenter(),
                   20,
                   cv::Scalar(255,0,0));
        
        if(DEBUG)
        {
            cv::Mat graph = getGraphImage();
            cv::flip(graph, graph, 1);
            graph.copyTo(debugImg(cv::Rect(0, debugImg.rows - graph.rows -2, graph.cols, graph.rows)));
        }
        
        cvtColor(debugImg, debugImg, CV_BGR2RGBA, 4);
    }
    
    
    int PupilwareControllerImpl::getCognitiveLoadLevel() const{
        
        throw_assert(false, "This function has not been impremented");
        
        return 0;
    }
    
    
    const cv::Mat& PupilwareControllerImpl::getDebugImage() const{
        
        return debugImg;
    }
    
    
    const PWDataModel& PupilwareControllerImpl::getRawPupilSignal() const{
        
        return storage;
    }
    
    const std::vector<float>& PupilwareControllerImpl::getSmoothPupilSignal() const{
        
        throw_assert(false, "This function has not been implemented");
        
        return storage.getLeftPupilSizes();
        
    }
    
    cv::Mat PupilwareControllerImpl::getGraphImage() const{
        
        const int graphHeight = 600;
        const float maxValue = 0.0;
        const float minValue = 0.0;
        
        PWGraph graph("PupilSignal");
        
        graph.drawGraph(" ",
                        leftEyeCloses,        // Data
                        cv::Scalar(200,200,100),               // Line color
                        minValue,                                  // Min value
                        maxValue,                                  // Max value
                        debugImg.cols,                      // Width
                        graphHeight);                               // Height

        
        graph.drawGraph("left eye red, right eye blue",
                        storage.getLeftPupilSizes(),        // Data
                        cv::Scalar(100,255,100),               // Line color
                        minValue,                                  // Min value
                        maxValue,                                  // Max value
                        debugImg.cols,                      // Width
                        graphHeight);                               // Height
        
        graph.drawGraph(" ",
                        storage.getRightPupilSizes(),       // Data
                        cv::Scalar(100,150,200),              // Line color
                        minValue,                                  // Min value
                        maxValue,                           // Max value
                        debugImg.cols,                      // Width
                        graphHeight);                       // Height

        
        return graph.getGraphImage();
    }
}
