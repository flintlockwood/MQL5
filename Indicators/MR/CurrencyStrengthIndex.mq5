//+------------------------------------------------------------------+
//|                                        CurrencyStrengthIndex.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 8
#property indicator_label1  "AUD"
#property indicator_type1   DRAW_NONE
#property indicator_label2  "CAD"
#property indicator_type2   DRAW_NONE
#property indicator_label3  "CHF"
#property indicator_type3   DRAW_NONE
#property indicator_label4  "EUR"
#property indicator_type4   DRAW_NONE
#property indicator_label5  "GBP"
#property indicator_type5   DRAW_NONE
#property indicator_label6  "JPY"
#property indicator_type6   DRAW_NONE
#property indicator_label7  "NZD"
#property indicator_type7   DRAW_NONE
#property indicator_label8  "USD"
#property indicator_type8   DRAW_NONE

#include <MR\ArrayListClass.mqh>

//--- indicator buffers
double    AUDBuffer[];
double    CADBuffer[];
double    CHFBuffer[];
double    EURBuffer[];
double    GBPBuffer[];
double    JPYBuffer[];
double    NZDBuffer[];
double    USDBuffer[];

input int inpRSIPeriod = 12;
input int inpAvgRangePeriod = 100;
input bool inpEnableHistory = false;

int eurgbpRsiHandle;
int eurchfRsiHandle;
int eurjpyRsiHandle;
int euraudRsiHandle;
int eurnzdRsiHandle;
int eurusdRsiHandle;
int eurcadRsiHandle;
int gbpchfRsiHandle;
int gbpjpyRsiHandle;
int gbpaudRsiHandle;
int gbpnzdRsiHandle;
int gbpusdRsiHandle;
int gbpcadRsiHandle;
int chfjpyRsiHandle;
int audchfRsiHandle;
int nzdchfRsiHandle;
int usdchfRsiHandle;
int cadchfRsiHandle;
int audjpyRsiHandle;
int nzdjpyRsiHandle;
int usdjpyRsiHandle;
int cadjpyRsiHandle;
int audnzdRsiHandle;
int audusdRsiHandle;
int audcadRsiHandle;
int nzdusdRsiHandle;
int nzdcadRsiHandle;
int usdcadRsiHandle;

class CurrStrengthItem: public IComparable<CurrStrengthItem*> {
 public:
   string            currency;
   double            strength;

   void              CurrStrengthItem() {};

   void              CurrStrengthItem(string curr, double pstrength) {
      this.currency = curr;
      this.strength = pstrength;
   };

   int               CompareTo(CurrStrengthItem* &other) {
      if (  this.strength < other.strength) return -1;
      if (  this.strength > other.strength) return 1;
      return 0;
   };
};

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
   EventSetTimer(1);

   SetIndexBuffer(0,AUDBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,CADBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,CHFBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,EURBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,GBPBuffer,INDICATOR_DATA);
   SetIndexBuffer(5,JPYBuffer,INDICATOR_DATA);
   SetIndexBuffer(6,NZDBuffer,INDICATOR_DATA);
   SetIndexBuffer(7,USDBuffer,INDICATOR_DATA);

