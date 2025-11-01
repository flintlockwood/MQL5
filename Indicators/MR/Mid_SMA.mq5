//+------------------------------------------------------------------+
//|                                                      Mid_SMA.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 5
#property indicator_plots   5

#property indicator_label1  "MID_SMA"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrWhiteSmoke
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

#property indicator_label2  "UPPER_RANGE"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrWhiteSmoke
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

#property indicator_label3  "LOWER_RANGE"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrWhiteSmoke
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1

#property indicator_label4  "UPPER_SD"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrBlueViolet
#property indicator_style4  STYLE_SOLID
#property indicator_width4  1

#property indicator_label5  "LOWER_SD"
#property indicator_type5   DRAW_LINE
#property indicator_color5  clrBlueViolet
#property indicator_style5  STYLE_SOLID
#property indicator_width5  1

#include <Math\Stat\Normal.mqh>

input int      inpPeriod= 20;
input int      inpRange = 100;
input bool     showMidAvg = true;
input bool     showUpperRange = true;
input bool     showLowerRange = true;
input bool     showUpperSd = true;
input bool     showLowerSd = true;

double         MidSmaBuffer[];
double         UpperRangeBuffer[];
double         LowerRangeBuffer[];
double         UpperSdBuffer[];
double         LowerSdBuffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//--- indicator buffers mapping
   SetIndexBuffer(0,MidSmaBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,UpperRangeBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,LowerRangeBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,UpperSdBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,LowerSdBuffer,INDICATOR_DATA);
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
   int maxperiod = inpPeriod > inpRange ? inpPeriod : inpRange;
   for(int i=prev_calculated; i<rates_total-1; i++) { 
      if (i-(maxperiod-1) < 0) {
         continue;
      }
      
      double midRange = 0;
      for(int j=i-(inpPeriod-1); j<=i; j++) {
         midRange = midRange + (low[j] + (high[j] - low[j])/2);
      }
      midRange = midRange / inpPeriod;
      if (showMidAvg) {
         MidSmaBuffer[i] = midRange;
      }
      
      double ranges[];
      for(int j=i-(inpRange-1); j<=i; j++) {
         ArrayResize(ranges, ArraySize(ranges)+1, 5);
         ranges[ArraySize(ranges)-1] = high[j] - low[j];
      }
      double rangeAvg = MathMean(ranges);
      double rangeSd = MathStandardDeviation(ranges);
      
      double midPrice = low[i] + (high[i] - low[i])/2;
      if (showUpperRange) {
         UpperRangeBuffer[i] = midPrice + rangeAvg/2;
      }
      if (showLowerRange) {
         LowerRangeBuffer[i] = midPrice - rangeAvg/2;
      }
      if (showUpperSd) {
         UpperSdBuffer[i] = midPrice + rangeAvg/2 + rangeSd/2;
      }
      if (showLowerSd) {
         LowerSdBuffer[i] = midPrice - rangeAvg/2 - rangeSd/2;
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
