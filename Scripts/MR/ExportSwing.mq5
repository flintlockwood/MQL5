//+------------------------------------------------------------------+
//|                                                  ExportSwing.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Files\File.mqh>
#include <Files\FileTxt.mqh>

input int inpSwingBarCount = 10;

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart() {
//---
   CFileTxt     File;
   MqlRates rates[];
   int nbars = iBars(_Symbol, _Period);
   CopyRates(_Symbol, _Period, 0, nbars, rates);

   string filepath = StringFormat("swing_%s_%s.csv", _Symbol, EnumToString(_Period));
   File.Open(filepath, FILE_WRITE | FILE_COMMON, 9);

   string format = "%s,%s,%s";
   File.WriteString("time,type,price\n");
   for(int i = 0; i < ArraySize(rates); i++) {
      if (i >= 2 * inpSwingBarCount) {
         MqlRates tempRates[];
         ArrayCopy(tempRates, rates, 0, i - 2 * inpSwingBarCount, 2 * inpSwingBarCount + 1);
         if (isSwingHigh(tempRates)) {
            string sOut = StringFormat(format,
                                       TimeToString(tempRates[inpSwingBarCount].time, TIME_DATE | TIME_MINUTES),
                                       "SH",
                                       DoubleToString(tempRates[inpSwingBarCount].high, _Digits));
            sOut = sOut + "\n";
            File.WriteString(sOut);
         } else if (isSwingLow(tempRates)) {
            string sOut = StringFormat(format,
                                       TimeToString(tempRates[inpSwingBarCount].time, TIME_DATE | TIME_MINUTES),
                                       "SL",
                                       DoubleToString(tempRates[inpSwingBarCount].low, _Digits));
            sOut = sOut + "\n";
            File.WriteString(sOut);
         }
      }
   }
   File.Close();
   Comment("Done");
}

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isSwingHigh(MqlRates & rates[]) {
   bool ret = false;
   int n = ArraySize(rates);
   if (n % 2 == 1) {
      int mid = (n - 1) / 2;
      double maxPrice = rates[0].high;
      int maxIndex = 0;
      for(int i = 1; i < n; i++) {
         if (rates[i].high > maxPrice) {
            maxPrice = rates[i].high;
            maxIndex = i;
         }
      }
      ret = maxIndex == mid;
   }
   return ret;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isSwingLow(MqlRates & rates[]) {
   bool ret = false;
   int n = ArraySize(rates);
   if (n % 2 == 1) {
      int mid = (n - 1) / 2;
      double minPrice = rates[0].low;
      int minIndex = 0;
      for(int i = 1; i < n; i++) {
         if (rates[i].low < minPrice) {
            minPrice = rates[i].low;
            minIndex = i;
         }
      }
      ret = minIndex == mid;
   }
   return ret;
}
//+------------------------------------------------------------------+