//--- indicator buffers mapping
   eurgbpRsiHandle = iRSI("EURGBP", _Period, inpRSIPeriod, PRICE_CLOSE);
   eurchfRsiHandle = iRSI("EURCHF", _Period, inpRSIPeriod, PRICE_CLOSE);
   eurjpyRsiHandle = iRSI("EURJPY", _Period, inpRSIPeriod, PRICE_CLOSE);
   euraudRsiHandle = iRSI("EURAUD", _Period, inpRSIPeriod, PRICE_CLOSE);
   eurnzdRsiHandle = iRSI("EURNZD", _Period, inpRSIPeriod, PRICE_CLOSE);
   eurusdRsiHandle = iRSI("EURUSD", _Period, inpRSIPeriod, PRICE_CLOSE);
   eurcadRsiHandle = iRSI("EURCAD", _Period, inpRSIPeriod, PRICE_CLOSE);
   gbpchfRsiHandle = iRSI("GBPCHF", _Period, inpRSIPeriod, PRICE_CLOSE);
   gbpjpyRsiHandle = iRSI("GBPJPY", _Period, inpRSIPeriod, PRICE_CLOSE);
   gbpaudRsiHandle = iRSI("GBPAUD", _Period, inpRSIPeriod, PRICE_CLOSE);
   gbpnzdRsiHandle = iRSI("GBPNZD", _Period, inpRSIPeriod, PRICE_CLOSE);
   gbpusdRsiHandle = iRSI("GBPUSD", _Period, inpRSIPeriod, PRICE_CLOSE);
   gbpcadRsiHandle = iRSI("GBPCAD", _Period, inpRSIPeriod, PRICE_CLOSE);
   chfjpyRsiHandle = iRSI("CHFJPY", _Period, inpRSIPeriod, PRICE_CLOSE);
   audchfRsiHandle = iRSI("AUDCHF", _Period, inpRSIPeriod, PRICE_CLOSE);
   nzdchfRsiHandle = iRSI("NZDCHF", _Period, inpRSIPeriod, PRICE_CLOSE);
   usdchfRsiHandle = iRSI("USDCHF", _Period, inpRSIPeriod, PRICE_CLOSE);
   cadchfRsiHandle = iRSI("CADCHF", _Period, inpRSIPeriod, PRICE_CLOSE);
   audjpyRsiHandle = iRSI("AUDJPY", _Period, inpRSIPeriod, PRICE_CLOSE);
   nzdjpyRsiHandle = iRSI("NZDJPY", _Period, inpRSIPeriod, PRICE_CLOSE);
   usdjpyRsiHandle = iRSI("USDJPY", _Period, inpRSIPeriod, PRICE_CLOSE);
   cadjpyRsiHandle = iRSI("CADJPY", _Period, inpRSIPeriod, PRICE_CLOSE);
   audnzdRsiHandle = iRSI("AUDNZD", _Period, inpRSIPeriod, PRICE_CLOSE);
   audusdRsiHandle = iRSI("AUDUSD", _Period, inpRSIPeriod, PRICE_CLOSE);
   audcadRsiHandle = iRSI("AUDCAD", _Period, inpRSIPeriod, PRICE_CLOSE);
   nzdusdRsiHandle = iRSI("NZDUSD", _Period, inpRSIPeriod, PRICE_CLOSE);
   nzdcadRsiHandle = iRSI("NZDCAD", _Period, inpRSIPeriod, PRICE_CLOSE);
   usdcadRsiHandle = iRSI("USDCAD", _Period, inpRSIPeriod, PRICE_CLOSE);

   for (int i=0; i<11; i++) {
      string objName = "CSI_Label_" + IntegerToString(i);
      ObjectCreate(0, objName, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
      ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, 100);
      ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, 10+i*12);
      ObjectSetString(0, objName, OBJPROP_TEXT, "");
      ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, 7);
      ObjectSetInteger(0, objName, OBJPROP_COLOR, clrYellow);
   }
