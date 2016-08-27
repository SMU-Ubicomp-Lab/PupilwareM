//
//  NMSimplex.cpp
//  Pupilware
//
//  Created by Xinyi Ding on 6/8/16.
//  Copyright © 2016 SMUUbicomp Lab. All rights reserved.
//

#include "NMSimplex.h"


void NMSimplex::setUp(std::shared_ptr<pw::PupilwareController> ptr, std::shared_ptr<pw::MDStarbustNeo> pwAlgo) {
    processor = ptr;
    algo = pwAlgo;
}

void NMSimplex::setBuffer(std::vector<cv::Mat> & videoFrameBuffer, std::vector<pw::PWFaceMeta> & faceMetaBuffer) {
    videoBuffer = videoFrameBuffer;
    faceBuffer = faceMetaBuffer;
}
int NMSimplex::getDims() const {
    return 3;
}

double NMSimplex::calc(const double* x) const {
    cv::Mat leftEyeVideoImage, rightEyeVideoImage;
    std::vector<float> results;
    algo->setThreshold(x[0]);
    algo->setSigma(x[1]);
    algo->setPrior(x[2]);
    
    
    float stdV;
    if(!processor->hasStarted())
    {
        /* init pupilware stage */
        processor->start();
        
        for (int i=0; i<videoBuffer.size(); ++i) {
            if (faceBuffer[i].getFaceRect().x == 0 || faceBuffer[i].getFaceRect().y == 0) {
                continue;
            }
            processor->setFaceMeta(faceBuffer[i]);
            processor->processFrame(videoBuffer[i], i);
        }
        
        auto rawPupilSizes = processor->getRawPupilSignal().getLeftPupilSizes();
        stdV = calStd(rawPupilSizes);
        
        std::cout << "th " << x[0] << " ,sig " << x[1] << " ,prior " << x[2] << std::endl;
        std::cout << "stdV " << stdV << std::endl;
        
        
        
        /* clear stage and do processing */
        processor->stop();
        processor->clearBuffer();
    }
    return stdV;
}

