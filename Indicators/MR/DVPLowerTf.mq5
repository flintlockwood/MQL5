//+------------------------------------------------------------------+
//|                                                   DVPLowerTf.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
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
input double   tfratio = 12;
//--- indicator buffers
double         POCBuffer[];
double         VAHBuffer[];
double         VALBuffer[];
ENUM_TIMEFRAMES tfs[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//--- indicator buffers mapping
   SetIndexBuffer(0,VAHBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,VALBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,POCBuffer,INDICATOR_DATA);
   
   ArrayResize(tfs, 21);
   tfs[0] = PERIOD_M1;
   tfs[1] = PERIOD_M2;
   tfs[2] = PERIOD_M3;
   tfs[3] = PERIOD_M4;
   tfs[4] = PERIOD_M5;
   tfs[5] = PERIOD_M6;
   tfs[6] = PERIOD_M10;
   tfs[7] = PERIOD_M12;
   tfs[8] = PERIOD_M15;
   tfs[9] = PERIOD_M20;
   tfs[10] = PERIOD_M30;
   tfs[11] = PERIOD_H1;
   tfs[12] = PERIOD_H2;
   tfs[13] = PERIOD_H3;
   tfs[14] = PERIOD_H4;
   tfs[15] = PERIOD_H6;
   tfs[16] = PERIOD_H8;
   tfs[17] = PERIOD_H12;
   tfs[18] = PERIOD_D1;
   tfs[19] = PERIOD_W1;
   tfs[20] = PERIOD_MN1;
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
      ENUM_TIMEFRAMES lowerTf = getLowerTF(tfratio);
      datetime starttime = time[i];
      int cntBars = PeriodSeconds(PERIOD_CURRENT) / PeriodSeconds(lowerTf);
      int cnt = inpPeriod * cntBars;
      MqlRates rates[];
      int copied = CopyRates(Symbol(),lowerTf,starttime,cnt,rates);
      
      if (ArraySize(rates) < cntBars) {
         printf("rates data not available starttime: %s", TimeToString(starttime, TIME_DATE|TIME_MINUTES));
         continue;
      }
      
      if (copied == cnt) {
         double prices[];
         long volumes[];
         ArrayResize(prices, ArraySize(rates));
         ArrayResize(volumes, ArraySize(rates));
         for(int j=0; j<ArraySize(rates); j++) {
            prices[j] = rates[j].close;
            volumes[j] = rates[j].tick_volume;
         }
         
         double min = prices[ArrayMinimum(prices, 0, WHOLE_ARRAY)];
         double max = prices[ArrayMaximum(prices, 0, WHOLE_ARRAY)];
         double d=(max-min)/inpNRows;
         if (d == 0) {
            string ex = "exception";
         }
   
         long totalVolume=0;
         long levelVolume[];
         ArrayResize(levelVolume,inpNRows+1);
         ArrayFill(levelVolume,0,inpNRows+1,0);
         for(int j=0; j<ArraySize(volumes); j++) {
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
         else {
            VALBuffer[i] = 0;
            VAHBuffer[i] = 0;
         }
      }
      else {
         printf("warning copyrates data not available starttime: %s", TimeToString(starttime, TIME_DATE|TIME_MINUTES));
         POCBuffer[i] = 0;
         VALBuffer[i] = 0;
         VAHBuffer[i] = 0;
      }      
   }

//--- return value of prev_calculated for next call
   return(rates_total);
}
//+------------------------------------------------------------------+
int getPriceLevel(double price,double min,double d,int nrow) {
   return MathMin(MathFloor((price-min)/d)+1, nrow);
}
//+------------------------------------------------------------------+
ENUM_TIMEFRAMES getLowerTF(double tfratio) {
   for(int i=ArraySize(tfs)-1; i>=0; i--) {
      if (PeriodSeconds(tfs[i]) <= PeriodSeconds(PERIOD_CURRENT)/tfratio) {
         return tfs[i];
      }
   }
   return tfs[0];
}
