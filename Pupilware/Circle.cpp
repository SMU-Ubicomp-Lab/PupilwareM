// Circle.cpp: implementation of the Circle class.
//
//////////////////////////////////////////////////////////////////////

// #include "stdafx.h"
// #include "MediSurf.h"
#include "Circle.h"
#include <iostream>

#ifdef _DEBUG
#undef THIS_FILE
static char THIS_FILE[]=__FILE__;
#define new DEBUG_NEW
#endif

//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////
using namespace cv;

Circle::Circle()
{
	this->m_dRadius=-1;		// error checking 
}

Circle::~Circle()
{

}

Circle::Circle(Point *V1, Point *V2, Point *V3)
{
	this->m_dRadius=-1;		// error checking 

	Point pt1 = *V1;
	Point pt2 = *V2;
	Point pt3 = *V3;
	
	if (!this->IsPerpendicular(&pt1, &pt2, &pt3) )			this->CalcCircle(&pt1, &pt2, &pt3);	
	else if (!this->IsPerpendicular(&pt1, &pt3, &pt2) )		this->CalcCircle(&pt1, &pt3, &pt2);	
	else if (!this->IsPerpendicular(&pt2, &pt1, &pt3) )		this->CalcCircle(&pt2, &pt1, &pt3);	
	else if (!this->IsPerpendicular(&pt2, &pt3, &pt1) )		this->CalcCircle(&pt2, &pt3, &pt1);	
	else if (!this->IsPerpendicular(&pt3, &pt2, &pt1) )		this->CalcCircle(&pt3, &pt2, &pt1);	
	else if (!this->IsPerpendicular(&pt3, &pt1, &pt2) )		this->CalcCircle(&pt3, &pt1, &pt2);	
	else { 
		std::cout << ("\nThe three pts are perpendicular to axis\n");
		this->m_dRadius=-1;
		return ;
	}

}

float Circle::GetLengthBetween2Points( Point * pt1, Point * pt2)
{
	return sqrtf(((pt1->x - pt2->x)*(pt1->x - pt2->x))+((pt1->y - pt2->y)*(pt1->y - pt2->y)));
}

bool Circle::IsPerpendicular(Point *pt1, Point *pt2, Point *pt3)
// Check the given point are perpendicular to x or y axis 
{
	double yDelta_a= pt2->y - pt1->y;
	double xDelta_a= pt2->x - pt1->x;
	double yDelta_b= pt3->y - pt2->y;
	double xDelta_b= pt3->x - pt2->x;
	

//	TRACE(" yDelta_a: %f xDelta_a: %f \n",yDelta_a,xDelta_a);
//	TRACE(" yDelta_b: %f xDelta_b: %f \n",yDelta_b,xDelta_b);

	// checking whether the line of the two pts are vertical
	if (fabs(xDelta_a) <= 0.000000001 && fabs(yDelta_b) <= 0.000000001){
		std::cout<<("The points are pependicular and parallel to x-y axis\n");
		return false;
	}

	if (fabs(yDelta_a) <= 0.0000001){
//		TRACE(" A line of two point are perpendicular to x-axis 1\n");
		return true;
	}
	else if (fabs(yDelta_b) <= 0.0000001){
//		TRACE(" A line of two point are perpendicular to x-axis 2\n");
		return true;
	}
	else if (fabs(xDelta_a)<= 0.000000001){
//		TRACE(" A line of two point are perpendicular to y-axis 1\n");
		return true;
	}
	else if (fabs(xDelta_b)<= 0.000000001){
//		TRACE(" A line of two point are perpendicular to y-axis 2\n");
		return true;
	}
	else return false ;
}

double Circle::CalcCircle(Point *pt1, Point *pt2, Point *pt3)
{
	double yDelta_a= pt2->y - pt1->y;
	double xDelta_a= pt2->x - pt1->x;
	double yDelta_b= pt3->y - pt2->y;
	double xDelta_b= pt3->x - pt2->x;
	
	if (fabs(xDelta_a) <= 0.000000001 && fabs(yDelta_b) <= 0.000000001){
		//std::cout<<("Calc cirlce \n");
		this->m_Center.x= 0.5*(pt2->x + pt3->x);
		this->m_Center.y= 0.5*(pt1->y + pt2->y);
		this->m_dRadius= GetLengthBetween2Points(&m_Center,pt1);		// calc. radius
//		TRACE(" Center: %f %f %f\n", m_Center.x(), m_Center.y(), m_Center.z());
//		TRACE(" radius: %f %f %f\n", length(&m_Center,pt1), length(&m_Center,pt2),length(&m_Center,pt3));

		return this->m_dRadius;
	}
	
	// IsPerpendicular() assure that xDelta(s) are not zero
	double aSlope=yDelta_a/xDelta_a; // 
	double bSlope=yDelta_b/xDelta_b;
	if (fabs(aSlope-bSlope) <= 0.000000001){	// checking whether the given points are colinear. 	
		//std::cout<<("The three pts are colinear\n");
		return -1;
	}

	// calc center
	this->m_Center.x= (aSlope*bSlope*(pt1->y - pt3->y) + bSlope*(pt1->x + pt2 ->x)
		- aSlope*(pt2->x+pt3->x) )/(2* (bSlope-aSlope) );
	this->m_Center.y = -1*(m_Center.x - (pt1->x+pt2->x)/2)/aSlope +  (pt1->y+pt2->y)/2;
	

	this->m_dRadius= GetLengthBetween2Points(&m_Center,pt1);		// calc. radius
//	TRACE(" Center: %f %f %f\n", m_Center.x(), m_Center.y(), m_Center.z());
//	TRACE(" radius: %f %f %f\n", length(&m_Center,pt1), length(&m_Center,pt2),length(&m_Center,pt3));
	return this->m_dRadius;
}

Point* Circle::GetCenter()
{
	return &this->m_Center;

}

double Circle::GetRadius()
{
	return this->m_dRadius;
}
