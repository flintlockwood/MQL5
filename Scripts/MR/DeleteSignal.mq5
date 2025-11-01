//+------------------------------------------------------------------+
//|                                                 DeleteSignal.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
//---
   ObjectsDeleteAll(0, "signal*");
   ObjectsDeleteAll(0, "Signal*");
   ObjectsDeleteAll(0, "unusual*");
   ObjectsDeleteAll(0, "unusual*");
   ObjectsDeleteAll(0, "SR*");
}
//+------------------------------------------------------------------+
