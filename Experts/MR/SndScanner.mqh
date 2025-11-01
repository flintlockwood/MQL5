//+------------------------------------------------------------------+
//|                                                  SignalCheck.mqh |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
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

#include "Common.mqh";
#include "CIsNewBar.mqh";

CIsNewBar inbM15;
CIsNewBar inbM30;
CIsNewBar inbH1;
CIsNewBar inbCurrent;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int scanSnd(ENUM_TIMEFRAMES tf, int period, int avgPeriod, double &keyLevel[]) {
   MqlRates rates[];
   CopyRates(_Symbol, tf, 1, period+avgPeriod, rates);
   
   double arrOpen[];
   double arrHigh[];
   double arrLow[];
   double arrClose[];
   double arrRange[];
   for (int i=avgPeriod-1; i<ArraySize(rates); i++) {
      for(int j=i-avgPeriod+1; j<=i; j++) {
         arrOpen[i] = rates[j].open;
         arrHigh[i] = rates[j].high;
         arrLow[i] = rates[j].low;
         arrClose[i] = rates[j].close;
         arrRange[i] = rates[j].high - rates[j].low;
      }
      double rangeMean = MathMean(arrRange);
      double rangeSd = MathStandardDeviation(arrRange);
      
   }
   return 0;
}