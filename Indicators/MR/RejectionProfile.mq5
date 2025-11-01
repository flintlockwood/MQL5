//+------------------------------------------------------------------+
//|                                             RejectionProfile.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   3

#property indicator_label1  "BullishRejection"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

#property indicator_label2  "BearishRejection"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrYellow
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

#property indicator_label3  "DynamicSupportResistance"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrYellow
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1

#include <MR\Dictionary.mqh>

double    BullishRejectionBuffer[];
double    BearishRejectionBuffer[];
double    DynamicSRBuffer[];

input int period = 200;
input int nLevel = 100;
input bool showRejection = false;
input bool showProfile = true;
input bool showDynamicSR = false;

string objectnameprefix = "SR_";

enum SRType {
   SR_TYPE_SUPPORT,
   SR_TYPE_RESISTANCE
};

class Titik {
 public:
   datetime date;
   double price;
   string type;
   int flag;

   Titik() {
   }

   Titik(const Titik &old) {
      date = old.date;
      price = old.price;
      type = old.type;
      flag = old.type;
   }
};

class SRLine {
 public:
   Titik Points[];
   SRType Type;

   void AddPoint(Titik &p) {
      ArrayResize(Points, ArraySize(Points)+1, 5);
      Points[ArraySize(Points)-1] = p;
   }
};

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//--- indicator buffers mapping
   EventSetTimer(5);
   SetIndexBuffer(0,BullishRejectionBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,BearishRejectionBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,DynamicSRBuffer,INDICATOR_DATA);

   PlotIndexSetInteger(0,PLOT_ARROW,226);
   PlotIndexSetInteger(1,PLOT_ARROW,225);
   PlotIndexSetInteger(0,PLOT_ARROW_SHIFT,-10);
   PlotIndexSetInteger(1,PLOT_ARROW_SHIFT,10);

   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   ObjectsDeleteAll(0,objectnameprefix);
   ObjectsDeleteAll(0,"RP");
   ChartRedraw();
   EventKillTimer();
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
   for(int i=prev_calculated; i<rates_total-1; i++) {
      if (showDynamicSR) {
         if (i >= period) {
            MqlRates rates[];
            for(int j=period; j>=0; j--) {
               MqlRates rate;
               rate.open = open[i-j];
               rate.high = high[i-j];
               rate.low = low[i-j];
               rate.close = close[i-j];
               rate.time = time[i-j];
               ArrayResize(rates, ArraySize(rates)+1, 5);
               rates[ArraySize(rates)-1] = rate;
            }
            double rp = calcRejectionProfile(rates);
            if (rp > 0) {
               DynamicSRBuffer[i] = rp;
            }
         }
      }

      if (showRejection) {
         double rangeLength = high[i] - low[i];
         double upperWickLength = high[i] - (open[i] > close[i] ? open[i] : close[i]);
         double lowerWickLength = (open[i] < close[i] ? open[i] : close[i]) - low[i];

         if (rangeLength > 0) {
            if (upperWickLength / rangeLength > 0.5) {
               BearishRejectionBuffer[i] = high[i];
            } else if (lowerWickLength / rangeLength > 0.5) {
               BullishRejectionBuffer[i] = low[i];
            }
         }

         if (i > 5) {
            double tempHigh[];
            ArrayCopy(tempHigh, high, 0, i-5+1, 5);
            if (isSwingHigh(tempHigh)) {
               BearishRejectionBuffer[i-2] = high[i-2];
            }
            double tempLow[];
            ArrayCopy(tempLow, low, 0, i-5+1, 5);
            if (isSwingLow(tempLow)) {
               BullishRejectionBuffer[i-2] = low[i-2];
            }
         }
      }
   }
