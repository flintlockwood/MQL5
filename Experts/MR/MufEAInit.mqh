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
#include <Math\Stat\Math.mqh>
#include <Generic\HashMap.mqh>
#include <MR\Array.mqh>
#include "SignalClass.mqh"

bool initialize = false;
datetime lastinittime = 0;
int nticks = 250000;
double volumeTreshold = 10;
double slippageTreshold = 10*_Point;
double spreadTreshold = 35*_Point;
int initPeriod = 3600;

void EAinit()
{
   datetime t = TimeCurrent();
   if (TimeCurrent() - lastinittime <= initPeriod)
   {
      return;
   }

   MqlTick ticks[];
   int n = CopyTicks(Symbol(), ticks, COPY_TICKS_ALL, 0, nticks);
   if (n == nticks)
   {
      Comment("Initialiazing...");
      //slippageTreshold = calcSlippageTH(ticks);
      //volumeTreshold = calcVolumeTH(ticks);
      //writeToFile(ticks);
      
      //Comment(StringFormat("sth:%s vth:%s spth:", 
      //                      DoubleToString(slippageTreshold,Digits()), 
      //                      DoubleToString(volumeTreshold, Digits())),
      //                      DoubleToString(spreadTreshold, Digits()));
      initialize = true;
      lastinittime = TimeCurrent();
   }
}

double calcSlippageTH(MqlTick &ticks[])
{
   double changes[];
   double prevbid = 0;
   double prevask = 0;
   ArrayResize(changes, ArraySize(ticks)*2);
   for(int i=0; i<ArraySize(ticks); i=i+2)
   {
      if (prevbid > 0 && prevask > 0) 
      {
         changes[i] = NormalizeDouble(MathAbs(ticks[i].bid - prevbid), Digits());
         changes[i+1] = NormalizeDouble(MathAbs(ticks[i].ask - prevask), Digits());
      }
      prevbid = ticks[i].bid;
      prevask = ticks[i].ask;
   }
   double sd = MathStandardDeviation(changes);
   double avg = MathMean(changes);
   double sth = NormalizeDouble(avg + sd*7, Digits());
   return sth;
}

double calcVolumeTH(MqlTick &ticks[])
{
   double spreads[];
   CHashMap<datetime, double> hmTicks;
   for(int i=0; i<ArraySize(ticks); i++)
   {
      if (hmTicks.ContainsKey(ticks[i].time))
      {
         double val;
         hmTicks.TryGetValue(ticks[i].time, val);
         val++;
         hmTicks.TrySetValue(ticks[i].time, val);
      }
      else 
      {
         hmTicks.Add(ticks[i].time, 1);
      }
      ArrayResize(spreads, ArraySize(spreads)+1, 1000);
      spreads[ArraySize(spreads)-1] = NormalizeDouble(ticks[i].ask - ticks[i].bid, Digits());
   }
   datetime dts[];
   double tc[];
   hmTicks.CopyTo(dts, tc);
   double avg = MathMean(tc);
   double sd = MathStandardDeviation(tc);
   double vth = NormalizeDouble(avg + sd*7, Digits());
   // spread treshold calculation
   avg = MathMean(spreads);
   sd = MathStandardDeviation(spreads);
   spreadTreshold = NormalizeDouble(avg + sd, Digits());
   return floor(vth);
}

void writeToFile(MqlTick &ticks[])
{
   int fhandle = FileOpen(Symbol() + "_ticks.txt", FILE_READ|FILE_WRITE|FILE_CSV|FILE_COMMON);
   for(int i=0; i<ArraySize(ticks); i++)
   {
      string strTime = TimeToString(ticks[i].time,TIME_DATE|TIME_SECONDS);
      string strFlag = ticks[i].flags;
      string format="%s, %s, %s, %s, %G, %d, %i, %G";
      string sOut = StringFormat(format,
                                 strTime,
                                 DoubleToString(ticks[i].bid, Digits()),
                                 DoubleToString(ticks[i].ask, Digits()),
                                 DoubleToString(ticks[i].last, Digits()),
                                 ticks[i].volume,
                                 ticks[i].time_msc,
                                 strFlag,
                                 ticks[i].volume_real);
      FileWrite(fhandle, sOut);
   }
   FileFlush(fhandle);
   FileClose(fhandle);
}
