//+------------------------------------------------------------------+
//|                                                    CSPattern.mq5 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots   4
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
//--- plot BullishFTR
#property indicator_label3  "BullishFTR"
#property indicator_type3   DRAW_ARROW
#property indicator_color3  clrBlue
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
//--- plot BearishFTR
#property indicator_label4  "BearishFTR"
#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrYellow
#property indicator_style4  STYLE_SOLID
#property indicator_width4  1

//--- indicator buffers
double         BullishPoleBuffer[];
double         BearishPoleBuffer[];
double         BullishFtrBuffer[];
double         BearishFtrBuffer[];

//--- input parameters
input int      inpPeriod= 24;
input bool     showPole = true;
input bool     showFtr = false;

#include "..\..\Experts\MR\Common.mqh";

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//--- indicator buffers mapping
   SetIndexBuffer(0,BullishPoleBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,BearishPoleBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,BullishFtrBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,BearishFtrBuffer,INDICATOR_DATA);

//--- setting a code from the Wingdings charset as the property of PLOT_ARROW
   PlotIndexSetInteger(0,PLOT_ARROW,233);
   PlotIndexSetInteger(1,PLOT_ARROW,234);
   PlotIndexSetInteger(2,PLOT_ARROW,233);
   PlotIndexSetInteger(3,PLOT_ARROW,234);

//--- setting shift
   PlotIndexSetInteger(0,PLOT_ARROW_SHIFT,10);
   PlotIndexSetInteger(1,PLOT_ARROW_SHIFT,-10);
   PlotIndexSetInteger(2,PLOT_ARROW_SHIFT,10);
   PlotIndexSetInteger(3,PLOT_ARROW_SHIFT,-10);

//---
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);

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
   if(prev_calculated<inpPeriod) {
      ArrayInitialize(BullishPoleBuffer,EMPTY_VALUE);
      ArrayInitialize(BearishPoleBuffer,EMPTY_VALUE);
      ArrayInitialize(BullishFtrBuffer,EMPTY_VALUE);
      ArrayInitialize(BearishFtrBuffer,EMPTY_VALUE);
   }

   for(int i=prev_calculated; i<rates_total-1; i++) {
      if (i-inpPeriod < 0) {
         continue;
      }
      double arrOpen[];
      ArrayCopy(arrOpen, open, 0, i-inpPeriod, inpPeriod);
      double arrHigh[];
      ArrayCopy(arrHigh, high, 0, i-inpPeriod, inpPeriod);
      double arrLow[];
      ArrayCopy(arrLow, low, 0, i-inpPeriod, inpPeriod);
      double arrClose[];
      ArrayCopy(arrClose, close, 0, i-inpPeriod, inpPeriod);

      double ranges[];
      ArrayResize(ranges, inpPeriod);
      for (int j=0; j<inpPeriod; j++) {
         ranges[j] = arrHigh[j] - arrLow[j];
      }
      double rangeAvg = MathMean(ranges);
      double rangeSd = MathStandardDeviation(ranges);

      double ratio = 0;
      if (high[i]-low[i] != 0) {
         ratio = MathAbs(close[i]-open[i]) / (high[i]-low[i]);
      }

      if (showPole) {
         if (close[i]>open[i] && (high[i]-low[i])>=(rangeAvg+rangeSd) && ratio>=0.618) {
            BullishPoleBuffer[i] = low[i];
         }
         else if (close[i]<open[i] && (high[i]-low[i])>=(rangeAvg+rangeSd) && ratio>=0.618) {
            BearishPoleBuffer[i] = high[i];
         }
      }

      if (showFtr) {
         bool ispole1 = isPole(open[i-2], high[i-2], low[i-2], close[i-2], rangeAvg, rangeSd);
         bool ispole2 = isPole(open[i-1], high[i-1], low[i-1], close[i-1], rangeAvg, rangeSd);
         bool ispole3 = isPole(open[i], high[i], low[i], close[i], rangeAvg, rangeSd);

         if (ispole1 && close[i-2]>open[i-2] && !ispole2 && close[i-1]<open[i-1] && ispole3 && close[i]>open[i]) {
            BullishFtrBuffer[i-1] = low[i-1];
         } else if (ispole1 && close[i-2]<open[i-2] && !ispole2 && close[i-1]>open[i-1] && ispole3 && close[i]<open[i]) {
            BearishFtrBuffer[i-1] = high[i-1];
         }
      }
   }

//--- return value of prev_calculated for next call
   return(rates_total);
}
//+------------------------------------------------------------------+
bool isPole(double open, double high, double low, double close, double avgRange, double stdRange) {
   double ratio = 0;
   if (high-low != 0) {
      ratio = MathAbs(close-open) / (high-low);
   }
   return (high-low) >= (avgRange+stdRange) && ratio>=0.618;
}
//+------------------------------------------------------------------+
