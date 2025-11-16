//+------------------------------------------------------------------+
//|                                                    DvpHelper.mqh |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
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

#include <Arrays\ArrayObj.mqh>
#include "PriceTime.mqh"

class Dvp {
 private:
   int               dvpPeriod;
   int               dvpNRows;
   double            dvpPctValueArea;
   double            tfratio;
   ENUM_TIMEFRAMES   tfs[];

   int               getPriceLevel(double price,double min,double d,int nrow) {
      return MathMin(MathFloor((price-min)/d)+1, nrow);
   }

   ENUM_TIMEFRAMES   getLowerTF(ENUM_TIMEFRAMES tf) {
      for(int i=ArraySize(tfs)-1; i>=0; i--) {
         if (PeriodSeconds(tfs[i]) <= PeriodSeconds(tf)/tfratio) {
            return tfs[i];
         }
      }
      return tfs[0];
   }

   PriceTime*        calculatePoc(MqlRates &rates[]) {
      double prices[];
      long volumes[];
      int cnt = ArraySize(rates);
      ArrayResize(prices, cnt);
      ArrayResize(volumes, cnt);
      for(int j=0; j<cnt; j++) {
         prices[j] = rates[j].close;
         volumes[j] = rates[j].tick_volume;
      }

      double min = prices[ArrayMinimum(prices, 0, WHOLE_ARRAY)];
      double max = prices[ArrayMaximum(prices, 0, WHOLE_ARRAY)];
      double d=(max-min)/dvpNRows;
      if (d == 0) {
         string ex = "exception";
      }

      long totalVolume=0;
      long levelVolume[];
      ArrayResize(levelVolume,dvpNRows+1);
      ArrayFill(levelVolume,0,dvpNRows+1,0);
      for(int j=0; j<ArraySize(volumes); j++) {
         int lvl=getPriceLevel(prices[j],min,d,dvpNRows);
         levelVolume[lvl]+=volumes[j];
         totalVolume+=volumes[j];
      }

      long pocVol=0.0;
      int pocLevel=0;
      for(int j=1; j<=dvpNRows; j++) {
         long vol=levelVolume[j];
         if(vol>pocVol) {
            pocLevel=j;
            pocVol=vol;
         }
      }

      double valueArea=totalVolume*dvpPctValueArea/100;
      double val = 0.0;
      double vah = 0.0;
      long tempVol=levelVolume[pocLevel];
      for(int j=1; j<=dvpNRows; j++) {
         long v1 = pocLevel-j > 0 ? levelVolume[pocLevel-j] : 0;
         long v2 = pocLevel+j <= dvpNRows ? levelVolume[pocLevel+j] : 0;
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

      int currIndex = ArraySize(rates)-1;
      double pocPrice = NormalizeDouble(min + (pocLevel-0.5)*d, _Digits);
      datetime pocTime = rates[currIndex].time;
      PriceTime *pt = new PriceTime(pocPrice, pocTime);

      return pt;
   }

 public:
                     Dvp(int p_dvpPeriod = 60, int p_dvpNRows = 100, double p_dvpPctValueArea = 70.0, double p_tfratio = 12) {
      this.dvpPeriod = p_dvpPeriod;
      this.dvpNRows = p_dvpNRows;
      this.dvpPctValueArea = p_dvpPctValueArea;
      this.tfratio = p_tfratio;

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
   }

   CArrayObj*        GetPocList(string symbol, ENUM_TIMEFRAMES tf, datetime fromdate, int count) {
      CArrayObj *list = new CArrayObj(); // array of PriceTime
      ENUM_TIMEFRAMES lowerTf = getLowerTF(tf);
      int cnt = dvpPeriod * tfratio;

      datetime lastbartime = fromdate;
      if (lastbartime == 0) {
         lastbartime = SeriesInfoInteger(symbol, tf, SERIES_LASTBAR_DATE) - PeriodSeconds(tf);
      }
      MqlRates rates[];
      int copied = CopyRates(symbol,tf,lastbartime,count,rates);

      if (copied == count) {
         for(int i=0; i<ArraySize(rates); i++) {
            datetime starttime = rates[i].time;
            MqlRates lowerTfRates[];
            copied = CopyRates(symbol,lowerTf,starttime,cnt,lowerTfRates);
            if (copied == cnt) {
               double prices[];
               long volumes[];
               ArrayResize(prices, cnt);
               ArrayResize(volumes, cnt);
               for(int j=0; j<cnt; j++) {
                  prices[j] = lowerTfRates[j].close;
                  volumes[j] = lowerTfRates[j].tick_volume;
               }

               double min = prices[ArrayMinimum(prices, 0, WHOLE_ARRAY)];
               double max = prices[ArrayMaximum(prices, 0, WHOLE_ARRAY)];
               double d=(max-min)/dvpNRows;
               if (d == 0) {
                  string ex = "exception";
               }

               long totalVolume=0;
               long levelVolume[];
               ArrayResize(levelVolume,dvpNRows+1);
               ArrayFill(levelVolume,0,dvpNRows+1,0);
               for(int j=0; j<ArraySize(volumes); j++) {
                  int lvl=getPriceLevel(prices[j],min,d,dvpNRows);
                  levelVolume[lvl]+=volumes[j];
                  totalVolume+=volumes[j];
               }

               long pocVol=0.0;
               int pocLevel=0;
               for(int j=1; j<=dvpNRows; j++) {
                  long vol=levelVolume[j];
                  if(vol>pocVol) {
                     pocLevel=j;
                     pocVol=vol;
                  }
               }

               double valueArea=totalVolume*dvpPctValueArea/100;
               double val = 0.0;
               double vah = 0.0;
               long tempVol=levelVolume[pocLevel];
               for(int j=1; j<=dvpNRows; j++) {
                  long v1 = pocLevel-j > 0 ? levelVolume[pocLevel-j] : 0;
                  long v2 = pocLevel+j <= dvpNRows ? levelVolume[pocLevel+j] : 0;
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

               double pocPrice = NormalizeDouble(min + (pocLevel-0.5)*d, _Digits);
               datetime pocTime = rates[i].time;
               PriceTime *pt = new PriceTime(pocPrice, pocTime);

               list.Add(pt);
            } else {
               double pocPrice = 0;
               datetime pocTime = rates[i].time;
               PriceTime *pt = new PriceTime(pocPrice, pocTime);
               list.Add(pt);
               printf("rates data not available");
            }
         }
      } else if (copied == -1) {
         int errcode = GetLastError();
         printf("an error occured during copyrates: %i", errcode);
         return NULL;
      } else {
         printf("rates data not available");
         return NULL;
      }
      return list;
   }

   CArrayObj*        GetPocList(MqlRates &rates[]) {
      CArrayObj *list = new CArrayObj(); // array of PriceTime

      for(int i=0; i<ArraySize(rates); i++) {
         if (i < dvpPeriod) {
            continue;
         }
         
         double prices[];
         long volumes[];
         ArrayResize(prices, dvpPeriod);
         ArrayResize(volumes, dvpPeriod);
         int k = 0;
         for(int j=i-dvpPeriod; j<i; j++) {
            prices[k] = rates[j].close;
            volumes[k] = rates[j].tick_volume;
            k++;
         }

         double min = prices[ArrayMinimum(prices, 0, WHOLE_ARRAY)];
         double max = prices[ArrayMaximum(prices, 0, WHOLE_ARRAY)];
         double d=(max-min)/dvpNRows;
         if (d == 0) {
            string ex = "exception";
         }

         long totalVolume=0;
         long levelVolume[];
         ArrayResize(levelVolume,dvpNRows+1);
         ArrayFill(levelVolume,0,dvpNRows+1,0);
         for(int j=0; j<ArraySize(volumes); j++) {
            int lvl=getPriceLevel(prices[j],min,d,dvpNRows);
            levelVolume[lvl]+=volumes[j];
            totalVolume+=volumes[j];
         }

         long pocVol=0.0;
         int pocLevel=0;
         for(int j=1; j<=dvpNRows; j++) {
            long vol=levelVolume[j];
            if(vol>pocVol) {
               pocLevel=j;
               pocVol=vol;
            }
         }

         double valueArea=totalVolume*dvpPctValueArea/100;
         double val = 0.0;
         double vah = 0.0;
         long tempVol=levelVolume[pocLevel];
         for(int j=1; j<=dvpNRows; j++) {
            long v1 = pocLevel-j > 0 ? levelVolume[pocLevel-j] : 0;
            long v2 = pocLevel+j <= dvpNRows ? levelVolume[pocLevel+j] : 0;
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

         double pocPrice = NormalizeDouble(min + (pocLevel-0.5)*d, _Digits);
         datetime pocTime = rates[i].time;
         PriceTime *pt = new PriceTime(pocPrice, pocTime);

         list.Add(pt);
      }
      return list;
   }
};
//+------------------------------------------------------------------+
