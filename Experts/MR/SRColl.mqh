//+------------------------------------------------------------------+
//|                                                       SRColl.mqh |
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
#include "SRLine.mqh"

class SRCollection {
 private:
   CArrayObj         *srList;
   double            range;

   SRLine*              getLine(double price) {
      for(int i=0; i<srList.Total(); i++) {
         SRLine *srline = srList.At(i);
         if (MathAbs(srline.AvgValue() - price)/_Point <= range) {
            return srline;
         }
      }
      return NULL;
   }

 public:
                     SRCollection(double p_range) {
      srList = new CArrayObj();
      this.range = p_range;
   }

                    ~SRCollection() {
      for(int i=0; i<srList.Total(); i++) {
         delete srList.At(i);
      }
      delete srList;
   }

   int               Total() {
      return srList.Total();
   }

   SRLine*              Get(int index) {
      SRLine *srline = srList.At(index);
      return srline;
   }

   SRCollection*        GetTopSR(int count) {
      if (count > srList.Total()) {
         count = srList.Total();
      }
      SRCollection *list = new SRCollection(this.range);
      srList.Sort(SORT_BY_STRENGTH);
      for(int i=0; i<count; i++) {
         list.AddLine(srList.At(srList.Total()-1-i));
      }
      return list;
   }

   bool              Contains(double price) {
      for(int i=0; i<srList.Total(); i++) {
         SRLine *srline = srList.At(i);
         if (MathAbs(srline.AvgValue() - price)/_Point <= range) {
            return true;
         }
      }
      return false;
   }

   void              AddSR(PriceTime *p) {
      SRLine *newline = new SRLine();
      newline.AddPoint(p);
      srList.Add(newline);
   }

   void              UpdateSR(PriceTime *p) {
      SRLine *oldline = getLine(p.price);
      oldline.AddPoint(p);
   }
   
   void AddLine(SRLine *newLine) {
      srList.Add(newLine);
   }

   void              Sort() {
      srList.Sort(SORT_BY_STRENGTH);
   }
};
//+------------------------------------------------------------------+
