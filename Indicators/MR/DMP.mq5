//+------------------------------------------------------------------+
//|                                             CSPatternWithDVP.mq5 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   2

////--- plot VAH
//#property indicator_label2  "VAH"
//#property indicator_type2   DRAW_LINE
//#property indicator_color2  clrWhiteSmoke
//#property indicator_style2  STYLE_SOLID
//#property indicator_width2  1
////--- plot VAL
//#property indicator_label3  "VAL"
//#property indicator_type3   DRAW_LINE
//#property indicator_color3  clrWhiteSmoke
//#property indicator_style3  STYLE_SOLID
//#property indicator_width3  1
//--- plot POC
#property indicator_label1  "POC"
#property indicator_type1  DRAW_LINE
#property indicator_color1  clrWhite
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//-- filling color
#property indicator_label16 "VAH;VAL"
#property indicator_type16  DRAW_FILLING
#property indicator_color16 clrDarkGreen

#include <MR\Dvp.mqh>
#include <Math\Stat\Math.mqh>

//--- input parameters
input int      inpPeriod             = 60;
input int      inpNRows              = 100;
input double   inpPctValueArea       = 70.0;
input bool     showValueArea         = true;
input bool     showPoc               = true;

//--- indicator buffers
double         POCBuffer[];
double         VAHBuffer[];
double         VALBuffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//--- indicator buffers mapping
   SetIndexBuffer(0,POCBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,VAHBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,VALBuffer,INDICATOR_DATA);
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
   if(rates_total<=inpPeriod)
      return(0);

//--- preliminary calculations
   int pos=prev_calculated;
   if(pos<=inpPeriod) {
      for(int i=0; i<inpPeriod; i++) {
         POCBuffer[i]=0.0;
         VAHBuffer[i]=0.0;
         VALBuffer[i]=0.0;
      }
      pos=inpPeriod-1;
   }

   for(int i=pos-3; i<rates_total && !IsStopped(); i++) {
      VAHBuffer[i] = EMPTY_VALUE;
      VALBuffer[i] = EMPTY_VALUE;
      POCBuffer[i] = EMPTY_VALUE;

      // calculate DMP
      double highs[];
      double lows[];
      long volumes[];
      ArrayCopy(highs,high,0,i-inpPeriod+1,inpPeriod);
      ArrayCopy(lows,low,0,i-inpPeriod+1,inpPeriod);
      ArrayCopy(volumes,tick_volume,0,i-inpPeriod+1,inpPeriod);
      DvpRates dvp;
      getCurrDVP(inpPeriod, inpNRows, inpPctValueArea, highs, lows, dvp);
      dvp.Time = time[i];
      if (showValueArea) {
         VALBuffer[i] = dvp.Val;
         VAHBuffer[i] = dvp.Vah;
      }
      if (showPoc) {
         POCBuffer[i] = dvp.Poc;
      }
   }
//--- return value of prev_calculated for next call
   return(rates_total);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void getCurrDVP(int period, int nrow, double vapct, double &highs[], double &lows[], DvpRates &dvp) {
   if (ArraySize(highs) != period || ArraySize(lows) != period) {
      return;
   }

   double min = lows[ArrayMinimum(lows, 0, period)];
   double max = highs[ArrayMaximum(highs, 0, period)];
   double d=(max-min)/nrow;

   long totalVolume=0;
   long levelVolume[];
   ArrayResize(levelVolume,nrow+1);
   ArrayFill(levelVolume,0,nrow+1,0);
   for(int i=0; i<period; i++) {
      for(int j=1; j<=nrow; j++) {
         double levelMin = min + d*(j-1);
         double levelMax = min + d*j;
         if (lows[i] < levelMax && highs[i] >= levelMin) {
            levelVolume[j] = levelVolume[j] + 1;
            totalVolume = totalVolume + 1;
         }
         
      }
   }

   long pocVol=0.0;
   int pocLevel=0;
   for(int j=1; j<=nrow; j++) {
      long vol=levelVolume[j];
      if(vol>pocVol) {
         pocLevel=j;
         pocVol=vol;
      }
   }

   double valueArea=totalVolume*vapct/100;
   double val = 0.0;
   double vah = 0.0;
   long tempVol=levelVolume[pocLevel];
   for(int j=1; j<=nrow; j++) {
      long v1 = pocLevel-j > 0 ? levelVolume[pocLevel-j] : 0;
      long v2 = pocLevel+j <= nrow ? levelVolume[pocLevel+j] : 0;
      tempVol = tempVol + v1 + v2;
      if(tempVol>=valueArea) {
         val = v1==0 ? min : min+(pocLevel-j-1)*d;
         vah = v2==0 ? max : min+(pocLevel+j)*d;
         break;
      }
   }

   if(val==0 && vah==0) {
      val = min;
      vah = max;
   }

   dvp.Poc = NormalizeDouble(min + (pocLevel-0.5)*d, _Digits);
   dvp.Val = NormalizeDouble(val, _Digits);
   dvp.Vah = NormalizeDouble(vah, _Digits);
}
