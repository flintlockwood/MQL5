//+------------------------------------------------------------------+
//|                                                    Rejection.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2

//--- plot BullishRejection
#property indicator_label14 "BullishRejection"
#property indicator_type14  DRAW_ARROW
#property indicator_color14 clrBlue
//--- plot BearishRejection
#property indicator_label15 "BearishRejection"
#property indicator_type15  DRAW_ARROW
#property indicator_color15 clrYellow

#include <Math\Stat\Math.mqh>

double         BullishRejectionBuffer[];
double         BearishRejectionBuffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//--- indicator buffers mapping
   SetIndexBuffer(0,BullishRejectionBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,BearishRejectionBuffer,INDICATOR_DATA);

   PlotIndexSetInteger(0,PLOT_ARROW_SHIFT,10);
   PlotIndexSetInteger(1,PLOT_ARROW_SHIFT,-10);

   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---
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

   for(int i=0; i<rates_total && !IsStopped(); i++) {
      BullishRejectionBuffer[i] = EMPTY_VALUE;
      BearishRejectionBuffer[i] = EMPTY_VALUE;

      // check Rejection
      int avgSize = 60;
      double hAvg[];
      ArrayCopy(hAvg,high,0,i-avgSize+1,avgSize);
      double lAvg[];
      ArrayCopy(lAvg,low,0,i-avgSize+1,avgSize);
      double rAvg[];
      ArrayResize(rAvg, avgSize);
      for(int i=0; i<avgSize; i++) {
         rAvg[i] = hAvg[i] - lAvg[i];
      }
      double avgRange = MathMean(rAvg);
      double stdDevRange = MathStandardDeviation(rAvg);
      double rangeTh = avgRange + stdDevRange;
      double rRates;
      int rFlag = checkRejection(open[i], high[i], low[i], close[i], rangeTh, rRates);
      if (rFlag == 1) {
         BullishRejectionBuffer[i] = rRates;
         //printf("bullish marubozu at %s, %s", TimeToString(time[i]), DoubleToString(mRates, _Digits));
      } else if (rFlag == -1) {
         BearishRejectionBuffer[i] = rRates;
         //printf("bearish marubozu at %s", TimeToString(time[i]));
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
int checkRejection(double open, double high, double low, double close, double avg, double &rates)
{
   double halfrange = (high - low) / 2;
   double mid = low + halfrange;
   double quarter = low + halfrange / 2;
   double quarter2 = low + (halfrange * 3 / 2);
   int ret = 0;
   rates = EMPTY_VALUE;
   if (high - low > avg) {
      if (open > mid && close > quarter2) {
         ret = 1;
         rates = low;
      }
      if (open < mid && close < quarter) {
         ret = -1;
         rates = high;
      }
   }
   return ret;
}

int checkRejection2(MqlRates &rates[])
{
   if (ArraySize(rates) != 3) {
      return 0;
   }
   
   int ret = 0;
   if (rates[1].high > rates[0].high && rates[1].high > rates[2].high) {
      ret = 1;
   }
   else if (rates[1].low < rates[0].low && rates[1].low < rates[2].low) {
      ret = -1;
   }
   
   return ret;
}
