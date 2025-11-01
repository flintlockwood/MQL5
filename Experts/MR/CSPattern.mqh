//+------------------------------------------------------------------+
//|                                                    CSPattern.mqh |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
// #define MacrosHello   "Hello, world!"
// #define MacrosYear    2010
//+------------------------------------------------------------------+
//| DLL imports                                                      |
//+------------------------------------------------------------------+
// #import "user32.dll"
//   int      SendMessageA(int hWnd,int Msg,int wParam,int lParam);
// #import "my_expert.dll"
//   int      ExpertRecalculate(int wParam,int lParam);
// #import
//+------------------------------------------------------------------+
//| EX5 imports                                                      |
//+------------------------------------------------------------------+
// #import "stdlib.ex5"
//   string ErrorDescription(int error_code);
// #import
//+------------------------------------------------------------------+
#include <Math\Stat\Math.mqh>
#include <MR\Array.mqh>
#include "SignalClass.mqh"
#include "MufEAInclude.mqh"
#include "MufEAGlobal.mqh"

bool checkAllCSPattern(ENUM_TIMEFRAMES tf, Line &keyLevel) {
   bool redraw = false;
   
   // get rates
   int period = 60;
   MqlRates rates[];
   int n = CopyRates(_Symbol, tf, 1, period, rates);
   if (n != period) {
      printf("cannot process checkAllCSPattern because CopyRates return: %i", n);
      return false;
   }
   
   // calculate DVP
   DvpRates dvp;
   getCurrDVP(period, 100, 70, rates, dvp);  
 
   // check Marubozu
   SignalBase *mSignal;
   mSignal = new MarubozuSignal();
   bool mFlag = checkMarubozuCross(tf, rates[period-1], keyLevel, mSignal);
   if (mFlag) {
      mSignal.timeframe = tf;
      writeSignal(mSignal.ToString());
      //signals.Push(mSignal);
      redraw = true;
      //printf("marubozu at %s, %s", TimeToString(mSignal.time), DoubleToString(mSignal.price, _Digits));
   }
   
   // check Rejection
   int rejectPeriod = 100;
   MqlRates rejectRates[];
   int rn = CopyRates(_Symbol, tf, 1, rejectPeriod, rejectRates);
   if (rn != rejectPeriod) {
      printf("cannot process checkAllCSPattern because CopyRates return: %i", n);
      return false;
   }
   double rAvg[];
   ArrayResize(rAvg, rejectPeriod);
   for(int i=0; i<rejectPeriod; i++) {
      rAvg[i] = rejectRates[i].high - rejectRates[i].low;
   }
   double avgRange = MathMean(rAvg);
   double stdDevRange = MathStandardDeviation(rAvg);
   double rangeTh = avgRange + stdDevRange;
   SignalBase *rSignal;
   rSignal = new RejectionSignal();
   bool rFlag = checkRejection(rates[period-1], rSignal);
   if (rFlag) {
      rSignal.timeframe = tf;
      writeSignal(rSignal.ToString());
      //signals.Push(rSignal);
      redraw = true;
      //printf("rejection at %s, %s", TimeToString(rSignal.time), DoubleToString(rSignal.price, _Digits));
   }
   
   MqlRates rates2[];
   ArrayCopy(rates2, rates, 0, period-2, 2);
   
   // check Engulfing
   SignalBase *eSignal;
   eSignal = new EngulfingSignal();
   bool eFlag = checkEnGulfingCross(tf, rates2, keyLevel, eSignal);
   if (eFlag) {
      eSignal.timeframe = tf;
      writeSignal(eSignal.ToString());
      //signals.Push(eSignal);
      redraw = true;
      //printf("engulfing at %s, %s", TimeToString(eSignal.time), DoubleToString(eSignal.price, _Digits));
   }
   
   // check Harami
   SignalBase *hSignal;
   hSignal = new HaramiSignal();
   bool hFlag = checkHaramiCross(rates2, keyLevel, hSignal);
   if (hFlag) {
      hSignal.timeframe = tf;
      writeSignal(hSignal.ToString());
      //signals.Push(hSignal);
      redraw = true;
      //printf("harami at %s, %s", TimeToString(hSignal.time), DoubleToString(hSignal.price, _Digits));
   }
   
   MqlRates rates3[];
   ArrayCopy(rates2, rates, 0, period-3, 3);
   
   // check Star
   SignalBase *sSignal;
   sSignal = new StarSignal();
   bool sFlag = checkStarCross(tf, rates3, keyLevel, sSignal);
   if (sFlag) {
      sSignal.timeframe = tf;
      writeSignal(sSignal.ToString());
      //signals.Push(sSignal);
      redraw = true;
      //printf("star at %s, %s", TimeToString(sSignal.time), DoubleToString(sSignal.price, _Digits));
   }
   
   // check Triple
   SignalBase *tSignal;
   tSignal = new TripleCsSignal();
   bool tFlag = checkTripleCSCross(rates3, keyLevel, tSignal);
   if (tFlag) {
      tSignal.timeframe = tf;
      writeSignal(tSignal.ToString());
      //signals.Push(tSignal);
      redraw = true;
      //printf("triple at %s, %s", TimeToString(tSignal.time), DoubleToString(tSignal.price, _Digits));
   }
   
   // check Three Inside
   SignalBase *tiSignal;
   tiSignal = new ThreeInsideSignal();
   bool tiFlag = checkThreeInsideCross(rates3, keyLevel, tiSignal);
   if (tiFlag) {
      tiSignal.timeframe = tf;
      writeSignal(tiSignal.ToString());
      //signals.Push(tiSignal);
      redraw = true;
      //printf("three inside at %s, %s", TimeToString(tiSignal.time), DoubleToString(tiSignal.price, _Digits));
   }
   
   return redraw;
}

