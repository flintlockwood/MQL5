//+------------------------------------------------------------------+
//|                                             CSPatternWithDVP.mq5 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 17
#property indicator_plots   16

////--- plot VAH
//#property indicator_label2  "VAH"
//#property indicator_type2   DRAW_LINE
//#property indicator_color2  clrWhiteSmoke
//#property indicator_style2  STYLE_SOLID
//#property indicator_width2  1
////--- plot VAL
//#property indicator_label3  "VAL"
//#property indicator_type3   DRAW_LINE
//#property indicator_color3  clrWhiteSmoke
//#property indicator_style3  STYLE_SOLID
//#property indicator_width3  1
//--- plot POC
#property indicator_label1  "POC"
#property indicator_type1  DRAW_LINE
#property indicator_color1  clrWhite
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot BullishMarubozu
#property indicator_label2  "BullishMarubozu"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrBlue
//--- plot BearishMarubozu
#property indicator_label3  "BearishMarubozu"
#property indicator_type3   DRAW_ARROW
#property indicator_color3  clrYellow
//--- plot BullishEngulfing
#property indicator_label4  "BullishEngulfing"
#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrBlue
//--- plot BearishEngulfing
#property indicator_label5  "BearishEngulfing"
#property indicator_type5   DRAW_ARROW
#property indicator_color5  clrYellow
//--- plot BullishHarami
#property indicator_label6  "BullishHarami"
#property indicator_type6   DRAW_ARROW
#property indicator_color6  clrBlue
//--- plot BearishHarami
#property indicator_label7  "BearishHarami"
#property indicator_type7   DRAW_ARROW
#property indicator_color7  clrYellow
//--- plot MorningStar
#property indicator_label8  "MorningStar"
#property indicator_type8   DRAW_ARROW
#property indicator_color8  clrBlue
//--- plot EveningStar
#property indicator_label9  "EveningStar"
#property indicator_type9   DRAW_ARROW
#property indicator_color9  clrYellow
//--- plot ThreeWhite
#property indicator_label10 "ThreeWhite"
#property indicator_type10  DRAW_ARROW
#property indicator_color10 clrBlue
//--- plot ThreeBlack
#property indicator_label11 "ThreeBlack"
#property indicator_type11  DRAW_ARROW
#property indicator_color11 clrYellow
//--- plot ThreeInsideUp
#property indicator_label12 "ThreeInsideUp"
#property indicator_type12  DRAW_ARROW
#property indicator_color12 clrBlue
//--- plot ThreeInsideDown
#property indicator_label13 "ThreeInsideDown"
#property indicator_type13  DRAW_ARROW
#property indicator_color13 clrYellow
//--- plot BullishRejection
#property indicator_label14 "BullishRejection"
#property indicator_type14  DRAW_ARROW
#property indicator_color14 clrBlue
//--- plot BearishRejection
#property indicator_label15 "BearishRejection"
#property indicator_type15  DRAW_ARROW
#property indicator_color15 clrYellow
//-- filling color
#property indicator_label16 "VAH;VAL"
#property indicator_type16  DRAW_FILLING
#property indicator_color16 clrDarkGreen

#include <MR\Dvp.mqh>
#include <Math\Stat\Math.mqh>

//--- input parameters
input int      inpPeriod             = 60;
input int      inpNRows              = 100;
input double   inpPctValueArea       = 70.0;
input bool     showValueArea         = true;
input bool     showPoc               = true;
input bool     useSma                = false;
input int      smaPeriod             = 5;
input bool     showBullishMarubozu   = false;
input bool     showBearishMarubozu   = false;
input bool     showBullishEngulfing  = false;
input bool     showBearishEngulfing  = false;
input bool     showBullisHarami      = false;
input bool     showBearishHarami     = false;
input bool     showMorningStar       = false;
input bool     showEveningStar       = false;
input bool     showThreeWhite        = false;
input bool     showThreeBlack        = false;
input bool     showThreeInsideUp     = false;
input bool     showThreeInsideDown   = false;
input bool     showBullishRejection  = false;
input bool     showBearishRejection  = false;

