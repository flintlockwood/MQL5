//+------------------------------------------------------------------+
//|                                                 SnD_Detector.mq5 |
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
#property indicator_label1  "BullishPole"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot BearishPole
#property indicator_label2  "BearishPole"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrYellow
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

#include <Math\Stat\Math.mqh>

//--- indicator buffers
double         BullishPoleBuffer[];
double         BearishPoleBuffer[];

//--- input parameters
input int      rangePeriod = 100;
input bool     showPole    = true;
input bool     showRBR     = true;
input bool     showDBD     = true;
input bool     showRBD     = true;
input bool     showDBR     = true;

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
   }

   RatesPoint(MqlRates &pRates, string pType) {
      rates = pRates;
      date = pRates.time;
      price = pRates.close;
      type = pType;
   }
   
   ~RatesPoint() {
      //delete rates;
   }
};

class SnDZone {
 public:
   datetime          startdate;
   datetime          enddate;
   double            maxzone;
   double            minzone;
   double            high;
   double            low;
   string            type; // supply / demand
   string            pattern;

   SnDZone() {
   }

   SnDZone(const SnDZone &old) {
      startdate = old.startdate;
      enddate = old.enddate;
      maxzone = old.maxzone;
      minzone = old.minzone;
      high = old.high;
      low = old.low;
      type = old.type;
      pattern = old.pattern;
   }

   SnDZone(datetime pStartdate, datetime pEnddate, double pMaxZone, double pMinZone, double pHigh, double pLow, string pType, string pPattern) {
      startdate = pStartdate;
      enddate = pEnddate;
      maxzone = pMaxZone;
      minzone = pMinZone;
      high = pHigh;
      low = pLow;
      type = pType;
      pattern = pPattern;
   }
   
   ~SnDZone() {
   }
};