bool checkEnGulfing(MqlRates &rates[], SignalBase &signal)
{
   if (ArraySize(rates) != 2) {
      return false;
   }
   
   bool ret = false;
   double b1 = rates[0].close - rates[0].open;
   double b2 = rates[1].close - rates[1].open;
   double range = MathAbs(rates[1].high - rates[1].low);
   double ratio = 0;
   if (range != 0) {
      ratio = MathAbs(b2) / range;
   }
   
   if (MathAbs(b2) > 2*MathAbs(b1)) {
      // check for bullish engulfing
      if (b1 < 0 && b2 > 0 && ratio >= 0.8) {
         EngulfingSignal s;
         s.price = rates[1].low;
         s.time = rates[1].time;
         s.type = SIGNAL_TYPE_BULLISH;
         signal = s;
         ret = true;
      }
      // check for bearish engulfing
      else if (b1 > 0 && b2 < 0 && ratio >= 0.8) {
         EngulfingSignal s;
         s.price = rates[1].high;
         s.time = rates[1].time;
         s.type = SIGNAL_TYPE_BEARISH;
         signal = s;
         ret = true;
      }
   }
   return ret;
}

bool checkEnGulfingCross(ENUM_TIMEFRAMES tf, MqlRates &rates[], Line &keyLevel, SignalBase &signal)
{
   bool ret = false;
   if (isInFrame(tf, rates, keyLevel)) {
      SignalBase *s;
      s = new EngulfingSignal();
      if (checkEnGulfing(rates, s)) {
         double midBody = MathAbs(rates[1].close - rates[1].open);
         double lowerBody = rates[1].close < rates[1].open ? rates[1].close : rates[1].open;
         double midLevel = lowerBody + midBody;
         double currLevel = calculateY(rates[1].time, keyLevel.x1, keyLevel.y1, keyLevel.x2, keyLevel.y2);
         if (midLevel >= currLevel || s.type == SIGNAL_TYPE_BULLISH) {
            ret = true;
         }
         else if (midLevel <= currLevel || s.type == SIGNAL_TYPE_BEARISH) {
            ret = true;
         }
      }
   }
   
   return ret;
}

