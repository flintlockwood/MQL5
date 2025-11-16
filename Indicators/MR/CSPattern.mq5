//+------------------------------------------------------------------+
//|                                                    CSPattern.mq5 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 12
#property indicator_plots   12
//--- plot BullishEngulfing
#property indicator_label1  "BullishEngulfing"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot BearishEngulfing
#property indicator_label2  "BearishEngulfing"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrYellow
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- plot BullishMarubozu
#property indicator_label3  "BullishMarubozu"
#property indicator_type3   DRAW_ARROW
#property indicator_color3  clrBlue
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
//--- plot BearishMarubozu
#property indicator_label4  "BearishMarubozu"
#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrYellow
#property indicator_style4  STYLE_SOLID
#property indicator_width4  1
//--- plot BullishHarami
#property indicator_label5  "BullishHarami"
#property indicator_type5   DRAW_ARROW
#property indicator_color5  clrBlue
#property indicator_style5  STYLE_SOLID
#property indicator_width5  1
//--- plot BearishHarami
#property indicator_label6  "BearishHarami"
#property indicator_type6   DRAW_ARROW
#property indicator_color6  clrYellow
#property indicator_style6  STYLE_SOLID
#property indicator_width6  1
//--- plot MorningStar
#property indicator_label7  "MorningStar"
#property indicator_type7   DRAW_ARROW
#property indicator_color7  clrBlue
#property indicator_style7  STYLE_SOLID
#property indicator_width7  1
//--- plot EveningStar
#property indicator_label8  "EveningStar"
#property indicator_type8   DRAW_ARROW
#property indicator_color8  clrYellow
#property indicator_style8  STYLE_SOLID
#property indicator_width8  1
//--- plot ThreeWhite
#property indicator_label9  "ThreeWhite"
#property indicator_type9   DRAW_ARROW
#property indicator_color9  clrBlue
#property indicator_style9  STYLE_SOLID
#property indicator_width9  1
//--- plot ThreeBlack
#property indicator_label10  "ThreeBlack"
#property indicator_type10   DRAW_ARROW
#property indicator_color10  clrYellow
#property indicator_style10  STYLE_SOLID
#property indicator_width10  1
//--- plot ThreeInsideUp
#property indicator_label11  "ThreeInsideUp"
#property indicator_type11   DRAW_ARROW
#property indicator_color11  clrBlue
#property indicator_style11  STYLE_SOLID
#property indicator_width11  1
//--- plot ThreeInsideDown
#property indicator_label12  "ThreeInsideDown"
#property indicator_type12   DRAW_ARROW
#property indicator_color12  clrYellow
#property indicator_style12  STYLE_SOLID
#property indicator_width12  1
//--- indicator buffers
double         BullishEngulfingBuffer[];
double         BearishEngulfingBuffer[];
double         BullishMarubozuBuffer[];
double         BearishMarubozuBuffer[];
double         BullishHaramiBuffer[];
double         BearishHaramiBuffer[];
double         MorningStarBuffer[];
double         EveningStarBuffer[];
double         ThreeWhiteBuffer[];
double         ThreeBlackBuffer[];
double         ThreeInsideUpBuffer[];
double         ThreeInsideDownBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,BullishEngulfingBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,BearishEngulfingBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,BullishMarubozuBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,BearishMarubozuBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,BullishHaramiBuffer,INDICATOR_DATA);
   SetIndexBuffer(5,BearishHaramiBuffer,INDICATOR_DATA);
   SetIndexBuffer(6,MorningStarBuffer,INDICATOR_DATA);
   SetIndexBuffer(7,EveningStarBuffer,INDICATOR_DATA);
   SetIndexBuffer(8,ThreeWhiteBuffer,INDICATOR_DATA);
   SetIndexBuffer(9,ThreeBlackBuffer,INDICATOR_DATA);
   SetIndexBuffer(10,ThreeInsideUpBuffer,INDICATOR_DATA);
   SetIndexBuffer(11,ThreeInsideDownBuffer,INDICATOR_DATA);
