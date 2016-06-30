//
//  mdStarbust.hpp
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 5/25/16.
//  Copyright © 2016 Chatchai Wangwiwattana. All rights reserved.
//

#ifndef DummyAlgo_hpp
#define DummyAlgo_hpp

#include "IPupilAlgorithm.hpp"

namespace pw {

    class DummyAlgo : public IPupilAlgorithm {
    
    public:
        DummyAlgo( const std::string& name);
        virtual ~DummyAlgo();
        
        virtual void init() override final;
        virtual PWPupilSize process( const cv::Mat& src, const PWFaceMeta &meta ) override final;
        virtual void exit() override final;
        
    private:
        int th;

        std::shared_ptr<CVWindow> thWin;
        
    };
}

#endif /* mdStarbust_hpp */
