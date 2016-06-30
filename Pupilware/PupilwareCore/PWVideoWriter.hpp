//
//  PWVideoWriter.hpp
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 6/29/16.
//  Copyright © 2016 SMU Ubicomp Lab All rights reserved.
//

#ifndef PWVideoWriter_hpp
#define PWVideoWriter_hpp

namespace pw{
    
    class PWVideoWriter{
        
    public:
        
        PWVideoWriter();
        PWVideoWriter( const std::string& filename);
        ~PWVideoWriter();
        
        bool open( const std::string& filename, int FPS=30, cv::Size frameSize=cv::Size(100,100));
        
        void close();
        
        void writeFrame( const cv::Mat& frame );
        PWVideoWriter& operator<<( const cv::Mat& frame );
    
    
    private:
        PWVideoWriter( const PWVideoWriter& other);
        PWVideoWriter& operator=( const PWVideoWriter& other);
        
        const int MAX_BUFFER_SIZE = 2048;
        
        std::vector<cv::Mat> frameBuffer;
        
        cv::VideoWriter    capture;
        
        
        
    };
}

#endif /* PWVideoWriter_hpp */
