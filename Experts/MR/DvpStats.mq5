//+------------------------------------------------------------------+
//|                                                     DvpStats.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Files\File.mqh>
#include <Files\FileTxt.mqh>
#include <MR\ArrayList.mqh>
#include <MR\CIsNewBar.mqh>

int dvp_handle;
bool done = false;
CFileTxt     File;
CIsNewBar currINB;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
//---
   dvp_handle = iCustom(_Symbol, _Period, "MR\\DVPLowerTf", 60, 100, 70, false);
//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
//---
   Comment("");
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
//---

   if(currINB.isNewBar() > 0) {
      OnNewBar();
   }

   if(!done) {
      if(dvp_handle == INVALID_HANDLE) {
         Print("invalid handle");
         return;
      }

      int cnt = 240;
      double pocs[];
      int poccnt = CopyBuffer(dvp_handle, 2, 0, cnt, pocs);
      datetime times[];
      int timecnt = CopyTime(_Symbol, _Period, 0, cnt, times);

      if(poccnt != cnt || timecnt != cnt) {
         return;
      }

      // print poc profiles to file
      string filepath = StringFormat("poc_%s_%s.csv", _Symbol, EnumToString(_Period));
      File.Open(filepath, FILE_WRITE | FILE_COMMON, 9);
      File.WriteString("time,poc\n");
      for(int i=0; i<ArraySize(pocs); i++) {
         string sOut = StringFormat("%s,%s",
                                    TimeToString(times[i], TIME_DATE | TIME_MINUTES),
                                    DoubleToString(pocs[i], _Digits));
         sOut = sOut + "\n";
         File.WriteString(sOut);
      }
      File.Close();

      // find support & resistance level using poc
      // 1. get distinct pocs
      double prevPoc = 0.0;
      double diffTh = 0.00099;
      PriceTime distinctPocList[];
      for(int i=0; i<ArraySize(pocs); i++) {
         if(MathAbs(pocs[i] - prevPoc) > diffTh) {
            PriceTime newPoint;
            newPoint.Time = times[i];
            newPoint.Price = pocs[i];
            bool valueIsNew = false;
            int oldPointIndex = -1;
            if(ArraySize(distinctPocList) == 0) {
               valueIsNew = true;
            } else {
               valueIsNew = true;
               for(int j=0; j<ArraySize(distinctPocList); j++) {
                  if(MathAbs(distinctPocList[j].Price - pocs[i]) < diffTh) {
                     valueIsNew = false;
                     oldPointIndex = j;
                     break;
                  }
               }
            }

            if(valueIsNew) {
               ArrayResize(distinctPocList, ArraySize(distinctPocList)+1, 10);
               distinctPocList[ArraySize(distinctPocList)-1] = newPoint;
            } else {
               if(oldPointIndex > -1) {
                  distinctPocList[oldPointIndex].Price = pocs[i];
                  distinctPocList[oldPointIndex].Time = times[i];
               }
            }
         }
         prevPoc = pocs[i];
      }

      // print distinct poc to file
      filepath = StringFormat("distinct_poc_%s_%s.csv", _Symbol, EnumToString(_Period));
      File.Open(filepath, FILE_WRITE | FILE_COMMON, 9);
      File.WriteString("time,poc\n");
      for(int i=0; i<ArraySize(distinctPocList); i++) {
         string sOut = StringFormat("%s,%s",
                                    TimeToString(distinctPocList[i].Time, TIME_DATE | TIME_MINUTES),
                                    DoubleToString(distinctPocList[i].Price, _Digits));
         sOut = sOut + "\n";
         File.WriteString(sOut);
      }
      File.Close();
   }
   done = true;
   Comment("done");
}
//+------------------------------------------------------------------+
void OnNewBar() {
   Print("New Bar: " + TimeToString(TimeCurrent(), TIME_SECONDS));

   int cnt = 240;
   double pocs[];
   int poccnt = CopyBuffer(dvp_handle, 2, 0, cnt, pocs);
   datetime times[];
   int timecnt = CopyTime(_Symbol, _Period, 0, cnt, times);

   if(poccnt != cnt || timecnt != cnt) {
      return;
   }

// find support & resistance level using poc
// 1. get distinct pocs
   double prevPoc = 0.0;
   double diffTh = 0.00099;
   PriceTime distinctPocList[];
   SRLine* srList[];
   for(int i=0; i<ArraySize(pocs); i++) {
      if(MathAbs(pocs[i] - prevPoc) > diffTh) {
         PriceTime newPoint;
         newPoint.Time = times[i];
         newPoint.Price = pocs[i];
         bool valueIsNew = false;
         int oldPointIndex = -1;
         if(ArraySize(distinctPocList) == 0) {
            valueIsNew = true;
         } else {
            valueIsNew = true;
            for(int j=0; j<ArraySize(distinctPocList); j++) {
               if(MathAbs(distinctPocList[j].Price - pocs[i]) < diffTh) {
                  valueIsNew = false;
                  oldPointIndex = j;
                  break;
               }
            }
         }

         if(valueIsNew) {
            ArrayResize(distinctPocList, ArraySize(distinctPocList)+1, 10);
            distinctPocList[ArraySize(distinctPocList)-1] = newPoint;
            
            SRLine *sr = new SRLine();
            sr.AddPoc(newPoint);
            ArrayResize(srList, ArraySize(srList)+1, 1);
            srList[ArraySize(srList)-1] = sr;
         } else {
            if(oldPointIndex > -1) {
               distinctPocList[oldPointIndex].Price = pocs[i];
               distinctPocList[oldPointIndex].Time = times[i];
            }
            SRLine* tempSR = GetSRFromSRList(pocs[i], srList);
            tempSR.AddPoc(newPoint);
         }
      }
      prevPoc = pocs[i];
   }
}

struct PriceTime {
   datetime          Time;
   double            Price;
};
//+------------------------------------------------------------------+
class SRLine {
   private: 
   PriceTime         PocList[];
   double diffTh;
   
   public :
   SRLine() {
      diffTh = 0.00099;
   }

   void              AddPoc(PriceTime &poc) {
      ArrayResize(PocList, ArraySize(PocList)+1, 5);
      PocList[ArraySize(PocList)-1] = poc;
   }

   double            GetAvgValue() {
      double value = 0;
      for(int i=0; i<ArraySize(PocList); i++) {
         value = value + PocList[i].Price;
      }
      return value / ArraySize(PocList);
   }
   
   bool isInRange(double price) {
      return MathAbs(GetAvgValue() - price) < diffTh;
   }
};
//+------------------------------------------------------------------+
SRLine* GetSRFromSRList(double price, SRLine* &srList[]) {
   for(int i=0; i<ArraySize(srList); i++) {
      if (srList[i].isInRange(price)) {
         return srList[i];
      }
   }
   return NULL;
}