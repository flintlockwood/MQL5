//+------------------------------------------------------------------+
//|                                                   ExportBars.mq5 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property script_show_inputs

#include <Files\File.mqh>
#include <Files\FileTxt.mqh>
//--- input parameters
input int      NumberOfBar;
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
//---
   exportBars();
   Comment("Finish!!");
}
//+------------------------------------------------------------------+

void exportBars()
{
   CFileTxt     File;
   MqlRates  rates_array[];
   string sSymbol=Symbol();
   string sPeriod = EnumToString(PERIOD_CURRENT);

   Comment("Processing...");
// prepare file name, for example, EURUSD1
   string filepath = StringFormat("%s_%s.csv", sSymbol, sPeriod);
   
   long n = NumberOfBar == 0 ? 1000: NumberOfBar;
   int res = CopyRates(Symbol(), PERIOD_CURRENT, 0, n, rates_array);
   if (res < 0)
   {
      Comment("Error");
      Print(res);
      Print(GetLastError());
      return;
   }
   
   File.Open(filepath,FILE_WRITE|FILE_COMMON,9);
   string format="%s,%s,%s,%s,%s,%i,%i";
   for(int i=0; i<ArraySize(rates_array); i++)
   {
      string sOut = StringFormat(format,
                                 TimeToString(rates_array[i].time, TIME_DATE|TIME_SECONDS),
                                 DoubleToString(rates_array[i].open, Digits()),
                                 DoubleToString(rates_array[i].high, Digits()),
                                 DoubleToString(rates_array[i].low, Digits()),
                                 DoubleToString(rates_array[i].close, Digits()),
                                 rates_array[i].tick_volume,
                                 rates_array[i].real_volume);
      sOut=sOut+"\n";
      File.WriteString(sOut);
   }
   File.Close();
}