//--- indicator buffers
double         POCBuffer[];
double         VAHBuffer[];
double         VALBuffer[];
double         BullishMarubozuBuffer[];
double         BearishMarubozuBuffer[];
double         BullishEngulfingBuffer[];
double         BearishEngulfingBuffer[];
double         BullishHaramiBuffer[];
double         BearishHaramiBuffer[];
double         MorningStarBuffer[];
double         EveningStarBuffer[];
double         ThreeWhiteBuffer[];
double         ThreeBlackBuffer[];
double         ThreeInsideUpBuffer[];
double         ThreeInsideDownBuffer[];
double         BullishRejectionBuffer[];
double         BearishRejectionBuffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,POCBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,BullishMarubozuBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,BearishMarubozuBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,BullishEngulfingBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,BearishEngulfingBuffer,INDICATOR_DATA);
   SetIndexBuffer(5,BullishHaramiBuffer,INDICATOR_DATA);
   SetIndexBuffer(6,BearishHaramiBuffer,INDICATOR_DATA);
   SetIndexBuffer(7,MorningStarBuffer,INDICATOR_DATA);
   SetIndexBuffer(8,EveningStarBuffer,INDICATOR_DATA);
   SetIndexBuffer(9,ThreeWhiteBuffer,INDICATOR_DATA);
   SetIndexBuffer(10,ThreeBlackBuffer,INDICATOR_DATA);
   SetIndexBuffer(11,ThreeInsideUpBuffer,INDICATOR_DATA);
   SetIndexBuffer(12,ThreeInsideDownBuffer,INDICATOR_DATA);
   SetIndexBuffer(13,BullishRejectionBuffer,INDICATOR_DATA);
   SetIndexBuffer(14,BearishRejectionBuffer,INDICATOR_DATA);
   SetIndexBuffer(15,VAHBuffer,INDICATOR_DATA);   
   SetIndexBuffer(16,VALBuffer,INDICATOR_DATA);