//--- setting a code from the Wingdings charset as the property of PLOT_ARROW
   PlotIndexSetInteger(0,PLOT_ARROW,233);
   PlotIndexSetInteger(1,PLOT_ARROW,234);
   PlotIndexSetInteger(2,PLOT_ARROW,233);
   PlotIndexSetInteger(3,PLOT_ARROW,234);
   PlotIndexSetInteger(4,PLOT_ARROW,233);
   PlotIndexSetInteger(5,PLOT_ARROW,234);
   PlotIndexSetInteger(6,PLOT_ARROW,233);
   PlotIndexSetInteger(7,PLOT_ARROW,234);
   PlotIndexSetInteger(8,PLOT_ARROW,233);
   PlotIndexSetInteger(9,PLOT_ARROW,234);
   PlotIndexSetInteger(10,PLOT_ARROW,233);
   PlotIndexSetInteger(11,PLOT_ARROW,234);
//--- setting shift
   PlotIndexSetInteger(0,PLOT_ARROW_SHIFT,10);
   PlotIndexSetInteger(1,PLOT_ARROW_SHIFT,-10);
   PlotIndexSetInteger(2,PLOT_ARROW_SHIFT,10);
   PlotIndexSetInteger(3,PLOT_ARROW_SHIFT,-10);
   PlotIndexSetInteger(4,PLOT_ARROW_SHIFT,10);
   PlotIndexSetInteger(5,PLOT_ARROW_SHIFT,-10);
   PlotIndexSetInteger(6,PLOT_ARROW_SHIFT,10);
   PlotIndexSetInteger(7,PLOT_ARROW_SHIFT,-10);
   PlotIndexSetInteger(8,PLOT_ARROW_SHIFT,10);
   PlotIndexSetInteger(9,PLOT_ARROW_SHIFT,-10);
   PlotIndexSetInteger(10,PLOT_ARROW_SHIFT,10);
   PlotIndexSetInteger(11,PLOT_ARROW_SHIFT,-10);
