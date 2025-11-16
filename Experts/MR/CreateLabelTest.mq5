//+------------------------------------------------------------------+
//|                                                        MufEA.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Generic\HashMap.mqh>
#include "CurrencyStrength.mqh"

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
//---
   EventSetTimer(1);

   int xdis = 100;
   int ydis = 20;
   int ydisIncr = 15;
   int lblClr = clrPurple;
   for(int i=1; i<=8; i++) {
      string name = "label" + IntegerToString(i);
      ObjectCreate(0,name,OBJ_LABEL,0,0,0);
      ObjectSetInteger(0,name,OBJPROP_XDISTANCE,xdis);
      ObjectSetInteger(0,name,OBJPROP_YDISTANCE,ydis+(i-1)*ydisIncr);
      ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_RIGHT_UPPER);
      ObjectSetString(0,name,OBJPROP_TEXT,"XXXXXX 0.0");
      ObjectSetInteger(0,name,OBJPROP_COLOR,lblClr);
      ObjectSetString(0,name,OBJPROP_FONT,"Courier New");
      ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,name,OBJPROP_SELECTED,false);
   }
   
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
//---
   EventKillTimer();
   for(int i=1; i<=8; i++) {
      string name = "label" + IntegerToString(i);
      ObjectDelete(0, name);
   }
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
   
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
   CHashMap<string,double> map;
   calculateCurrencyStrength(12, PERIOD_CURRENT, map);
   string pairs[];
   double values[];
   map.CopyTo(pairs, values, 0);
   for(int i=0; i<map.Count(); i++) {
      string objName = "label" + IntegerToString(i+1);
      string text = pairs[i] + " " + DoubleToString(values[i], 1);
      ObjectSetString(0, objName, OBJPROP_TEXT, text);
      if (values[i] > 60) {
         ObjectSetInteger(0, objName, OBJPROP_COLOR, clrGreen);
      }
      else if (values[i] < 40) {
         ObjectSetInteger(0, objName, OBJPROP_COLOR, clrRed);
      }
   }
}

//+------------------------------------------------------------------+