//---
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   EventKillTimer();

   IndicatorRelease(eurgbpRsiHandle);
   IndicatorRelease(eurchfRsiHandle);
   IndicatorRelease(eurjpyRsiHandle);
   IndicatorRelease(euraudRsiHandle);
   IndicatorRelease(eurnzdRsiHandle);
   IndicatorRelease(eurusdRsiHandle);
   IndicatorRelease(eurcadRsiHandle);
   IndicatorRelease(gbpchfRsiHandle);
   IndicatorRelease(gbpjpyRsiHandle);
   IndicatorRelease(gbpaudRsiHandle);
   IndicatorRelease(gbpnzdRsiHandle);
   IndicatorRelease(gbpusdRsiHandle);
   IndicatorRelease(gbpcadRsiHandle);
   IndicatorRelease(chfjpyRsiHandle);
   IndicatorRelease(audchfRsiHandle);
   IndicatorRelease(nzdchfRsiHandle);
   IndicatorRelease(usdchfRsiHandle);
   IndicatorRelease(cadchfRsiHandle);
   IndicatorRelease(audjpyRsiHandle);
   IndicatorRelease(nzdjpyRsiHandle);
   IndicatorRelease(usdjpyRsiHandle);
   IndicatorRelease(cadjpyRsiHandle);
   IndicatorRelease(audnzdRsiHandle);
   IndicatorRelease(audusdRsiHandle);
   IndicatorRelease(audcadRsiHandle);
   IndicatorRelease(nzdusdRsiHandle);
   IndicatorRelease(nzdcadRsiHandle);
   IndicatorRelease(usdcadRsiHandle);

   ObjectsDeleteAll(0, "CSI_");
   ChartRedraw();
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]) {
//---
   if (inpEnableHistory) {
      for(int i=0; i<rates_total; i++) {
         double eurgbpRsi = getSymbolRsi("EURGBP", time[i]);
         double eurchfRsi = getSymbolRsi("EURCHF", time[i]);
         double eurjpyRsi = getSymbolRsi("EURJPY", time[i]);
         double euraudRsi = getSymbolRsi("EURAUD", time[i]);
         double eurnzdRsi = getSymbolRsi("EURNZD", time[i]);
         double eurusdRsi = getSymbolRsi("EURUSD", time[i]);
         double eurcadRsi = getSymbolRsi("EURCAD", time[i]);
         double gbpchfRsi = getSymbolRsi("GBPCHF", time[i]);
         double gbpjpyRsi = getSymbolRsi("GBPJPY", time[i]);
         double gbpaudRsi = getSymbolRsi("GBPAUD", time[i]);
         double gbpnzdRsi = getSymbolRsi("GBPNZD", time[i]);
         double gbpusdRsi = getSymbolRsi("GBPUSD", time[i]);
         double gbpcadRsi = getSymbolRsi("GBPCAD", time[i]);
         double chfjpyRsi = getSymbolRsi("CHFJPY", time[i]);
         double audchfRsi = getSymbolRsi("AUDCHF", time[i]);
         double nzdchfRsi = getSymbolRsi("NZDCHF", time[i]);
         double usdchfRsi = getSymbolRsi("USDCHF", time[i]);
         double cadchfRsi = getSymbolRsi("CADCHF", time[i]);
         double audjpyRsi = getSymbolRsi("AUDJPY", time[i]);
         double nzdjpyRsi = getSymbolRsi("NZDJPY", time[i]);
         double usdjpyRsi = getSymbolRsi("USDJPY", time[i]);
         double cadjpyRsi = getSymbolRsi("CADJPY", time[i]);
         double audnzdRsi = getSymbolRsi("AUDNZD", time[i]);
         double audusdRsi = getSymbolRsi("AUDUSD", time[i]);
         double audcadRsi = getSymbolRsi("AUDCAD", time[i]);
         double nzdusdRsi = getSymbolRsi("NZDUSD", time[i]);
         double nzdcadRsi = getSymbolRsi("NZDCAD", time[i]);
         double usdcadRsi = getSymbolRsi("USDCAD", time[i]);

         double eurStrength = NormalizeDouble((eurgbpRsi + eurchfRsi + eurjpyRsi + euraudRsi + eurnzdRsi + eurusdRsi + eurcadRsi) / 7, 4);
         double gbpStrength = NormalizeDouble((100-eurgbpRsi + gbpchfRsi + gbpjpyRsi + gbpaudRsi + gbpnzdRsi + gbpusdRsi + gbpcadRsi) / 7, 4);
         double chfStrength = NormalizeDouble((100-eurchfRsi + 100-gbpchfRsi + chfjpyRsi + 100-audchfRsi + 100-nzdchfRsi + 100-usdchfRsi + 100-cadchfRsi) / 7, 4);
         double jpyStrength = NormalizeDouble((100-eurjpyRsi + 100-gbpjpyRsi + 100-chfjpyRsi + 100-audjpyRsi + 100-nzdjpyRsi + 100-usdjpyRsi + 100-cadjpyRsi) / 7, 4);
         double audStrength = NormalizeDouble((100-euraudRsi + 100-gbpaudRsi + audchfRsi + audjpyRsi + audnzdRsi + audusdRsi + audcadRsi) / 7, 4);
         double nzdStrength = NormalizeDouble((100-eurnzdRsi + 100-gbpnzdRsi + nzdchfRsi + nzdjpyRsi + 100-audnzdRsi + nzdusdRsi + nzdcadRsi) / 7, 4);
         double usdStrength = NormalizeDouble((100-eurusdRsi + 100-gbpusdRsi + usdchfRsi + usdjpyRsi + 100-audusdRsi + 100-nzdusdRsi + usdcadRsi) / 7, 4);
         double cadStrength = NormalizeDouble((100-eurcadRsi + 100-gbpcadRsi + cadchfRsi + cadjpyRsi + 100-audcadRsi + 100-nzdcadRsi + 100-usdcadRsi) / 7, 4);

         EURBuffer[i] = eurStrength;
         GBPBuffer[i] = gbpStrength;
         CHFBuffer[i] = chfStrength;
         JPYBuffer[i] = jpyStrength;
         AUDBuffer[i] = audStrength;
         NZDBuffer[i] = nzdStrength;
         USDBuffer[i] = usdStrength;
         CADBuffer[i] = cadStrength;
      }
   }
//--- return value of prev_calculated for next call
   return(rates_total);
}
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
//---
   double eurgbpRsi = getSymbolRsi("EURGBP");
   double eurchfRsi = getSymbolRsi("EURCHF");
   double eurjpyRsi = getSymbolRsi("EURJPY");
   double euraudRsi = getSymbolRsi("EURAUD");
   double eurnzdRsi = getSymbolRsi("EURNZD");
   double eurusdRsi = getSymbolRsi("EURUSD");
   double eurcadRsi = getSymbolRsi("EURCAD");
   double gbpchfRsi = getSymbolRsi("GBPCHF");
   double gbpjpyRsi = getSymbolRsi("GBPJPY");
   double gbpaudRsi = getSymbolRsi("GBPAUD");
   double gbpnzdRsi = getSymbolRsi("GBPNZD");
   double gbpusdRsi = getSymbolRsi("GBPUSD");
   double gbpcadRsi = getSymbolRsi("GBPCAD");
   double chfjpyRsi = getSymbolRsi("CHFJPY");
   double audchfRsi = getSymbolRsi("AUDCHF");
   double nzdchfRsi = getSymbolRsi("NZDCHF");
   double usdchfRsi = getSymbolRsi("USDCHF");
   double cadchfRsi = getSymbolRsi("CADCHF");
   double audjpyRsi = getSymbolRsi("AUDJPY");
   double nzdjpyRsi = getSymbolRsi("NZDJPY");
   double usdjpyRsi = getSymbolRsi("USDJPY");
   double cadjpyRsi = getSymbolRsi("CADJPY");
   double audnzdRsi = getSymbolRsi("AUDNZD");
   double audusdRsi = getSymbolRsi("AUDUSD");
   double audcadRsi = getSymbolRsi("AUDCAD");
   double nzdusdRsi = getSymbolRsi("NZDUSD");
   double nzdcadRsi = getSymbolRsi("NZDCAD");
   double usdcadRsi = getSymbolRsi("USDCAD");

   double eurStrength = NormalizeDouble((eurgbpRsi + eurchfRsi + eurjpyRsi + euraudRsi + eurnzdRsi + eurusdRsi + eurcadRsi) / 7, 4);
   double gbpStrength = NormalizeDouble((100-eurgbpRsi + gbpchfRsi + gbpjpyRsi + gbpaudRsi + gbpnzdRsi + gbpusdRsi + gbpcadRsi) / 7, 4);
   double chfStrength = NormalizeDouble((100-eurchfRsi + 100-gbpchfRsi + chfjpyRsi + 100-audchfRsi + 100-nzdchfRsi + 100-usdchfRsi + 100-cadchfRsi) / 7, 4);
   double jpyStrength = NormalizeDouble((100-eurjpyRsi + 100-gbpjpyRsi + 100-chfjpyRsi + 100-audjpyRsi + 100-nzdjpyRsi + 100-usdjpyRsi + 100-cadjpyRsi) / 7, 4);
   double audStrength = NormalizeDouble((100-euraudRsi + 100-gbpaudRsi + audchfRsi + audjpyRsi + audnzdRsi + audusdRsi + audcadRsi) / 7, 4);
   double nzdStrength = NormalizeDouble((100-eurnzdRsi + 100-gbpnzdRsi + nzdchfRsi + nzdjpyRsi + 100-audnzdRsi + nzdusdRsi + nzdcadRsi) / 7, 4);
   double usdStrength = NormalizeDouble((100-eurusdRsi + 100-gbpusdRsi + usdchfRsi + usdjpyRsi + 100-audusdRsi + 100-nzdusdRsi + usdcadRsi) / 7, 4);
   double cadStrength = NormalizeDouble((100-eurcadRsi + 100-gbpcadRsi + cadchfRsi + cadjpyRsi + 100-audcadRsi + 100-nzdcadRsi + 100-usdcadRsi) / 7, 4);

   CArrayListClass<CurrStrengthItem>* CSIList = new CArrayListClass<CurrStrengthItem>();
   CSIList.add(new CurrStrengthItem("EUR", eurStrength));
   CSIList.add(new CurrStrengthItem("GBP", gbpStrength));
   CSIList.add(new CurrStrengthItem("CHF", chfStrength));
   CSIList.add(new CurrStrengthItem("JPY", jpyStrength));
   CSIList.add(new CurrStrengthItem("AUD", audStrength));
   CSIList.add(new CurrStrengthItem("NZD", nzdStrength));
   CSIList.add(new CurrStrengthItem("USD", usdStrength));
   CSIList.add(new CurrStrengthItem("CAD", cadStrength));
   CSIList.SortDesc();

   for(int i=0; i<CSIList.size(); i++) {
      string objName = "CSI_Label_" + IntegerToString(i);
      ObjectSetString(0, objName, OBJPROP_TEXT, CSIList[i].currency + " " + DoubleToString(CSIList[i].strength, 1));
   }
   ObjectSetString(0, "CSI_Label_8", OBJPROP_TEXT, _Symbol + " " + DoubleToString(getSymbolRsi(_Symbol),1));
   ObjectSetString(0, "CSI_Label_9", OBJPROP_TEXT, "Avg Range " + DoubleToString(getAvgRangeInPoint(inpAvgRangePeriod),0) + " points");
   ObjectSetString(0, "CSI_Label_10", OBJPROP_TEXT, "Spread " + DoubleToString(getSpreadInPoint(),0) + " points");
   ChartRedraw();

   CSIList.clear();
   delete CSIList;
}
//+------------------------------------------------------------------+
double getSymbolRsi(string symbol, datetime time = 0) {
   int rsiHandle;

   if(symbol == "EURGBP") {
      rsiHandle = eurgbpRsiHandle;
   } else if (symbol == "EURCHF") {
      rsiHandle = eurchfRsiHandle;
   } else if (symbol == "EURJPY") {
      rsiHandle = eurjpyRsiHandle;
   } else if (symbol == "EURAUD") {
      rsiHandle = euraudRsiHandle;
   } else if (symbol == "EURNZD") {
      rsiHandle = eurnzdRsiHandle;
   } else if (symbol == "EURUSD") {
      rsiHandle = eurusdRsiHandle;
   } else if (symbol == "EURCAD") {
      rsiHandle = eurcadRsiHandle;
   } else if (symbol == "GBPCHF") {
      rsiHandle = gbpchfRsiHandle;
   } else if (symbol == "GBPJPY") {
      rsiHandle = gbpjpyRsiHandle;
   } else if (symbol == "GBPAUD") {
      rsiHandle = gbpaudRsiHandle;
   } else if (symbol == "GBPNZD") {
      rsiHandle = gbpnzdRsiHandle;
   } else if (symbol == "GBPUSD") {
      rsiHandle = gbpusdRsiHandle;
   } else if (symbol == "GBPCAD") {
      rsiHandle = gbpcadRsiHandle;
   } else if (symbol == "CHFJPY") {
      rsiHandle = chfjpyRsiHandle;
   } else if (symbol == "AUDCHF") {
      rsiHandle = audchfRsiHandle;
   } else if (symbol == "NZDCHF") {
      rsiHandle = nzdchfRsiHandle;
   } else if (symbol == "USDCHF") {
      rsiHandle = usdchfRsiHandle;
   } else if (symbol == "CADCHF") {
      rsiHandle = cadchfRsiHandle;
   } else if (symbol == "AUDJPY") {
      rsiHandle = audjpyRsiHandle;
   } else if (symbol == "NZDJPY") {
      rsiHandle = nzdjpyRsiHandle;
   } else if (symbol == "USDJPY") {
      rsiHandle = usdjpyRsiHandle;
   } else if (symbol == "CADJPY") {
      rsiHandle = cadjpyRsiHandle;
   } else if (symbol == "AUDNZD") {
      rsiHandle = audnzdRsiHandle;
   } else if (symbol == "AUDUSD") {
      rsiHandle = audusdRsiHandle;
   } else if (symbol == "AUDCAD") {
      rsiHandle = audcadRsiHandle;
   } else if (symbol == "NZDUSD") {
      rsiHandle = nzdusdRsiHandle;
   } else if (symbol == "NZDCAD") {
      rsiHandle = nzdcadRsiHandle;
   } else if (symbol == "USDCAD") {
      rsiHandle = usdcadRsiHandle;
   } else {
      Print("warning getCurrentRsi return 0; symbol=" + symbol);
      return 0;
   }

   double buffer[];
   if(time == 0) {
      CopyBuffer(rsiHandle, 0, 0, 1, buffer);
   } else {
      CopyBuffer(rsiHandle, 0, time, 1, buffer);
   }

   return buffer[0];
}
//+------------------------------------------------------------------+
double getAvgRangeInPoint(int period) {
   MqlRates rates[];
   CopyRates(_Symbol, PERIOD_CURRENT, 1, period, rates);
   double avgRange = 0;
   for(int i=0; i<ArraySize(rates); i++) {
      avgRange = avgRange + (rates[i].high - rates[i].low);
   }
   return (avgRange / period) / _Point;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getSpreadInPoint() {
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   return (ask - bid) / _Point;
}
//+------------------------------------------------------------------+
