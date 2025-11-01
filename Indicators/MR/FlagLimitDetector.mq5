//+------------------------------------------------------------------+
//|                                                 FL_Detector.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2
//--- plot BullishPole
#property indicator_label1  "SwingLow"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot BearishPole
#property indicator_label2  "SwingHigh"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrYellow
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

#include <Math\Stat\Math.mqh>
#include <MR\ArrayListClass.mqh>
#include <MR\ArrayList.mqh>

//--- indicator buffers
double         SwingLowBuffer[];
double         SwingHighBuffer[];

//--- input parameters
input int      rangePeriod   = 100;
input int      swingPeriod   = 20;
input bool     showSwings    = true;
input bool     showFlagLimit = true;
input bool     showSnR_ref   = true;
input int      inpLastBarForAnalysis = 500;
// ZigZag input
input int      InpDepth      = 12;  // Depth
input int      InpDeviation  = 5;   // Deviation
input int      InpBackstep   = 3;   // Back Step
// DVP Input
input int      inpDVPPeriod        = 60;
input int      inpDVPNRows         = 100;
input double   inpDVPPctValueArea  = 70;
input bool     inpDVPshowValueArea = true;
// Peak analysis inputs
input int      InpGapPoints   =  100;        // Minimum gap between peaks in points
input int      InpSensitivity =  2;          // Peak sensitivity
input int      InpLookback    =  50;         // Lookback

class RatesPoint {
 public:
   datetime          date;
   double            price;
   string            type;
   int               flag;
   MqlRates          rates;

                     RatesPoint() {
   }

                     RatesPoint(const RatesPoint &old) {
      date = old.date;
      price = old.price;
      type = old.type;
      flag = old.flag;
      rates = old.rates;
   }

                     RatesPoint(MqlRates &pRates, string pType) {
      rates = pRates;
      date = pRates.time;
      price = pType == "SH" ? pRates.high : pType == "SL" ? pRates.low : pRates.close;
      type = pType;
   }

                    ~RatesPoint() {
      //delete rates;
   }
};

class FLZone: public IEquatable<FLZone*> {
 public:
   datetime          startdate;
   datetime          enddate;
   double            high;
   double            low;
   double            avgRange;
   double            swingPrice;
   double            level;
   string            formationLoc;
   RatesPoint        *reference;

   FLZone() {
   }

   FLZone(const FLZone* &old) {
      startdate = old.startdate;
      enddate = old.enddate;
      reference = new RatesPoint(old.reference);
      avgRange = old.avgRange;
      calculateHighLow();
   }

   FLZone(datetime pStartdate, datetime pEnddate, RatesPoint* &rp, double plevel) {
      startdate = pStartdate;
      enddate = pEnddate;
      reference = new RatesPoint(rp);
      level = plevel;
   }

   ~FLZone() {
      delete reference;
   }
   
   bool Equals(FLZone* &other) {
      if (  other.startdate == this.startdate && other.level == this.level) {
         return true;
      }
      return false;
   }

 private:
   void              calculateHighLow() {
      double tempHighs[];
      CopyHigh(_Symbol, PERIOD_CURRENT, startdate, enddate, tempHighs);
      int highIdx = ArrayMaximum(tempHighs, 0, WHOLE_ARRAY);
      high = tempHighs[highIdx];

      double tempLows[];
      CopyLow(_Symbol, PERIOD_CURRENT, startdate, enddate, tempLows);
      int lowIdx = ArrayMinimum(tempLows, 0, WHOLE_ARRAY);
      low = tempLows[lowIdx];

      swingPrice = reference.type == "SH" ? reference.rates.high : reference.rates.low;
      if(MathAbs(high - swingPrice) > MathAbs(low - swingPrice)) {
         formationLoc = "upper";
      } else if(MathAbs(high - swingPrice) < MathAbs(low - swingPrice)) {
         formationLoc = "lower";
      }
   }
};

class SRLevel {
 public:
   double            level;
   datetime          startdate;
   datetime          enddate;
   RatesPoint*       points[];

                     SRLevel() {
   }

   SRLevel(const SRLevel &old) {
      level = old.level;
      startdate = old.startdate;
      enddate = old.enddate;
      ArrayResize(points, ArraySize(old.points));
      for(int i=0; i<ArraySize(old.points)-1; i++) {
         points[i] = new RatesPoint(old.points[i]);
      }
      calculateAverage();
   }

