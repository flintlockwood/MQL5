//+------------------------------------------------------------------+
//|                                           FixedVolumeProfile.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
//--- input parameters
input datetime StartDate;
input datetime EndDate;
input int      NRows = 100;
input int      VAPct = 70;

class SwingPoint {
 public:
   datetime          date;
   double            price;
   string            type;
   int               flag;
   MqlRates          rates;

                     SwingPoint() {
   }

                     SwingPoint(const SwingPoint &old) {
      date = old.date;
      price = old.price;
      type = old.type;
      flag = old.flag;
   }

                     SwingPoint(MqlRates &pRates, string pType) {
      rates = pRates;
      date = pRates.time;
      type = pType;
      if (type == "SH") {
         price = pRates.high;
      } else if (type == "SL") {
         price = pRates.low;
      }
   }
};
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//--- indicator buffers mapping
   EventSetTimer(60);
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
                const int &spread[]) {
//---

//--- return value of prev_calculated for next call
   return(rates_total);
}
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
//---
   SwingPoint swingList[];
   getSwingList(swingList);
   for(int i = ArraySize(swingList) - 1; i > 0; i--) {
      if(swingList[i].type != swingList[i-1].type) {
         double poc = calculatePoc(swingList[i-1].date, swingList[i].date);
      }
   }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void getSwingList(SwingPoint &swingList[]) {
   MqlRates rates[];
   int nswing = 10;
   CopyRates(_Symbol, _Period, 0, 500, rates);
   for(int i = nswing; i < ArraySize(rates) - 1; i++) {
      MqlRates temprates[];
      ArrayCopy(temprates, rates, 0, i - nswing, nswing + 1);
      if (isSwingHigh(temprates)) {
         SwingPoint* sp = new SwingPoint(temprates[nswing / 2], "SH");
         ArrayResize(swingList, ArraySize(swingList) + 1, 10);
         swingList[ArraySize(swingList) - 1] = sp;
      } else if (isSwingLow(temprates)) {
         SwingPoint* sp = new SwingPoint(temprates[nswing / 2], "SL");
         ArrayResize(swingList, ArraySize(swingList) + 1, 10);
         swingList[ArraySize(swingList) - 1] = sp;
      }
   }
}
//+------------------------------------------------------------------+
bool isSwingHigh(MqlRates &rates[]) {
   bool ret = false;
   int n = ArraySize(rates);
   if (n % 2 == 1) {
      int mid = (n - 1) / 2;
      double maxPrice = rates[0].high;
      int maxIndex = 0;
      for(int i = 1; i < n; i++) {
         if (rates[i].high > maxPrice) {
            maxPrice = rates[i].high;
            maxIndex = i;
         }
      }
      ret = maxIndex == mid;
   }
   return ret;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isSwingLow(MqlRates &rates[]) {
   bool ret = false;
   int n = ArraySize(rates);
   if (n % 2 == 1) {
      int mid = (n - 1) / 2;
      double minPrice = rates[0].low;
      int minIndex = 0;
      for(int i = 1; i < n; i++) {
         if (rates[i].low < minPrice) {
            minPrice = rates[i].low;
            minIndex = i;
         }
      }
      ret = minIndex == mid;
   }
   return ret;
}
//+------------------------------------------------------------------+
double calculatePoc(datetime startDate, datetime endDate) {
   MqlRates rates[];
   CopyRates(_Symbol, PERIOD_M1, startDate, endDate, rates);
   double max = rates[0].high;
   double min = rates[0].low;
   for(int i=1; i<ArraySize(rates)-1; i++) {
      if (rates[i].high > max) {
         max = rates[i].high;
      }
      if (rates[i].low < min) {
         min = rates[i].low;
      }
   }
   double d  =0;
   if (NRows != 0) {
      d = (max - min) / NRows;
   }
   else {
      d = (max - min) / 100;
   }
   
   long totalVolume=0;
   long levelVolume[];
   ArrayResize(levelVolume,NRows+1);
   ArrayFill(levelVolume,0,NRows+1,0);
   for(int j=0; j<ArraySize(rates)-1; j++) {
      int lvl=getPriceLevel(rates[j].close,min,d,NRows);
      levelVolume[lvl]+=rates[j].tick_volume;
      totalVolume+=rates[j].tick_volume;
   }

   long pocVol=0.0;
   int pocLevel=0;
   for(int j=1; j<=NRows; j++) {
      long vol=levelVolume[j];
      if(vol>pocVol) {
         pocLevel=j;
         pocVol=vol;
      }
   }
   return pocLevel;
}

int getPriceLevel(double price,double min,double d,int nrow) {
   return MathMin(MathFloor((price-min)/d)+1, nrow);
}