// global variable
SnDZone* ZoneList[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//--- indicator buffers mapping
   SetIndexBuffer(0,BullishPoleBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,BearishPoleBuffer,INDICATOR_DATA);

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
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int  reason) {
   int cntdeleted = ObjectsDeleteAll(0, "SnD_");
   if (cntdeleted != ArraySize(ZoneList)) {
      int err = GetLastError();
      printf("ERROR while deleting objects:%i", err);
   }
   for(int i=0; i<ArraySize(ZoneList); i++) {
      delete ZoneList[i];
   }
   ArrayFree(ZoneList);
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
   RatesPoint *prevpole;
   if(prev_calculated<rangePeriod) {
      ArrayInitialize(BullishPoleBuffer,EMPTY_VALUE);
      ArrayInitialize(BearishPoleBuffer,EMPTY_VALUE);
   }

   for(int i=prev_calculated; i<rates_total-1; i++) {
      if (i-(rangePeriod-1) < 0) {
         continue;
      }
      double arrHigh[];
      ArrayCopy(arrHigh, high, 0, i-rangePeriod+1, rangePeriod);
      double arrLow[];
      ArrayCopy(arrLow, low, 0, i-rangePeriod+1, rangePeriod);

      double ranges[];
      ArrayResize(ranges, rangePeriod);
      for (int j=0; j<rangePeriod; j++) {
         ranges[j] = arrHigh[j] - arrLow[j];
      }
      double rangeAvg = MathMean(ranges);
      double rangeSd = MathStandardDeviation(ranges);

      double ratio = 0;
      if (high[i]-low[i] != 0) {
         ratio = MathAbs(close[i]-open[i]) / (high[i]-low[i]);
      }

      RatesPoint *pole;
      ZeroMemory(pole);
      if (close[i]>open[i] && (high[i]-low[i])>=(rangeAvg+rangeSd) && ratio>=0.618) {
         if (showPole) {
            BullishPoleBuffer[i] = low[i];
         }
         MqlRates tempRates[];
         CopyRates(_Symbol, PERIOD_CURRENT, time[i], 1, tempRates);
         pole = new RatesPoint(tempRates[0], "rally");
      }

      if (close[i]<open[i] && (high[i]-low[i])>=(rangeAvg+rangeSd) && ratio>=0.618) {
         if (showPole) {
            BearishPoleBuffer[i] = high[i];
         }
         MqlRates tempRates[];
         CopyRates(_Symbol, PERIOD_CURRENT, time[i], 1, tempRates);
         pole = new RatesPoint(tempRates[0], "drop");
      }

      SnDZone* snd;
      ZeroMemory(snd);
      if (pole != NULL) {
         if (prevpole != NULL) {
            string poletype = pole.type;
            string prevpoletype = prevpole.type;
            if (poletype == "drop" && prevpoletype == "drop") {
               // check DBD
               checkDBD(prevpole, pole, snd);
            } else if (poletype == "rally" && prevpoletype == "rally") {
               // check RBR
               checkRBR(prevpole, pole, snd);
            } else if (poletype == "drop" && prevpoletype == "rally") {
               // check RBD
               checkRBD(prevpole, pole, snd);
            } else if (poletype == "rally" && prevpoletype == "drop") {
               // check DBR
               checkDBR(prevpole, pole, snd);
            }
            
            if (snd != NULL) {
               if (snd.type != NULL) {
                  ArrayResize(ZoneList, ArraySize(ZoneList)+1, 5);
                  ZoneList[ArraySize(ZoneList)-1] = new SnDZone(snd);
                  delete snd;
               }
            }
         }
         delete prevpole;
         prevpole = new RatesPoint(pole.rates, pole.type);
         delete pole;
      }
   }
   delete prevpole;
   
   ZoneRedraw();
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
bool isPole(MqlRates &rates[], int inpPeriod, RatesPoint &snd[]) {
   for(int i=0; i<ArraySize(rates)-1; i++) {
      if (i-inpPeriod < 0) {
         continue;
      }
      MqlRates arr[];
      ArrayCopy(arr, rates, 0, i-inpPeriod, inpPeriod);

      double ranges[];
      ArrayResize(ranges, inpPeriod);
      for (int j=0; j<inpPeriod; j++) {
         ranges[j] = arr[j].high - arr[j].low;
      }
      double rangeAvg = MathMean(ranges);
      double rangeSd = MathStandardDeviation(ranges);

      double ratio = 0;
      if (rates[i].high-rates[i].low != 0) {
         ratio = MathAbs(rates[i].close-rates[i].open) / (rates[i].high-rates[i].low);
      }

      if (rates[i].close>rates[i].open && (rates[i].high-rates[i].low)>=(rangeAvg+rangeSd) && ratio>=0.618) {
         RatesPoint *rp;
         rp = new RatesPoint(rates[i], "demand");
         ArrayResize(snd, ArraySize(snd)+1, 5);
         snd[ArraySize(snd)-1] = rp;
      }

      if (rates[i].close<rates[i].open && (rates[i].high-rates[i].low)>=(rangeAvg+rangeSd) && ratio>=0.618) {
         RatesPoint *rp;
         rp = new RatesPoint(rates[i], "supply");
         ArrayResize(snd, ArraySize(snd)+1, 5);
         snd[ArraySize(snd)-1] = rp;
      }
   }
   return false;
}
//+------------------------------------------------------------------+
void checkDBD(RatesPoint &drop1, RatesPoint &drop2, SnDZone* &sndZone) {
   MqlRates tempRates[];
   CopyRates(_Symbol, PERIOD_CURRENT, drop1.rates.time, drop2.rates.time, tempRates);
   if (ArraySize(tempRates) > 2 && ArraySize(tempRates) <= 6) {
      if (drop2.rates.high < drop1.rates.high-(drop1.rates.high-drop1.rates.low)*0.382) {
         bool hasretrace = false;
         bool isavgrange = true;
         double avgRange = getAvgRanges(drop1.rates.time, 100);
         for (int j=1; j<ArraySize(tempRates)-1; j++) {
            if (tempRates[j].open < tempRates[j].close) {
               hasretrace = true;
            }
            if (tempRates[j].high - tempRates[j].low > avgRange) {
               isavgrange = false;
            }
         }
         if (hasretrace && !isavgrange) {
            datetime startdate = drop1.date;
            datetime enddate = drop2.date;
            double minprice = 999999;
            double maxprice = 0;
            string type = "supply";
            for (int j=1; j<ArraySize(tempRates)-1; j++) {
               if (tempRates[j].high > maxprice) {
                  maxprice = tempRates[j].high;
               }
               if (tempRates[j].low < minprice) {
                  minprice = tempRates[j].low;
               }
            }
            double high = drop1.rates.high;
            double low = drop2.rates.low;
            string pattern = "DBD";
            SnDZone *snd = new SnDZone(startdate, enddate, maxprice, minprice, high, low, type, pattern);
            sndZone = snd;
         }
      }
   }
}
//+------------------------------------------------------------------+
void checkRBR(RatesPoint &rally1, RatesPoint &rally2, SnDZone* &sndZone) {
   MqlRates tempRates[];
   CopyRates(_Symbol, PERIOD_CURRENT, rally1.rates.time, rally2.rates.time, tempRates);
   if (ArraySize(tempRates) > 2 && ArraySize(tempRates) <= 6) {
      if (rally2.rates.low > rally1.rates.low+(rally1.rates.high-rally1.rates.low)*0.382) {
         bool hasretrace = false;
         for (int j=1; j<ArraySize(tempRates)-1; j++) {
            if (tempRates[j].open > tempRates[j].close) {
               hasretrace = true;
            }
         }
         if (hasretrace) {
            datetime startdate = rally1.date; 
            datetime enddate = rally2.date;
            double minprice = 999999;
            double maxprice = 0;
            string type = "demand";
            for (int j=1; j<ArraySize(tempRates)-1; j++) {
               if (tempRates[j].high > maxprice) {
                  maxprice = tempRates[j].high;
               }
               if (tempRates[j].low < minprice) {
                  minprice = tempRates[j].low;
               }
            }
            double high = rally2.rates.high;
            double low = rally1.rates.low;
            string pattern = "RBR";
            SnDZone *snd = new SnDZone(startdate, enddate, maxprice, minprice, high, low, type, pattern);
            sndZone = snd;
         }
      }
   }
}

void checkDBR(RatesPoint &drop, RatesPoint &rally, SnDZone* &sndZone) {
   MqlRates tempRates[];
   CopyRates(_Symbol, PERIOD_CURRENT, drop.rates.time, rally.rates.time, tempRates);
   if (ArraySize(tempRates) > 2 && ArraySize(tempRates) <= 6) {
      if (rally.rates.close > drop.rates.high) {
         datetime startdate = drop.date; 
         datetime enddate = rally.date;
         double minprice = 999999;
         double maxprice = 0;
         string type = "demand";
         for (int j=1; j<ArraySize(tempRates)-1; j++) {
            if (tempRates[j].high > maxprice) {
               maxprice = tempRates[j].high;
            }
            if (tempRates[j].low < minprice) {
               minprice = tempRates[j].low;
            }
         }
         double high = drop.rates.high > rally.rates.high ? drop.rates.high : rally.rates.high;
         double low = drop.rates.low < rally.rates.low ? drop.rates.low : rally.rates.low;
         string pattern = "DBR";
         SnDZone *snd = new SnDZone(startdate, enddate, maxprice, minprice, high, low, type, pattern);
         sndZone = snd;
      }
   }
}

void checkRBD(RatesPoint &rally, RatesPoint &drop, SnDZone* &sndZone) {
   MqlRates tempRates[];
   CopyRates(_Symbol, PERIOD_CURRENT, rally.rates.time, drop.rates.time, tempRates);
   if (ArraySize(tempRates) > 2 && ArraySize(tempRates) <= 6) {
      if (drop.rates.close < rally.rates.low) {
         datetime startdate = rally.date; 
         datetime enddate = drop.date;
         double minprice = 999999;
         double maxprice = 0;
         string type = "supply";
         for (int j=1; j<ArraySize(tempRates)-1; j++) {
            if (tempRates[j].high > maxprice) {
               maxprice = tempRates[j].high;
            }
            if (tempRates[j].low < minprice) {
               minprice = tempRates[j].low;
            }
         }
         double high = drop.rates.high > rally.rates.high ? drop.rates.high : rally.rates.high;
         double low = drop.rates.low < rally.rates.low ? drop.rates.low : rally.rates.low;
         string pattern = "RBD";
         SnDZone *snd = new SnDZone(startdate, enddate, maxprice, minprice, high, low, type, pattern);
         sndZone = snd;
      }
   }
}

void ZoneRedraw() {
   ObjectsDeleteAll(0, "SnD_");
   if (ArraySize(ZoneList) > 0) {
      for(int i=0; i<ArraySize(ZoneList); i++) {
         datetime d1 = ZoneList[i].startdate - PeriodSeconds();
         double p1 = ZoneList[i].low - 50*_Point;
         datetime d2 = ZoneList[i].enddate + PeriodSeconds();
         double p2 = ZoneList[i].high + 50*_Point;
         
         if (ZoneList[i].type != NULL) {
            bool show = false;
            if (ZoneList[i].pattern == "RBR" && showRBR)
               show = true;
            else if (ZoneList[i].pattern == "DBD" && showDBD)
               show = true;
            else if (ZoneList[i].pattern == "RBD" && showRBD)
               show = true;
            else if (ZoneList[i].pattern == "DBR" && showDBR)
               show = true;   
            
            if (show) {
               string objName = "SnD_" + ZoneList[i].pattern + "_" + IntegerToString(i);
               ObjectCreate(0, objName, OBJ_RECTANGLE, 0, d1, p1, d2, p2);
            }
         }
      }
   }
   ChartRedraw();
}

double getCurrentAvgRanges(int period) {
   MqlRates rates[];
   CopyRates(_Symbol, PERIOD_CURRENT, 0, period, rates);
   double avgRanges = 0;
   for(int i=0; i<period; i++) {
      avgRanges += rates[i].high - rates[i].low;
   }
   return avgRanges /= period;
}

double getAvgRanges(datetime startTime, int period) {
   MqlRates rates[];
   CopyRates(_Symbol, PERIOD_CURRENT, startTime, period, rates);
   double avgRanges = 0;
   for(int i=0; i<period; i++) {
      avgRanges += rates[i].high - rates[i].low;
   }
   return avgRanges /= period;
}