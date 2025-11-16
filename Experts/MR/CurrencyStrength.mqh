//+------------------------------------------------------------------+
//|                                             CurrencyStrength.mqh |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
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

#include <Generic\HashMap.mqh>
#include "Common.mqh"

void calculateCurrencyStrength(int period, ENUM_TIMEFRAMES tf, string comment) {
   
   double eurgbpRsi = getCurrentRsi("EURGBP", tf, period);
   double eurchfRsi = getCurrentRsi("EURCHF", tf, period);
   double eurjpyRsi = getCurrentRsi("EURJPY", tf, period);
   double euraudRsi = getCurrentRsi("EURAUD", tf, period);
   double eurnzdRsi = getCurrentRsi("EURNZD", tf, period);
   double eurusdRsi = getCurrentRsi("EURUSD", tf, period);
   double eurcadRsi = getCurrentRsi("EURCAD", tf, period);
   double gbpchfRsi = getCurrentRsi("GBPCHF", tf, period);
   double gbpjpyRsi = getCurrentRsi("GBPJPY", tf, period);
   double gbpaudRsi = getCurrentRsi("GBPAUD", tf, period);
   double gbpnzdRsi = getCurrentRsi("GBPNZD", tf, period);
   double gbpusdRsi = getCurrentRsi("GBPUSD", tf, period);
   double gbpcadRsi = getCurrentRsi("GBPCAD", tf, period);
   double chfjpyRsi = getCurrentRsi("CHFJPY", tf, period);
   double audchfRsi = getCurrentRsi("AUDCHF", tf, period);
   double nzdchfRsi = getCurrentRsi("NZDCHF", tf, period);
   double usdchfRsi = getCurrentRsi("USDCHF", tf, period);
   double cadchfRsi = getCurrentRsi("CADCHF", tf, period);
   double audjpyRsi = getCurrentRsi("AUDJPY", tf, period);
   double nzdjpyRsi = getCurrentRsi("NZDJPY", tf, period);
   double usdjpyRsi = getCurrentRsi("USDJPY", tf, period);
   double cadjpyRsi = getCurrentRsi("CADJPY", tf, period);
   double audnzdRsi = getCurrentRsi("AUDNZD", tf, period);
   double audusdRsi = getCurrentRsi("AUDUSD", tf, period);
   double audcadRsi = getCurrentRsi("AUDCAD", tf, period);
   double nzdusdRsi = getCurrentRsi("NZDUSD", tf, period);
   double nzdcadRsi = getCurrentRsi("NZDCAD", tf, period);
   double usdcadRsi = getCurrentRsi("USDCAD", tf, period);

   double eurStrength = NormalizeDouble((eurgbpRsi + eurchfRsi + eurjpyRsi + euraudRsi + eurnzdRsi + eurusdRsi + eurcadRsi) / 7, 4);
   double gbpStrength = NormalizeDouble((100-eurgbpRsi + gbpchfRsi + gbpjpyRsi + gbpaudRsi + gbpnzdRsi + gbpusdRsi + gbpcadRsi) / 7, 4);
   double chfStrength = NormalizeDouble((100-eurchfRsi + 100-gbpchfRsi + chfjpyRsi + 100-audchfRsi + 100-nzdchfRsi + 100-usdchfRsi + 100-cadchfRsi) / 7, 4);
   double jpyStrength = NormalizeDouble((100-eurjpyRsi + 100-gbpjpyRsi + 100-chfjpyRsi + 100-audjpyRsi + 100-nzdjpyRsi + 100-usdjpyRsi + 100-cadjpyRsi) / 7, 4);
   double audStrength = NormalizeDouble((100-euraudRsi + 100-gbpaudRsi + audchfRsi + audjpyRsi + audnzdRsi + audusdRsi + audcadRsi) / 7, 4);
   double nzdStrength = NormalizeDouble((100-eurnzdRsi + 100-gbpnzdRsi + nzdchfRsi + nzdjpyRsi + 100-audnzdRsi + nzdusdRsi + nzdcadRsi) / 7, 4);
   double usdStrength = NormalizeDouble((100-eurusdRsi + 100-gbpusdRsi + usdchfRsi + usdjpyRsi + 100-audusdRsi + 100-nzdusdRsi + usdcadRsi) / 7, 4);
   double cadStrength = NormalizeDouble((100-eurcadRsi + 100-gbpcadRsi + cadchfRsi + cadjpyRsi + 100-audcadRsi + 100-nzdcadRsi + 100-usdcadRsi) / 7, 4);
   
   double rank[];
   ArrayResize(rank, 8);
   rank[0] = eurStrength;
   rank[1] = gbpStrength;
   rank[2] = chfStrength;
   rank[3] = jpyStrength;
   rank[4] = audStrength;
   rank[5] = nzdStrength;
   rank[6] = usdStrength;
   rank[7] = cadStrength;
   ArraySort(rank);
   ArrayReverse(rank);
   
   CHashMap<string, double> map;
   map.Add("EUR", eurStrength);
   map.Add("GBP", gbpStrength);
   map.Add("CHF", chfStrength);
   map.Add("JPY", jpyStrength);
   map.Add("AUD", audStrength);
   map.Add("NZD", nzdStrength);
   map.Add("USD", usdStrength);
   map.Add("CAD", cadStrength);
   
   string out = "";
   for (int i=0; i<8; i++) {
      out = out + hashMapFindByValue(map, rank[i]) + " " + DoubleToString(rank[i],1) + "\r\n";
   }
   double curRsi = getCurrentRsi(_Symbol, PERIOD_CURRENT, 14);
   out = out + _Symbol + " " + DoubleToString(curRsi, 1) + "\r\n";
   out = out + "avg CTF range " + DoubleToString(getCurrRange(PERIOD_CURRENT), 0) + " / " + DoubleToString(getAverageRangeInPips(PERIOD_CURRENT, 100), 0) + " pips\r\n";
   out = out + "avg M30 range " + DoubleToString(getCurrRange(PERIOD_M30), 0) + " / " + DoubleToString(getAverageRangeInPips(PERIOD_M30, 100), 0) + " pips\r\n";
   out = out + "avg D1 range " + DoubleToString(getCurrRange(PERIOD_D1), 0) + " / " + DoubleToString(getAverageRangeInPips(PERIOD_D1, 100), 0) + " pips\r\n";
   out = out + "spread: " + DoubleToString(SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) / 10.0, 1) + "\r\n";
   out = out + "comment: " + comment;
   
   Comment(out);
}

