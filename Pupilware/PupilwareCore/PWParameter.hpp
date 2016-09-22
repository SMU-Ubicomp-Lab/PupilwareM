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
        float           threshold;
        float           prior;
        float           sigma;
        unsigned int    sbRayNumber;
        int             degreeOffset;

    };

}
#endif /* PWPARAMETER_hpp */