//---
   PlotIndexSetInteger(1,PLOT_ARROW,233);
   PlotIndexSetInteger(2,PLOT_ARROW,234);
   PlotIndexSetInteger(3,PLOT_ARROW,233);
   PlotIndexSetInteger(4,PLOT_ARROW,234);
   PlotIndexSetInteger(5,PLOT_ARROW,233);
   PlotIndexSetInteger(6,PLOT_ARROW,234);
   PlotIndexSetInteger(7,PLOT_ARROW,233);
   PlotIndexSetInteger(8,PLOT_ARROW,234);
   PlotIndexSetInteger(9,PLOT_ARROW,233);
   PlotIndexSetInteger(10,PLOT_ARROW,234);
   PlotIndexSetInteger(11,PLOT_ARROW,233);
   PlotIndexSetInteger(12,PLOT_ARROW,234);
   PlotIndexSetInteger(13,PLOT_ARROW,233);
   PlotIndexSetInteger(14,PLOT_ARROW,234);
   
   PlotIndexSetInteger(1,PLOT_ARROW_SHIFT,10);
   PlotIndexSetInteger(2,PLOT_ARROW_SHIFT,-10);
   PlotIndexSetInteger(3,PLOT_ARROW_SHIFT,10);
   PlotIndexSetInteger(4,PLOT_ARROW_SHIFT,-10);
   PlotIndexSetInteger(5,PLOT_ARROW_SHIFT,10);
   PlotIndexSetInteger(6,PLOT_ARROW_SHIFT,-10);
   PlotIndexSetInteger(7,PLOT_ARROW_SHIFT,10);
   PlotIndexSetInteger(8,PLOT_ARROW_SHIFT,-10);
   PlotIndexSetInteger(9,PLOT_ARROW_SHIFT,10);
   PlotIndexSetInteger(10,PLOT_ARROW_SHIFT,-10);
   PlotIndexSetInteger(11,PLOT_ARROW_SHIFT,10);
   PlotIndexSetInteger(12,PLOT_ARROW_SHIFT,-10);
   PlotIndexSetInteger(13,PLOT_ARROW_SHIFT,10);
   PlotIndexSetInteger(14,PLOT_ARROW_SHIFT,-10);
   
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
   PlotIndexSetDouble(12,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(13,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(14,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   
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
   if(rates_total<=inpPeriod)
      return(0);
   
//--- preliminary calculations
   int pos=prev_calculated;
   if(pos<=inpPeriod) {
      for(int i=0;i<inpPeriod;i++) {
         POCBuffer[i]=0.0;
         VAHBuffer[i]=0.0;
         VALBuffer[i]=0.0;
      }
      pos=inpPeriod-1;
   }

   for(int i=pos-3;i<rates_total && !IsStopped();i++) {
      BullishMarubozuBuffer[i] = EMPTY_VALUE;
      BearishMarubozuBuffer[i] = EMPTY_VALUE;
      BullishEngulfingBuffer[i] = EMPTY_VALUE;
      BearishEngulfingBuffer[i] = EMPTY_VALUE;
      BullishHaramiBuffer[i] = EMPTY_VALUE;
      BearishHaramiBuffer[i] = EMPTY_VALUE;
      MorningStarBuffer[i] = EMPTY_VALUE;
      EveningStarBuffer[i] = EMPTY_VALUE;
      ThreeWhiteBuffer[i] = EMPTY_VALUE;
      ThreeBlackBuffer[i] = EMPTY_VALUE;
      ThreeInsideUpBuffer[i] = EMPTY_VALUE;
      ThreeInsideDownBuffer[i] = EMPTY_VALUE;
      BullishRejectionBuffer[i] = EMPTY_VALUE;
      BearishRejectionBuffer[i] = EMPTY_VALUE;
      VAHBuffer[i] = EMPTY_VALUE;
      VALBuffer[i] = EMPTY_VALUE;
      POCBuffer[i] = EMPTY_VALUE;
      
      // calculate DVP
      double prices[];
      long volumes[];
      ArrayCopy(prices,close,0,i-inpPeriod+1,inpPeriod);
      ArrayCopy(volumes,tick_volume,0,i-inpPeriod+1,inpPeriod);
      DvpRates dvp;
      getCurrDVP(inpPeriod, inpNRows, inpPctValueArea, prices, volumes, dvp);
      dvp.Time = time[i];
      if (showValueArea) {
         VALBuffer[i] = dvp.Val;
         VAHBuffer[i] = dvp.Vah;
      }
      if (showPoc) {
         POCBuffer[i] = dvp.Poc;
      }
      
      // check Marubozu
      double mRates;
      int mFlag = checkMarubozu(open[i], high[i], low[i], close[i], dvp, mRates);
      if (mFlag == 1) {
         if (showBullishMarubozu) {
            BullishMarubozuBuffer[i] = mRates;
            //printf("bullish marubozu at %s, %s", TimeToString(time[i]), DoubleToString(mRates, _Digits));
         }
      }
      else if (mFlag == -1) {
         if (showBearishMarubozu) {
            BearishMarubozuBuffer[i] = mRates;
            //printf("bearish marubozu at %s", TimeToString(time[i]));
         }
      }
      
      // check Rejection
      int avgSize = 60;
      double hAvg[];
      ArrayCopy(hAvg,high,0,i-avgSize+1,avgSize);
      double lAvg[];
      ArrayCopy(lAvg,low,0,i-avgSize+1,avgSize);
      double rAvg[];
      ArrayResize(rAvg, avgSize);
      for(int i=0; i<avgSize; i++) {
         rAvg[i] = hAvg[i] - lAvg[i];
      }
      double avgRange = MathMean(rAvg);
      double stdDevRange = MathStandardDeviation(rAvg);
      double rangeTh = avgRange + stdDevRange;
      double rRates;
      int rFlag = checkRejection(open[i], high[i], low[i], close[i], rangeTh, rRates);
      if (rFlag == 1) {
         if (showBullishRejection) {
            BullishRejectionBuffer[i] = rRates;
            //printf("bullish marubozu at %s, %s", TimeToString(time[i]), DoubleToString(mRates, _Digits));
         }
      }
      else if (rFlag == -1) {
         if (showBearishRejection) {
            BearishRejectionBuffer[i] = rRates;
            //printf("bearish marubozu at %s", TimeToString(time[i]));
         }
      }
      
      double open2[];
      double high2[];
      double low2[];
      double close2[];
      ArrayCopy(open2, open, 0, i-1, 2);
      ArrayCopy(high2, high, 0, i-1, 2);
      ArrayCopy(low2, low, 0, i-1, 2);
      ArrayCopy(close2, close, 0, i-1, 2);
      
      // check Engulfing
      double eRates;
      int eFlag = checkEnGulfing(open2, high2, low2, close2, dvp, eRates);
      if (eFlag == 1) {
         if(showBullishEngulfing) {
            BullishEngulfingBuffer[i] = eRates;
            //printf("bullish enguling at %s", TimeToString(time[i]));
         }
      }
      else if (eFlag == -1) {
         if (showBearishEngulfing) {
            BearishEngulfingBuffer[i] = eRates;
            //printf("bearish enguling at %s", TimeToString(time[i]));
         }
      }
      
      // check Harami
      double hRates;
      int hFlag = checkHarami(open2, high2, low2, close2, dvp, hRates);
      if (hFlag == 1) {
         if (showBullisHarami) {
            BullishHaramiBuffer[i] = hRates;
            //printf("bullish harami at %s", TimeToString(time[i]));
         }
      }
      else if (hFlag == -1) {
         if (showBearishHarami) {
            BearishHaramiBuffer[i] = hRates;
            //printf("bearish harami at %s", TimeToString(time[i]));
         }
      }
      
      double open3[];
      double high3[];
      double low3[];
      double close3[];
      ArrayCopy(open3, open, 0, i-2, 3);
      ArrayCopy(high3, high, 0, i-2, 3);
      ArrayCopy(low3, low, 0, i-2, 3);
      ArrayCopy(close3, close, 0, i-2, 3);
      
      // check Star
      double sRates;
      int sFlag = checkStar(open3, high3, low3, close3, dvp, sRates);
      if (sFlag == 1) {
         if (showMorningStar) {
            MorningStarBuffer[i] = sRates;
            //printf("morning star at %s", TimeToString(time[i]));
         }
      }
      else if (sFlag == -1) {
         if (showEveningStar) {
            EveningStarBuffer[i] = sRates;
            //printf("evening star at %s", TimeToString(time[i]));
         }
      }
      
      // check Triple
      double tRates;
      int tFlag = checkTripleCS(open3, high3, low3, close3, dvp, tRates);
      if (tFlag == 1) {
         if (showThreeWhite) {
            ThreeWhiteBuffer[i] = tRates;
            //printf("three white soldiers at %s", TimeToString(time[i]));
         }
      }
      else if (tFlag == -1) {
         if (showThreeBlack) {
            ThreeBlackBuffer[i] = tRates;
            //printf("three black crows at %s", TimeToString(time[i]));
         }
      }
      
      // check Three Inside
      double tiRates;
      int tiFlag = checkThreeInside(open3, high3, low3, close3, dvp, tiRates);
      if (tiFlag == 1) {
         if (showThreeInsideUp) {
            ThreeInsideUpBuffer[i] = tiRates;
            //printf("three inside up at %s", TimeToString(time[i]));
         }
      }
      else if (tiFlag == -1) {
         if (showThreeInsideDown) {
            ThreeInsideDownBuffer[i] = tiRates;
            //printf("three inside down at %s", TimeToString(time[i]));
         }
      }
   }
//--- return value of prev_calculated for next call
   return(rates_total);
}
//+------------------------------------------------------------------+

void getCurrDVP(int period, int nrow, double vapct, double &prices[], long &volumes[], DvpRates &dvp)
{
   if (ArraySize(prices) != period || ArraySize(volumes) != period) {
      return;
   }
   
   double min = prices[ArrayMinimum(prices, 0, period)];
   double max = prices[ArrayMaximum(prices, 0, period)];
   double d=(max-min)/nrow;

   long totalVolume=0;
   long levelVolume[];
   ArrayResize(levelVolume,nrow+1);
   ArrayFill(levelVolume,0,nrow+1,0);
   for(int j=0;j<period;j++) {
      int lvl=getPriceLevel(prices[j],min,d,nrow);
      levelVolume[lvl]+=volumes[j];
      totalVolume+=volumes[j];
   }

   long pocVol=0.0;
   int pocLevel=0;
   for(int j=1; j<=nrow; j++){
      long vol=levelVolume[j];
      if(vol>pocVol) {
         pocLevel=j;
         pocVol=vol;
      }
   }

   double valueArea=totalVolume*vapct/100;
   double val = 0.0;
   double vah = 0.0;
   long tempVol=levelVolume[pocLevel];
   for(int j=1; j<=nrow; j++) {
      long v1 = pocLevel-j > 0 ? levelVolume[pocLevel-j] : 0;
      long v2 = pocLevel+j <= nrow ? levelVolume[pocLevel+j] : 0;
      tempVol = tempVol + v1 + v2;
      if(tempVol>=valueArea) {
         val = v1==0 ? min : min+(pocLevel-j-1)*d;
         vah = v2==0 ? max : min+(pocLevel+j)*d;
         break;
      }
   }
   
   if(val==0 && vah==0) {
      val = min;
      vah = max;
   }

   dvp.Poc = NormalizeDouble(min + (pocLevel-0.5)*d, _Digits);
   dvp.Val = NormalizeDouble(val, _Digits);
   dvp.Vah = NormalizeDouble(vah, _Digits);
}

int checkMarubozu(double open, double high, double low, double close, DvpRates &dvp, double &rates)
{
   bool greencandle = close - open >= 0;
   double bodylength = MathAbs(close - open);
   double rangelength = high - low;
   
   rates = EMPTY_VALUE;
   int ret = 0;
   if (bodylength == rangelength) {
      if (greencandle) {
         if ((open < dvp.Val && close > dvp.Val) ||
             (open < dvp.Poc && close > dvp.Poc) ||
             (open < dvp.Vah && close > dvp.Vah)) {
            rates = low;
            ret = 1;
         }
      }
      else {
         if ((open > dvp.Val && close < dvp.Val) ||
             (open > dvp.Poc && close < dvp.Poc) ||
             (open > dvp.Vah && close < dvp.Vah)) {
            rates = high;
            ret = -1;
         }
      }
   }
   return ret;
}

int checkEnGulfing(double &opens[], double &highs[], double &lows[], double &closes[], DvpRates &dvp, double &rates)
{
   if (ArraySize(opens) != 2 || ArraySize(highs) != 2 || ArraySize(lows) != 2 || ArraySize(closes) != 2) {
      return 0;
   }
   
   rates = 0.0;
   int ret = 0;
   double b1 = closes[0] - opens[0];
   double b2 = closes[1] - opens[1];
   double range = MathAbs(highs[1] - lows[1]);
   double ratio = 0;
   if (range != 0) {
      ratio = MathAbs(b2) / range;
   }
   
   // check for bullish engulfing
   if (b1 < 0 && b2 > 0 && ratio >= 0.8) {
      if (MathAbs(b2) > 2*MathAbs(b1)) {
         if ((opens[1] < dvp.Val && closes[1] > dvp.Val) ||
             (opens[1] < dvp.Poc && closes[1] > dvp.Poc) ||
             (opens[1] < dvp.Vah && closes[1] > dvp.Vah)) {
            rates = lows[1];
            ret = 1;
         }
      }
   }
   // check for bearish engulfing
   else if (b1 > 0 && b2 < 0 && ratio >= 0.8) {
      if (MathAbs(b2) > 2*MathAbs(b1)) {
         if ((opens[1] > dvp.Val && closes[1] < dvp.Val) ||
             (opens[1] > dvp.Poc && closes[1] < dvp.Poc) ||
             (opens[1] > dvp.Vah && closes[1] < dvp.Vah)) {
            rates = highs[1];
            ret = -1;
         }
      }
   }
   return ret;
}

int checkHarami(double &opens[], double &highs[], double &lows[], double &closes[], DvpRates &dvp, double &rates)
{
   if (ArraySize(opens) != 2 || ArraySize(highs) != 2 || ArraySize(lows) != 2 || ArraySize(closes) != 2) {
      return 0;
   }
   
   rates = 0.0;
   int ret = 0;
   
   double bodyMax0 = closes[0] > opens[0] ? closes[0] : opens[0];
   double bodyMin0 = closes[0] < opens[0] ? closes[0] : opens[0];
   double bodyMax1 = closes[1] > opens[1] ? closes[1] : opens[1];
   double bodyMin1 = closes[1] < opens[1] ? closes[1] : opens[1];
   bool bodyWhite0 = closes[0] > opens[0];
   bool bodyWhite1 = closes[1] > opens[1];
   double body0 = MathAbs(closes[0] - opens[0]);
   double body1 = MathAbs(closes[1] - opens[1]);
   double range0 = MathAbs(highs[0] - lows[0]);
   double range1 = MathAbs(highs[1] - lows[1]);
   double ratio0 = 0;
   if (range0 != 0) {
      ratio0 = body0 / range0;
   }
   double ratio1 = 0;
   if (range1 != 0) {
      ratio1 = body1 / range1;
   }

   if (bodyMax0 > bodyMax1 && bodyMin0 < bodyMin1 && ratio0 >= 0.8 && ratio1 <= 0.2) {
      if (MathAbs(closes[1] - dvp.Val) <= 10*_Point ||
          MathAbs(closes[1] - dvp.Poc) <= 10*_Point ||
          MathAbs(closes[1] - dvp.Vah) <= 10*_Point) {
         // Bullish Harami
         if (!bodyWhite0 && bodyWhite1) {
            rates = lows[0];
            ret = 1;
         }
         // Bearish Harami
         else if (bodyWhite0 && !bodyWhite1) {
            rates = highs[0];
            ret = -1;
         }
      }
   }
   return ret;
}

int checkStar(double &opens[], double &highs[], double &lows[], double &closes[], DvpRates &dvp, double &rates)
{
   if (ArraySize(opens) != 3 || ArraySize(highs) != 3 || ArraySize(lows) != 3 || ArraySize(closes) != 3) {
      return 0;
   }
   
   rates = 0.0;
   int ret = 0;
   
   bool bodyWhite0 = closes[0] > opens[0];
   bool bodyWhite1 = closes[1] > opens[1];
   bool bodyWhite2 = closes[2] > opens[2];
   double bodyMax0 = closes[0] > opens[0] ? closes[0] : opens[0];
   double bodyMin0 = closes[0] < opens[0] ? closes[0] : opens[0];
   double bodyMax1 = closes[1] > opens[1] ? closes[1] : opens[1];
   double bodyMin1 = closes[1] < opens[1] ? closes[1] : opens[1];
   double bodyMax2 = closes[2] > opens[2] ? closes[2] : opens[2];
   double bodyMin2 = closes[2] < opens[2] ? closes[2] : opens[2];
   double body0 = MathAbs(closes[0] - opens[0]);
   double body1 = MathAbs(closes[1] - opens[1]);
   double body2 = MathAbs(closes[2] - opens[2]);
   double range0 = MathAbs(highs[0] - lows[0]);
   double range1 = MathAbs(highs[1] - lows[1]);
   double range2 = MathAbs(highs[2] - lows[2]);
   double ratio0 = 0;
   if (range0 != 0) {
      ratio0 = body0 / range0;
   }
   double ratio1 = 0;
   if (range1 != 0) {
      ratio1 = body1 / range1;
   }
   double ratio2 = 0;
   if (range2 != 0) {
      ratio2 = body2 / range2;
   }
   
   if (ratio0 >= 0.8 && ratio1 <= 0.2) {
      // check for bullish morning star
      if (!bodyWhite0 && bodyWhite2 && bodyMax1 < bodyMin0 && bodyMax1 < bodyMin2 && closes[2] > (closes[0]+0.5*body0)) {
         if (lows[1] < dvp.Val) {
            rates = lows[2];
            ret = 1;
         }
      }
      // check for bearish evening star
      else if (bodyWhite0 && !bodyWhite2 && bodyMin1 > bodyMax0 && bodyMin1 > bodyMax2 && closes[2] < (closes[0]-0.5*body0)) {
         if (highs[1] > dvp.Vah) {
            rates = highs[2];
            ret = -1;
         }
      }
   }
   return ret;
}

int checkTripleCS(double &opens[], double &highs[], double &lows[], double &closes[], DvpRates &dvp, double &rates)
{
   if (ArraySize(opens) != 3 || ArraySize(highs) != 3 || ArraySize(lows) != 3 || ArraySize(closes) != 3) {
      return 0;
   }
   
   rates = 0.0;
   int ret = 0;
   
   bool bodyWhite0 = closes[0] > opens[0];
   bool bodyWhite1 = closes[1] > opens[1];
   bool bodyWhite2 = closes[2] > opens[2];
   double bodyMax0 = closes[0] > opens[0] ? closes[0] : opens[0];
   double bodyMin0 = closes[0] < opens[0] ? closes[0] : opens[0];
   double bodyMax1 = closes[1] > opens[1] ? closes[1] : opens[1];
   double bodyMin1 = closes[1] < opens[1] ? closes[1] : opens[1];
   double bodyMax2 = closes[2] > opens[2] ? closes[2] : opens[2];
   double bodyMin2 = closes[2] < opens[2] ? closes[2] : opens[2];
   double body0 = MathAbs(closes[0] - opens[0]);
   double body1 = MathAbs(closes[1] - opens[1]);
   double body2 = MathAbs(closes[2] - opens[2]);
   double range0 = MathAbs(highs[0] - lows[0]);
   double range1 = MathAbs(highs[1] - lows[1]);
   double range2 = MathAbs(highs[2] - lows[2]);
   double ratio0 = 0;
   if (range0 != 0) {
      ratio0 = body0 / range0;
   }
   double ratio1 = 0;
   if (range1 != 0) {
      ratio1 = body1 / range1;
   }
   double ratio2 = 0;
   if (range2 != 0) {
      ratio2 = body2 / range2;
   }
   
   if (ratio0 > 0.4 && ratio1 > 0.4 && ratio2 > 0.4) {
      // check bullish three white soldier
      if (bodyWhite0 && bodyWhite1 && bodyWhite2) {
         if (opens[0] < dvp.Val && closes[2] > dvp.Val) {
            rates = lows[2];
            ret = 1;
         }
      }
      // check bearish three black soldier
      else if (!bodyWhite0 && !bodyWhite1 && !bodyWhite2) {
         if (opens[0] > dvp.Vah && closes[2] < dvp.Vah) {
            rates = highs[2];
            ret = -1;
         }
      }
   }
   //else if (body0 < body1 && body1 < body2) {
   //    three white momentum 
   //   if (bodyWhite0 && bodyWhite1 && bodyWhite2) {
   //      rates = lows[2];
   //      ret = 1;
   //   }
   //    three black momentum 
   //   else if (!bodyWhite0 && !bodyWhite1 && !bodyWhite2) {
   //      rates = highs[2];
   //      ret = -1;
   //   }
   //}
   
   return ret;
}

int checkThreeInside(double &opens[], double &highs[], double &lows[], double &closes[], DvpRates &dvp, double &rates)
{
   if (ArraySize(opens) != 3 || ArraySize(highs) != 3 || ArraySize(lows) != 3 || ArraySize(closes) != 3) {
      return 0;
   }
   
   rates = 0.0;
   int ret = 0;
   
   bool bodyWhite0 = closes[0] > opens[0];
   bool bodyWhite1 = closes[1] > opens[1];
   bool bodyWhite2 = closes[2] > opens[2];
   double bodyMax0 = closes[0] > opens[0] ? closes[0] : opens[0];
   double bodyMin0 = closes[0] < opens[0] ? closes[0] : opens[0];
   double bodyMax1 = closes[1] > opens[1] ? closes[1] : opens[1];
   double bodyMin1 = closes[1] < opens[1] ? closes[1] : opens[1];
   
   if (highs[1] <= highs[0] && lows[1] >= lows[0]) {
      // check three inside up
      if (!bodyWhite0 && bodyWhite1 && bodyWhite2 && closes[1] > closes[0] && closes[2] > opens[0]) {
         if (opens[1] < dvp.Val && closes[2] > dvp.Val) {
            rates = lows[2];
            ret = 1;
         }
      }
      // check three inside down
      else if (bodyWhite0 && !bodyWhite1 && !bodyWhite2 && closes[1] < closes[0] && closes[2] < opens[0]) {
         if (opens[1] > dvp.Vah && closes[2] < dvp.Vah) {
            rates = highs[2];
            ret = -1;   
         }
      }
   }
   
   return ret;
}

int checkRejection(double open, double high, double low, double close, double avg, double &rates)
{
   double halfrange = (high - low) / 2;
   double mid = low + halfrange;
   double quarter = low + halfrange / 2;
   double quarter2 = low + (halfrange * 3 / 2);
   int ret = 0;
   rates = EMPTY_VALUE;
   if (high - low > avg) {
      if (open > mid && close > quarter2) {
         ret = 1;
         rates = low;
      }
      if (open < mid && close < quarter) {
         ret = -1;
         rates = high;
      }
   }
   return ret;
}
