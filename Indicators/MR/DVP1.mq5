//+------------------------------------------------------------------+
//|                                                         DVP1.mq5 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   4
//-- filling color
#property indicator_label1  "Filling"
#property indicator_type1   DRAW_FILLING
#property indicator_color1  clrDarkGreen
#property indicator_width1  1
//--- plot VAH
#property indicator_label2  "VAH"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrWhiteSmoke
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- plot VAL
#property indicator_label3  "VAL"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrWhiteSmoke
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
//--- plot POC
#property indicator_label4  "POC"
#property indicator_type4  DRAW_LINE
#property indicator_color4  clrBlue
#property indicator_style4  DRAW_LINE
#property indicator_width4  1
//--- input parameters
input int      inpPeriod= 60;
input int      inpNRows = 100;
input double   inpPctValueArea=70;
input bool     showValueArea = true;
//--- indicator buffers
double         POCBuffer[];
double         VAHBuffer[];
double         VALBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//--- indicator buffers mapping
   SetIndexBuffer(0,VAHBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,VALBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,POCBuffer,INDICATOR_DATA);
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

   for(int i=pos; i<rates_total && !IsStopped(); i++) {
      //MqlRates rates[];
      //int copied=CopyRates(Symbol(),PERIOD_M1,0,30*inpPeriod,rates);

      double prices[];
      long volumes[];
      ArrayCopy(prices,close,0,i-inpPeriod+1,inpPeriod);
      ArrayCopy(volumes,tick_volume,0,i-inpPeriod+1,inpPeriod);
      double min = prices[ArrayMinimum(prices, 0, inpPeriod)];
      double max = prices[ArrayMaximum(prices, 0, inpPeriod)];
      double d=(max-min)/inpNRows;

      long totalVolume=0;
      long levelVolume[];
      ArrayResize(levelVolume,inpNRows+1);
      ArrayFill(levelVolume,0,inpNRows+1,0);
      for(int j=0; j<inpPeriod; j++) {
         int lvl=getPriceLevel(prices[j],min,d,inpNRows);
         levelVolume[lvl]+=volumes[j];
         totalVolume+=volumes[j];
      }

      long pocVol=0.0;
      int pocLevel=0;
      for(int j=1; j<=inpNRows; j++) {
         long vol=levelVolume[j];
         if(vol>pocVol) {
            pocLevel=j;
            pocVol=vol;
         }
      }

      double valueArea=totalVolume*inpPctValueArea/100;
      double val = 0.0;
      double vah = 0.0;
      long tempVol=levelVolume[pocLevel];
      for(int j=1; j<=inpNRows; j++) {
         long v1 = pocLevel-j > 0 ? levelVolume[pocLevel-j] : 0;
         long v2 = pocLevel+j <= inpNRows ? levelVolume[pocLevel+j] : 0;
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

      POCBuffer[i] = NormalizeDouble(min + (pocLevel-0.5)*d, _Digits);
      if (showValueArea) {
         VALBuffer[i] = NormalizeDouble(val, _Digits);
         VAHBuffer[i] = NormalizeDouble(vah, _Digits);
      }
   }

//--- return value of prev_calculated for next call
   return(rates_total);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int getPriceLevel(double price,double min,double d,int nrow) {
   return MathMin(MathFloor((price-min)/d)+1, nrow);
}
//+------------------------------------------------------------------+
