//+------------------------------------------------------------------+
//|                             YURAZ_CreaHistorCSVFromMT5forMT4.mq5 |
//|            Copyright 2010, MetaQuotes Software Corp. (C) & YURAZ |
//|                                            www.masterforex-v.org |
//+------------------------------------------------------------------+
//
// The script creates CSV file with M1 history for export to MetaTrader 4.
// Unfortunately, some of the history bars are absent in MetaTrader 4
// For example, some brokers doesn't have the history in 2010, May, July and August
// MetaTrader 5 hisotry has no such problems

#property copyright "Copyright 2010, MetaQuotes Software Corp. & (C) YURAZ"
#property link      "www.masterforex-v.org"
#property version   "1.00"
#include <Files\File.mqh>
#include <Files\FileTxt.mqh>
#include <Mr\Dvp.mqh>

string    ExtFileName; // ="XXXXXX_PERIOD.CSV";
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void  OnStart()
{
   //exportDvp();
   exportTick();
   Comment("Finish!!");
}
  
string flagToString(uint flag)
{
   switch(flag)
   {
      case TICK_FLAG_BID : return "BID";
      case TICK_FLAG_ASK : return "ASK";
      case TICK_FLAG_LAST : return "LAST";
      case TICK_FLAG_VOLUME : return "VOLUME";
      case TICK_FLAG_BUY : return "BUY";
      case TICK_FLAG_SELL : return "SELL";
      default : return flag;
   }
}

void readline()
{
   int fhandle = FileOpen("TradeCommand.txt", FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON);
   while(!FileIsEnding(fhandle))
   {
      string str = FileReadString(fhandle);
      Print(str);
   }
   FileClose(fhandle);
}

void exportTick()
{
   CFileTxt     File;
   MqlRates  rates_array[];
   string sSymbol=Symbol();
   string  sPeriod;

   Comment("Processing...");
// prepare file name, for example, EURUSD1
   ExtFileName=sSymbol;
   StringConcatenate(ExtFileName,sSymbol,".CSV");
   
   MqlTick tickArray[];
   
   //CopyTicks(sSymbol, tickArray, COPY_TICKS_ALL, 0, 200000);
   datetime startTime = D'2020.11.30 00:00:00';
   datetime endTime = D'2020.12.02 23:59:59';
   datetime currtime = TimeCurrent();
   //int res = CopyTicksRange(sSymbol, tickArray, COPY_TICKS_ALL, startTime*1000, endTime*1000);
   int res = CopyTicks(sSymbol, tickArray, COPY_TICKS_ALL, 0, 200000);
   if (res < 0)
   {
      Comment("Error");
      Print(res);
      Print(GetLastError());
      return;
   }
   
   Print(ExtFileName);
   File.Open(ExtFileName,FILE_WRITE|FILE_COMMON,9);
   string format="%s,%G,%G,%G,%G,%d,%s,%G";
   for(int i=0; i<ArraySize(tickArray); i++)
   {
      string strTime = TimeToString(tickArray[i].time,TIME_DATE);
      strTime = strTime + " " + TimeToString(tickArray[i].time,TIME_SECONDS);
      string strFlag = tickArray[i].flags; //flagToString(tickArray[i].flags);
      string sOut = StringFormat(format,
                                 strTime,
                                 tickArray[i].bid,
                                 tickArray[i].ask,
                                 tickArray[i].last,
                                 tickArray[i].volume,
                                 tickArray[i].time_msc,
                                 strFlag,
                                 tickArray[i].volume_real);
      sOut=sOut+"\n";
      File.WriteString(sOut);
   }
   File.Close();
   
//   datetime lastticktime = 0;
//   double lastsum = 0;
//   double lastcnt = 0;
//   double sum = 0;
//   double cnt = 0;
//   double avg = 0;
//   
//   for(int i=0; i<ArraySize(tickArray); i++)
//   {
//      if (tickArray[i].time != lastticktime)
//      {
//         sum = sum + lastcnt;
//         lastcnt = 1;
//         cnt = cnt + 1;
//         lastticktime = tickArray[i].time;
//      }
//      else 
//      {
//         lastcnt = lastcnt + 1;
//      }
//   }
//   sum = sum + lastcnt;
//   avg = sum / cnt;
//   readline();
}

void exportDvp()
{
   int dvpLength = 20 * 24 * 2;
   int dvpPeriod = 60;
   int dvpBars = 100;
   int dvpVa = 70;
   DvpRates dvp[];
   MqlRates rates[];
   CopyRates(Symbol(), PERIOD_M30, 0, dvpLength, rates);
   CalculateDvp(dvpPeriod, dvpBars, dvpVa, rates, dvp, Symbol(), false);
   
   CFileTxt File;
   File.Open(Symbol() + "_dvp.txt",FILE_WRITE,9);
   string format="%s, %s, %s, %s, %s, %s";
   for(int i=0; i<ArraySize(dvp); i++)
   {
      string sOut = StringFormat(format,
                                 TimeToString(dvp[i].Time, TIME_DATE|TIME_SECONDS),
                                 DoubleToString(dvp[i].Min, Digits()),
                                 DoubleToString(dvp[i].Max, Digits()),
                                 DoubleToString(dvp[i].Val, Digits()),
                                 DoubleToString(dvp[i].Vah, Digits()),
                                 DoubleToString(dvp[i].Poc, Digits()));
      sOut=sOut+"\n";
      File.WriteString(sOut);
   }
   File.Close();
}