//+------------------------------------------------------------------+
//|                                                     screener.mqh |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"

#include <CommonIO.mqh>
#include <Generic\HashMap.mqh>
#include <Dvp.mqh>
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
datetime lastgaptime;
CKeyValuePair<string,datetime>lastGapTime;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int ScanGapAll(ENUM_TIMEFRAMES tf=PERIOD_M30)
  {
   ScanGap("EURUSD",tf);
   ScanGap("GBPUSD",tf);
   ScanGap("AUDUSD",tf);
   ScanGap("NZDUSD",tf);
   ScanGap("USDCHF",tf);
   ScanGap("USDJPY",tf);
   ScanGap("USDCAD",tf);
   ScanGap("EURGBP",tf);
   ScanGap("EURCHF",tf);
   ScanGap("EURAUD",tf);
   ScanGap("EURNZD",tf);
   ScanGap("EURJPY",tf);
   ScanGap("EURCAD",tf);
   ScanGap("GBPCHF",tf);
   ScanGap("GBPAUD",tf);
   ScanGap("GBPNZD",tf);
   ScanGap("GBPJPY",tf);
   ScanGap("GBPCAD",tf);
   ScanGap("AUDCHF",tf);
   ScanGap("AUDNZD",tf);
   ScanGap("AUDJPY",tf);
   ScanGap("AUDCAD",tf);
   ScanGap("NZDCHF",tf);
   ScanGap("NZDJPY",tf);
   ScanGap("NZDCAD",tf);
   ScanGap("CADCHF",tf);
   ScanGap("CADJPY",tf);
   ScanGap("CHFJPY",tf);
   return 0;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int ScanGap(string symbol,ENUM_TIMEFRAMES tf)
  {
   datetime dts[];
   MqlRates rates[];
   CopyTime(symbol, tf, 0, 100, dts);
   if(CopyRates(symbol,tf,0,2,rates)==2)
     {
      MqlTick tick;
      if(SymbolInfoTick(symbol,tick))
        {
         MqlDateTime dt1;
         MqlDateTime dt2;
         TimeToStruct(rates[0].time,dt1);
         TimeToStruct(rates[1].time,dt2);
         if(dt1.day_of_week!=0 && dt2.day_of_week!=1)
           {
            if(rates[0].open<rates[0].close && rates[1].open-rates[0].close>0.5*_Digits)
              {
               if(rates[1].time!=lastgaptime)
                 {
                  Alert("alert! we have gap up at ",rates[1].time);
                  lastgaptime=rates[1].time;
                  return 1;
                 }
              }
            if(rates[0].open<rates[0].close && rates[0].close-rates[1].open>0.5*_Digits)
              {
               if(rates[1].time!=lastgaptime)
                 {
                  Alert("alert! we have gap down at ",rates[1].time);
                  lastgaptime=rates[1].time;
                  return -1;
                 }
              }
           }
        }
     }
   return 0;
  }
//+------------------------------------------------------------------+
void ScanUnusualBuyingSelling()
  {

  }
//+------------------------------------------------------------------+
CHashMap<string, double> lastPocColl;

void ScanDvp(string symbol, ENUM_TIMEFRAMES timeframe)
{
   MqlRates rates[];
   DvpRates dvpRates[];
   if  (CopyRates(symbol, timeframe, 0, 420, rates) == 420)
   {
      int cnt = CalculateDvp(60, 100, 70, rates, dvpRates, symbol, false);
      for (int i=0; i<cnt; i++)
      {
         double lastPoc;
         lastPocColl.TryGetValue(symbol, lastPoc);
         int digit = SymbolInfoInteger(symbol, SYMBOL_DIGITS);
         int point = SymbolInfoDouble(symbol, SYMBOL_POINT);
         double poc = NormalizeDouble(dvpRates[i].Poc, digit-1);
         if(MathAbs(rates[cnt-1].close - dvpRates[i].Poc) <= 35*point && poc != lastPoc && MathAbs(poc - lastPoc) >= 50*point)
         {
            lastPocColl.TrySetValue(symbol, poc);
            Alert(symbol, ": we have price approaching poc ", poc);
         }
      }
   }
}