//---
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(5,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(6,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(7,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(8,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(9,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(10,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(11,PLOT_EMPTY_VALUE,EMPTY_VALUE);
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
   if(prev_calculated<7){
     ArrayInitialize(BullishEngulfingBuffer,EMPTY_VALUE);
     ArrayInitialize(BearishEngulfingBuffer,EMPTY_VALUE);
     ArrayInitialize(BullishMarubozuBuffer,EMPTY_VALUE);
     ArrayInitialize(BearishMarubozuBuffer,EMPTY_VALUE);
     ArrayInitialize(BullishHaramiBuffer,EMPTY_VALUE);
     ArrayInitialize(BearishHaramiBuffer,EMPTY_VALUE);
     ArrayInitialize(MorningStarBuffer,EMPTY_VALUE);
     ArrayInitialize(EveningStarBuffer,EMPTY_VALUE);
     ArrayInitialize(ThreeWhiteBuffer,EMPTY_VALUE);
     ArrayInitialize(ThreeBlackBuffer,EMPTY_VALUE);
     ArrayInitialize(ThreeInsideUpBuffer,EMPTY_VALUE);
     ArrayInitialize(ThreeInsideDownBuffer,EMPTY_VALUE);
   }
   
   for(int i=prev_calculated; i<rates_total-1; i++) 
   {
      //BullishEngulfingBuffer[i] = 0;
      //BearishEngulfingBuffer[i] = 0;
      //BullishMarubozuBuffer[i] = 0;
      //BearishMarubozuBuffer[i] = 0;
      //BullishHaramiBuffer[i] = 0;
      //BearishHaramiBuffer[i] = 0;
      //MorningStarBuffer[i] = 0;
      //EveningStarBuffer[i] = 0;
      //ThreeWhiteBuffer[i] = 0;
      //ThreeBlackBuffer[i] = 0;
      //ThreeInsideUpBuffer[i] = 0;
      //ThreeInsideDownBuffer[i] = 0;
      
      // calculate DVP for support and resistance
      if () {
         double prices[];
         long volumes[];
         ArrayCopy(prices,close,0,i-inpPeriod+1,inpPeriod);
         ArrayCopy(volumes,tick_volume,0,i-inpPeriod+1,inpPeriod);
         double min = prices[ArrayMinimum(prices, 0, inpPeriod)];
         double max = prices[ArrayMaximum(prices, 0, inpPeriod)];
         double d=(max-min)/inpNRows;
   
         long totalVolume=0;
         long levelVolume[];
         ArrayResize(levelVolume,inpNRows+1);
         ArrayFill(levelVolume,0,inpNRows+1,0);
         for(int j=0;j<inpPeriod;j++)
           {
            int lvl=getPriceLevel(prices[j],min,d,inpNRows);
            levelVolume[lvl]+=volumes[j];
            totalVolume+=volumes[j];
           }
   
         long pocVol=0.0;
         int pocLevel=0;
         for(int j=1; j<=inpNRows; j++)
           {
            long vol=levelVolume[j];
            if(vol>pocVol)
              {
               pocLevel=j;
               pocVol=vol;
              }
           }
   
         double valueArea=totalVolume*inpPctValueArea/100;
         double val = 0.0;
         double vah = 0.0;
         long tempVol=levelVolume[pocLevel];
         for(int j=1; j<=inpNRows; j++)
           {
            long v1 = pocLevel-j > 0 ? levelVolume[pocLevel-j] : 0;
            long v2 = pocLevel+j <= inpNRows ? levelVolume[pocLevel+j] : 0;
            tempVol = tempVol + v1 + v2;
            if(tempVol>=valueArea)
              {
               val = v1==0 ? min : min+(pocLevel-j-1)*d;
               vah = v2==0 ? max : min+(pocLevel+j)*d;
               break;
              }
           }
         if(val==0 && vah==0)
           {
            val = min;
            vah = max;
           }
   
         POCBuffer[i] = NormalizeDouble(min + (pocLevel-0.5)*d, _Digits);
         if (showValueArea)
         {
            VALBuffer[i] = NormalizeDouble(val, _Digits);
            VAHBuffer[i] = NormalizeDouble(vah, _Digits);
         }
      }
      
      // calculate Marubozu
      bool greencandle = close[i] - open[i] >= 0;
      double bodylength = MathAbs(close[i] - open[i]);
      double rangelength = high[i] - low[i];
      
      if (bodylength == rangelength) {
         if (greencandle) {
            BullishMarubozuBuffer[i] = low[i];
            printf("bullish marubozu at %s bodylength: %s rangelength: %s", 
               TimeToString(time[i]), 
               DoubleToString(bodylength, Digits()), 
               DoubleToString(rangelength, Digits()));
         }
         else {
            BearishMarubozuBuffer[i] = high[i];
            printf("bearish marubozu at %s bodylength: %s rangelength: %s", 
               TimeToString(time[i]), 
               DoubleToString(bodylength, Digits()), 
               DoubleToString(rangelength, Digits()));
         }
      }
      
      // calculate Engulfing
      if(i > 0) {
         double b1 = close[i-1] - open[i-1];
         double b2 = close[i] - open[i];
         double range = MathAbs(high[i] - low[i]);
         double ratio = 0;
         if (b2 != 0) {
            ratio = MathAbs(high[i] - low[i]) / MathAbs(b2);
         }
         // check for bullish engulfing
         if (b1 < 0 && b2 > 0 && ratio <= 4.0/3.0) {
            if (MathAbs(b2) > 2*MathAbs(b1)) {
               double min = low[i] >= low[i-1] ? low[i] : low[i-1];
               BullishEngulfingBuffer[i] = low[i];
               printf("bullish engulfing at %s b1: %s b1: %s r:%s", 
                  TimeToString(time[i]), 
                  DoubleToString(b1, Digits()), 
                  DoubleToString(b2, Digits()),
                  DoubleToString(range, Digits()));
            }
         }
         // check for bearish engulfing
         else if (b1 > 0 && b2 < 0 && ratio <= 4.0/3.0) {
            if (MathAbs(b2) > 2*MathAbs(b1)) {
               double max = high[i] >= high[i-1] ? high[i] : high[i-1];
               BearishEngulfingBuffer[i] = high[i];
               printf("bearish engulfing at %s b1: %s b1: %s r:%s", 
                  TimeToString(time[i]), 
                  DoubleToString(b1, Digits()), 
                  DoubleToString(b2, Digits()),
                  DoubleToString(range, Digits()));
            }
         }
      }
   }
   printf("last analyzed: %s", TimeToString(time[rates_total-1]));
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
