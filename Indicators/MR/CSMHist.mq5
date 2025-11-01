//+------------------------------------------------------------------+
//|                                                      CSMHist.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 8
#property indicator_plots   8
#property indicator_minimum 0
#property indicator_maximum 100
#property indicator_level1 40
#property indicator_level2 60

#property indicator_label1  "AUD"
#property indicator_type1  DRAW_LINE
#property indicator_color1  clrRed

#property indicator_label2  "CAD"
#property indicator_type2  DRAW_LINE
#property indicator_color2  clrGreen

#property indicator_label3  "CHF"
#property indicator_type3  DRAW_LINE
#property indicator_color3  clrBlue

#property indicator_label4  "EUR"
#property indicator_type4  DRAW_LINE
#property indicator_color4  clrYellow

#property indicator_label5  "GBP"
#property indicator_type5  DRAW_LINE
#property indicator_color5  clrWhite

#property indicator_label6  "NZD"
#property indicator_type6  DRAW_LINE
#property indicator_color6  clrPink

#property indicator_label7  "USD"
#property indicator_type7  DRAW_LINE
#property indicator_color7  clrCyan

#property indicator_label8  "JPY"
#property indicator_type8  DRAW_LINE
#property indicator_color8  clrMagenta

#include <Generic\HashMap.mqh>

//--- input parameters
input int             inpPeriod = 12;
input ENUM_TIMEFRAMES inpTF     = PERIOD_H1;
input bool showAud              = true;
input bool showCad              = true;
input bool showChf              = true;
input bool showEur              = true;
input bool showGbp              = true;
input bool showNzd              = true;
input bool showUsd              = true;
input bool showJpy              = true;
//--- indicator buffers
double    AudBuffer[];
double    CadBuffer[];
double    ChfBuffer[];
double    EurBuffer[];
double    GbpBuffer[];
double    NzdBuffer[];
double    UsdBuffer[];
double    JpyBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,AudBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,CadBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,ChfBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,EurBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,GbpBuffer,INDICATOR_DATA);
   SetIndexBuffer(5,NzdBuffer,INDICATOR_DATA);
   SetIndexBuffer(6,UsdBuffer,INDICATOR_DATA);
   SetIndexBuffer(7,JpyBuffer,INDICATOR_DATA);
   
   IndicatorSetInteger(INDICATOR_DIGITS,2);
