//+------------------------------------------------------------------+
//|                                                  TestPointer.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "Dvp.mqh"
#include "SRLine.mqh"
#include <Arrays\ArrayObj.mqh>

Dvp *dvp;
CArrayObj *srList;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
//---
   printf("init");
   dvp = new Dvp();
   CArrayObj *arr = dvp.GetPocList(_Symbol, PERIOD_CURRENT, 100);
   delete arr;

   srList = new CArrayObj();
   SRLine *line = new SRLine();
   PriceTime *pt = new PriceTime(0, 0);
   line.AddPoint(pt);
   delete pt;
   srList.Add(line);

   srList.Sort(SORT_BY_STRENGTH);
   CArrayObj *newSRlist = new CArrayObj();
   for(int i=0; i<newSRlist.Total(); i++) {
      SRLine *templine = srList.At(srList.Total()-1-i);
      newSRlist.Add(templine.Clone());
   }

   for(int i=0; i<srList.Total(); i++) {
      SRLine *line = srList.At(i);
      line.ClearPoints();
      delete line;
   }
   delete srList;
   
   srList = newSRlist;


//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
//---
   printf("deinit");
   delete dvp;
   for(int i=0; i<srList.Total(); i++) {
      SRLine *line = srList.At(i);
      line.ClearPoints();
      delete line;
   }
   delete srList;
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
//---

}
//+------------------------------------------------------------------+
