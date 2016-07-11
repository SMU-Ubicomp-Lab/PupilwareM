//
//  PWFaceMeta.hpp
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 6/26/16.
//  Copyright © 2016 SMU Ubicomp Lab All rights reserved.
//

#ifndef PWFaceMeta_hpp
#define PWFaceMeta_hpp


namespace pw {
    
    class PWFaceMeta {
        
    private:
        
        cv::Rect faceRect;
        cv::Rect leftEyeRect;
        cv::Rect rightEyeRect;
        cv::Point leftEyeCenter;
        cv::Point rightEyeCenter;
        bool leftEyeClosed;
        bool rightEyeClosed;
        
        
        float               eyeDistancePx;
        unsigned int        frameNumber;
        
    public:
        PWFaceMeta();
        virtual ~PWFaceMeta();
        
        unsigned int        getFrameNumber() const;
        void                setFrameNumber( unsigned int frameNumber );
        
        cv::Point           getLeftEyeCenter() const;
        void                setLeftEyeCenter( cv::Point leftEyeCenter);
        
        cv::Point           getRightEyeCenter() const;
        void                setRightEyeCenter( cv::Point rightEyeCenter );
        
        const cv::Rect&     getLeftEyeRect() const;
        void                setLeftEyeRect( const cv::Rect& eyeRect );
        
        const cv::Rect&     getRightEyeRect() const;
        void                setRightEyeRect( const cv::Rect& eyeRect );
        
        const cv::Rect&     getFaceRect() const;
        void                setFaceRect( const cv::Rect& faceRect );
        
        bool                isLeftEyeClosed() const;
        void                setLeftEyeClosed( bool closed );
        
        bool                isRightEyeClosed() const;
        void                setRightEyeClosed( bool closed );
        
        const float         getEyeDistancePx() const;
        void                setEyeDistancePx( float eyeDist );
        
        inline bool hasFace() const { return (faceRect.width != 0 && faceRect.height != 0); }
        
    };
}

#endif /* PWFaceMeta_hpp */
