//+------------------------------------------------------------------+
//|                                                 TesEngulfing.mq5 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//---
   MqlRates rates[];
   CopyRates("NZDUSD", PERIOD_M30, 0, 7, rates);
   for (int i=1; i<ArraySize(rates)-1; i++)
   {
      double b1 = rates[i-1].close - rates[i-1].open;
      double b2 = rates[i].close - rates[i].open;
      double range = MathAbs(rates[i].high - rates[i].low);
      double ratio = 0;
      if (b2 != 0)
      {
         ratio = range / MathAbs(b2);
      }
      printf("time:%s, b1:%s, b2:%s, ratio:%s", TimeToString(rates[1].time,TIME_DATE|TIME_SECONDS), DoubleToString(b1, Digits()), DoubleToString(b2, Digits()), DoubleToString(ratio, 2));
      string check1 = MathAbs(b2) > 1.5*MathAbs(b1) ? "true" : "false";
      printf("MathAbs(b2) > 1.5*MathAbs(b1): %s", check1);
      string check2 = ratio <= 4.0/3.0 ? "true" : "false";
      printf("ratio <= 4/3: %s", check1);
      if ((MathAbs(b2) > 1.5*MathAbs(b1)) && (ratio <= 4.0/3.0))
      {
         printf("pass first condition");
         // check for bullish engulfing
         if (b1 < 0 && b2 > 0)
         {
            printf("Bullish engulfing detected");
            string name = StringFormat("Bullish Engulfing #%i", 1);
            double min = rates[i].low <= rates[i-1].low ? rates[i].low : rates[i-1].low;
            ObjectCreate(0, name, OBJ_ARROW_BUY, 0, rates[i].time, min);
            ObjectSetInteger(0, name, OBJPROP_COLOR, clrGreen);
            //printf("b1: %s, b2: %s, ratio: %s", DoubleToString(b1, Digits()), DoubleToString(b2, Digits()), DoubleToString(ratio, Digits()));
         }
         // check for bearish engulfing
         else if (b1 > 0 && b2 < 0)
         {
            printf("Bearish engulfing detected");
            string name = StringFormat("Bearish Engulfing #%i", 1);
            double max = rates[i].high >= rates[i-1].high ? rates[i].high : rates[i-1].high;
            ObjectCreate(0, name, OBJ_ARROW_SELL, 0, rates[i].time, max);
            ObjectSetInteger(0, name, OBJPROP_COLOR, clrRed);
         }
      }
   }
  }
//+------------------------------------------------------------------+
