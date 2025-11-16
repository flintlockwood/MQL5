//+------------------------------------------------------------------+
//|                                        CurrencyStrengthMeter.mq5 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Generic\HashMap.mqh>

input int              inpRocPeriod    = 4;
input ENUM_TIMEFRAMES  inpRocTimeFrame = PERIOD_D1;

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
void OnTimer() {
//---
   ENUM_TIMEFRAMES rocTF = inpRocTimeFrame;
   int rocPeriod = inpRocPeriod;
   
   MqlRates eurgbpRates[];
   MqlRates eurchfRates[];
   MqlRates eurjpyRates[];
   MqlRates euraudRates[];
   MqlRates eurnzdRates[];
   MqlRates eurusdRates[];
   MqlRates eurcadRates[];
   MqlRates gbpchfRates[];
   MqlRates gbpjpyRates[];
   MqlRates gbpaudRates[];
   MqlRates gbpnzdRates[];
   MqlRates gbpusdRates[];
   MqlRates gbpcadRates[];
   MqlRates chfjpyRates[];
   MqlRates audchfRates[];
   MqlRates nzdchfRates[];
   MqlRates usdchfRates[];
   MqlRates cadchfRates[];
   MqlRates audjpyRates[];
   MqlRates nzdjpyRates[];
   MqlRates usdjpyRates[];
   MqlRates cadjpyRates[];
   MqlRates audnzdRates[];
   MqlRates audusdRates[];
   MqlRates audcadRates[];
   MqlRates nzdusdRates[];
   MqlRates nzdcadRates[];
   MqlRates usdcadRates[];
   
   int tot = 0;
   tot = tot + CopyRates("EURGBP", rocTF, 0, rocPeriod, eurgbpRates);
   tot = tot + CopyRates("EURCHF", rocTF, 0, rocPeriod, eurchfRates);
   tot = tot + CopyRates("EURJPY", rocTF, 0, rocPeriod, eurjpyRates);
   tot = tot + CopyRates("EURAUD", rocTF, 0, rocPeriod, euraudRates);
   tot = tot + CopyRates("EURNZD", rocTF, 0, rocPeriod, eurnzdRates);
   tot = tot + CopyRates("EURUSD", rocTF, 0, rocPeriod, eurusdRates);
   tot = tot + CopyRates("EURCAD", rocTF, 0, rocPeriod, eurcadRates);
   tot = tot + CopyRates("GBPCHF", rocTF, 0, rocPeriod, gbpchfRates);
   tot = tot + CopyRates("GBPJPY", rocTF, 0, rocPeriod, gbpjpyRates);
   tot = tot + CopyRates("GBPAUD", rocTF, 0, rocPeriod, gbpaudRates);
   tot = tot + CopyRates("GBPNZD", rocTF, 0, rocPeriod, gbpnzdRates);
   tot = tot + CopyRates("GBPUSD", rocTF, 0, rocPeriod, gbpusdRates);
   tot = tot + CopyRates("GBPCAD", rocTF, 0, rocPeriod, gbpcadRates);
   tot = tot + CopyRates("CHFJPY", rocTF, 0, rocPeriod, chfjpyRates);
   tot = tot + CopyRates("AUDCHF", rocTF, 0, rocPeriod, audchfRates);
   tot = tot + CopyRates("NZDCHF", rocTF, 0, rocPeriod, nzdchfRates);
   tot = tot + CopyRates("USDCHF", rocTF, 0, rocPeriod, usdchfRates);
   tot = tot + CopyRates("CADCHF", rocTF, 0, rocPeriod, cadchfRates);
   tot = tot + CopyRates("AUDJPY", rocTF, 0, rocPeriod, audjpyRates);
   tot = tot + CopyRates("NZDJPY", rocTF, 0, rocPeriod, nzdjpyRates);
   tot = tot + CopyRates("USDJPY", rocTF, 0, rocPeriod, usdjpyRates);
   tot = tot + CopyRates("CADJPY", rocTF, 0, rocPeriod, cadjpyRates);
   tot = tot + CopyRates("AUDNZD", rocTF, 0, rocPeriod, audnzdRates);
   tot = tot + CopyRates("AUDUSD", rocTF, 0, rocPeriod, audusdRates);
   tot = tot + CopyRates("AUDCAD", rocTF, 0, rocPeriod, audcadRates);
   tot = tot + CopyRates("NZDUSD", rocTF, 0, rocPeriod, nzdusdRates);
   tot = tot + CopyRates("NZDCAD", rocTF, 0, rocPeriod, nzdcadRates);
   tot = tot + CopyRates("USDCAD", rocTF, 0, rocPeriod, usdcadRates);
   if (tot != rocPeriod*28) {
      Print("Error copying data");
      return;
   }

   double eurgbpRoc = eurgbpRates[ArraySize(eurgbpRates)-1].close - eurgbpRates[0].close;
   double eurchfRoc = eurchfRates[ArraySize(eurchfRates)-1].close - eurchfRates[0].close;
   double eurjpyRoc = eurjpyRates[ArraySize(eurjpyRates)-1].close - eurjpyRates[0].close;
   double euraudRoc = euraudRates[ArraySize(euraudRates)-1].close - euraudRates[0].close;
   double eurnzdRoc = eurnzdRates[ArraySize(eurnzdRates)-1].close - eurnzdRates[0].close;
   double eurusdRoc = eurusdRates[ArraySize(eurusdRates)-1].close - eurusdRates[0].close;
   double eurcadRoc = eurcadRates[ArraySize(eurcadRates)-1].close - eurcadRates[0].close;
   double gbpchfRoc = gbpchfRates[ArraySize(gbpchfRates)-1].close - gbpchfRates[0].close;
   double gbpjpyRoc = gbpjpyRates[ArraySize(gbpjpyRates)-1].close - gbpjpyRates[0].close;
   double gbpaudRoc = gbpaudRates[ArraySize(gbpaudRates)-1].close - gbpaudRates[0].close;
   double gbpnzdRoc = gbpnzdRates[ArraySize(gbpnzdRates)-1].close - gbpnzdRates[0].close;
   double gbpusdRoc = gbpusdRates[ArraySize(gbpusdRates)-1].close - gbpusdRates[0].close;
   double gbpcadRoc = gbpcadRates[ArraySize(gbpcadRates)-1].close - gbpcadRates[0].close;
   double chfjpyRoc = chfjpyRates[ArraySize(chfjpyRates)-1].close - chfjpyRates[0].close;
   double audchfRoc = audchfRates[ArraySize(audchfRates)-1].close - audchfRates[0].close;
   double nzdchfRoc = nzdchfRates[ArraySize(nzdchfRates)-1].close - nzdchfRates[0].close;
   double usdchfRoc = usdchfRates[ArraySize(usdchfRates)-1].close - usdchfRates[0].close;
   double cadchfRoc = cadchfRates[ArraySize(cadchfRates)-1].close - cadchfRates[0].close;
   double audjpyRoc = audjpyRates[ArraySize(audjpyRates)-1].close - audjpyRates[0].close;
   double nzdjpyRoc = nzdjpyRates[ArraySize(nzdjpyRates)-1].close - nzdjpyRates[0].close;
   double usdjpyRoc = usdjpyRates[ArraySize(usdjpyRates)-1].close - usdjpyRates[0].close;
   double cadjpyRoc = cadjpyRates[ArraySize(cadjpyRates)-1].close - cadjpyRates[0].close;
   double audnzdRoc = audnzdRates[ArraySize(audnzdRates)-1].close - audnzdRates[0].close;
   double audusdRoc = audusdRates[ArraySize(audusdRates)-1].close - audusdRates[0].close;
   double audcadRoc = audcadRates[ArraySize(audcadRates)-1].close - audcadRates[0].close;
   double nzdusdRoc = nzdusdRates[ArraySize(nzdusdRates)-1].close - nzdusdRates[0].close;
   double nzdcadRoc = nzdcadRates[ArraySize(nzdcadRates)-1].close - nzdcadRates[0].close;
   double usdcadRoc = usdcadRates[ArraySize(usdcadRates)-1].close - usdcadRates[0].close;

   double eurStrength = NormalizeDouble(eurgbpRoc + eurchfRoc + eurjpyRoc + euraudRoc + eurnzdRoc + eurusdRoc + eurcadRoc, 4);
   double gbpStrength = NormalizeDouble(-eurgbpRoc + gbpchfRoc + gbpjpyRoc + gbpaudRoc + gbpnzdRoc + gbpusdRoc + gbpcadRoc, 4);
   double chfStrength = NormalizeDouble(-eurchfRoc - gbpchfRoc + chfjpyRoc - audchfRoc - nzdchfRoc - usdchfRoc - cadchfRoc, 4);
   double jpyStrength = NormalizeDouble(-eurjpyRoc - gbpjpyRoc - chfjpyRoc - audjpyRoc - nzdjpyRoc - usdjpyRoc - cadjpyRoc, 4);
   double audStrength = NormalizeDouble(-euraudRoc - gbpaudRoc + audchfRoc + audjpyRoc + audnzdRoc + audusdRoc + audcadRoc, 4);
   double nzdStrength = NormalizeDouble(-eurnzdRoc - gbpnzdRoc + nzdchfRoc + nzdjpyRoc - audnzdRoc + nzdusdRoc + nzdcadRoc, 4);
   double usdStrength = NormalizeDouble(-eurusdRoc - gbpusdRoc + usdchfRoc + usdjpyRoc - audusdRoc - nzdusdRoc + usdcadRoc, 4);
   double cadStrength = NormalizeDouble(-eurcadRoc - gbpcadRoc + cadchfRoc + cadjpyRoc - audcadRoc - nzdcadRoc - usdcadRoc, 4);
   
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
      out = out + hashMapFindByValue(map, rank[i]) + " " + DoubleToString(rank[i],2) + "\r\n";
   }
   
   Comment(out);
}
//+------------------------------------------------------------------+
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