//bool checkRejection(MqlRates &rates, double th, SignalBase &signal)
//{
//   bool ret = false;
//   double halfrange = (rates.high - rates.low) / 2;
//   double mid = rates.low + halfrange;
//   double quarter = rates.low + halfrange / 2;
//   double quarter2 = rates.low + (halfrange * 3 / 2);
//   if (rates.high - rates.low > th) {
//      if (rates.open > mid && rates.close > quarter2) {
//         RejectionSignal s;
//         s.price = rates.low;
//         s.time = rates.time;
//         s.type = SIGNAL_TYPE_BULLISH;
//         signal = s;
//         ret = true;
//      }
//      if (rates.open < mid && rates.close < quarter) {
//         RejectionSignal s;
//         s.price = rates.high;
//         s.time = rates.time;
//         s.type = SIGNAL_TYPE_BEARISH;
//         signal = s;
//         ret = true;
//      }
//   }
//   
//   return ret;
//}

//bool checkRejection2Cross(MqlRates &rates, double th, SignalBase &signal)
//{
//   bool ret = false;
//   double range = rates.high - rates.low;
//   double lwick = rates.close < rates.open ? rates.close - rates.low : rates.open - rates.low;
//   double hwick = rates.close < rates.open ? rates.high - rates.open : rates.high - rates.close;
//   
//   if (lwick / range > 0.8) {
//      RejectionSignal s;
//      s.price = rates.low;
//      s.time = rates.time;
//      s.type = SIGNAL_TYPE_BULLISH;
//      signal = s;
//      ret = true;
//   }
//   if (hwick / range > 0.8) {
//         RejectionSignal s;
//         s.price = rates.high;
//         s.time = rates.time;
//         s.type = SIGNAL_TYPE_BEARISH;
//         signal = s;
//         ret = true;
//    }
//   
//   return ret;
//}

bool checkRejection(MqlRates &rates, SignalBase &signal)
{
   bool ret = false;
   double range = rates.high - rates.low;
   double lwick = rates.close < rates.open ? rates.close - rates.low : rates.open - rates.low;
   double hwick = rates.close < rates.open ? rates.high - rates.open : rates.high - rates.close;
   
   if (lwick / range >= 0.6) {
      RejectionSignal s;
      s.price = rates.low;
      s.time = rates.time;
      s.type = SIGNAL_TYPE_BULLISH;
      signal = s;
      ret = true;
   }
   if (hwick / range >= 0.6) {
         RejectionSignal s;
         s.price = rates.high;
         s.time = rates.time;
         s.type = SIGNAL_TYPE_BEARISH;
         signal = s;
         ret = true;
    }
   
   return ret;
}

bool checkRejectionCross(ENUM_TIMEFRAMES tf, MqlRates &rates, Line &keyLevel, SignalBase &signal)
{
   bool ret = false;
   if (isInFrame(tf, rates, keyLevel)) {
      SignalBase *s;
      s = new RejectionSignal();
      if (checkRejection(rates, s)) {
         double currLevel = calculateY(rates.time, keyLevel.x1, keyLevel.y1, keyLevel.x2, keyLevel.y2);
         double avgRange = getAverageRange(tf, 100);
         if (s.type == SIGNAL_TYPE_BULLISH) {
            if (rates.low >= currLevel-avgRange/4 && rates.open <= currLevel+avgRange/4) {
               ret = true;
            }
         }
         else if (s.type == SIGNAL_TYPE_BEARISH) {
            if (rates.high >= currLevel-avgRange/4 && rates.open <= currLevel+avgRange/4) {
               ret = true;
            }
         }
      }
   }
   
   return ret;
}

