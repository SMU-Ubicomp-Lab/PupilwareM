// Circle.h: interface for the Circle class.
// Circle class.
// Purpose : Represent the circle object
// Input : 3 different points
// Process : Calcuate the radius and center
// Output : Circle
//           
// This class originally designed for representation of discretized curvature information 
// of sequential pointlist  
// KJIST CAD/CAM     Ryu, Jae Hun ( ryu@geguri.kjist.ac.kr)
// Last update : 11 / 24 / 2014
// Modify using OPENCV by Chatchai Wangwiwattana ( chatchai.mark.wang@gmail.com )

#if !defined(AFX_CIRCLE_H__1EC15131_4038_11D3_8404_00C04FCC7989__INCLUDED_)
#define AFX_CIRCLE_H__1EC15131_4038_11D3_8404_00C04FCC7989__INCLUDED_

#include <opencv2/opencv.hpp>

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

class Circle  
{
public:
	double GetRadius();
	cv::Point2f* GetCenter();
	Circle(cv::Point2f *p1, cv::Point2f *p2, cv::Point2f *p3);	// p1, p2, p3 are co-planar
	Circle();
	virtual ~Circle();

	double CalcCircle(cv::Point2f *pt1, cv::Point2f *pt2, cv::Point2f *pt3);
private:
	bool IsPerpendicular(cv::Point2f *pt1, cv::Point2f *pt2, cv::Point2f *pt3);
	float GetLengthBetween2Points( cv::Point2f * pt1, cv::Point2f * pt2);
	double m_dRadius;
	cv::Point2f m_Center;
};

#endif // !defined(AFX_CIRCLE_H__1EC15131_4038_11D3_8404_00C04FCC7989__INCLUDED_)
