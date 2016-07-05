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

#include "PupilwareCore/PupilwareController.hpp"
#include "PupilwareCore/Algorithm/MDStarbustNeo.hpp"

#include "PWUtilities.h"


class NMSimplex:public cv::MinProblemSolver::Function {
public:
    int getDims() const;
    double calc(const double* x) const;
    void setUp(std::shared_ptr<pw::PupilwareController> ptr, std::shared_ptr<pw::MDStarbustNeo> pwAlgo);
    void setBuffer(std::vector<cv::Mat> & videoFrameBuffer, std::vector<pw::PWFaceMeta> & faceMetaBuffer);
    
private:
    cv::Mat leftEyeVideoImage, rightEyeVideoImage;
    std::shared_ptr<pw::PupilwareController> processor;
    std::shared_ptr<pw::MDStarbustNeo> algo;
    std::vector<cv::Mat> videoBuffer;
    std::vector<pw::PWFaceMeta> faceBuffer;
};

#endif /* NMSimplex_hpp */