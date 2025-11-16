//+------------------------------------------------------------------+
//|                                                       SRLine.mqh |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"

#define EQUAL 0
#define LESS -1
#define MORE 1

#include <Object.mqh>
#include <Arrays\ArrayObj.mqh>
#include "PriceTime.mqh"

enum ENUM_SORT_TYPE {
   SORT_BY_STRENGTH,
   SORT_BY_VALUE,
   SORT_BY_DATE
};

class SRLine: public CObject {
 private:
   CArrayObj         *points; // array of PriceTime

 public:
   double Value;
    
                     SRLine() {
      points = new CArrayObj();
   }

                    ~SRLine() {
      points.Clear();
      delete points;
   }

   void              AddPoint(PriceTime *p) {
      PriceTime *newPt = new PriceTime(p.price, p.time);
      points.Add(newPt);
      Value = AvgValue();
   }

   void              ClearPoints() {
      for(int i=0; i<points.Total(); i++) {
         points.Delete(i);
         delete points.At(i);
      }
      points.Clear();
      Value = AvgValue();
   }

   double            AvgValue() const{
      if (points.Total() == 0) {
         return 0;
      }
      double avgVal = 0;
      for(int i=0; i<points.Total(); i++) {
         PriceTime *pt = points.At(i);
         avgVal += pt.price;
      }
      return avgVal / points.Total();
   }
   
   double            MinValue() {
      if (points.Total() == 0) {
         return 0;
      }
      double minVal = DBL_MAX;
      for(int i=0; i<points.Total(); i++) {
         PriceTime *pt = points.At(i);
         if (pt.price < minVal) {
            minVal = pt.price;
         }
      }
      return minVal;
   }
   
   double            MaxValue() {
      if (points.Total() == 0) {
         return 0;
      }
      double maxVal = 0;
      for(int i=0; i<points.Total(); i++) {
         PriceTime *pt = points.At(i);
         if (pt.price > maxVal) {
            maxVal = pt.price;
         }
      }
      return maxVal;
   }

   int               Strength() const {
      return points.Total();
   }

   datetime          StartDate() const {
      PriceTime *first = points.At(0);
      datetime minDate = first.time;
      for(int i=1; i<points.Total(); i++) {
         PriceTime *pt = points.At(i);
         if (pt.time < minDate) {
            minDate = pt.time;
         }
      }
      return minDate;
   }

   bool              IsInRange(double price, double range) {
      return MathAbs(price - AvgValue())/_Point <= range;
   }

   virtual int       Compare(const CObject *node,const int mode=0) const {
      const SRLine *srline=node;
      switch(mode) {
      case SORT_BY_STRENGTH:
         if(srline.Strength()==this.Strength())
            return EQUAL;
         else if(srline.Strength()<this.Strength())
            return MORE;
         else
            return LESS;
      case SORT_BY_VALUE:
         if(srline.AvgValue()==this.AvgValue())
            return EQUAL;
         else if(srline.AvgValue()<this.AvgValue())
            return MORE;
         else
            return LESS;      
      case SORT_BY_DATE:
         if(srline.StartDate()==this.StartDate())
            return EQUAL;
         else if(srline.StartDate()<this.StartDate())
            return MORE;
         else
            return LESS;
      }
      return EQUAL;
   }

   SRLine*           Clone() {
      SRLine *newSRLine = new SRLine();
      for(int i=0; i<points.Total(); i++) {
         PriceTime *oldPT = points.At(i);
         PriceTime *newPT = new PriceTime(oldPT.price, oldPT.time);
         newSRLine.AddPoint(newPT);
         delete newPT;
      }
      return newSRLine;
   }
};
//+------------------------------------------------------------------+
