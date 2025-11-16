//+------------------------------------------------------------------+
//|                                                         DVP1.mq5 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   4
//-- filling color
#property indicator_label1  "Filling"
#property indicator_type1   DRAW_FILLING
#property indicator_color1  clrDarkGreen
#property indicator_width1  1
//--- plot VAH
#property indicator_label2  "VAH"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrWhiteSmoke
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- plot VAL
#property indicator_label3  "VAL"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrWhiteSmoke
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
//--- plot POC
#property indicator_label4  "POC"
#property indicator_type4  DRAW_LINE
#property indicator_color4  clrBlue
#property indicator_style4  DRAW_LINE
#property indicator_width4  1
//--- input parameters
input datetime StartDate        = 0;
input datetime EndDate          = 0;
input int      inpPeriod        = 60;
input bool     inpUseFixedNRows = true;
input int      inpNRows         = 100;
input double   inpPctValueArea  = 70;
input bool     showValueArea    = true;
//--- indicator buffers
double         POCBuffer[];
double         VAHBuffer[];
double         VALBuffer[];

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
   SetIndexBuffer(0, VAHBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, VALBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, POCBuffer, INDICATOR_DATA);
//---
   EventSetTimer(60);
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
//--- return value of prev_calculated for next call
   return(rates_total);
}
//+------------------------------------------------------------------+
void OnTimer() {
   EventKillTimer();
   // get poc range by last swing
//   SwingPoint swingList[];
//   getSwingList(swingList);
//   for(int i = ArraySize(swingList) - 1; i > 0; i--) {
//      if(swingList[i].type != swingList[i-1].type) {
//         long volumes[];
//         double poc = calculatePoc(swingList[i-1].date, swingList[i].date, volumes);
//         
//         break;
//      }
//   }
   
   // get poc range by rectangle
   //for(int i=0; i<ObjectsTotal(0, 0, OBJ_RECTANGLE); i++) {
   //   string name = ObjectName(0, i, 0, OBJ_TREND);
   //   if (name.Substr(0, 8) == "FVP_RECT") {
   //      double p1 = ObjectGetDouble(0, name, OBJPROP_PRICE, 0);
   //      datetime t1 = ObjectGetInteger(0, name, OBJPROP_TIME, 0);
   //      double p2 = ObjectGetDouble(0, name, OBJPROP_PRICE, 1);
   //      datetime t2 = ObjectGetInteger(0, name, OBJPROP_TIME, 1);
   //      long volumes[];
   //      double minPrice;
   //      double maxPrice;
   //      double poc = calculatePoc(t1, t2, minPrice, maxPrice, volumes);
   //      drawHistogram(t1, t2, minPrice, maxPrice, volumes);
   //   }
   //}
   
   // test
   datetime t1 = D'2022.09.06 10:00:00';
   datetime t2 = D'2022.09.06 17:00:00';
   long volumes[];
   double minPrice;
   double maxPrice;
   double poc = calculatePoc(t1, t2, minPrice, maxPrice, volumes);
   drawHistogram(t1, t2, minPrice, maxPrice, volumes);
   EventSetTimer(60);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int getPriceLevel(double price, double min, double d, int nrow) {
   return MathMin(MathFloor((price - min) / d) + 1, nrow);
}
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

double calculatePoc(datetime startDate, datetime endDate, double &minPrice, double &maxPrice, long &volumes[]) {
   MqlRates rates[];
   int nBars = (endDate - startDate) / 60;
   int nRates = CopyRates(_Symbol, PERIOD_M1, startDate, endDate, rates);
   if (nRates < nBars) {
      return 0;
   }
   double max = rates[0].high;
   double min = rates[0].low;
   for(int i=1; i<ArraySize(rates); i++) {
      if (rates[i].high > max) {
         max = rates[i].high;
      }
      if (rates[i].low < min) {
         min = rates[i].low;
      }
   }
   double d = 0;
   if (inpUseFixedNRows ) {
      d = _Point * 10;
   }
   else {
      if (inpNRows != 0) {
         d = (max - min) / inpNRows;
      }
      else {
         d = (max - min) / 100;
      }
   }
   
   long totalVolume=0;
   //long volumes[];
   ArrayResize(volumes,inpNRows+1);
   ArrayFill(volumes,0,inpNRows+1,0);
   for(int j=0; j<ArraySize(rates)-1; j++) {
      int lvl=getPriceLevel(rates[j].close,min,d,inpNRows);
      volumes[lvl]+=rates[j].tick_volume;
      totalVolume+=rates[j].tick_volume;
   }

   long pocVol=0.0;
   int pocLevel=0;
   for(int j=1; j<=inpNRows; j++) {
      long vol=volumes[j];
      if(vol>pocVol) {
         pocLevel=j;
         pocVol=vol;
      }
   }
   
   minPrice = min;
   maxPrice = max;
   return NormalizeDouble(min + (pocLevel - 0.5) * d, _Digits);;
}

void drawHistogram(datetime dateFrom, datetime dateTo, double minPrice, double maxPrice, long &volumes[]) {
   ObjectsDeleteAll(0, "FVP_HIST", 0, OBJ_RECTANGLE);
   double maxLevelCount = volumes[ArrayMaximum(volumes, 0, WHOLE_ARRAY)];
   int histSize = 50;
   datetime t0 = TimeCurrent() - histSize*PeriodSeconds();
   double avg = 0;
   double cnt = 0;
   for(int j=0; j<ArraySize(volumes); j++) {
      if (volumes[j] > 0) {
         avg += volumes[j];
         cnt += 1;
      }
   }
   avg /= cnt;
   avg = ceil(avg);
   double d = _Point*10;
   if (!inpUseFixedNRows) {
      d = (maxPrice - minPrice) / ArraySize(volumes);
   }
   for(int j=0; j<ArraySize(volumes); j++) {
      if (volumes[j] > avg) {
         datetime t1 = t0 + ((histSize - (volumes[j] / maxLevelCount * histSize)) * PeriodSeconds());
         //double p1 = minPriceNormalize + (j*inpLevelInterval*_Point);
         double p1 = minPrice + j*d;
         datetime t2 = TimeCurrent() + (3*PeriodSeconds());
         //double p2 = p1 + (inpLevelInterval*_Point);
         double p2 = p1 + d;
   
         ObjectCreate(0, "PP_LEVEL_" + IntegerToString(j), OBJ_RECTANGLE, 0, t1, p1, t2, p2);
      }
   }
   ChartRedraw();
}