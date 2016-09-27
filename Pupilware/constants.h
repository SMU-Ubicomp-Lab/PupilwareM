#ifndef CONSTANTS_H
#define CONSTANTS_H

// Settings

// Signal Processing Setting
#define kEyeDistance    @"s_eyeDistance"
#define kWindowSize     @"s_windowSize"
#define kMbWindowSize   @"s_mbWindowSize"
#define kBaselineStart  @"s_baselineStart"
#define kBaselineEnd    @"s_baselineEnd"
#define kIntensityThrehold @"s_intensityThreshold"
#define kBaseline       @"s_baseLine"
#define kCogHighSize    @"s_cogHighSize"

//MDStartbust Neo Setting
#define kSBThreshold      @"s_sb_threshold"
#define kSBPrior          @"s_sb_prior"
#define kSBSigma          @"s_sb_sigma"
#define kSBNumberOfRays   @"s_sb_numberOfRays"
#define kSBDegreeOffset   @"s_sb_degreeOffset"

// Calibration Setting
const float kCalibrationDuration = 7.0f;  //Allow 10 secs to collect frames before analysis data


#endif