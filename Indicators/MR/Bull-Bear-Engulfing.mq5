//+------------------------------------------------------------------+
//|                                          Bull-Bear-Engulfing.mq5 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window

int bullEnCnt;
int bearEnCnt;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   bullEnCnt = 0;
   bearEnCnt = 0;
//---
   return(INIT_SUCCEEDED);
  }
  
void OnDeinit(const int  reason)
{
   ObjectsDeleteAll(0, "*Engulfing*");
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
                const int &spread[])
  {
//---
   if (prev_calculated == 0)
   {
      ObjectsDeleteAll(0, "*Engulfing*");
   }
   for(int i=prev_calculated; i<rates_total; i++) 
   {
      if(i > 0) 
      {
         double b1 = close[i-1] - open[i-1];
         double b2 = close[i] - open[i];
         double range = MathAbs(high[i] - low[i]);
         double ratio = 0;
         if (b2 != 0)
         {
            ratio = MathAbs(high[i] - low[i]) / MathAbs(b2);
         }
         // check for bullish engulfing
         if (b1 < 0 && b2 > 0 && ratio <= 4/3)
         {
            if (MathAbs(b2) > 1.5*MathAbs(b1))
            {
               string name = StringFormat("Bullish Engulfing #%i", bullEnCnt);
               double min = low[i] >= low[i-1] ? low[i] : low[i-1];
               ObjectCreate(0, name, OBJ_ARROW_BUY, 0, time[i], min);
               ObjectSetInteger(0, name, OBJPROP_COLOR, clrGreen);
               bullEnCnt++;
               printf("b1: %s, b2: %s, ratio: %s", DoubleToString(b1, Digits()), DoubleToString(b2, Digits()), DoubleToString(ratio, Digits()));
            }
         }
         // check for bearish engulfing
         else if (b1 > 0 && b2 < 0 && ratio <= 4/3)
         {
            if (MathAbs(b2) > 1.5*MathAbs(b1))
            {
               string name = StringFormat("Bearish Engulfing #%i", bearEnCnt);
               double max = high[i] >= high[i-1] ? high[i] : high[i-1];
               ObjectCreate(0, name, OBJ_ARROW_SELL, 0, time[i], max);
               ObjectSetInteger(0, name, OBJPROP_COLOR, clrRed);
               bearEnCnt++;
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
void OnTimer()
  {
//---
   
  }
//+------------------------------------------------------------------+
