//
//  NMSimplex.cpp
//  Pupilware
//
//  Created by Xinyi Ding on 6/8/16.
//  Copyright © 2016 SMUUbicomp Lab. All rights reserved.
//

#include "NMSimplex.h"


void NMSimplex::setUp(pw::PWPupilProcessor * ptr) {
    processor = ptr;
}

int NMSimplex::getDims() const {
    return 3;
}

double NMSimplex::calc(const double* x) const {
    cv::Mat leftEyeVideoImage, rightEyeVideoImage;
    std::vector<float> results;
    processor->threshold_ud         =           x[0];
    processor->markCost              =          x[1];
    processor->intensityThreshold_ud  =         x[2];
    for (int j=0; j < processor->leftOutputMatVideoVector.size(); j++)
    {
        // NSLog(@"Inside J Loop %d", j);
        leftEyeVideoImage = processor->leftOutputMatVideoVector[j];
        rightEyeVideoImage = processor->rightOutputMatVideoVector[j];
        
        processor->eyeFeatureExtraction(leftEyeVideoImage, rightEyeVideoImage, j);
    }
    processor->firstIteration = 0;
    processor->process_signal();
    results = processor->getPupilPixel();
    float stdV = calStd(results);
    processor->clearData();
    return stdV;
}