   SRLevel(double pLevel) {
      level = pLevel;
   }

   void AddPoint(RatesPoint *point) {
      ArrayResize(points, ArraySize(points)+1, 10);
      points[ArraySize(points)-1] = new RatesPoint(point);
      calculateAverage();
   }

                    ~SRLevel() {
   }

 private:
   void              calculateAverage() {
      double avg;
      startdate = points[0].rates.time;
      enddate = points[0].rates.time;
      for(int i=0; i<ArraySize(points); i++) {
         double price = points[i].type == "SH" ? points[i].rates.high : points[i].rates.low;
         avg += price;
         if (points[i].rates.time < startdate) {
            startdate = points[i].rates.time;
         }
         if (points[i].rates.time > enddate) {
            enddate = points[i].rates.time;
         }
      }
      avg /= ArraySize(points);
      level = avg;
   }
};

struct PocLevel {
   datetime time;
   double poc;
};

class RatesPointSortByPrice: public ICompare<RatesPoint*> {
 public:
   int               Compare(RatesPoint* &el1, RatesPoint* &el2) {
      if (  el1.price < el2.price) return -1;
      if (  el1.price > el2.price) return 1;
      return 0;
   }
};

// global variable
RatesPoint* SwingList[];
//FLZone* FlagLimitList[];

CArrayListClass<FLZone>* FlagLimitList;

int zigzagHandle;
int dvpHandle;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//--- indicator buffers mapping
   SetIndexBuffer(0,SwingLowBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,SwingHighBuffer,INDICATOR_DATA);

//--- setting a code from the Wingdings charset as the property of PLOT_ARROW
   PlotIndexSetInteger(0,PLOT_ARROW,233);
   PlotIndexSetInteger(1,PLOT_ARROW,234);

//--- setting shift
   PlotIndexSetInteger(0,PLOT_ARROW_SHIFT,10);
   PlotIndexSetInteger(1,PLOT_ARROW_SHIFT,-10);

