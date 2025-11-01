//+------------------------------------------------------------------+
//|                                                      AutoSnR.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2

#property indicator_label1  "Support"
#property indicator_type1  DRAW_LINE
#property indicator_color1  clrBlue
#property indicator_style1  DRAW_LINE
#property indicator_width1  1

#property indicator_label1  "Resistance"
#property indicator_type1  DRAW_LINE
#property indicator_color1  clrRed
#property indicator_style1  DRAW_LINE
#property indicator_width1  1

#include <MR\Dictionary.mqh>

input int nLevel = 100;
input int swingPeriod = 250;
input int rangesPeriod = 100;
input int swingSize = 5;

double    SupportBuffer[];
double    ResistanceBuffer[];

enum SRType {
   SR_TYPE_SUPPORT,
   SR_TYPE_RESISTANCE
};

class Titik {
 public:
   datetime date;
   double price;
   string type;
   int weight;

   Titik() {
   }

   Titik(const Titik &old) {
      date = old.date;
      price = old.price;
      type = old.type;
      weight = old.weight;
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

SRLine SRList[];
Titik swingHighList[];
Titik swingLowList[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//--- indicator buffers mapping
   SetIndexBuffer(0,SupportBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ResistanceBuffer,INDICATOR_DATA);
//---
   EventSetTimer(5);

   //SRLine res1;
   //res1.Type = SR_TYPE_RESISTANCE;
   //Titik p1;
   //p1.date = D'2022.03.01 23:00:00';
   //p1.price = 1950.26;
   //res1.AddPoint(p1);
   //Titik p2;
   //p2.date = D'2022.03.12 00:30:00';
   //p2.price = 1950.26;
   //res1.AddPoint(p2);
   //ArrayResize(SRList, ArraySize(SRList)+1);
   //SRList[0] = res1;
   return(INIT_SUCCEEDED);
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
//   int avgRangePeriod = 100;
//   int pos=prev_calculated;
//   double avgRange = 0;
//   for(int i=pos; i<rates_total && !IsStopped(); i++) {
//      if (i >= avgRangePeriod-1) {
//         for(int j=i-avgRangePeriod+1; j<i+1; j++) {
//            avgRange = avgRange + (high[j] - low[j]);
//         }
//         avgRange = avgRange / avgRangePeriod;
//      }
//      if (i >= avgRangePeriod-1 && i < ArraySize(open) - 2 && avgRange > 0) {
//         double tempHighs[];
//         ArrayCopy(tempHighs, high, 0, i-2, 5);
//         double tempLows[];
//         ArrayCopy(tempLows, low, 0, i-2, 5);
//         double tempTimes[];
//         ArrayCopy(tempTimes, time, 0, i-2, 5);
//
//         if (isSwingHigh(tempHighs)) {
//            Titik titik;
//            titik.date = tempTimes[2];
//            titik.price = tempHighs[2];
//            ArrayResize(swingHighList, ArraySize(swingHighList)+1);
//            swingHighList[ArraySize(swingHighList)-1] = titik;
//
//            for(int j=0; j<ArraySize(swingHighList)-1; j++) {
//               if (MathAbs(swingHighList[j].price - tempHighs[2]) < avgRange/5) {
//                  SRLine res;
//                  res.Type = SR_TYPE_RESISTANCE;
//                  Titik p1;
//                  p1.date = swingHighList[j].date;
//                  p1.price = swingHighList[j].price;
//                  res.AddPoint(p1);
//                  Titik p2;
//                  p2.date = tempTimes[2];
//                  p2.price = tempHighs[2];
//                  res.AddPoint(p2);
//                  ArrayResize(SRList, ArraySize(SRList)+1);
//                  SRList[ArraySize(SRList)-1] = res;
//
//                  int datediff = time[i] - swingHighList[j].date;
//                  int nBar = datediff / PeriodSeconds();
//                  for(int k=0; k<nBar; k++) {
//                     if (i-k < 0 || i-k > ArraySize(ResistanceBuffer)) {
//                        printf("i-k:%i i:%i k:%i", i-k, i, k);
//                     }
//                     else {
//                        ResistanceBuffer[i-k] = tempHighs[2];
//                     }
//                  }
//               }
//            }
//         } else if (isSwingLow(tempLows)) {
//            Titik titik;
//            titik.date = tempTimes[2];
//            titik.price = tempLows[2];
//            ArrayResize(swingLowList, ArraySize(swingLowList)+1);
//            swingLowList[ArraySize(swingLowList)-1] = titik;
//
//            for(int j=0; j<ArraySize(swingLowList)-1; j++) {
//               if (MathAbs(swingLowList[j].price - tempLows[2]) < avgRange/5) {
//                  SRLine sup;
//                  sup.Type = SR_TYPE_SUPPORT;
//                  Titik p1;
//                  p1.date = swingLowList[j].date;
//                  p1.price = swingLowList[j].price;
//                  sup.AddPoint(p1);
//                  Titik p2;
//                  p2.date = tempTimes[2];
//                  p2.price = tempLows[2];
//                  sup.AddPoint(p2);
//                  ArrayResize(SRList, ArraySize(SRList)+1);
//                  SRList[ArraySize(SRList)-1] = sup;
//               }
//            }
//         }
//      }
//   }
//--- return value of prev_calculated for next call
   return(rates_total);
}
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
//---
   EventKillTimer();

   Dictionary<datetime, Titik> swings;

   MqlRates rates[];
   CopyRates(_Symbol, _Period, 1, swingPeriod, rates);
   //for(int i=ArraySize(rates)-1; i>=rangesPeriod-1; i--) {
   for(int i=0; i<ArraySize(rates); i++) {
      if (i<2*swingSize) {
         continue;
      }
      MqlRates tempRates[];
      ArrayCopy(tempRates, rates, 0, i-2*swingSize, 2*swingSize+1);
      MqlRates tempRates5[];
      ArrayCopy(tempRates, rates, 0, i-2*5, 2*5+1);
      MqlRates tempRates10[];
      ArrayCopy(tempRates, rates, 0, i-2*10, 2*10+1);
      MqlRates tempRates15[];
      ArrayCopy(tempRates, rates, 0, i-2*15, 2*15+1);
      if (isSwingHigh(tempRates15)) {
         // swing high
         Titik t;
         t.date = rates[i-2].time;
         t.price = rates[i-2].high;
         t.type = "SH";
         t.weight = 5;
         if (!swings.ContainsKey(t.date)) {
            swings.Add(t.date, t);
         }
      } 
      else if (isSwingHigh(tempRates10)) {
         // swing high
         Titik t;
         t.date = rates[i-2].time;
         t.price = rates[i-2].high;
         t.type = "SH";
         t.weight = 4;
         if (!swings.ContainsKey(t.date)) {
            swings.Add(t.date, t);
         }
      }
      else if (isSwingHigh(tempRates5)) {
         // swing high
         Titik t;
         t.date = rates[i-2].time;
         t.price = rates[i-2].high;
         t.type = "SH";
         t.weight = 3;
         if (!swings.ContainsKey(t.date)) {
            swings.Add(t.date, t);
         }
      }
      else if (isSwingLow(tempRates15)) {
         // swing low
         Titik t;
         t.date = rates[i-2].time;
         t.price = rates[i-2].low;
         t.type = "SL";
         t.weight = 5;
         if (!swings.ContainsKey(t.date)) {
            swings.Add(t.date, t);
         }
      }
      else if (isSwingLow(tempRates10)) {
         // swing low
         Titik t;
         t.date = rates[i-2].time;
         t.price = rates[i-2].low;
         t.type = "SL";
         t.weight = 4;
         if (!swings.ContainsKey(t.date)) {
            swings.Add(t.date, t);
         }
      }
      else if (isSwingLow(tempRates5)) {
         // swing low
         Titik t;
         t.date = rates[i-2].time;
         t.price = rates[i-2].low;
         t.type = "SL";
         t.weight = 3;
         if (!swings.ContainsKey(t.date)) {
            swings.Add(t.date, t);
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
         t.weight = 1;
         if (!swings.ContainsKey(t.date)) {
            swings.Add(t.date, t);
         }
      } else if (isBullishReject) {
         // swing low
         Titik t;
         t.date = rates[i].time;
         t.price = rates[i].low;
         t.type = "SL";
         t.weight = 1;
         if (!swings.ContainsKey(t.date)) {
            swings.Add(t.date, t);
         }
      }
   }

   swings.Sort();

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
   
//   for (int i=0; i<ArraySize(levelPrice); i++) {
//      string objName = "SR_LEVEL" + IntegerToString(i);
//      
//      ObjectCreate(0, objName, OBJ_HLINE, 0, 0, minPrice+d*i);
//      ObjectSetInteger(0, objName, OBJPROP_COLOR, clrYellowGreen);
//   }

   for(int i=0; i<swings.Length(); i++) {
      double p = swings.GetValueAt(i).price;
      int levelP = getPriceLevel(p, minPrice, d, nLevel);
      if (levelP >= nLevel)
         levelP = nLevel - 1;
      levelPrice[levelP] += swings.GetValueAt(i).weight;
   }

   double maxLevelCount = levelPrice[ArrayMaximum(levelPrice, 0, WHOLE_ARRAY)];
   double avg = 0;
   double cnt = 0;
   double tempLevelPrice[];
   for(int j=0; j<nLevel; j++) {
      if (levelPrice[j] > 0) {
         avg += levelPrice[j];
         cnt += 1;
      }
      if (levelPrice[j] != maxLevelCount) {
         ArrayResize(tempLevelPrice, ArraySize(tempLevelPrice)+1, 5);
         tempLevelPrice[ArraySize(tempLevelPrice)-1] = levelPrice[j];
      }
   }
   avg /= cnt;
   avg = ceil(avg);
   double secondMaxLevelCount = tempLevelPrice[ArrayMaximum(tempLevelPrice, 0, WHOLE_ARRAY)];
   ArrayFree(tempLevelPrice);
   for(int j=0; j<nLevel; j++) {
      if (levelPrice[j] != maxLevelCount && levelPrice[j] != secondMaxLevelCount) {
         ArrayResize(tempLevelPrice, ArraySize(tempLevelPrice)+1, 5);
         tempLevelPrice[ArraySize(tempLevelPrice)-1] = levelPrice[j];
      }
   }
   double thirdMaxLevelCount = tempLevelPrice[ArrayMaximum(tempLevelPrice, 0, WHOLE_ARRAY)];
   
   int strongLevel[];
   for(int j=0; j<nLevel; j++) {
      //if (levelPrice[j] > 0) {
      //if (levelPrice[j] > avg) {
      if (levelPrice[j] == maxLevelCount || levelPrice[j] == secondMaxLevelCount || levelPrice[j] == thirdMaxLevelCount) {
         ArrayResize(strongLevel, ArraySize(strongLevel)+1, 5);
         strongLevel[ArraySize(strongLevel)-1] = j;
      }
   }

   ArrayFree(SRList);

   for(int i=swings.Length()-1; i>0; i--) {
      MqlRates rangesArray[];
      double avgRanges = getAvgRanges(swings.GetValueAt(i).date, rangesPeriod);
      SRLine line;
      line.AddPoint(swings.GetValueAt(i));
      double avgPrice = swings.GetValueAt(i).price;
      for(int j=i-1; j>=0; j--) {
         int l = getPriceLevel(swings.GetValueAt(i).price, minPrice, d, nLevel);
         bool isStrongLevel = false;
         for(int k=0; k<ArraySize(strongLevel); k++) {
            if (strongLevel[k] == l) {
               isStrongLevel = true;
               break;
            }
         }
         if (MathAbs(avgPrice - swings.GetValueAt(j).price) < avgRanges*0.5) {
         //if (isStrongLevel) {
            avgPrice = (avgPrice * ArraySize(line.Points) + swings.GetValueAt(j).price) / (ArraySize(line.Points)+1);
            line.AddPoint(swings.GetValueAt(j));
         }
      }
      if (ArraySize(line.Points) > 1) {
         ArrayResize(SRList, ArraySize(SRList)+1, 10);
         SRList[ArraySize(SRList)-1] = line;
      }
   }

   ObjectsDeleteAll(0, "SR_");
   if (ArraySize(SRList) > 0) {
      for(int i=0; i<ArraySize(SRList); i++) {
         int n = ArraySize(SRList[i].Points);
         datetime d1 = SRList[i].Points[0].date;
         datetime d2 = SRList[i].Points[n-1].date;
         double p = 0;
         for(int j=0; j<ArraySize(SRList[i].Points); j++) {
            p += SRList[i].Points[j].price;
         }
         p /= ArraySize(SRList[i].Points);
         p = SRList[i].Points[0].price;
         if (ArraySize(SRList[i].Points) > 2) {
            int l = getPriceLevel(p, minPrice, d, nLevel);
            bool isStrongLevel = false;
            for(int j=0; j<ArraySize(strongLevel); j++) {
               if (strongLevel[j] == l) {
                  isStrongLevel = true;
                  break;
               }
            }
            if (isStrongLevel) {
               string objName = "SR_" + IntegerToString(i);
               ObjectCreate(0, objName, OBJ_TREND, 0, d1, p, d2, p);
               if (ArraySize(SRList[i].Points) > 5) {
                  ObjectSetInteger(0, objName, OBJPROP_COLOR, clrRed);
               } else if (ArraySize(SRList[i].Points) == 4) {
                  ObjectSetInteger(0, objName, OBJPROP_COLOR, clrYellow);
               } else if (ArraySize(SRList[i].Points) == 3) {
                  ObjectSetInteger(0, objName, OBJPROP_COLOR, clrGreen);
               } else if (ArraySize(SRList[i].Points) == 2) {
                  ObjectSetInteger(0, objName, OBJPROP_COLOR, clrBlue);
               }
            }
         }
      }
   }
   ChartRedraw();

   EventSetTimer(5);
}
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam) {
//---

}
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   EventKillTimer();
   ObjectsDeleteAll(0, "SR_");
   ChartRedraw();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isSwingHigh(double &highs[]) {
   if (ArraySize(highs) == 5) {
      if (highs[2] > highs[0] && highs[2] > highs[1] && highs[2] > highs[3] && highs[2] > highs[4]) {
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
      if (lows[2] < lows[0] && lows[2] < lows[1] && lows[2] < lows[3] && lows[2] < lows[4]) {
         return true;
      }
   }
   return false;
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
double calculateAvgRanges(MqlRates &rates[]) {
   double avgRanges = 0;
   for(int i=0; i<ArraySize(rates); i++) {
      avgRanges = avgRanges + rates[i].high - rates[i].low;
   }
   avgRanges = avgRanges / ArraySize(rates);
   return avgRanges;
}
//+------------------------------------------------------------------+
double getAvgRanges(datetime starttime, int period) {
   MqlRates rates[];
   CopyRates(_Symbol, PERIOD_CURRENT, starttime, period, rates);
   return calculateAvgRanges(rates);
}
//+------------------------------------------------------------------+
int getPriceLevel(double price,double min,double d,int nrow) {
   return MathMin(MathFloor((price-min)/d)+1, nrow);
}
//+------------------------------------------------------------------+
