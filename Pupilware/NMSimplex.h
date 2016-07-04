//
//  NMSimplex.hpp
//  Pupilware
//
//  Created by Xinyi Ding on 6/8/16.
//  Copyright © 2016 SMUUbicomp Lab. All rights reserved.
//

#ifndef NMSimplex_hpp
#define NMSimplex_hpp

#include <stdio.h>
#include <opencv2/core.hpp>
#include <opencv2/opencv.hpp>

#include "PWPupilProcessor.hpp"
#include "PWUtilities.h"


class NMSimplex:public cv::MinProblemSolver::Function {
public:
    int getDims() const;
    double calc(const double* x) const;
    void setUp(pw::PWPupilProcessor *ptr);
    
private:
    cv::Mat leftEyeVideoImage, rightEyeVideoImage;
    pw::PWPupilProcessor * processor;
};

#endif /* NMSimplex_hpp */