//---
   return(INIT_SUCCEEDED);
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
                const int &spread[])
  {
//---
   int pos = prev_calculated;
   if(pos<inpPeriod+1) {
      for(int i=0;i<inpPeriod+1;i++) {
         AudBuffer[i]=EMPTY_VALUE;
         CadBuffer[i]=EMPTY_VALUE;
         ChfBuffer[i]=EMPTY_VALUE;
         EurBuffer[i]=EMPTY_VALUE;
         GbpBuffer[i]=EMPTY_VALUE;
         NzdBuffer[i]=EMPTY_VALUE;
         UsdBuffer[i]=EMPTY_VALUE;
         JpyBuffer[i]=EMPTY_VALUE;
      }
      pos = inpPeriod+1;
   }

   for(int i=pos;i<rates_total && !IsStopped();i++) {
      AudBuffer[i]=EMPTY_VALUE;
      CadBuffer[i]=EMPTY_VALUE;
      ChfBuffer[i]=EMPTY_VALUE;
      EurBuffer[i]=EMPTY_VALUE;
      GbpBuffer[i]=EMPTY_VALUE;
      NzdBuffer[i]=EMPTY_VALUE;
      UsdBuffer[i]=EMPTY_VALUE;
      JpyBuffer[i]=EMPTY_VALUE;
      
      datetime inpTime[];
      ArrayCopy(inpTime, time, 0, i-inpPeriod-1, inpPeriod+1);
         
      double eurgbpRoc = getCurrentRsi("EURGBP", inpTime);
      double eurchfRoc = getCurrentRsi("EURCHF", inpTime);
      double eurjpyRoc = getCurrentRsi("EURJPY", inpTime);
      double euraudRoc = getCurrentRsi("EURAUD", inpTime);
      double eurnzdRoc = getCurrentRsi("EURNZD", inpTime);
      double eurusdRoc = getCurrentRsi("EURUSD", inpTime);
      double eurcadRoc = getCurrentRsi("EURCAD", inpTime);
      double gbpchfRoc = getCurrentRsi("GBPCHF", inpTime);
      double gbpjpyRoc = getCurrentRsi("GBPJPY", inpTime);
      double gbpaudRoc = getCurrentRsi("GBPAUD", inpTime);
      double gbpnzdRoc = getCurrentRsi("GBPNZD", inpTime);
      double gbpusdRoc = getCurrentRsi("GBPUSD", inpTime);
      double gbpcadRoc = getCurrentRsi("GBPCAD", inpTime);
      double chfjpyRoc = getCurrentRsi("CHFJPY", inpTime);
      double audchfRoc = getCurrentRsi("AUDCHF", inpTime);
      double nzdchfRoc = getCurrentRsi("NZDCHF", inpTime);
      double usdchfRoc = getCurrentRsi("USDCHF", inpTime);
      double cadchfRoc = getCurrentRsi("CADCHF", inpTime);
      double audjpyRoc = getCurrentRsi("AUDJPY", inpTime);
      double nzdjpyRoc = getCurrentRsi("NZDJPY", inpTime);
      double usdjpyRoc = getCurrentRsi("USDJPY", inpTime);
      double cadjpyRoc = getCurrentRsi("CADJPY", inpTime);
      double audnzdRoc = getCurrentRsi("AUDNZD", inpTime);
      double audusdRoc = getCurrentRsi("AUDUSD", inpTime);
      double audcadRoc = getCurrentRsi("AUDCAD", inpTime);
      double nzdusdRoc = getCurrentRsi("NZDUSD", inpTime);
      double nzdcadRoc = getCurrentRsi("NZDCAD", inpTime);
      double usdcadRoc = getCurrentRsi("USDCAD", inpTime);
      
      //double eurgbpRoc = getCurrentRsi2("EURGBP", PERIOD_CURRENT, 14);
      //double eurchfRoc = getCurrentRsi2("EURCHF", PERIOD_CURRENT, 14);
      //double eurjpyRoc = getCurrentRsi2("EURJPY", PERIOD_CURRENT, 14);
      //double euraudRoc = getCurrentRsi2("EURAUD", PERIOD_CURRENT, 14);
      //double eurnzdRoc = getCurrentRsi2("EURNZD", PERIOD_CURRENT, 14);
      //double eurusdRoc = getCurrentRsi2("EURUSD", PERIOD_CURRENT, 14);
      //double eurcadRoc = getCurrentRsi2("EURCAD", PERIOD_CURRENT, 14);
      //double gbpchfRoc = getCurrentRsi2("GBPCHF", PERIOD_CURRENT, 14);
      //double gbpjpyRoc = getCurrentRsi2("GBPJPY", PERIOD_CURRENT, 14);
      //double gbpaudRoc = getCurrentRsi2("GBPAUD", PERIOD_CURRENT, 14);
      //double gbpnzdRoc = getCurrentRsi2("GBPNZD", PERIOD_CURRENT, 14);
      //double gbpusdRoc = getCurrentRsi2("GBPUSD", PERIOD_CURRENT, 14);
      //double gbpcadRoc = getCurrentRsi2("GBPCAD", PERIOD_CURRENT, 14);
      //double chfjpyRoc = getCurrentRsi2("CHFJPY", PERIOD_CURRENT, 14);
      //double audchfRoc = getCurrentRsi2("AUDCHF", PERIOD_CURRENT, 14);
      //double nzdchfRoc = getCurrentRsi2("NZDCHF", PERIOD_CURRENT, 14);
      //double usdchfRoc = getCurrentRsi2("USDCHF", PERIOD_CURRENT, 14);
      //double cadchfRoc = getCurrentRsi2("CADCHF", PERIOD_CURRENT, 14);
      //double audjpyRoc = getCurrentRsi2("AUDJPY", PERIOD_CURRENT, 14);
      //double nzdjpyRoc = getCurrentRsi2("NZDJPY", PERIOD_CURRENT, 14);
      //double usdjpyRoc = getCurrentRsi2("USDJPY", PERIOD_CURRENT, 14);
      //double cadjpyRoc = getCurrentRsi2("CADJPY", PERIOD_CURRENT, 14);
      //double audnzdRoc = getCurrentRsi2("AUDNZD", PERIOD_CURRENT, 14);
      //double audusdRoc = getCurrentRsi2("AUDUSD", PERIOD_CURRENT, 14);
      //double audcadRoc = getCurrentRsi2("AUDCAD", PERIOD_CURRENT, 14);
      //double nzdusdRoc = getCurrentRsi2("NZDUSD", PERIOD_CURRENT, 14);
      //double nzdcadRoc = getCurrentRsi2("NZDCAD", PERIOD_CURRENT, 14);
      //double usdcadRoc = getCurrentRsi2("USDCAD", PERIOD_CURRENT, 14);
   
      double eurStrength = NormalizeDouble((eurgbpRoc + eurchfRoc + eurjpyRoc + euraudRoc + eurnzdRoc + eurusdRoc + eurcadRoc) / 7, 4);
      double gbpStrength = NormalizeDouble((100-eurgbpRoc + gbpchfRoc + gbpjpyRoc + gbpaudRoc + gbpnzdRoc + gbpusdRoc + gbpcadRoc) / 7, 4);
      double chfStrength = NormalizeDouble((100-eurchfRoc + 100-gbpchfRoc + chfjpyRoc + 100-audchfRoc + 100-nzdchfRoc + 100-usdchfRoc + 100-cadchfRoc) / 7, 4);
      double jpyStrength = NormalizeDouble((100-eurjpyRoc + 100-gbpjpyRoc + 100-chfjpyRoc + 100-audjpyRoc + 100-nzdjpyRoc + 100-usdjpyRoc + 100-cadjpyRoc) / 7, 4);
      double audStrength = NormalizeDouble((100-euraudRoc + 100-gbpaudRoc + audchfRoc + audjpyRoc + audnzdRoc + audusdRoc + audcadRoc) / 7, 4);
      double nzdStrength = NormalizeDouble((100-eurnzdRoc + 100-gbpnzdRoc + nzdchfRoc + nzdjpyRoc + 100-audnzdRoc + nzdusdRoc + nzdcadRoc) / 7, 4);
      double usdStrength = NormalizeDouble((100-eurusdRoc + 100-gbpusdRoc + usdchfRoc + usdjpyRoc + 100-audusdRoc + 100-nzdusdRoc + usdcadRoc) / 7, 4);
      double cadStrength = NormalizeDouble((100-eurcadRoc + 100-gbpcadRoc + cadchfRoc + cadjpyRoc + 100-audcadRoc + 100-nzdcadRoc + 100-usdcadRoc) / 7, 4);
      
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
      
      if (showAud) {
         AudBuffer[i]=audStrength;
      }
      if (showCad) {
         CadBuffer[i]=cadStrength;
      }
      if (showChf) {
         ChfBuffer[i]=chfStrength;
      }
      if (showEur) {
         EurBuffer[i]=eurStrength;
      }
      if (showGbp) {
         GbpBuffer[i]=gbpStrength;
      }
      if (showNzd) {
         NzdBuffer[i]=nzdStrength;
      }
      if (showUsd) {
         UsdBuffer[i]=usdStrength;
      }
      if (showJpy) {
         JpyBuffer[i]=jpyStrength;
      }
   }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+

double getCurrentRsi(string symbol, datetime &time[]) {
   MqlRates rates[];
   int cnt = CopyRates(symbol, PERIOD_CURRENT, time[0], time[ArraySize(time)-1], rates);
   if (cnt != ArraySize(time)) {
      return 0;
   }
   
   double price[];
   ArrayResize(price, ArraySize(time));
   for(int i=0; i<ArraySize(time); i++) {
      price[i] = rates[i].close;
   }
   int period = ArraySize(price) - 1;
   double gain[];
   double loss[];
   ArrayResize(gain, period);
   ArrayResize(loss, period);
   double avggain = 0;
   double avgloss = 0;
   double rs = 0;
   double rsi = 0;
   
   for(int i=1; i<ArraySize(price); i++){
      gain[i-1] = price[i] - price[i-1] < 0 ? 0 : price[i] - price[i-1];
      loss[i-1] = price[i-1] - price[i] < 0 ? 0 : price[i-1] - price[i];
      avggain = avggain + gain[i-1];
      avgloss = avgloss + loss[i-1];
   }
   avggain = avggain / period;
   avgloss = avgloss / period;
   rs = avgloss == 0 ? 0 : avggain / avgloss;
   rsi = avgloss == 0 ? 100 : 100 - (100 / (1 + rs));
   
   return rsi;
}

double getCurrentRsi2(string symbol, ENUM_TIMEFRAMES tf, int period) {
   int rsiHandle = iRSI(symbol, tf, period, PRICE_CLOSE);
   if (rsiHandle != INVALID_HANDLE) {
      double rsiBuffer[];
      CopyBuffer(rsiHandle,0,0,1,rsiBuffer);
      return rsiBuffer[0];
   }
   return 0;
}