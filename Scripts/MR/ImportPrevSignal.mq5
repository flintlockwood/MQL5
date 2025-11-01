//+------------------------------------------------------------------+
//|                                             ImportPrevSignal.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Files\File.mqh>
#include <Files\FileTxt.mqh>
#include <MR\Array.mqh>
#include <Math\Stat\Math.mqh>
#include <Generic\HashMap.mqh>
#include <Generic\ArrayList.mqh>
#include "..\..\Experts\MR\MufEAInclude.mqh"
#include "..\..\Experts\MR\MufEADvp.mqh"
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+

double sth = 10*_Point;
double vth = 10;
double spreadth = 35*_Point;
int scount = 0;

void OnStart()
{
//---
   Comment("Processing...");
   
   ObjectsDeleteAll(0, "Signal*");
   
   MqlTick tickArray[];
   int res = CopyTicks(Symbol(), tickArray, COPY_TICKS_ALL, 0, 500000);
   //int res = CopyTicks(Symbol(), tickArray, COPY_TICKS_ALL, D'2021.01.22 18:00:00', D'2021.01.22 18:01:00');
   if (res < 0)
   {
      Comment("Error getting ticks");
      Print(res);
      Print(GetLastError());
      return;
   }
   
   // calculate slippage treshold
   sth = calcSlippageTH(tickArray);
   // calculate volume theshold
   CHashMap<datetime, double> hmTicks;
   vth = calcVolumeTH(tickArray, hmTicks);
   
   // find slippage
   findSlippage(tickArray);
   // find unusual volume activity
   findUnusualVolume(tickArray, hmTicks);
   
   writeToFile(tickArray);
   Comment(StringFormat("Finish... \r\nsth:%s vth:%s, spth:%s", DoubleToString(sth, Digits()), DoubleToString(vth, Digits()), DoubleToString(spreadth, Digits())));
   //while(!IsStopped())
   //{
   //}
}
//+------------------------------------------------------------------+
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

void findSlippage(MqlTick &ticks[])
{
   double prevbid = 0;
   double prevask = 0;
   datetime prevtime = 0;
   for(int i=0; i<ArraySize(ticks); i++)
   {
      MufTick mtick;
      mtick.time = ticks[i].time;
      mtick.bid = ticks[i].bid;
      mtick.ask = ticks[i].ask;
      mtick.last = ticks[i].last;
      mtick.volume = ticks[i].volume;
      mtick.time_msc = ticks[i].time_msc;
      mtick.flags = ticks[i].flags;
      mtick.volume_real = ticks[i].volume_real;
      mtick.prevtime = prevtime;
      mtick.prevbid = prevbid;
      mtick.prevask = prevask;
      mtick.slippage_treshold = sth;
      mtick.spread_treshold = spreadth;
      
      if (mtick.BuySlippage()) 
      {
         MSignal signal;
         signal.signalType = BUY_SLIPPAGE;
         signal.Time = mtick.time;
         signal.Sym = Symbol();
         signal.Price = mtick.ask;
         signal.BidChanges = mtick.BidChanges();
         signal.AskChanges = mtick.AskChanges();
         signal.Spread = mtick.Spread();
         double poc = CalculateCurrentDvp(PERIOD_M30, 60, 100, 70);
         signal.Poc = poc;
         signal.comment = MathAbs(signal.Price - signal.Poc) <= 15 * Point() ? "Confirmed by poc" : "";
         
         string name = StringFormat("Signal #%i %s", scount, signal.SignalName());
         string comment = signal.ToString();
         ObjectCreate(0, name, OBJ_ARROW_BUY, 0, mtick.time, mtick.AvgPrice());
         ObjectSetInteger(0, name, OBJPROP_COLOR, clrGreen);
         ObjectSetString(0, name, OBJPROP_TEXT, comment);
         scount++;
      }
      else if (mtick.SellSlippage())
      {
         MSignal signal;
         signal.signalType = SELL_SLIPPAGE;
         signal.Time = mtick.time;
         signal.Sym = Symbol();
         signal.Price = mtick.bid;
         signal.BidChanges = mtick.BidChanges();
         signal.AskChanges = mtick.AskChanges();
         signal.Spread = mtick.Spread();
         double poc = CalculateCurrentDvp(PERIOD_M30, 60, 100, 70);
         signal.Poc = poc;
         signal.comment = MathAbs(signal.Price - signal.Poc) <= 15 * Point() ? "Confirmed by poc" : "";
         
         string name = StringFormat("Signal #%i %s", scount, signal.SignalName());
         string comment = signal.ToString();
         ObjectCreate(0, name, OBJ_ARROW_SELL, 0, mtick.time, mtick.AvgPrice());
         ObjectSetInteger(0, name, OBJPROP_COLOR, clrRed);
         ObjectSetString(0, name, OBJPROP_TEXT, comment);
         scount++;
      }
      prevbid = ticks[i].bid;
      prevask = ticks[i].ask;
      prevtime = ticks[i].time;
   }
}

