//
//  PWPupilProcessor.h
//  Pupilware
//
//  Authors : Chatchai Wangwiwattana
//            <Fill your name here>
//
//  Update : 2/5/2015
//
//  Copyright (c) 2014 SMU. All rights reserved.
//

#include <opencv2/opencv.hpp>
#include <opencv2/objdetect/objdetect.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/core/core.hpp>

// #include <list>
#include <string>

namespace pw
{

    class PWPupilProcessor
    {
    public:
        
        PWPupilProcessor(const std::string& videoFileName,
                         const std::string& outputFileName);
        
        
        ~PWPupilProcessor();
        
        
        // Setting, make they public just
        // because future direct binding with the UI.
        float   eyeDistance_ud;
        int     windowSize_ud;
        int     mbWindowSize_ud;
        int     baselineStart_ud;
        int     baselineEnd_ud;
        int     threshold_ud;
        int     markCost;
        float   baseline;
        float   cogHigh;
        

        cv::VideoCapture    getVideoDevice();
        float               getPupilSize() const;
        size_t              getTotalFrames() const;
        float               getLeftEyeW(int idx) const;
        float               getRightEyeW(int idx) const;
        float               getEyeDistSB(int idx) const;
        
        std::vector<float>  getResultGraph() const;
        float               getResultPeak() const;
        
        
        bool                isShouldDetectFace;
        bool                isDrawFPS;
        bool                isShouldWriteVideo;
        bool                isGetBaselineFromVideo;
    
        bool loadVideo      ( const std::string& videoFileName );
        bool closeCapture   ();
        void clearData      ();
        
        // This function only use to link with Object-C
        
//        bool faceAndEyeFeatureExtraction(cv::Mat srcImage, cv::Mat leftEyeMat, cv::Mat rightEyeMat, cv::Mat& resultImage);
        
        bool faceAndEyeFeatureExtraction(cv::Mat srcImage, cv::Mat leftEyeMat, cv::Mat rightEyeMat, cv::Mat leftEyeMatColor, cv::Mat rightEyeMatColor, cv::Rect leftEyeRect, cv::Rect rightEyeRect, BOOL isFinished, cv::Mat& resultImage);
        
//        bool faceAndEyeFeatureExtraction(cv::Mat srcImage, CGRect leftEyeRect, CGRect rightEyeRect, cv::Mat& resultImage);

       
        bool processImage(cv::Mat srcImage, cv::Mat& resultImage);
        void process_signal ();
        const std::vector<float>& getPupilMM() const;
        const std::vector<float>& getPupilPixel() const;
        
        // Return 0.0 - 1.0:
        // 0.0 is baseline
        // 1.0 is high cognitive load.
        float getCognitiveLevel() const;
        float getCurrentCognitiveLoad();
        float getBaseline();
        float calBaselineFromCurrentSignal();
        
    private:
        
        cv::VideoCapture    capture;
        cv::VideoWriter     outvideo;
        
        float               pupilSize;
        

        std::vector<float>  left_eye_w_sb;
        std::vector<float>  right_eye_w_sb;
        std::vector<float>  eye_dist_sb;
        std::vector<float>  pupil_mm;
        std::vector<cv::Point>  right_eye_center;
        std::vector<cv::Point>  left_eye_center;
        std::vector<float>  resultGraph;
        
        ///////////////////////////////////////////////////////////////////////////////
        // Member function
        ///////////////////////////////////////////////////////////////////////////////
        
        
        
        void store_signal               ();
        
        cv::Mat equalizeIntensity       ( const cv::Mat& inputImage);
        
  //      void findEyes                   (cv::Mat frame_gray, cv::Rect leftEyeRect, cv::Rect rightEyeRect, cv::Rect face);
       void findEyes                   (cv::Mat frame_gray, cv::Mat leftEyeMat, cv::Mat rightEyeMat, cv::Rect face);


        void searchDarkestSpotWithInRange( int range,
                                          cv::Mat& grayImage,
                                          cv::Point& inOutPoint );
        
        bool applyStarbust              (const cv::Mat& eyeROI,
                                         const cv::Point& eyeCenter,
                                         float& outWidth,
                                         float& outHeight,
                                         cv::Point& outCenterPoint,
                                         const std::string& eye_type,
                                         cv::Mat& outDisplayImage );
        
        void extractFeaturesAndSaveToGlobal(cv::Mat& leftEyeROIMat,
                                         cv::Mat& rightEyeROIMat,
                                         cv::Point leftCenter,
                                         cv::Point rightCenter);
        
        void combineImages              (cv::Size canvasSize,
                                         cv::Mat face,
                                         cv::Mat leftEye,
                                         cv::Mat rightEye,
                                         cv::Mat& out );
    
        
        
        
        
        float calCogMax( std::vector<float>signal) const;
        
    };

    
    ///////////////////////////////////////////////////////////////////////////////
    // Utility functions
    ///////////////////////////////////////////////////////////////////////////////
    inline float convert_pixel_to_mm(float pupilSizeInPixel,
                                     float eyeDistanceInPixel,
                                     float eyeDistanceInMM)
    {
        return (eyeDistanceInMM/eyeDistanceInPixel) * pupilSizeInPixel;
    }

    
}

