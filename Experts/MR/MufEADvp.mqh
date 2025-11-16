//+------------------------------------------------------------------+
//|                                                 MufEAInclude.mqh |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
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
#include <MR\Dvp.mqh>
#include "MufEAInclude.mqh"

datetime lastdvpsignaltime = 0;
DvpRates dvp[];
int dvpLength = 360; // 7.5 hari
int dvpPeriod = 60;
int dvpBars = 100;
int dvpVa = 70;

void calculateDvp()
{
   MqlRates rates[];
   CopyRates(Symbol(), PERIOD_M30, 0, dvpLength, rates);
   CalculateDvp(dvpPeriod, dvpBars, dvpVa, rates, dvp, Symbol(), false);
}

double CalculateCurrentDvp(ENUM_TIMEFRAMES tf, int period, int bars, int va, DvpRates &dvp[])
{
   MqlRates rates[];
   CopyRates(Symbol(), tf, 0, period, rates);
   CalculateDvp(dvpPeriod, dvpBars, dvpVa, rates, dvp, Symbol(), false);
   return dvp[ArraySize(dvp)-1].Poc;
}

void dvpSignal()
{
   datetime currTime = TimeCurrent();
   MqlDateTime currDT;
   TimeToStruct(currTime, currDT);
   if (ArraySize(dvp) == 0)
   {
      calculateDvp();
   }
   else if (currDT.min == 0 || currDT.min == 30)
   {
      calculateDvp();
   }
   MqlRates rates[];
   CopyRates(Symbol(), PERIOD_M1, 0, 1, rates);
   double price = rates[0].close;
   double point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
   int digit = (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);
   if (ArraySize(dvp) > 0)
   {
      for(int i=ArraySize(dvp)-1; i>=0; i--)
      {
         if (MathAbs(price - dvp[i].Poc) < 5*point)
         {
            if ((TimeCurrent() - lastdvpsignaltime) >= 15*60)
            {
               string content = StringFormat("%s is crossing pass POC. current price: %s, past POC: %s, %s",
                     Symbol(),
                     DoubleToString(price, digit),
                     DoubleToString(dvp[i].Poc, digit),
                     TimeToString(dvp[i].Time, TIME_DATE|TIME_MINUTES|TIME_SECONDS));
               writeSignal(content);
               lastdvpsignaltime = TimeCurrent();
            }
            break;
         }
      }
   }
}

void calculateVolume()
{
}