double calcVolumeTH(MqlTick &ticks[], CHashMap<datetime, double> &hmTicks)
{
   double spreads[];
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
   spreadth = NormalizeDouble(avg + sd, Digits());
   return vth;
}

void findUnusualVolume(MqlTick &ticks[], CHashMap<datetime, double> &hmTicks)
{
   datetime lastticktime = 0;
   double sumprice = 0;
   for(int i=0; i<ArraySize(ticks); i++)
   {
      if (ticks[i].time != lastticktime)
      {
         double v;
         hmTicks.TryGetValue(lastticktime, v);
         if (v >= vth)
         {           
            MSignal signal;
            signal.signalType = NEUTRAL_UNUSUAL_VOLUME;
            signal.Time = lastticktime;
            signal.Sym = Symbol();
            signal.Price = sumprice/v;
            signal.totalCount = v;
         
            string name = StringFormat("Signal #%i %s", scount, signal.SignalName());
            string comment = signal.ToString();
            ENUM_OBJECT type = signal.SignalArrowType();
            long clr = signal.SignalColor();
            ObjectCreate(0, name, type, 0, signal.Time, signal.Price);
            ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
            ObjectSetString(0, name, OBJPROP_TEXT, comment);
            scount++;
         }
         sumprice = 0;
      }
      sumprice = sumprice + ticks[i].bid+(ticks[i].ask-ticks[i].bid)/2;
      lastticktime = ticks[i].time;
   }
}

void writeToFile(MqlTick &tickArray[])
{
   CFileTxt     File;
   ResetLastError();
   string documentRoot = "";
   string filepath = documentRoot + "test.csv";
   //File.Open(documentRoot + "import_script_" + Symbol() + "_ticks.csv",FILE_WRITE,9);
   File.Open(filepath,FILE_WRITE|FILE_COMMON,9);
   if (GetLastError() > 0) {
      PrintFormat("error with code: %i", GetLastError());
   }
   datetime prevtime = 0;
   double prevbid = 0;
   double prevask = 0;
   for(int i=0; i<ArraySize(tickArray); i++)
   {
      MufTick mtick;
      mtick.time = tickArray[i].time;
      mtick.bid = tickArray[i].bid;
      mtick.ask = tickArray[i].ask;
      mtick.last = tickArray[i].last;
      mtick.volume = tickArray[i].volume;
      mtick.time_msc = tickArray[i].time_msc;
      mtick.flags = tickArray[i].flags;
      mtick.volume_real = tickArray[i].volume_real;
      mtick.prevtime = prevtime;
      mtick.prevbid = prevbid;
      mtick.prevask = prevask;
      string str = mtick.ToString();
      string typ = mtick.TickType();
      bool slip = mtick.Slippage();
      
      prevtime = tickArray[i].time;
      prevbid = tickArray[i].bid;
      prevask = tickArray[i].ask;
      
      string sOut = mtick.ToString()+"\n";
      File.WriteString(sOut);
   }
   File.Close();
}

void onTick(MqlTick &tick)
{
}