//--- return value of prev_calculated for next call
   return(rates_total);
}
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
//---
   EventKillTimer();

   int rangesPeriod = 100;

   Dictionary<datetime, Titik> dic;

   MqlRates rates[];
   CopyRates(_Symbol, _Period, 0, rangesPeriod+period, rates);
   //for(int i=ArraySize(rates)-1; i>=rangesPeriod-1; i--) {
   for(int i=rangesPeriod-1; i<ArraySize(rates); i++) {
      MqlRates tempRates[];
      ArrayCopy(tempRates, rates, 0, i-5+1, 5);
      if (isSwingHigh(tempRates)) {
         // swing high
         Titik t;
         t.date = rates[i-2].time;
         t.price = rates[i-2].high;
         t.type = "SH";
         if (!dic.ContainsKey(t.date)) {
            dic.Add(t.date, t);
         }
      } else if (isSwingLow(tempRates)) {
         // swing low
         Titik t;
         t.date = rates[i-2].time;
         t.price = rates[i-2].low;
         t.type = "SL";
         if (!dic.ContainsKey(t.date)) {
            dic.Add(t.date, t);
         }
      }

      double rangeLength = rates[i].high - rates[i].low;
      double upperWickLength = rates[i].high - (rates[i].open > rates[i].close ? rates[i].open : rates[i].close);
      double lowerWickLength = (rates[i].open < rates[i].close ? rates[i].open : rates[i].close) - rates[i].low;
      bool isBearishReject = rangeLength == 0 ? false : upperWickLength / rangeLength > 0.5;
      bool isBullishReject = rangeLength == 0 ? false : lowerWickLength / rangeLength > 0.5;

      if (isBearishReject) {
         // swing high
         Titik t;
         t.date = rates[i].time;
         t.price = rates[i].high;
         t.type = "SH";
         if (!dic.ContainsKey(t.date)) {
            dic.Add(t.date, t);
         }
      } else if (isBullishReject) {
         // swing low
         Titik t;
         t.date = rates[i].time;
         t.price = rates[i].low;
         t.type = "SL";
         if (!dic.ContainsKey(t.date)) {
            dic.Add(t.date, t);
         }
      }
   }

   dic.Sort();

   double levelPrice[];
   ArrayResize(levelPrice, nLevel);
   ArrayInitialize(levelPrice, 0);

   double minPrice = rates[0].low;
   double maxPrice = rates[0].high;
   for(int i=1; i<ArraySize(rates); i++) {
      if (rates[i].low < minPrice) {
         minPrice = rates[i].low;
      }
      if (rates[i].high > maxPrice) {
         maxPrice = rates[i].high;
      }
   }
   double d = (maxPrice - minPrice) / nLevel;

   for(int i=0; i<dic.Length(); i++) {
      double p = dic.GetValueAt(i).price;
      int levelP = getPriceLevel(p, minPrice, d, nLevel);
      if (levelP >= nLevel)
         levelP = nLevel - 1;
      levelPrice[levelP] += 1;
   }

   if (showProfile) {
      ObjectsDeleteAll(0, "RP_", 0, OBJ_RECTANGLE);
      double maxLevelCount = levelPrice[ArrayMaximum(levelPrice, 0, WHOLE_ARRAY)];
      int histSize = 50;
      datetime t0 = (TimeCurrent()+4*PeriodSeconds()) - histSize*PeriodSeconds();
      double avg = 0;
      double cnt = 0;
      for(int j=0; j<nLevel; j++) {
         if (levelPrice[j] > 0) {
            avg += levelPrice[j];
            cnt += 1;
         }
      }
      avg /= cnt;
      avg = ceil(avg);
      for(int j=0; j<nLevel; j++) {
         //if (levelPrice[j] > 0) {
         if (levelPrice[j] > avg) {
            datetime t1 = t0 + ((histSize - (levelPrice[j] / maxLevelCount * histSize)) * PeriodSeconds());
            //double p1 = minPriceNormalize + (j*inpLevelInterval*_Point);
            double p1 = minPrice + j*d;
            datetime t2 = (TimeCurrent()+4*PeriodSeconds()) + (3*PeriodSeconds());
            //double p2 = p1 + (inpLevelInterval*_Point);
            double p2 = p1 + d;

            ObjectCreate(0, "RP_" + IntegerToString(j), OBJ_RECTANGLE, 0, t1, p1, t2, p2);
            ObjectCreate(0, "RP_TXT_" + IntegerToString(j), OBJ_TEXT, 0, t2+PeriodSeconds(), p1, t2+PeriodSeconds(), p2);
            ObjectSetString(0, "RP_TXT_" + IntegerToString(j), OBJPROP_TEXT, IntegerToString(levelPrice[j]));
         }
      }
   }

   EventSetTimer(5);
}
//+------------------------------------------------------------------+
bool isSwingHigh(MqlRates &rates[]) {
   if (ArraySize(rates) == 5) {
      if (rates[2].high > rates[0].high && rates[2].high > rates[1].high
            && rates[2].high > rates[3].high && rates[2].high > rates[4].high) {
         return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isSwingHigh(double &highs[]) {
   if (ArraySize(highs) == 5) {
      if (highs[2] > highs[0] && highs[2] > highs[1]
            && highs[2] > highs[3] && highs[2] > highs[4]) {
         return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isSwingLow(MqlRates &rates[]) {
   if (ArraySize(rates) == 5) {
      if (rates[2].low < rates[0].low && rates[2].low < rates[1].low
            && rates[2].low < rates[3].low && rates[2].low < rates[4].low) {
         return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isSwingLow(double &lows[]) {
   if (ArraySize(lows) == 5) {
      if (lows[2] < lows[0] && lows[2] < lows[1]
            && lows[2] < lows[3] && lows[2] < lows[4]) {
         return true;
      }
   }
   return false;
}
//+------------------------------------------------------------------+
double calculateAvgRanges(MqlRates &rates[]) {
   double avgRanges = 0;
   for(int i=0; i<ArraySize(rates); i++) {
      avgRanges = avgRanges + rates[i].high - rates[i].low;
   }
   avgRanges = avgRanges / ArraySize(rates);
   return avgRanges;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int getPriceLevel(double price,double min,double d,int nrow) {
   return MathMin(MathFloor((price-min)/d)+1, nrow);
}
//+------------------------------------------------------------------+
double calcRejectionProfile(MqlRates &rates[]) {
   Titik swings[];

   for(int i=4; i<ArraySize(rates); i++) {
      // find swing high and swing low
      MqlRates tempRates[];
      ArrayCopy(tempRates, rates, 0, i-5+1, 5);
      if (isSwingHigh(tempRates)) {
         // swing high
         Titik t;
         t.date = rates[i-2].time;
         t.price = rates[i-2].high;
         t.type = "SH";
         ArrayResize(swings, ArraySize(swings)+1, 10);
         swings[ArraySize(swings)-1] = t;
      } else if (isSwingLow(tempRates)) {
         // swing low
         Titik t;
         t.date = rates[i-2].time;
         t.price = rates[i-2].low;
         t.type = "SL";
         ArrayResize(swings, ArraySize(swings)+1, 10);
         swings[ArraySize(swings)-1] = t;
      }

      // find rejection candle
      double rangeLength = rates[i].high - rates[i].low;
      double upperWickLength = rates[i].high - (rates[i].open > rates[i].close ? rates[i].open : rates[i].close);
      double lowerWickLength = (rates[i].open < rates[i].close ? rates[i].open : rates[i].close) - rates[i].low;
      bool isBearishReject = rangeLength == 0 ? false : upperWickLength / rangeLength > 0.5;
      bool isBullishReject = rangeLength == 0 ? false : lowerWickLength / rangeLength > 0.5;

      if (isBearishReject) {
         // swing high
         Titik t;
         t.date = rates[i].time;
         t.price = rates[i].high;
         t.type = "BearishReject";
         ArrayResize(swings, ArraySize(swings)+1, 10);
         swings[ArraySize(swings)-1] = t;
      } else if (isBullishReject) {
         // swing low
         Titik t;
         t.date = rates[i].time;
         t.price = rates[i].low;
         t.type = "BullishReject";
         ArrayResize(swings, ArraySize(swings)+1, 10);
         swings[ArraySize(swings)-1] = t;
      }
   }

   int nLevel = 100;
   double levelPrice[];
   ArrayResize(levelPrice, nLevel);
   ArrayInitialize(levelPrice, 0);

   double minPrice = rates[0].low;
   double maxPrice = rates[0].high;
   for(int i=1; i<ArraySize(rates); i++) {
      if (rates[i].low < minPrice) {
         minPrice = rates[i].low;
      }
      if (rates[i].high > maxPrice) {
         maxPrice = rates[i].high;
      }
   }
   double d = (maxPrice - minPrice) / nLevel;

   for(int i=0; i<ArraySize(swings); i++) {
      double p = swings[i].price;
      int levelP = getPriceLevel(p, minPrice, d, nLevel);
      if (levelP >= nLevel)
         levelP = nLevel - 1;
      levelPrice[levelP] += 1;
   }

   int maxIndex = 0;
   int maxCount = levelPrice[0];
   for(int i=1; i<ArraySize(levelPrice); i++) {
      if (levelPrice[i] > maxCount) {
         maxIndex = i;
         maxCount = levelPrice[i];
      }
   }
   double price = minPrice + d*maxIndex + d/2;

   for(int i=ArraySize(swings)-1; i>=0; i--) {
      double p1 = minPrice + d*maxIndex;
      double p2 = minPrice + d*maxIndex + d;
      if (swings[i].price >= p1 && swings[i].price < p2) {
         price = swings[i].price;
         break;
      }
   }

   if (price == 0) {
      Print("dynamic SR is zero");
   }

   return price;
}
//+------------------------------------------------------------------+