bool checkStar(MqlRates &rates[], SignalBase &signal)
{
   if (ArraySize(rates) != 3) {
      return false;
   }
   
   bool ret = false;
   
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
         StarSignal s;
         s.price = rates[2].low;
         s.time = rates[2].time;
         s.type = SIGNAL_TYPE_BULLISH;
         signal = s;
         ret = true;
      }
      // check for bearish evening star
      else if (bodyWhite0 && !bodyWhite2 && bodyMin1 > bodyMax0 && bodyMin1 > bodyMax2 && rates[2].close < (rates[0].close-0.5*body0)) {
         StarSignal s;
         s.price = rates[2].high;
         s.time = rates[2].time;
         s.type = SIGNAL_TYPE_BEARISH;
         signal = s;
         ret = true;
      }
   }
   return ret;
}

bool checkStarCross(ENUM_TIMEFRAMES tf, MqlRates &rates[], Line &keyLevel, SignalBase &signal)
{
   bool ret = false;
   if (isInFrame(tf, rates, keyLevel)) {
      SignalBase *s;
      s = new StarSignal();
      if (checkStar(rates, s)) {
         double currLevel = calculateY(rates[2].time, keyLevel.x1, keyLevel.y1, keyLevel.x2, keyLevel.y2);
         double avgRange = getAverageRange(tf, 100);
         if (s.type == SIGNAL_TYPE_BULLISH) {
            if (rates[2].low >= currLevel-avgRange/4 && rates[2].open <= currLevel+avgRange/4) {
               ret = true;
            }
         }
         else if (s.type == SIGNAL_TYPE_BEARISH) {
            if (rates[2].high >= currLevel-avgRange/4 && rates[2].open <= currLevel+avgRange/4) {
               ret = true;
            }
         }
      }
   }
   
   return ret;
}

bool checkMarubozu(MqlRates &rates, SignalBase &signal)
{
   bool greencandle = rates.close - rates.open >= 0;
   double bodylength = MathAbs(rates.close - rates.open);
   double rangelength = rates.high - rates.low;
   
   bool ret = false;
   if (bodylength == rangelength) {
      if (greencandle) {
         MarubozuSignal s;
         s.price = rates.low;
         s.time = rates.time;
         s.type = SIGNAL_TYPE_BULLISH;
         signal = s;
         ret = true;
      }
      else {
         MarubozuSignal s;
         s.price = rates.high;
         s.time = rates.time;
         s.type = SIGNAL_TYPE_BEARISH;
         signal = s;
         ret = true;
      }
   }
   return ret;
}

bool checkMarubozuCross(ENUM_TIMEFRAMES tf, MqlRates &rates, Line &keyLevel, SignalBase &signal)
{
   bool greencandle = rates.close - rates.open >= 0;
   double bodylength = MathAbs(rates.close - rates.open);
   double rangelength = rates.high - rates.low;
   double currLevel = calculateY(rates.time, keyLevel.x1, keyLevel.y1, keyLevel.x2, keyLevel.y2);
   double avgBody = getAverageBody(tf, 14);
   double avgRange = getAverageRange(tf, 100);
   
   bool ret = false;
   if (bodylength >= avgBody && bodylength / rangelength >= 0.9) {
      if (greencandle) {
         if (rates.open >= currLevel - avgRange/2 && rates.open <= currLevel + avgRange/2) {
            MarubozuSignal s;
            s.price = rates.low;
            s.time = rates.time;
            s.type = SIGNAL_TYPE_BULLISH;
            signal = s;
            ret = true;
         }
      }
      else {
         if (rates.open >= currLevel - avgRange/2 && rates.open <= currLevel + avgRange/2) {
            MarubozuSignal s;
            s.price = rates.high;
            s.time = rates.time;
            s.type = SIGNAL_TYPE_BEARISH;
            signal = s;
            ret = true;
         }
      }
   }
   return ret;
}

