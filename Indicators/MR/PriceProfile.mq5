//+------------------------------------------------------------------+
//|                                                 PriceProfile.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window

#include <Math\Stat\Math.mqh>
#include <MR\CIsNewBar.mqh>

input int           inpPeriod        = 200;
input int           inpNLevel        = 100;
input double        inpLevelInterval = 10; // distance between level (in points)

CIsNewBar isNewBarCurrent;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//--- indicator buffers mapping
   EventSetTimer(5);
   isNewBarCurrent.SetPeriod(PERIOD_CURRENT);
//---
   return(INIT_SUCCEEDED);
}

int OnDeinit(const int reason) {
   ObjectsDeleteAll(0, "PP_", 0, OBJ_RECTANGLE);
   return (reason);
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

//--- return value of prev_calculated for next call
   return(rates_total);
}
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
//---
   EventKillTimer();
   MqlRates rates[];
   double lows[];
   double highs[];
   int nrates = CopyRates(_Symbol, PERIOD_CURRENT, 0, inpPeriod, rates);
   int nlows = CopyLow(_Symbol, PERIOD_CURRENT, 0, inpPeriod, lows);
   int nhighs = CopyHigh(_Symbol, PERIOD_CURRENT, 0, inpPeriod, highs);
   if (nrates != inpPeriod || nlows != inpPeriod || nhighs != inpPeriod) {
      printf("error getting price data");
      return;
   }

   double minPrice = NormalizeDouble(lows[ArrayMinimum(lows, 0, WHOLE_ARRAY)], _Digits);
   double maxPrice = NormalizeDouble(highs[ArrayMaximum(highs, 0, WHOLE_ARRAY)], _Digits);
   double minPriceNormalize = NormalizeDouble(minPrice, _Digits-1);
   double maxPriceNormalize = NormalizeDouble(maxPrice, _Digits-1) + 10*_Point;
   //double d = ceil((maxPriceNormalize - minPriceNormalize) / (inpLevelInterval*_Point));
   double d = (maxPrice - minPrice) / inpNLevel;

   double levelPrice[];
   ArrayResize(levelPrice, inpNLevel);
   ArrayInitialize(levelPrice, 0);
   for(int i=0; i<nrates && !IsStopped(); i++) {
      if (i > 19) {
         MqlRates arr20[];
         ArrayCopy(arr20, rates, 0, i-20, 20);
         
         MqlRates rates2[];
         ArrayCopy(rates2, arr20, 0, ArraySize(arr20)-2, 2);
         
         MqlRates rates3[];
         ArrayCopy(rates3, arr20, 0, ArraySize(arr20)-3, 3);
         
         MqlRates rates5[];
         ArrayCopy(rates5, arr20, 0, ArraySize(arr20)-5, 5);
         
         MqlRates rates7[];
         ArrayCopy(rates7, arr20, 0, ArraySize(arr20)-7, 7);
         
         double avgRanges;
         for(int j=0; j<20; j++) {
            avgRanges += arr20[j].high - arr20[j].low;
         }
         avgRanges /= 20;
         int res = checkRejection3(rates3);
         //if (res != 0) {
         //   if (res == 1) {
         //      double p = rates3[1].low;
         //      int levelP = getPriceLevel(p, minPrice, d, inpNLevel);
         //      if (levelP >= inpNLevel)
         //         levelP = inpNLevel - 1;
         //      levelPrice[levelP] += 1;
         //   }
         //   else if (res == -1) {
         //      double p = rates3[1].high;
         //      int levelP = getPriceLevel(p, minPrice, d, inpNLevel);
         //      if (levelP >= inpNLevel)
         //         levelP = inpNLevel - 1;
         //      levelPrice[levelP] += 1;
         //   }
         //}
         
         res = checkRejection5(rates5);
         if (res != 0) {
            if (res == 1) {
               double p = arr20[19].open;
               int levelP = getPriceLevel(p, minPrice, d, inpNLevel);
               if (levelP >= inpNLevel)
                  levelP = inpNLevel - 1;
               levelPrice[levelP] += 1;
            }
            else if (res == -1) {
               double p = arr20[19].close;
               int levelP = getPriceLevel(p, minPrice, d, inpNLevel);
               if (levelP >= inpNLevel)
                  levelP = inpNLevel - 1;
               levelPrice[levelP] += 1;
            }
         }
         
         res = checkRejection7(rates7);
         if (res != 0) {
            if (res == 1) {
               double p = rates7[3].low;
               int levelP = getPriceLevel(p, minPrice, d, inpNLevel);
               if (levelP >= inpNLevel)
                  levelP = inpNLevel - 1;
               levelPrice[levelP] += 1;
            }
            else if (res == -1) {
               double p = rates7[3].high;
               int levelP = getPriceLevel(p, minPrice, d, inpNLevel);
               if (levelP >= inpNLevel)
                  levelP = inpNLevel - 1;
               levelPrice[levelP] += 1;
            }
         }
         
         res = checkSupplyDemand();
         if (res != 0) {
            if (res == 1) {
               double p = rates7[3].low;
               int levelP = getPriceLevel(p, minPrice, d, inpNLevel);
               if (levelP >= inpNLevel)
                  levelP = inpNLevel - 1;
               levelPrice[levelP] += 1;
            }
            else if (res == -1) {
               double p = rates7[3].high;
               int levelP = getPriceLevel(p, minPrice, d, inpNLevel);
               if (levelP >= inpNLevel)
                  levelP = inpNLevel - 1;
               levelPrice[levelP] += 1;
            }
         }
         
//         res = checkEnGulfing(rates2);
//         if (res != 0) {
//            if (res == 1) {
//               double p = MathMin(rates2[0].low, rates2[1].low);
//               int levelP = getPriceLevel(p, minPrice, d, inpNLevel);
//               levelPrice[levelP] += 5;
//            }
//            else if (res == -1) {
//               double p = MathMax(rates2[0].high, rates2[1].high);
//               int levelP = getPriceLevel(p, minPrice, d, inpNLevel);
//               levelPrice[levelP] += 5;
//            }
//         }
//         
//         res = checkMarubozu(arr20[19]);
//         if (res != 0) {
//            if (res == 1) {
//               double p = arr20[19].low;
//               int levelP = getPriceLevel(p, minPrice, d, inpNLevel);
//               levelPrice[levelP] += 5;
//            }
//            else if (res == -1) {
//               double p = arr20[19].high;
//               int levelP = getPriceLevel(p, minPrice, d, inpNLevel);
//               levelPrice[levelP] += 5;
//            }
//         }
//         
//         res = checkHarami(rates2);
//         if (res != 0) {
//            if (res == 1) {
//               double p = MathMin(rates2[0].low, rates2[1].low);
//               int levelP = getPriceLevel(p, minPrice, d, inpNLevel);
//               levelPrice[levelP] += 5;
//            }
//            else if (res == -1) {
//               double p = MathMax(rates2[0].high, rates2[1].high);
//               int levelP = getPriceLevel(p, minPrice, d, inpNLevel);
//               levelPrice[levelP] += 5;
//            }
//         }
//         
//         res = checkStar(rates3);
//         if (res != 0) {
//            if (res == 1) {
//               double p = MathMin(MathMin(rates3[0].low, rates3[1].low), rates3[2].low);
//               int levelP = getPriceLevel(p, minPrice, d, inpNLevel);
//               levelPrice[levelP] += 5;
//            }
//            else if (res == -1) {
//               double p = MathMax(MathMax(rates3[0].high, rates3[1].high), rates3[2].high);
//               int levelP = getPriceLevel(p, minPrice, d, inpNLevel);
//               levelPrice[levelP] += 5;
//            }
//         }
//         
//         res = checkTripleCS(rates3);
//         if (res != 0) {
//            if (res == 1) {
//               double p = MathMin(MathMin(rates3[0].low, rates3[1].low), rates3[2].low);
//               int levelP = getPriceLevel(p, minPrice, d, inpNLevel);
//               levelPrice[levelP] += 5;
//            }
//            else if (res == -1) {
//               double p = MathMax(MathMax(rates3[0].high, rates3[1].high), rates3[2].high);
//               int levelP = getPriceLevel(p, minPrice, d, inpNLevel);
//               levelPrice[levelP] += 5;
//            }
//         }
//         
//         res = checkThreeInside(rates3);
//         if (res != 0) {
//            if (res == 1) {
//               double p = MathMin(MathMin(rates3[0].low, rates3[1].low), rates3[2].low);
//               int levelP = getPriceLevel(p, minPrice, d, inpNLevel);
//               levelPrice[levelP] += 5;
//            }
//            else if (res == -1) {
//               double p = MathMax(MathMax(rates3[0].high, rates3[1].high), rates3[2].high);
//               int levelP = getPriceLevel(p, minPrice, d, inpNLevel);
//               levelPrice[levelP] += 5;
//            }
//         }
      }
      //for(int j=0; j<d; j++) {
      //   double currLowLevel = minPriceNormalize + (j*inpLevelInterval*_Point);
      //   double currHighLevel = currLowLevel + (inpLevelInterval*_Point);
      //   if (isInRange(currLowLevel, currHighLevel, rates[i].low, rates[i].high)) {
      //      levelPrice[j] = levelPrice[j] + 1;
      //   }
      //}
   }

   ObjectsDeleteAll(0, "PP_", 0, OBJ_RECTANGLE);
   double maxLevelCount = levelPrice[ArrayMaximum(levelPrice, 0, WHOLE_ARRAY)];
   int histSize = 50;
   datetime t0 = TimeCurrent() - histSize*PeriodSeconds();
   double avg = 0;
   double cnt = 0;
   for(int j=0; j<inpNLevel; j++) {
      if (levelPrice[j] > 0) {
         avg += levelPrice[j];
         cnt += 1;
      }
   }
   avg /= cnt;
   avg = ceil(avg);
   for(int j=0; j<inpNLevel; j++) {
      if (levelPrice[j] > avg) {
         datetime t1 = t0 + ((histSize - (levelPrice[j] / maxLevelCount * histSize)) * PeriodSeconds());
         //double p1 = minPriceNormalize + (j*inpLevelInterval*_Point);
         double p1 = minPrice + j*d;
         datetime t2 = TimeCurrent() + (3*PeriodSeconds());
         //double p2 = p1 + (inpLevelInterval*_Point);
         double p2 = p1 + d;
   
         ObjectCreate(0, "PP_LEVEL_" + IntegerToString(j), OBJ_RECTANGLE, 0, t1, p1, t2, p2);
      }
   }
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
bool isInRange(double lbound, double hbound, double low, double high) {
   return (low <= hbound && high > lbound);
}
//+------------------------------------------------------------------+
int checkMarubozu(MqlRates &price) {
   bool greencandle = price.close - price.open >= 0;
   double bodylength = MathAbs(price.close - price.open);
   double rangelength = price.high - price.low;

   int ret = 0;
   if (bodylength == rangelength) {
      if (greencandle) {
         ret = 1;
      } else {
         ret = -1;
      }
   }
   return ret;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int checkEnGulfing(MqlRates &rates[]) {
   if (ArraySize(rates) != 2) {
      return 0;
   }

   int ret = 0;
   double b1 = rates[0].close - rates[0].open;
   double b2 = rates[1].close - rates[1].open;
   double range = MathAbs(rates[1].high - rates[1].low);
   double ratio = 0;
   if (range != 0) {
      ratio = MathAbs(b2) / range;
   }

   // check for bullish engulfing
   if (b1 < 0 && b2 > 0 && ratio >= 0.8) {
      if (MathAbs(b2) > 2*MathAbs(b1)) {
         ret = 1;
      }
   }
   // check for bearish engulfing
   else if (b1 > 0 && b2 < 0 && ratio >= 0.8) {
      if (MathAbs(b2) > 2*MathAbs(b1)) {
         ret = -1;
      }
   }
   return ret;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int checkHarami(MqlRates &rates[]) {
   if (ArraySize(rates) != 2) {
      return 0;
   }

   int ret = 0;

   double bodyMax0 = rates[0].close > rates[0].open ? rates[0].close : rates[0].open;
   double bodyMin0 = rates[0].close < rates[0].open ? rates[0].close : rates[0].open;
   double bodyMax1 = rates[1].close > rates[1].open ? rates[1].close : rates[1].open;
   double bodyMin1 = rates[1].close < rates[1].open ? rates[1].close : rates[1].open;
   bool bodyWhite0 = rates[0].close > rates[0].open;
   bool bodyWhite1 = rates[1].close > rates[1].open;
   double body0 = MathAbs(rates[0].close - rates[0].open);
   double body1 = MathAbs(rates[1].close - rates[1].open);
   double range0 = MathAbs(rates[0].high - rates[0].low);
   double range1 = MathAbs(rates[1].high - rates[1].low);
   double ratio0 = 0;
   if (range0 != 0) {
      ratio0 = body0 / range0;
   }
   double ratio1 = 0;
   if (range1 != 0) {
      ratio1 = body1 / range1;
   }

   if (bodyMax0 > bodyMax1 && bodyMin0 < bodyMin1 && ratio0 >= 0.8 && ratio1 <= 0.2) {
      // Bullish Harami
      if (!bodyWhite0 && bodyWhite1) {
         ret = 1;
      }
      // Bearish Harami
      else if (bodyWhite0 && !bodyWhite1) {
         ret = -1;
      }
   }
   return ret;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int checkStar(MqlRates &rates[]) {
   if (ArraySize(rates) != 3) {
      return 0;
   }

   int ret = 0;

   bool bodyWhite0 = rates[0].close > rates[0].open;
   bool bodyWhite1 = rates[1].close > rates[1].open;
   bool bodyWhite2 = rates[2].close > rates[2].open;
   double bodyMax0 = rates[0].close > rates[0].open ? rates[0].close : rates[0].open;
   double bodyMin0 = rates[0].close < rates[0].open ? rates[0].close : rates[0].open;
   double bodyMax1 = rates[1].close > rates[1].open ? rates[1].close : rates[1].open;
   double bodyMin1 = rates[1].close < rates[1].open ? rates[1].close : rates[1].open;
   double bodyMax2 = rates[2].close > rates[2].open ? rates[2].close : rates[2].open;
   double bodyMin2 = rates[2].close < rates[2].open ? rates[2].close : rates[2].open;
   double body0 = MathAbs(rates[0].close - rates[0].open);
   double body1 = MathAbs(rates[1].close - rates[1].open);
   double body2 = MathAbs(rates[2].close - rates[2].open);
   double range0 = MathAbs(rates[0].high - rates[0].low);
   double range1 = MathAbs(rates[1].high - rates[1].low);
   double range2 = MathAbs(rates[2].high - rates[2].low);
   double ratio0 = 0;
   if (range0 != 0) {
      ratio0 = body0 / range0;
   }
   double ratio1 = 0;
   if (range1 != 0) {
      ratio1 = body1 / range1;
   }
   double ratio2 = 0;
   if (range2 != 0) {
      ratio2 = body2 / range2;
   }

   if (ratio0 >= 0.8 && ratio1 <= 0.2) {
      // check for bullish morning star
      if (!bodyWhite0 && bodyWhite2 && bodyMax1 < bodyMin0 && bodyMax1 < bodyMin2 && rates[2].close > (rates[0].close+0.5*body0)) {
         ret = 1;
      }
      // check for bearish evening star
      else if (bodyWhite0 && !bodyWhite2 && bodyMin1 > bodyMax0 && bodyMin1 > bodyMax2 && rates[2].close < (rates[0].close-0.5*body0)) {
         ret = -1;
      }
   }
   return ret;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int checkTripleCS(MqlRates &rates[]) {
   if (ArraySize(rates) != 3) {
      return 0;
   }

   int ret = 0;

   bool bodyWhite0 = rates[0].close > rates[0].open;
   bool bodyWhite1 = rates[1].close > rates[1].open;
   bool bodyWhite2 = rates[2].close > rates[2].open;
   double bodyMax0 = rates[0].close > rates[0].open ? rates[0].close : rates[0].open;
   double bodyMin0 = rates[0].close < rates[0].open ? rates[0].close : rates[0].open;
   double bodyMax1 = rates[1].close > rates[1].open ? rates[1].close : rates[1].open;
   double bodyMin1 = rates[1].close < rates[1].open ? rates[1].close : rates[1].open;
   double bodyMax2 = rates[2].close > rates[2].open ? rates[2].close : rates[2].open;
   double bodyMin2 = rates[2].close < rates[2].open ? rates[2].close : rates[2].open;
   double body0 = MathAbs(rates[0].close - rates[0].open);
   double body1 = MathAbs(rates[1].close - rates[1].open);
   double body2 = MathAbs(rates[2].close - rates[2].open);
   double range0 = MathAbs(rates[0].high - rates[0].low);
   double range1 = MathAbs(rates[1].high - rates[1].low);
   double range2 = MathAbs(rates[2].high - rates[2].low);
   double ratio0 = 0;
   if (range0 != 0) {
      ratio0 = body0 / range0;
   }
   double ratio1 = 0;
   if (range1 != 0) {
      ratio1 = body1 / range1;
   }
   double ratio2 = 0;
   if (range2 != 0) {
      ratio2 = body2 / range2;
   }

   if (ratio0 > 0.4 && ratio1 > 0.4 && ratio2 > 0.4) {
      // check bullish three white soldier
      if (bodyWhite0 && bodyWhite1 && bodyWhite2) {
         ret = 1;
      }
      // check bearish three black soldier
      else if (!bodyWhite0 && !bodyWhite1 && !bodyWhite2) {
         ret = -1;
      }
   }
   //else if (body0 < body1 && body1 < body2) {
   //    three white momentum
   //   if (bodyWhite0 && bodyWhite1 && bodyWhite2) {
   //      rates = lows[2];
   //      ret = 1;
   //   }
   //    three black momentum
   //   else if (!bodyWhite0 && !bodyWhite1 && !bodyWhite2) {
   //      rates = highs[2];
   //      ret = -1;
   //   }
   //}

   return ret;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int checkThreeInside(MqlRates &rates[]) {
   if (ArraySize(rates) != 3) {
      return 0;
   }

   int ret = 0;

   bool bodyWhite0 = rates[0].close > rates[0].open;
   bool bodyWhite1 = rates[1].close > rates[1].open;
   bool bodyWhite2 = rates[2].close > rates[2].open;
   double bodyMax0 = rates[0].close > rates[0].open ? rates[0].close : rates[0].open;
   double bodyMin0 = rates[0].close < rates[0].open ? rates[0].close : rates[0].open;
   double bodyMax1 = rates[1].close > rates[1].open ? rates[1].close : rates[1].open;
   double bodyMin1 = rates[1].close < rates[1].open ? rates[1].close : rates[1].open;

   if (rates[1].high <= rates[0].high && rates[1].low >= rates[0].low) {
      // check three inside up
      if (!bodyWhite0 && bodyWhite1 && bodyWhite2 && rates[1].close > rates[0].close && rates[2].close > rates[0].open) {
         ret = 1;
      }
      // check three inside down
      else if (bodyWhite0 && !bodyWhite1 && !bodyWhite2 && rates[1].close < rates[0].close && rates[2].close < rates[0].open) {
         ret = -1;
      }
   }

   return ret;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int checkRejection(MqlRates &rates, double avg) {
   double halfrange = (rates.high - rates.low) / 2;
   double mid = rates.low + halfrange;
   double quarter = rates.low + halfrange / 2;
   double quarter2 = rates.low + (halfrange * 3 / 2);
   int ret = 0;

   if (rates.high - rates.low > avg) {
      if (rates.open > mid && rates.close > quarter2) {
         ret = 1;
      }
      if (rates.open < mid && rates.close < quarter) {
         ret = -1;
      }
   }
   return ret;
}

int checkRejection3(MqlRates &rates[])
{
   if (ArraySize(rates) != 3) {
      return 0;
   }
   
   int ret = 0;
   if (rates[1].low <= rates[0].low && rates[1].low <= rates[2].low) {
      ret = 1;
   }
   else if (rates[1].high >= rates[0].high && rates[1].high >= rates[2].high) {
      ret = -1;
   }
   
   return ret;
}

int checkRejection5(MqlRates &rates[])
{
   if (ArraySize(rates) != 5) {
      return 0;
   }
   
   int ret = 0;
   if (rates[2].low <= rates[0].low && rates[2].low <= rates[1].low && rates[2].low <= rates[3].low && rates[2].low <= rates[4].low) {
      ret = 1;
   }
   else if (rates[2].high >= rates[0].high && rates[2].high >= rates[2].high && rates[2].high >= rates[3].high && rates[2].high >= rates[4].high) {
      ret = -1;
   }
   
   return ret;
}

int checkRejection7(MqlRates &rates[])
{
   if (ArraySize(rates) != 7) {
      return 0;
   }
   
   int ret = 0;
   if (rates[3].low <= rates[0].low && rates[3].low <= rates[1].low && rates[3].low <= rates[2].low && rates[3].low <= rates[4].low && rates[3].low <= rates[5].low && rates[3].low <= rates[6].low) {
      ret = 1;
   }
   else if (rates[3].high >= rates[0].high && rates[3].high >= rates[1].high && rates[3].high >= rates[2].high && rates[3].high >= rates[4].high && rates[3].high >= rates[5].high && rates[3].high >= rates[6].high) {
      ret = -1;
   }
   
   return ret;
}

int checkSupplyDemand() {
   MqlRates rates[];
   CopyRates(_Symbol, PERIOD_CURRENT, 0, 14, rates);
   double avgRanges = 0;
   for(int i=0; i<ArraySize(rates)-1; i++) {
      avgRanges += rates[i].high - rates[i].low;
   }
   avgRanges /= ArraySize(rates);
   int ret = 0;
   
   MqlRates lastBar = rates[ArraySize(rates)-1];
   double bodyRatio = MathAbs(lastBar.open - lastBar.close) / (lastBar.high - lastBar.low);
   if ((lastBar.high - lastBar.low) > avgRanges && bodyRatio > 0.618) {
      if (lastBar.close > lastBar.open) {
         ret = 1;
      }
      else if (lastBar.close < lastBar.open) {
         ret = -1;
      }
   }
   
   return ret;
}
//+------------------------------------------------------------------+
int getPriceLevel(double price,double min,double d,int nrow) {
   return MathMin(MathFloor((price-min)/d)+1, nrow);
}
//+------------------------------------------------------------------+
