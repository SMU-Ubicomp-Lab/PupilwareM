//
//  PWVideoReader.hpp
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 6/29/16.
//  Copyright © 2016 SMU Ubicomp Lab All rights reserved.
//

#ifndef PWVideoReader_hpp
#define PWVideoReader_hpp

namespace pw{
    
    class PWVideoReader{
        
    public:
        
        PWVideoReader();
        PWVideoReader( const std::string& filename);
        
        bool open( const std::string& filename);
        
        void close();
        
        cv::Mat readFrame();
        
        /* if you buffer it, you can get a frame by number*/
        cv::Mat getFrameAt( unsigned int frameNumber );
        
        unsigned int getMaxFrame() const;
        
        
    private:
    
        PWVideoReader( const PWVideoReader& other);
        PWVideoReader& operator=( const PWVideoReader& other);
    
        const int MAX_BUFFER_SIZE = 2048;
        
        std::vector<cv::Mat> frameBuffer;
        
        cv::VideoCapture    capture;
        
        
        
    };
}

#endif /* PWVideoReader_hpp */