bool checkHarami(MqlRates &rates[], SignalBase &signal)
{
   if (ArraySize(rates) != 2) {
      return false;
   }
   
   bool ret = false;
   
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
      if (!bodyWhite0 && bodyWhite1) {
         HaramiSignal s;
         s.price = rates[1].low;
         s.time = rates[1].time;
         s.type = SIGNAL_TYPE_BULLISH;
         signal = s;
         ret = true;
      }
      // Bearish Harami
      else if (bodyWhite0 && !bodyWhite1) {
         HaramiSignal s;
         s.price = rates[1].high;
         s.time = rates[1].time;
         s.type = SIGNAL_TYPE_BEARISH;
         signal = s;
         ret = true;
      }   
   }
   return ret;
}

bool checkHaramiCross(MqlRates &rates[], Line &line, SignalBase &signal)
{
   if (ArraySize(rates) != 2) {
      return false;
   }
   
   bool ret = false;
   
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
   double currLevel = calculateY(rates[1].time, line.x1, line.y1, line.x2, line.y2);

   if (bodyMax0 > bodyMax1 && bodyMin0 < bodyMin1 && ratio0 >= 0.8 && ratio1 <= 0.2) {
      if (MathAbs(rates[1].close - currLevel) <= 10*_Point) {
         // Bullish Harami
         if (!bodyWhite0 && bodyWhite1) {
            HaramiSignal s;
            s.price = rates[1].low;
            s.time = rates[1].time;
            s.type = SIGNAL_TYPE_BULLISH;
            signal = s;
            ret = true;
         }
         // Bearish Harami
         else if (bodyWhite0 && !bodyWhite1) {
            HaramiSignal s;
            s.price = rates[1].high;
            s.time = rates[1].time;
            s.type = SIGNAL_TYPE_BEARISH;
            signal = s;
            ret = true;
         }   
      }
   }
   return ret;
}

bool checkTripleCS(MqlRates &rates[], SignalBase &signal)
{
   if (ArraySize(rates) != 3) {
      return false;
   }
   
   bool ret = false;
   
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
         TripleCsSignal s;
         s.price = rates[2].low;
         s.time = rates[2].time;
         s.type = SIGNAL_TYPE_BULLISH;
         signal = s;
         ret = true;
      }
      // check bearish three black soldier
      else if (!bodyWhite0 && !bodyWhite1 && !bodyWhite2) {
         TripleCsSignal s;
         s.price = rates[2].high;
         s.time = rates[2].time;
         s.type = SIGNAL_TYPE_BEARISH;
         signal = s;
         ret = true;
      }
   }
   else if (body0 < body1 && body1 < body2) {
      // three white momentum 
      if (bodyWhite0 && bodyWhite1 && bodyWhite2) {
         TripleCsSignal s;
         s.price = rates[2].low;
         s.time = rates[2].time;
         s.type = SIGNAL_TYPE_BULLISH;
         signal = s;
         ret = true;
      }
      // three black momentum 
      else if (!bodyWhite0 && !bodyWhite1 && !bodyWhite2) {
         TripleCsSignal s;
         s.price = rates[2].high;
         s.time = rates[2].time;
         s.type = SIGNAL_TYPE_BEARISH;
         signal = s;
         ret = true;
      }
   }
   
   return ret;
}