//---
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---

   zigzagHandle   =  iCustom(Symbol(), Period(), "Examples\\ZigZag", InpDepth, InpDeviation, InpBackstep);
   if (zigzagHandle==INVALID_HANDLE) {
      Print("Could not create a handle to zigzag indicator");
      return(INIT_FAILED);
   }
   dvpHandle = iCustom(Symbol(), Period(), "MR\\DVP1", inpDVPPeriod, inpDVPNRows, inpDVPPctValueArea, inpDVPshowValueArea);
   if (dvpHandle==INVALID_HANDLE) {
      Print("Could not create a handle to DVP indicator");
      return(INIT_FAILED);
   }
   
   FlagLimitList = new CArrayListClass<FLZone>();

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int  reason) {
   int cntdeleted = ObjectsDeleteAll(0, "FL_");
   
   for(int i=0; i<ArraySize(SwingList); i++) {
      delete SwingList[i];
   }
   ArrayFree(SwingList);

   IndicatorRelease(zigzagHandle);
   IndicatorRelease(dvpHandle);
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]) {
//---
   if(prev_calculated<rangePeriod) {
      ArrayInitialize(SwingLowBuffer,EMPTY_VALUE);
      ArrayInitialize(SwingHighBuffer,EMPTY_VALUE);
   }

// Only do this on a new bar
   if (rates_total==prev_calculated) {
      return(rates_total);
   }

   for(int i=prev_calculated; i<rates_total-1; i++) {
      if (i-(inpLastBarForAnalysis-1) < 0) {
         continue;
      }
      
      double dvpBuffer[];
      int dvpCnt = CopyBuffer(dvpHandle, 2, 0, 1, dvpBuffer);
      if (dvpCnt != 1) {
         printf("error copybuffer: %s", GetLastError());
         return(rates_total);
      }
      double poc = dvpBuffer[0];

      CArrayListClass<RatesPoint>* levels = new CArrayListClass<RatesPoint>();
      GetZigZagLevel(time[i-(inpLastBarForAnalysis-1)], time[i], levels);
      if (levels.size() <= 0) {
         continue;
      }
      
      double avgRange = getAvgRanges(time[i], 100);
      RatesPoint* ref;
      bool found = false;
      for(int j=levels.size()-1; j>=0; j--) {
         double lowerlevel = poc - avgRange;
         double upperlevel = poc + avgRange;
         if (levels[j].type == "SH") {
            if (levels[j].rates.high > lowerlevel && levels[j].rates.high < upperlevel) { 
               ref = levels[j];
               found = true;
            }
         }
         else if (levels[j].type == "SL") {
            if (levels[j].rates.low > lowerlevel && levels[j].rates.low < upperlevel) {
               ref = levels[j];
               found = true;
            }
         }
      }
      
      if (found) {
         FLZone* zone = new FLZone();
         MqlRates rates[];
         CopyRates(_Symbol, _Period, ref.rates.time, time[i], rates);
         datetime startdate = 0;
         datetime enddate = 0;
         double min = rates[ArraySize(rates)-1].low;
         double max = rates[ArraySize(rates)-1].high;
         for(int j=ArraySize(rates)-1; j>=0; j--) {
            if (rates[j].low < poc && rates[j].high > poc && (rates[j].high-rates[j].low <= avgRange)) {
               if (enddate == 0) {
                  enddate = rates[j].time;
               }
            }
            else {
               if (enddate > 0) {
                  startdate = rates[j+1].time;
               }
            }
            if (enddate > 0) {
               if (rates[j].low < min) {
                  min = rates[j].low;
               }
               if (rates[j].high > max) {
                  max = rates[j].high;
               }
            }
         }
         if (startdate > 0 && enddate > 0) {
            if ((ref.type == "SL" && max < ref.rates.high) || (ref.type == "SH" && min > ref.rates.low)) {
               FLZone* zone = new FLZone(startdate, enddate, ref, poc);
               if (!FlagLimitList.exist(zone)) {
                  FlagLimitList.add(zone);
               }
               else {
                  int idx = FlagLimitList.indexOf(zone);
                  FlagLimitList.set(idx, zone);
               }
            }
         }
      }
   }

   //ZoneRedraw();
//--- return value of prev_calculated for next call
   return(rates_total);
}
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
//---

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void getLastSwing(datetime time, RatesPoint* &swinglist[]) {
   for (int i=ArraySize(SwingList)-1; i>=0; i--) {
      if (SwingList[i].rates.time > time-500*PeriodSeconds()) {
         ArrayResize(swinglist, ArraySize(swinglist)+1, 5);
         swinglist[ArraySize(swinglist)-1] = SwingList[i];
      }
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isSwingExist(RatesPoint &rp) {
   for(int i=0; i<ArraySize(SwingList)-1; i++) {
      if (SwingList[i].rates.time == rp.rates.time && SwingList[i].type == rp.type) {
         return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//bool isFlagLimitExist(FLZone &fl) {
//   for(int i=0; i<ArraySize(FlagLimitList)-1; i++) {
//      if (FlagLimitList[i].startdate == fl.startdate && FlagLimitList[i].enddate == fl.enddate && FlagLimitList[i].reference.rates.time == fl.reference.rates.time) {
//         return true;
//      }
//   }
//   return false;
//}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ZoneRedraw() {
   ObjectsDeleteAll(0, "FL_");
//   if (ArraySize(FlagLimitList) > 0) {
//      for(int i=0; i<ArraySize(FlagLimitList); i++) {
//         if (showFlagLimit) {
//            datetime d1Line = FlagLimitList[i].reference.rates.time;
//            double pLine = FlagLimitList[i].reference.type == "SH" ? FlagLimitList[i].reference.rates.high : FlagLimitList[i].reference.rates.low;
//            datetime d2Line = FlagLimitList[i].enddate;
//            string objLine = "FL_Line_" + IntegerToString(i);
//            ObjectCreate(0, objLine, OBJ_TREND, 0, d1Line, pLine, d2Line, pLine);
//
//            datetime d1 = FlagLimitList[i].startdate - PeriodSeconds();
//            double p1 = FlagLimitList[i].formationLoc == "upper" ? FlagLimitList[i].swingPrice : FlagLimitList[i].swingPrice - FlagLimitList[i].avgRange;
//            datetime d2 = FlagLimitList[i].enddate + PeriodSeconds();
//            double p2 = FlagLimitList[i].formationLoc == "upper" ? FlagLimitList[i].swingPrice + FlagLimitList[i].avgRange : FlagLimitList[i].swingPrice;
//            string objName = "FL_Rect_" + IntegerToString(i);
//            ObjectCreate(0, objName, OBJ_RECTANGLE, 0, d1, p1, d2, p2);
//         }
//      }
//   }
   ChartRedraw();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getCurrentAvgRanges(int period) {
   MqlRates rates[];
   CopyRates(_Symbol, PERIOD_CURRENT, 0, period, rates);
   double avgRanges = 0;
   for(int i=0; i<period; i++) {
      avgRanges += rates[i].high - rates[i].low;
   }
   return avgRanges /= period;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getAvgRanges(datetime startTime, int period) {
   MqlRates rates[];
   CopyRates(_Symbol, PERIOD_CURRENT, startTime, period, rates);
   double avgRanges = 0;
   for(int i=0; i<ArraySize(rates); i++) {
      avgRanges += rates[i].high - rates[i].low;
   }
   return avgRanges /= period;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isSwingHigh(MqlRates &rates[]) {
   bool ret = false;
   int n = ArraySize(rates);
   if (n % 2 == 1) {
      int mid = (n - 1) / 2;
      double maxPrice = rates[0].high;
      int maxIndex = 0;
      for(int i=1; i<n; i++) {
         if (rates[i].high > maxPrice) {
            maxPrice = rates[i].high;
            maxIndex = i;
         }
      }
      ret = maxIndex == mid;
   }
   return ret;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isSwingLow(MqlRates &rates[]) {
   bool ret = true;
   int n = ArraySize(rates);
   if (n % 2 == 1) {
      int mid = (n - 1) / 2;
      double minPrice = rates[0].low;
      int minIndex = 0;
      for(int i=1; i<n; i++) {
         if (rates[i].low < minPrice) {
            minPrice = rates[i].low;
            minIndex = i;
         }
      }
      ret = minIndex == mid;
   }
   return ret;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isNotRetested(double level, string type, datetime startdate, datetime enddate) {
   MqlRates rates[];
   CopyRates(_Symbol, PERIOD_CURRENT, startdate, enddate, rates);
   for(int i=0; i<ArraySize(rates)-1; i++) {
      if (type == "high") {
         if (rates[i].high > level) {
            return false;
         }
      } else if (type == "low") {
         if (rates[i].low < level) {
            return false;
         }
      }
   }
   return true;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isMovedFar(double level, string type, datetime startdate, datetime enddate) {
   MqlRates rates[];
   CopyRates(_Symbol, PERIOD_CURRENT, startdate, enddate, rates);
   double max = rates[0].high;
   double min = rates[0].low;
   for(int i=1; i<ArraySize(rates)-1; i++) {
      if (rates[i].high > max) {
         max = rates[i].high;
      }
      if (rates[i].low < min) {
         min = rates[i].low;
      }
   }
   double avgRange = getAvgRanges(enddate, 100);
   if (type == "SH") {
      if (level - min > 2*avgRange) {
         return true;
      }
   } else if (type == "SL") {
      if (max - level > 2*avgRange) {
         return true;
      }
   }
   return false;
}

void GetSRLevel(datetime startdate, datetime enddate, CArrayListClass<SRLevel>* levels) {
   double zigzagBufffer[];
   MqlRates rates[];

   double   zz       =  0;
   int      zzCount  =  0;
   CArrayListClass<RatesPoint> *zzPeaks = new CArrayListClass<RatesPoint>();
//ArrayResize(zzPeaks, InpLookback);

   int cntBuff = CopyBuffer(zigzagHandle, 0, startdate, enddate, zigzagBufffer);
   int cntRates = CopyRates(_Symbol, _Period, startdate, enddate, rates);
   if (cntBuff < 0 || cntRates < 0) {
      int err=GetLastError();
      return;
   }

   for (int i=1; i< ArraySize(zigzagBufffer) && zzCount< InpLookback; i++) {
      zz =  zigzagBufffer[i];
      if (zz!=0 && zz!=EMPTY_VALUE) {
         string stype = "";
         if (i > 0) {
            stype = rates[i].high > rates[i-1].high ? "SH" : rates[i].low < rates[i-1].low ? "SL" : "";
         }
         if (rates[i].time == D'2021.01.11 16:30') {
            string stop = true;
         }
         zzPeaks.add(new RatesPoint(rates[i], stype));
         //zzPeaks[zzCount] = ;
         zzCount++;
      }
   }
   ICompare<RatesPoint*>* comparer = new RatesPointSortByPrice();
   zzPeaks.SortBy(comparer);
   delete comparer;

// Search for groupings and set levels
   int      srCounter   =  0;
   double   price       =  0;
   int      priceCount  =  0;
//static double  levelGap = InpGapPoints*SymbolInfoDouble(Symbol(), SYMBOL_POINT);
   static double  levelGap = getAvgRanges(enddate, 100) * 0.75;

   SRLevel* l = new SRLevel();
   for (int i=zzPeaks.size()-1; i>=0; i--) {
      if (zzPeaks[i].price > 0) {
         l.AddPoint(zzPeaks[i]);
         price += zzPeaks[i].price;
         priceCount++;
      }
      if (i==0 || (l.level - zzPeaks[i-1].price) > levelGap) {
         if (priceCount>=InpSensitivity) {
            //bool levelexist = false;
            //for(int j=0; j<levels.size(); j++) {
            //   if (l.startdate == levels[j].startdate && MathAbs(l.level-levels[j].level) < levelGap) {
            //      levels.remove(j);
            //   }
            //}
            price = price/priceCount;
            levels.add(l);
            l = new SRLevel();
         }
         price       =  0;
         priceCount  =  0;
      }
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//void GetDvpLevel(datetime startdate, datetime enddate, double &levels[]) {
//   double dvpBufffer[];
//   datetime timeBuffer[];
//
//   int cntBuff = CopyBuffer(dvpHandle, 0, startdate, enddate, dvpBufffer);
//   int cntTime = CopyTime(_Symbol, _Period, startdate, enddate, timeBuffer);
//   if (cntBuff < 0 || cntTime < 0) {
//      int err=GetLastError();
//      return;
//   }
//   
//   CArrayList<PocLevel> PocList;
//   for (int i=0 i<ArraySize(dvpBufffer); i++) {
//      PocLevel pl;
//      pl.time = timeBuffer[i];
//      pl.poc = dvpBufffer[i];
//      zz =  zigzagBufffer[i];
//      PocList.add(pl);
//   }
//
//   //static double  levelGap = getAvgRanges(enddate, 100) * 0.25;
//   //double   price       =  0;
//   //int      priceCount  =  0;
//   //for (int i=ArraySize(dvpBufffer)-1; i>=0; i--) {
//   //   if (dvpBufffer[i]> 0) {
//   //      price += dvpBufffer[i];
//   //      priceCount++;
//   //   }
//   //   if (i==0 || (dvpBufffer[i]-dvpBufffer[i-1])> levelGap) {
//   //      if (priceCount>=InpSensitivity) {
//   //         price = price/priceCount;
//   //         ArrayResize(levels, ArraySize(levels)+1, 10);
//   //         levels[ArraySize(levels)-1] = price;
//   //      }
//   //      price       =  0;
//   //      priceCount  =  0;
//   //   }
//   //}
//}
//+------------------------------------------------------------------+
void GetZigZagLevel(datetime startdate, datetime enddate, CArrayListClass<RatesPoint>* levels) {
   double zigzagBufffer[];
   MqlRates rates[];

   int cntBuff = CopyBuffer(zigzagHandle, 0, startdate, enddate, zigzagBufffer);
   int cntRates = CopyRates(_Symbol, _Period, startdate, enddate, rates);
   if (cntBuff < 0 || cntRates < 0) {
      int err=GetLastError();
      return;
   }

   for (int i=0; i<ArraySize(zigzagBufffer); i++) {
      double zz =  zigzagBufffer[i];
      if (zz!=0 && zz!=EMPTY_VALUE) {
         string stype = "";
         if (i > 0) {
            stype = rates[i].high > rates[i-1].high ? "SH" : rates[i].low < rates[i-1].low ? "SL" : "";
         }
         levels.add(new RatesPoint(rates[i], stype));
      }
   }
}