void calculateCurrencyStrength(int period, ENUM_TIMEFRAMES tf, CHashMap<string,double> &map) {
   
   double eurgbpRsi = getCurrentRsi("EURGBP", tf, period);
   double eurchfRsi = getCurrentRsi("EURCHF", tf, period);
   double eurjpyRsi = getCurrentRsi("EURJPY", tf, period);
   double euraudRsi = getCurrentRsi("EURAUD", tf, period);
   double eurnzdRsi = getCurrentRsi("EURNZD", tf, period);
   double eurusdRsi = getCurrentRsi("EURUSD", tf, period);
   double eurcadRsi = getCurrentRsi("EURCAD", tf, period);
   double gbpchfRsi = getCurrentRsi("GBPCHF", tf, period);
   double gbpjpyRsi = getCurrentRsi("GBPJPY", tf, period);
   double gbpaudRsi = getCurrentRsi("GBPAUD", tf, period);
   double gbpnzdRsi = getCurrentRsi("GBPNZD", tf, period);
   double gbpusdRsi = getCurrentRsi("GBPUSD", tf, period);
   double gbpcadRsi = getCurrentRsi("GBPCAD", tf, period);
   double chfjpyRsi = getCurrentRsi("CHFJPY", tf, period);
   double audchfRsi = getCurrentRsi("AUDCHF", tf, period);
   double nzdchfRsi = getCurrentRsi("NZDCHF", tf, period);
   double usdchfRsi = getCurrentRsi("USDCHF", tf, period);
   double cadchfRsi = getCurrentRsi("CADCHF", tf, period);
   double audjpyRsi = getCurrentRsi("AUDJPY", tf, period);
   double nzdjpyRsi = getCurrentRsi("NZDJPY", tf, period);
   double usdjpyRsi = getCurrentRsi("USDJPY", tf, period);
   double cadjpyRsi = getCurrentRsi("CADJPY", tf, period);
   double audnzdRsi = getCurrentRsi("AUDNZD", tf, period);
   double audusdRsi = getCurrentRsi("AUDUSD", tf, period);
   double audcadRsi = getCurrentRsi("AUDCAD", tf, period);
   double nzdusdRsi = getCurrentRsi("NZDUSD", tf, period);
   double nzdcadRsi = getCurrentRsi("NZDCAD", tf, period);
   double usdcadRsi = getCurrentRsi("USDCAD", tf, period);

   double eurStrength = NormalizeDouble((eurgbpRsi + eurchfRsi + eurjpyRsi + euraudRsi + eurnzdRsi + eurusdRsi + eurcadRsi) / 7, 4);
   double gbpStrength = NormalizeDouble((100-eurgbpRsi + gbpchfRsi + gbpjpyRsi + gbpaudRsi + gbpnzdRsi + gbpusdRsi + gbpcadRsi) / 7, 4);
   double chfStrength = NormalizeDouble((100-eurchfRsi + 100-gbpchfRsi + chfjpyRsi + 100-audchfRsi + 100-nzdchfRsi + 100-usdchfRsi + 100-cadchfRsi) / 7, 4);
   double jpyStrength = NormalizeDouble((100-eurjpyRsi + 100-gbpjpyRsi + 100-chfjpyRsi + 100-audjpyRsi + 100-nzdjpyRsi + 100-usdjpyRsi + 100-cadjpyRsi) / 7, 4);
   double audStrength = NormalizeDouble((100-euraudRsi + 100-gbpaudRsi + audchfRsi + audjpyRsi + audnzdRsi + audusdRsi + audcadRsi) / 7, 4);
   double nzdStrength = NormalizeDouble((100-eurnzdRsi + 100-gbpnzdRsi + nzdchfRsi + nzdjpyRsi + 100-audnzdRsi + nzdusdRsi + nzdcadRsi) / 7, 4);
   double usdStrength = NormalizeDouble((100-eurusdRsi + 100-gbpusdRsi + usdchfRsi + usdjpyRsi + 100-audusdRsi + 100-nzdusdRsi + usdcadRsi) / 7, 4);
   double cadStrength = NormalizeDouble((100-eurcadRsi + 100-gbpcadRsi + cadchfRsi + cadjpyRsi + 100-audcadRsi + 100-nzdcadRsi + 100-usdcadRsi) / 7, 4);
   
   double rank[];
   ArrayResize(rank, 8);
   rank[0] = eurStrength;
   rank[1] = gbpStrength;
   rank[2] = chfStrength;
   rank[3] = jpyStrength;
   rank[4] = audStrength;
   rank[5] = nzdStrength;
   rank[6] = usdStrength;
   rank[7] = cadStrength;
   ArraySort(rank);
   ArrayReverse(rank);
   
   CHashMap<string,double> tempMap;
   tempMap.Clear();
   tempMap.Add("EUR", eurStrength);
   tempMap.Add("GBP", gbpStrength);
   tempMap.Add("CHF", chfStrength);
   tempMap.Add("JPY", jpyStrength);
   tempMap.Add("AUD", audStrength);
   tempMap.Add("NZD", nzdStrength);
   tempMap.Add("USD", usdStrength);
   tempMap.Add("CAD", cadStrength);
   
   map.Clear();
   for (int i=0; i<8; i++) {
      map.Add(hashMapFindByValue(tempMap, rank[i]), rank[i]);
   }
}

string hashMapFindByValue(CHashMap<string, double> &map, double value) {
   string keys[];
   double values[];
   map.CopyTo(keys, values);
   for(int i=0; i<ArraySize(keys); i++) {
      double v;
      map.TryGetValue(keys[i], v);
      if (v == value) {
         return keys[i];
      }
   }
   return "";
}

