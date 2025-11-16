//+------------------------------------------------------------------+
//|                                                     SRHelper.mqh |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
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

#include <Arrays\ArrayObj.mqh>
#include "Dvp.mqh"
#include "SRColl.mqh"

class DvpSR {
 private:
   Dvp               *dvp;
   double            range;

 public:
                     DvpSR(Dvp *p_dvp, double p_range) {
      this.dvp = p_dvp;
      this.range = p_range;
   }

                    ~DvpSR() {
      delete dvp;
   }

   SRCollection*            CalculateSRByPOC(int scanPeriod, int count) {
      SRCollection* srColl = new SRCollection(range);
      CArrayObj *pocArrList = dvp.GetPocList(_Symbol, PERIOD_CURRENT, scanPeriod);

      for(int i=0; i<pocArrList.Total(); i++) {
         PriceTime *pt = pocArrList.At(i);
         if (srColl.Contains(pt.price)) {
            srColl.UpdateSR(pt);
         } else {
            srColl.AddSR(pt);
         }
      }

      return srColl.GetTopSR(count);
   }
};
//+------------------------------------------------------------------+
