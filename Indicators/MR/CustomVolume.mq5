//+------------------------------------------------------------------+
//|                                                 CustomVolume.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 5                   
#property indicator_plots 3                     

#property indicator_type1     DRAW_COLOR_HISTOGRAM  
#property indicator_width1    4                    
#property indicator_color1    clrGreen, clrYellow, clrRed //0x26A69A,0xEF5350,clrBlueViolet 

#property indicator_label2  "Avg"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrYellow

#property indicator_label3  "StdDev"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrRed

//--- input parameters
input int      inpPeriod = 14;
input bool     showChanges = false;

//--- indicator buffers
//Declaration of buffers
double VolumeBuffer[];
double ColorBuffer[];
double    AvgBuffer[];
double    StdDevBuffer[];

#include <Math\Stat\Normal.mqh>
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,VolumeBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ColorBuffer,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,AvgBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,StdDevBuffer,INDICATOR_DATA);

   PlotIndexSetInteger(0,PLOT_COLOR_INDEXES,4);
   PlotIndexSetInteger(0,PLOT_LINE_COLOR,0,clrGreen);
   PlotIndexSetInteger(0,PLOT_LINE_COLOR,1,clrYellow);
   PlotIndexSetInteger(0,PLOT_LINE_COLOR,2,clrRed);
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
                const int &spread[])
  {
//---
   int pos = prev_calculated;
   if(pos<inpPeriod+1) {
      for(int i=0;i<inpPeriod+1;i++) {
         VolumeBuffer[i]=EMPTY_VALUE;
         ColorBuffer[i]=EMPTY_VALUE;
         AvgBuffer[i]=EMPTY_VALUE;
         StdDevBuffer[i]=EMPTY_VALUE;
      }
      pos = inpPeriod+1;
   }
   
   for(int i=pos;i<rates_total && !IsStopped();i++)
   {
      double tempArr[];
      int n = ArrayCopy(tempArr, tick_volume, 0, i-inpPeriod+1, inpPeriod);
      if (n != inpPeriod) {
         printf("cannot process because ArrayCopy return: %i", n);
         return(i);
      }
      
      double volposArr[];
      double volnegArr[];
      double volArr[];
      for(int j=1; j<ArraySize(tempArr); j++) {
         double d = ((double)tempArr[j] - (double)tempArr[j-1])/(double)tempArr[j-1];
         ArrayResize(volposArr, ArraySize(volposArr)+1, 20);
         ArrayResize(volnegArr, ArraySize(volnegArr)+1, 20);
         ArrayResize(volArr, ArraySize(volArr)+1, 20);
         volposArr[j-1] = (d > 0 ? d : 0);
         volnegArr[j-1] = (d < 0 ? -d : 0);
         volArr[j-1] = MathAbs(d);
      }
      double volposAvg = MathMean(volposArr);
      double volnegAvg = MathMean(volnegArr);
      double volAvg = MathMean(volArr);
      double volposStdDev = MathStandardDeviation(volposArr);
      double volnegStdDev = MathStandardDeviation(volnegArr);
      double volStdDev = MathStandardDeviation(volArr);
      
      double diffPct = ((double)tick_volume[i] - (double)tick_volume[i-1]) / (double)tick_volume[i-1];
      if(showChanges) {
         VolumeBuffer[i] = MathAbs(diffPct);
         AvgBuffer[i] = volAvg;
         StdDevBuffer[i] = volAvg + volStdDev;
         if (diffPct > 0) {
            ColorBuffer[i]=0;
         }
         else {
            ColorBuffer[i]=2;
         }
      }
      else {
         VolumeBuffer[i]=tick_volume[i];
         AvgBuffer[i] = MathMean(tempArr);
         StdDevBuffer[i] = AvgBuffer[i] + MathStandardDeviation(tempArr);
         
         ColorBuffer[i]=0;
         if (diffPct > 0) {
            if (diffPct > (volposAvg + volposStdDev)) {
               ColorBuffer[i] = 2;
            }
            else if (diffPct > volposAvg) {
               ColorBuffer[i] = 1;
            }
            else {
               ColorBuffer[i] = 0;
            }
         }
         else {
            if (-diffPct > (volnegAvg + volnegStdDev)) {
               ColorBuffer[i] = 2;
            }
            else if (-diffPct > volnegAvg) {
               ColorBuffer[i] = 1;
            }
            else {
               ColorBuffer[i] = 0;
            }
         }
      }
   }

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
