//+------------------------------------------------------------------+
//|                                                 ExportZigZag.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Files\File.mqh>
#include <Files\FileTxt.mqh>

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart() {
//---
   CFileTxt     File;
   string sSymbol=Symbol();
   string sPeriod = EnumToString(PERIOD_CURRENT);

   Comment("Processing...");
// prepare file name, for example, EURUSD1
   string filepath = StringFormat("zigzag_%s_%s.csv", sSymbol, sPeriod);

   int handle = iCustom(Symbol(), PERIOD_CURRENT, "Examples\\ZigZag", 12, 5, 3);
   double zigzagBuffer[];
   CopyBuffer(handle, 0, 0, iBars(_Symbol, PERIOD_CURRENT), zigzagBuffer);
   if (handle == INVALID_HANDLE) {
      Comment("Error");
      Print(handle);
      Print(GetLastError());
      return;
   }
   
   datetime timeBuffer[];
   CopyTime(_Symbol, PERIOD_CURRENT, 0, iBars(_Symbol, PERIOD_CURRENT), timeBuffer);

   File.Open(filepath,FILE_WRITE|FILE_COMMON,9);
   double prevswing = 0;
   double currswing = 0;
   int nbar = 0;
   string format="%s,%s,%s,%i";
   for(int i=0; i<ArraySize(zigzagBuffer); i++) {
      if (zigzagBuffer[i] != 0) {
         string sOut = StringFormat(format,
                                    TimeToString(timeBuffer[i], TIME_DATE|TIME_MINUTES),
                                    DoubleToString(prevswing, _Digits),
                                    DoubleToString(zigzagBuffer[i], _Digits),
                                    nbar+1);
         sOut=sOut+"\n";
         File.WriteString(sOut);
         prevswing = zigzagBuffer[i];
         nbar = 0;
      }
      else {
         nbar++;
      }
   }
   File.Close();
   Comment("Done");
}
//+------------------------------------------------------------------+
