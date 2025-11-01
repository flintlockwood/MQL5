//+------------------------------------------------------------------+
//|                                                  Correlation.mq5 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <MR\Array.mqh>
#include <Math\Stat\Math.mqh>

TArrayStack<MqlTick> eurusdTicks(1000);
TArrayStack<MqlTick> gbpusdTicks(1000);
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetTimer(1);
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   int nTicks = 10000;
   MqlTick eurusdTempTicks[];
   int n = CopyTicks("EURUSD", eurusdTempTicks, COPY_TICKS_ALL, 0, nTicks);
   MqlTick gbpusdTempTicks[];
   int m = CopyTicks("USDCAD", gbpusdTempTicks, COPY_TICKS_ALL, 0, nTicks);
   
   double eurusdPrice[];
   ArrayResize(eurusdPrice, nTicks);
   double gbpusdPrice[];
   ArrayResize(gbpusdPrice, nTicks);
   if(n == nTicks && m == nTicks)
   {
      for(int i=0; i<ArraySize(eurusdTempTicks)-1; i++)
      {
         double midPrice = eurusdTempTicks[i].bid + (eurusdTempTicks[i].ask - eurusdTempTicks[i].bid) / 2;
         eurusdPrice[i] = midPrice;
      }
      for(int i=0; i<ArraySize(gbpusdTempTicks)-1; i++)
      {
         double midPrice = gbpusdTempTicks[i].bid + (gbpusdTempTicks[i].ask - gbpusdTempTicks[i].bid) / 2;
         gbpusdPrice[i] = midPrice;
      }
   }
   //writeTicks(eurusdTempTicks, gbpusdTempTicks);
   
   double cr = 0;
   double cr2 = 0;
   double cr3 = 0;
   //bool res = MathCorrelationPearson(eurusdPrice, gbpusdPrice, cr);
   bool res2 = MathCorrelationSpearman(eurusdPrice, gbpusdPrice, cr2);
   //bool res3 = MathCorrelationKendall(eurusdPrice, gbpusdPrice, cr3);
   cr = NormalizeDouble(cr, 8);
   double lastPrice1 = eurusdPrice[ArraySize(eurusdPrice)-2];
   double lastPrice2 = gbpusdPrice[ArraySize(gbpusdPrice)-2];
   writeToFile(StringFormat("%s,%s,%s,%s", 
                             TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS),
                             DoubleToString(lastPrice1, Digits()),
                             DoubleToString(lastPrice2, Digits()),
                             DoubleToString(cr2, 8)));
  }
//+------------------------------------------------------------------+

void writeToFile(string content)
{
   int fhandle = FileOpen("Correlation.txt", FILE_READ|FILE_WRITE|FILE_CSV|FILE_COMMON);
   FileSeek(fhandle, 0, SEEK_END);
   FileWrite(fhandle, content);
   FileFlush(fhandle);
   FileClose(fhandle);
}

void writeTicks(MqlTick &tick1[], MqlTick &tick2[])
{
   int fhandle = FileOpen("ticks.txt", FILE_READ|FILE_WRITE|FILE_CSV|FILE_COMMON);
   FileSeek(fhandle, 0, SEEK_END);
   for(int i=0; i<ArraySize(tick1); i++)
   {
      string content = StringFormat("%s,%s,%s,%s",
                                    DoubleToString(tick1[i].bid, Digits()),
                                    DoubleToString(tick1[i].ask, Digits()),
                                    DoubleToString(tick2[i].bid, Digits()),
                                    DoubleToString(tick2[i].ask, Digits()));
      FileWrite(fhandle, content);
   }
   FileFlush(fhandle);
   FileClose(fhandle);
}