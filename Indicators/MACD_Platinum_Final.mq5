//+------------------------------------------------------------------+
//|                                    MACD_Platinum_NoSignal.mq5   |
//|  MT5: MACD main line + bi-color histogram (no signal line plot) |
//+------------------------------------------------------------------+
#property strict
#property indicator_separate_window
#property indicator_plots 3
#property indicator_buffers 3

//--- MACD Main line
#property indicator_label1  "MACD Main"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDodgerBlue
#property indicator_width1  2
//--- Histogram up
#property indicator_label2  "Hist Up"
#property indicator_type2   DRAW_HISTOGRAM
#property indicator_color2  clrLime
#property indicator_width2  3
//--- Histogram down
#property indicator_label3  "Hist Down"
#property indicator_type3   DRAW_HISTOGRAM
#property indicator_color3  clrTomato
#property indicator_width3  3

//---- Inputs
input int      FastEMA      = 8;
input int      SlowEMA      = 13;
input int      SignalPeriod = 9;
input ENUM_APPLIED_PRICE PriceType = PRICE_CLOSE;
input bool     AlertOnCross = false;   // popup when MACD main crosses its signal

//---- Output buffers
double MainBuf[], HistUpBuf[], HistDnBuf[];

//---- Internal arrays / handle
double macdMain[], macdSignal[];   // signal is computed internally but not shown
int    hMACD = INVALID_HANDLE;

//+------------------------------------------------------------------+
//| OnInit                                                           |
//+------------------------------------------------------------------+
int OnInit()
{
   IndicatorSetString(INDICATOR_SHORTNAME,"Biden MACD");

   SetIndexBuffer(0, MainBuf,   INDICATOR_DATA);
   SetIndexBuffer(1, HistUpBuf, INDICATOR_DATA);
   SetIndexBuffer(2, HistDnBuf, INDICATOR_DATA);

   ArraySetAsSeries(MainBuf,   true);
   ArraySetAsSeries(HistUpBuf, true);
   ArraySetAsSeries(HistDnBuf, true);

   // zero line for reference
   IndicatorSetInteger(INDICATOR_LEVELS, 1);
   IndicatorSetDouble (INDICATOR_LEVELVALUE, 0, 0.0);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR, clrSilver);

   // MACD handle
   hMACD = iMACD(_Symbol, _Period, FastEMA, SlowEMA, SignalPeriod, PriceType);
   if(hMACD == INVALID_HANDLE) return(INIT_FAILED);

   ArraySetAsSeries(macdMain,  true);
   ArraySetAsSeries(macdSignal,true);

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| OnCalculate                                                      |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime& time[],
                const double& open[],
                const double& high[],
                const double& low[],
                const double& close[],
                const long& tick_volume[],
                const long& volume[],
                const int& spread[])
{
   if(rates_total < SlowEMA + SignalPeriod + 5) return(0);

   // size internal arrays
   ArrayResize(macdMain,  rates_total);
   ArrayResize(macdSignal,rates_total);

   // copy MACD buffers: 0 = main, 1 = signal
   if(CopyBuffer(hMACD,0,0,rates_total,macdMain)   <= 0) return(prev_calculated);
   if(CopyBuffer(hMACD,1,0,rates_total,macdSignal) <= 0) return(prev_calculated);

   // ensure i+1 exists when checking crosses -> start <= rates_total-2
   int start = (prev_calculated>0 ? rates_total - prev_calculated : rates_total - 2);
   if(start > rates_total - 2) start = rates_total - 2;
   if(start < 0) start = 0;

   for(int i=start; i>=0; --i)
   {
      // MACD main line
      MainBuf[i] = macdMain[i];

      // Histogram relative to signal (classic)
      double hist = macdMain[i] - macdSignal[i];
      if(hist >= 0.0) { HistUpBuf[i] = hist; HistDnBuf[i] = EMPTY_VALUE; }
      else            { HistDnBuf[i] = hist; HistUpBuf[i] = EMPTY_VALUE; }

      // Optional alert on the most recent completed bar
      if(AlertOnCross && i==1)
      {
         bool crossUp   = (macdMain[i] > macdSignal[i]) && (macdMain[i+1] <= macdSignal[i+1]);
         bool crossDown = (macdMain[i] < macdSignal[i]) && (macdMain[i+1] >= macdSignal[i+1]);
         if(crossUp)   Alert("MACD Platinum: BUY cross on ", _Symbol, " ", EnumToString((ENUM_TIMEFRAMES)_Period));
         if(crossDown) Alert("MACD Platinum: SELL cross on ", _Symbol, " ", EnumToString((ENUM_TIMEFRAMES)_Period));
      }
   }
   return(rates_total);
}
//+------------------------------------------------------------------+
