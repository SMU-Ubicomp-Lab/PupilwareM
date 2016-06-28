//
//  AlgorithmBase.hpp
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 5/25/16.
//  Copyright © 2016 Chatchai Wangwiwattana. All rights reserved.
//

#ifndef AlgorithmBase_hpp
#define AlgorithmBase_hpp

#include <opencv2/opencv.hpp>
#include "PWFaceMeta.hpp"

#include "../Helpers/CWUIHelper.hpp"
#include "../Helpers/CWCVHelper.hpp"

#include "PWTypes.hpp"


namespace pw{

    class IPupilAlgorithm {

    public:
        IPupilAlgorithm(const std::string& name):_name(name){};
        virtual ~IPupilAlgorithm(){};

        virtual void init() =0;

        virtual PWPupilSize process( const cv::Mat src, const PWFaceMeta &meta ) =0;
        
        virtual void exit() =0;

        inline const std::string& getName() const{ return _name; };
        
        

    private:
        std::string _name;
    };
}


#endif /* AlgorithmBase_hpp */
