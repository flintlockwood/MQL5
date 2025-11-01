//+------------------------------------------------------------------+
//|                                         DynamicVolumeProfile.mq5 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   4
//--- plot POC
#property indicator_label1  "POC"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrOrange
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot VAH
#property indicator_label2  "VAH"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrGray
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- plot VAL
#property indicator_label3  "VAL"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrGray
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
//-- filling color
#property indicator_label4  "Filling"
#property indicator_type4   DRAW_FILLING
#property indicator_color4  clrLime

#include <MR/dvp.mqh>
//--- input parameters
input int      inpPeriod= 60;
input int      inpNRows = 50;
input int      inpPctValueArea=70;
//--- indicator buffers
double         POCBuffer[];
double         VAHBuffer[];
double         VALBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,POCBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,VAHBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,VALBuffer,INDICATOR_DATA);

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
   MqlRates rates[];
   int startPos=0;
   int nCount=0;
   int includeAll=true;
   if(prev_calculated==0)
     {
      startPos=0;
      nCount=rates_total;
      includeAll=true;
     }
   else if(prev_calculated<rates_total)
     {
      startPos=prev_calculated-inpPeriod+1;
      nCount=rates_total-startPos;
      includeAll=false;
     }
   else if(prev_calculated==rates_total)
     {
      startPos=prev_calculated-inpPeriod;
      nCount=inpPeriod;
      includeAll=false;
     }

   int check1=CopyRates(_Symbol,_Period,time[rates_total-1],nCount,rates);
   if(check1!=nCount)
     {
      return prev_calculated;
     }

   DvpRates dvpRates[];
   int check2=CalculateDvp(inpPeriod,inpNRows,inpPctValueArea,rates,dvpRates,_Symbol,includeAll);
   int nCount2=(includeAll ? nCount : nCount-inpPeriod+1);
   if(check2 != nCount2)
     {
      return prev_calculated;
     }

   int startPos2=(includeAll ? startPos : startPos+inpPeriod-1);
   for(int i=0; i<nCount2; i++)
     {
      POCBuffer[startPos2+i] = dvpRates[i].Poc;
      VAHBuffer[startPos2+i] = dvpRates[i].Vah;
      VALBuffer[startPos2+i] = dvpRates[i].Val;
     }
   return rates_total;
  }
//+------------------------------------------------------------------+
