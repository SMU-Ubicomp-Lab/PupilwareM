//
//  PWParameter.h
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 8/3/16.
//  Copyright © 2016 Chatchai Mark Wangwiwattana. All rights reserved.
//

#ifndef PWPARAMETER_hpp
#define PWPARAMETER_hpp

namespace pw{
    

    struct PWParameter
    {
    //    processor->windowSize_ud        = (int)[defaults integerForKey:kWindowSize];
    //    processor->mbWindowSize_ud      = (int)[defaults integerForKey:kMbWindowSize];
    //    processor->eyeDistance_ud       = self.model.getDist;
    //    processor->baselineStart_ud     = self.model.getBaseStart;
    //    processor->baselineEnd_ud       = self.model.getBaseEnd;
    //    processor->baseline             = self.model.getBaseline;
    //    processor->cogHigh              = self.model.getCogHigh;

        float           threshold;
        float           prior;
        float           sigma;
        unsigned int    sbRayNumber;
        int             degreeOffset;

    };

}
#endif /* PWPARAMETER_hpp */