bool checkTripleCSCross(MqlRates &rates[], Line &line, SignalBase &signal)
{
   if (ArraySize(rates) != 3) {
      return false;
   }
   
   bool ret = false;
   
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
   double currLevel = calculateY(rates[2].time, line.x1, line.y1, line.x2, line.y2);
   
   if (ratio0 > 0.4 && ratio1 > 0.4 && ratio2 > 0.4) {
      // check bullish three white soldier
      if (bodyWhite0 && bodyWhite1 && bodyWhite2) {
         if (rates[0].open < currLevel && rates[2].close > currLevel) {
            TripleCsSignal s;
            s.price = rates[2].low;
            s.time = rates[2].time;
            s.type = SIGNAL_TYPE_BULLISH;
            signal = s;
            ret = true;
         }
      }
      // check bearish three black soldier
      else if (!bodyWhite0 && !bodyWhite1 && !bodyWhite2) {
         if (rates[0].open > currLevel && rates[2].close < currLevel) {
            TripleCsSignal s;
            s.price = rates[2].high;
            s.time = rates[2].time;
            s.type = SIGNAL_TYPE_BEARISH;
            signal = s;
            ret = true;
         }
      }
   }
   else if (body0 < body1 && body1 < body2) {
      // three white momentum 
      if (bodyWhite0 && bodyWhite1 && bodyWhite2) {
         TripleCsSignal s;
         s.price = rates[2].low;
         s.time = rates[2].time;
         s.type = SIGNAL_TYPE_BULLISH;
         signal = s;
         ret = true;
      }
      // three black momentum 
      else if (!bodyWhite0 && !bodyWhite1 && !bodyWhite2) {
         TripleCsSignal s;
         s.price = rates[2].high;
         s.time = rates[2].time;
         s.type = SIGNAL_TYPE_BEARISH;
         signal = s;
         ret = true;
      }
   }
   
   return ret;
}

bool checkThreeInside(MqlRates &rates[], SignalBase &signal)
{
   if (ArraySize(rates) != 3) {
      return false;
   }
   
   bool ret = false;
   
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
         ThreeInsideSignal s;
         s.price = rates[2].low;
         s.time = rates[2].time;
         s.type = SIGNAL_TYPE_BULLISH;
         signal = s;
         ret = true;
      }
      // check three inside down
      else if (bodyWhite0 && !bodyWhite1 && !bodyWhite2 && rates[1].close < rates[0].close && rates[2].close < rates[0].open) {
         ThreeInsideSignal s;
         s.price = rates[2].high;
         s.time = rates[2].time;
         s.type = SIGNAL_TYPE_BEARISH;
         signal = s;
         ret = true;   
      }
   }
   
   return ret;
}

bool checkThreeInsideCross(MqlRates &rates[], Line &line, SignalBase &signal)
{
   if (ArraySize(rates) != 3) {
      return false;
   }
   
   bool ret = false;
   
   bool bodyWhite0 = rates[0].close > rates[0].open;
   bool bodyWhite1 = rates[1].close > rates[1].open;
   bool bodyWhite2 = rates[2].close > rates[2].open;
   double bodyMax0 = rates[0].close > rates[0].open ? rates[0].close : rates[0].open;
   double bodyMin0 = rates[0].close < rates[0].open ? rates[0].close : rates[0].open;
   double bodyMax1 = rates[1].close > rates[1].open ? rates[1].close : rates[1].open;
   double bodyMin1 = rates[1].close < rates[1].open ? rates[1].close : rates[1].open;
   double currLevel = calculateY(rates[2].time, line.x1, line.y1, line.x2, line.y2);
   
   if (rates[1].high <= rates[0].high && rates[1].low >= rates[0].low) {
      // check three inside up
      if (!bodyWhite0 && bodyWhite1 && bodyWhite2 && rates[1].close > rates[0].close && rates[2].close > rates[0].open) {
         if (rates[1].open < currLevel && rates[2].close > currLevel) {
            ThreeInsideSignal s;
            s.price = rates[2].low;
            s.time = rates[2].time;
            s.type = SIGNAL_TYPE_BULLISH;
            signal = s;
            ret = true;
         }
      }
      // check three inside down
      else if (bodyWhite0 && !bodyWhite1 && !bodyWhite2 && rates[1].close < rates[0].close && rates[2].close < rates[0].open) {
         if (rates[1].open > currLevel && rates[2].close < currLevel) {
            ThreeInsideSignal s;
            s.price = rates[2].high;
            s.time = rates[2].time;
            s.type = SIGNAL_TYPE_BEARISH;
            signal = s;
            ret = true;   
         }
      }
   }
   
   return ret;
}
