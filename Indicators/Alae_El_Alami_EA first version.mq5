//+------------------------------------------------------------------+
//|                                             Alae_El_Alami_EA.mq5 |
//|                                 Copyright 2024, FX-Intellect Ltd |
//|                                      https://www.fxintellect.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, FX-Intellect Ltd"
#property link      "https://www.fxintellect.com"
#property version   "1.20"
#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
#resource "\\Indicators\\Examples\\ZigZag.ex5"

#include <Trade\Trade.mqh>
CTrade *Trade;

input string genSet="******* GENERL SETTINGS *******";//******* GENERL SETTINGS *******
input ulong MagicID=20000008;//magic Number
input ulong Slippage=1000;//Slippage
input int pointsBelowAbove=1;//Points below/above Stop Loss
input int pointsFromMA=0;//Points From MA to High/Low
input double riskPercentage=1.0;//Risk Percentage
input double rrRatio=1;//Risk Reward Ratio
input bool showGrid=false;//Show Grid on the Chart
input color nuColor=clrBlue;//Label Color Buy
input color nuColorSells=clrYellow;//Label Color Sell
input int labDist=5;//Label Distance
enum INIT_STEP
  {
   zigzag=0,//Use ZigZag
   swing=1,//Use Swing High/Low
  };
input INIT_STEP useZigZagBased=zigzag;//Step Zero Setting
input int SwingRange=2;//Swing range
/*enum STRATEGY
  {
   hh_ll=0,//Higher Highs & Lower Lows
   hl_hl=1,//Lower Highs & Higher Lows
  };*/
//input STRATEGY init_HL_Type=hh_ll;//High/Low type

input string sSet="******* Session Settings *******";//******* Session Settings *******
input bool useSeeions=false;//Use Trade Sessions
input bool NewYork=true;//Use NewYork Session
input bool London=false;//Use London Session
input bool Tokyo=false;//Use Tokyo Session
input bool Sydney=false;//Use Sydney Session


input string maSet="******* EMA SETTINGS *******";//******* EMA SETTINGS *******
input int maPeriod=21;//Period
input int maShift=0;//Shift
input ENUM_MA_METHOD maMode=MODE_EMA;//Mode
input ENUM_APPLIED_PRICE maAppliedPrice=PRICE_CLOSE;//Applied Price

input string zigZ="******* ZIGZAG SETTINGS *******";//******* ZIGZAG SETTINGS *******
//input bool useZigZag=true;//Use ZigZAg Guide
input int InpDepth    =12;  // Depth
input int InpDeviation=5;   // Deviation
input int InpBackstep =3;   // Back Step

int maHandle,ZigZagHandle;
int OnInit()
  {
   ChartSetInteger(0,CHART_COLOR_CANDLE_BEAR,clrRed);
   ChartSetInteger(0,CHART_COLOR_CANDLE_BULL,clrLime);
   ChartSetInteger(0,CHART_COLOR_CHART_DOWN,clrRed);
   ChartSetInteger(0,CHART_COLOR_CHART_UP,clrLime);
   ChartSetInteger(0,CHART_SHOW_GRID,showGrid);

   Trade=new CTrade();
   Trade.SetExpertMagicNumber(MagicID);
   Trade.SetDeviationInPoints(Slippage);
   EventSetTimer(60);
   maHandle = iMA(Symbol(),PERIOD_CURRENT,maPeriod,maShift,maMode,maAppliedPrice);
   if(useZigZagBased==0)
      ZigZagHandle=iCustom(Symbol(),PERIOD_CURRENT,"::Indicators\\Examples\\ZigZag.ex5",InpDepth,InpDeviation,InpBackstep);
//ChartIndicatorAdd(0,0,ma1Handle);
   ChartIndicatorAdd(0,0,ZigZagHandle);
// ProcessZigZagStrategy();
//---
   ListAllSymbols();
   return(INIT_SUCCEEDED);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
struct ZIG_CONDITIONS
  {
   bool              isPeakFound;
   double            PeakVal;
   double            prevPeak;
   bool              step1;
   bool              step2;
   bool              step3;
   datetime          step2Time;
                     ZIG_CONDITIONS()
     {
      isPeakFound=false;
      prevPeak=0;
      step2Time=0;
      PeakVal=0;
      step1=false;
      step2=false;
      step3=false;
     }
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ZIG_CONDITIONS ZigBuyConditions=ZIG_CONDITIONS();
ZIG_CONDITIONS ZigSellConditions=ZIG_CONDITIONS();
ZIG_CONDITIONS ZigBuyConditions_strat2=ZIG_CONDITIONS();
ZIG_CONDITIONS ZigSellConditions_strat2=ZIG_CONDITIONS();
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime prevPeakTime=0;
datetime currentPeakTime=0;
datetime peakTime=0;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ProcessZigZagStrategy()
  {
   static datetime time2;
   if(time2!=iTime(Symbol(),PERIOD_CURRENT,0))
     {
      ///Invalidating
      //--------------------------------------
      if(ZigBuyConditions.isPeakFound)
        {
         double prevLow=iLow(Symbol(),PERIOD_CURRENT,1);
         double prevHigh=iHigh(Symbol(),PERIOD_CURRENT,1);
         if(prevLow<ZigBuyConditions.prevPeak ||prevHigh>ZigBuyConditions.PeakVal)
           {
            ZigBuyConditions=ZIG_CONDITIONS();
            // Print("Invalidating High Strategy 11");
           }
        }

      if(ZigSellConditions.isPeakFound)
        {
         double prevLow=iLow(Symbol(),PERIOD_CURRENT,1);
         double prevHigh=iHigh(Symbol(),PERIOD_CURRENT,1);
         if(prevLow<ZigSellConditions.PeakVal ||prevHigh>ZigSellConditions.prevPeak)
           {
            ZigSellConditions=ZIG_CONDITIONS();
            //  Print("Invalidating Low  Strategy 11");
           }
        }

      time2=iTime(Symbol(),PERIOD_CURRENT,0);
      double ZigBuffer[];
      CopyBuffer(ZigZagHandle,0,2,500,ZigBuffer);
      double ZigVals[];

      int peakIndex=0;
      int count = 1;
      for(int x=ArraySize(ZigBuffer)-1;x>=0;x--)
        {
         if(!(ZigBuffer[x]==EMPTY_VALUE || ZigBuffer[x]==0))
           {
            int size=ArraySize(ZigVals);
            ArrayResize(ZigVals,size+1,0);
            ZigVals[size]=ZigBuffer[x];
            if(size==5)
               break;
            if(size==0)
              {
               peakIndex=count;
               peakTime=iTime(Symbol(),PERIOD_CURRENT,peakIndex+1);
              }
           }
         count++;
        }

      //   ArrayPrint(ZigVals,Digits(),NULL,0,WHOLE_ARRAY);

      //////Buying comditions
      if(peakTime!=prevPeakTime || prevPeakTime==0)
        {
         if(!ZigBuyConditions.isPeakFound)
            if(ZigVals[0]>ZigVals[1] && ZigVals[0]>ZigVals[2])
              {
               double buffMA[];
               CopyBuffer(maHandle,0,peakIndex,1,buffMA);
               if(ZigVals[0]>buffMA[0])
                 {
                  ZigBuyConditions.isPeakFound=true;
                  ZigBuyConditions.PeakVal=ZigVals[0];
                  ZigBuyConditions.prevPeak=ZigVals[2];
                  drawStepLabel(0,nuColor,ZigVals[0]+Point()*labDist,peakTime);
                  // Print("Looking for Buy conditions peakIndex  =  "+peakIndex+"  buffMA[0] = "+buffMA[0]);
                  currentPeakTime=peakTime;
                 }
              }

         if(!ZigSellConditions.isPeakFound)
            if(ZigVals[0]<ZigVals[1] && ZigVals[0]<ZigVals[2])
              {
               double buffMA[];
               CopyBuffer(maHandle,0,peakIndex,1,buffMA);
               if(ZigVals[0]<buffMA[0])
                 {
                  ZigSellConditions.isPeakFound=true;
                  ZigSellConditions.PeakVal=ZigVals[0];
                  ZigSellConditions.prevPeak=ZigVals[2];
                  drawStepLabel(0,nuColorSells,ZigVals[0]-Point()*labDist,peakTime);
                  //  Print("Looking for Sell conditions  peakIndex = "+peakIndex+"  buffMA[0] = "+buffMA[0]);
                  currentPeakTime=peakTime;
                 }
              }
        }
      // Print("prevPeakTime = "+prevPeakTime+"  currentPeakTime = "+currentPeakTime);
      prevPeakTime=currentPeakTime;


      //////////////
      ///Conditions after zigzag conditions
      if(ZigBuyConditions.isPeakFound)
        {
         double high1=iHigh(Symbol(),PERIOD_CURRENT,1);
         double high2=iHigh(Symbol(),PERIOD_CURRENT,2);

         if(ZigBuyConditions.step1)
           {
            double low1=iLow(Symbol(),PERIOD_CURRENT,1);
            double low2=iLow(Symbol(),PERIOD_CURRENT,2);
            if(low1<low2 && !ZigBuyConditions.step2)
              {
               ZigBuyConditions.step2=true;
               ZigBuyConditions.step2Time=iTime(Symbol(),PERIOD_CURRENT,0);
               // Print("isStep2Found isStep2Found isStep2Found");
               drawStepLabel(2,nuColor,low1-Point()*labDist,iTime(Symbol(),PERIOD_CURRENT,1));

              }
           }

         if(high1>high2 &&!ZigBuyConditions.step1)
           {
            ZigBuyConditions.step1=true;
            // Print("isStep1Found isStep1Found isStep1Found");
            drawStepLabel(1,nuColor,high1+Point()*labDist,iTime(Symbol(),PERIOD_CURRENT,1));
           }
        }

      ////Sell conditions after zigzag
      //----------------------------------------
      //----------------------------------------
      if(ZigSellConditions.isPeakFound)
        {
         double low1=iLow(Symbol(),PERIOD_CURRENT,1);
         double low2=iLow(Symbol(),PERIOD_CURRENT,2);

         if(ZigSellConditions.step1)
           {
            double high1=iHigh(Symbol(),PERIOD_CURRENT,1);
            double high2=iHigh(Symbol(),PERIOD_CURRENT,2);
            if(high1>high2 && !ZigSellConditions.step2)
              {
               ZigSellConditions.step2=true;
               ZigSellConditions.step2Time=iTime(Symbol(),PERIOD_CURRENT,0);
               // Print("isStep2Found isStep2Found isStep2Found");
               drawStepLabel(2,nuColorSells,high1+Point()*labDist,iTime(Symbol(),PERIOD_CURRENT,1));

              }
           }

         if(low1<low2 &&!ZigSellConditions.step1)
           {
            ZigSellConditions.step1=true;
            // Print("isStep1Found isStep1Found isStep1Found");
            drawStepLabel(1,nuColorSells,low1-Point()*labDist,iTime(Symbol(),PERIOD_CURRENT,1));
           }
        }
      //------------------------------------------
      //------------------------------------------


      //----------------------------------
      ///Finished Invalidating


     }



///Proccessing entry for Buys
//-----------------------------------
//  if(ZigBuyConditions.step2Time!=iTime(Symbol(),PERIOD_CURRENT,0))
//   {
   if(ZigBuyConditions.step2)
     {
      double prev_high=iHigh(Symbol(),PERIOD_CURRENT,1);
      double buffMA[];
      CopyBuffer(maHandle,0,1,1,buffMA);
      double cruLow=iLow(Symbol(),PERIOD_CURRENT,0);

      double close=iClose(Symbol(),PERIOD_CURRENT,0);
      if(close>prev_high)
        {
         //  Print("Entry step met");
         drawStepLabel(3,nuColor,cruLow-Point()*labDist,iTime(Symbol(),PERIOD_CURRENT,0));
         double low1=iLow(Symbol(),PERIOD_CURRENT,1);
         bool isCandleAboveMA=iClose(Symbol(),PERIOD_CURRENT,1)>buffMA[0];
         // Print((low1<=buffMA[0]+pointsFromMA*Point())+"   "+(isCandleAboveMA)+" "+isCandleBullish(1));
         if(low1<=buffMA[0]+pointsFromMA*Point() && isCandleAboveMA && isCandleBullish(1))
           {
            double stopLoss=low1-pointsBelowAbove*Point();
            processTradeOpen(ORDER_TYPE_BUY,stopLoss);
           }
         ZigBuyConditions=ZIG_CONDITIONS();
        }
     }
//  }
//-------------------------------------
//-------------------------------------
//  if(ZigSellConditions.step2Time!=iTime(Symbol(),PERIOD_CURRENT,0))
//    {
   if(ZigSellConditions.step2)
     {
      double prev_low=iLow(Symbol(),PERIOD_CURRENT,1);
      double buffMA[];
      CopyBuffer(maHandle,0,1,1,buffMA);
      double cruHigh=iHigh(Symbol(),PERIOD_CURRENT,0);

      double close=iClose(Symbol(),PERIOD_CURRENT,0);
      if(close<prev_low) //Done
        {
         //  Print("Entry step met");
         drawStepLabel(3,nuColorSells,cruHigh+Point()*labDist,iTime(Symbol(),PERIOD_CURRENT,0));
         double high1=iHigh(Symbol(),PERIOD_CURRENT,1);
         bool isCandleBelowMA=iClose(Symbol(),PERIOD_CURRENT,1)<buffMA[0];
         if(high1>=buffMA[0]-pointsFromMA*Point() && isCandleBelowMA && isCandleBearish(1))
           {
            double stopLoss=high1+pointsBelowAbove*Point();
            processTradeOpen(ORDER_TYPE_SELL,stopLoss);
           }
         ZigSellConditions=ZIG_CONDITIONS();
        }
     }
//  }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void drawStepLabel(int stepVal,color arrColor,double price,datetime arrowTime)
  {
   int arrowCode=128+stepVal;
   ObjectDelete(0,"lab"+(string)arrowTime);
   ObjectCreate(0,"lab"+(string)arrowTime,OBJ_ARROW,0,arrowTime,price);
   ObjectSetInteger(0,"lab"+(string)arrowTime,OBJPROP_ARROWCODE,arrowCode);
   ObjectSetInteger(0,"lab"+(string)arrowTime,OBJPROP_COLOR,arrColor);
   ObjectSetInteger(0,"lab"+(string)arrowTime,OBJPROP_WIDTH,1);

   if(arrowTime<lastArrowTime && stepVal==0)
     {
      ObjectDelete(0,"lab"+(string)lastArrowTime);
     }
   lastArrowTime=arrowTime;

   ChartRedraw(0);
  }
datetime lastArrowTime;
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();
   delete Trade;
   IndicatorRelease(maHandle);
   IndicatorRelease(ZigZagHandle);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
struct TRADE_CONDITIONS
  {
   bool              isfractalFound;
   double            factVal;
   bool              isStep1Found;
   bool              isStep2Found;
   datetime          step2Time;
   bool              isStep3Found;

                     TRADE_CONDITIONS()
     {
      isfractalFound=false;
      factVal=0;
      isStep1Found=false;
      isStep2Found=false;
      isStep3Found=false;
      step2Time=0;
     }
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
TRADE_CONDITIONS conditionsBuy=TRADE_CONDITIONS();
TRADE_CONDITIONS conditionsSell=TRADE_CONDITIONS();

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
TRADE_CONDITIONS conditionsBuy_strat2=TRADE_CONDITIONS();
TRADE_CONDITIONS conditionsSell_strat2=TRADE_CONDITIONS();

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int swingIndex=0;
double getSwingHigh(int startPoint)
  {
   int range=SwingRange;
   int lookbackPeriod=100;
   double swingHigh=0;
   for(int i = range+startPoint; i <range + lookbackPeriod+startPoint; i++)
     {
      // Check for Swing High
      bool isSwingHigh = true;
      for(int j = 1; j <= range; j++)
        {
         if(iHigh(Symbol(), PERIOD_CURRENT, i) < iHigh(Symbol(), PERIOD_CURRENT, i - j) ||
            iHigh(Symbol(), PERIOD_CURRENT, i) < iHigh(Symbol(), PERIOD_CURRENT, i + j))
           {
            isSwingHigh = false;
            break;
           }
        }
      if(isSwingHigh)
        {
         // Print("Swing High found at bar ", i, " with price ", iHigh(Symbol(), PERIOD_CURRENT, i));
         swingIndex=i;
         swingHigh = iHigh(Symbol(), PERIOD_CURRENT, i);
         break;
         // Here you can do something with the swing high (e.g., mark on chart or use in strategy)
        }
     }
   return swingHigh;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getSwingLow(int startPoint)
  {
   int range=SwingRange;
   int lookbackPeriod=100;
   double swingLow=0;
   for(int i = range+startPoint; i <range + lookbackPeriod+startPoint; i++)
     {
      // Check for Swing Low
      bool isSwingLow = true;
      for(int j = 1; j <= range; j++)
        {
         if(iLow(Symbol(), PERIOD_CURRENT, i) > iLow(Symbol(), PERIOD_CURRENT, i - j) ||
            iLow(Symbol(), PERIOD_CURRENT, i) > iLow(Symbol(), PERIOD_CURRENT, i + j))
           {
            isSwingLow = false;
            break;
           }
        }
      if(isSwingLow)
        {
         // Print("Swing Low found at bar ", i, " with price ", iLow(Symbol(), PERIOD_CURRENT, i));
         //swingLowTime = iTime(Symbol(), PERIOD_CURRENT, i);
         swingIndex=i;
         swingLow = iLow(Symbol(), PERIOD_CURRENT, i);
         // Here you can do something with the swing low (e.g., mark on chart or use in strategy)
         break;
        }
     }
   return swingLow;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int getTotalTrades()
  {
   int total=0;
   for(int x=0;x<PositionsTotal();x++)
     {
      ulong ticket=PositionGetTicket(x);
      if(PositionSelectByTicket(ticket))
        {
         if(PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetInteger(POSITION_MAGIC)==MagicID)
           {
            total++;
           }
        }
     }
   return total;
  }
datetime time1;
void OnTick()
  {
//---
   if(isTimeOK())
     {
      if(getTotalTrades()==0)
        {
         if(useZigZagBased==0)
           {
            if(!ZigBuyConditions_strat2.isPeakFound && !ZigSellConditions_strat2.isPeakFound)
               ProcessZigZagStrategy();
            if(!ZigBuyConditions.isPeakFound&& !ZigSellConditions.isPeakFound)
               ProcessZigZagStrategy_Strategy2();
           }
         else
           {
            if(!conditionsBuy_strat2.isfractalFound && !conditionsSell_strat2.isfractalFound)
               ProcessSwingStrategy();
            if(!conditionsBuy.isfractalFound && !conditionsSell.isfractalFound)
               ProcessSwingStrategy_Strategy2();
           }
        }
     }
   Comment("ZigBuyConditions_strat2.isPeakFound ",ZigBuyConditions_strat2.isPeakFound," ZigSellConditions_strat2.isPeakFound ",ZigSellConditions_strat2.isPeakFound,"  ZigBuyConditions.isPeakFound = ",ZigBuyConditions.isPeakFound," conditionsSell.isfractalFound = ",conditionsSell.isfractalFound);
   /* return;
    */
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

datetime prevSwingTimeBuy=0;
datetime prevSwingTimeSell=0;
void ProcessSwingStrategy()
  {
   /*  if(time1!=iTime(Symbol(),PERIOD_CURRENT,0))
       {
        time1=iTime(Symbol(),PERIOD_CURRENT,0);
        double swingHigh1=getSwingHigh(0);
        double swingHigh2=getSwingHigh(swingIndex+SwingRange-1);

       // Print("swingHigh1 = "+swingHigh1+"   swingHigh2  =  "+swingHigh2);

        double swingLow1=getSwingLow(0);
        double swingLow2=getSwingLow(swingIndex+SwingRange-1);

        Print("swingLow1 = "+DoubleToString(swingLow1,Digits())+"   swingLow2  =  "+DoubleToString(swingLow2,Digits()));

       }*/

   if(time1!=iTime(Symbol(),PERIOD_CURRENT,0))
     {
      datetime  currentSwingTime=0;
      time1=iTime(Symbol(),PERIOD_CURRENT,0);
      double high1=iHigh(Symbol(),PERIOD_CURRENT,1);
      double high2=iHigh(Symbol(),PERIOD_CURRENT,2);
      double high3=iHigh(Symbol(),PERIOD_CURRENT,3);

      double swingHigh1=getSwingHigh(0);
      int initFractal=swingIndex;
      currentSwingTime=iTime(Symbol(),PERIOD_CURRENT,initFractal);
      double swingHigh2=getSwingHigh(swingIndex+SwingRange-1);

      if(currentSwingTime!=prevSwingTimeBuy &&!conditionsSell.isfractalFound)
        {
         if(swingHigh1>swingHigh2 &&!conditionsBuy.isfractalFound)
           {
            conditionsBuy.isfractalFound=true;
            conditionsBuy.factVal=swingHigh1;
            drawStepLabel(0,nuColor,swingHigh1+Point()*labDist,iTime(Symbol(),PERIOD_CURRENT,initFractal));
            //  Print("Fract Found");
           }
        }
      prevSwingTimeBuy=currentSwingTime;

      if(conditionsBuy.isfractalFound)
        {
         double low1=iLow(Symbol(),PERIOD_CURRENT,1);
         double low2=iLow(Symbol(),PERIOD_CURRENT,2);


         if(conditionsBuy.isStep1Found)
           {
            if(low1<low2 && !conditionsBuy.isStep2Found)
              {
               conditionsBuy.isStep2Found=true;
               // Print("isStep2Found isStep2Found isStep2Found");
               conditionsBuy.step2Time=iTime(Symbol(),PERIOD_CURRENT,0);
               // conditionsBuy.isfractalFound=false;
               drawStepLabel(2,nuColor,low1-Point()*labDist,iTime(Symbol(),PERIOD_CURRENT,1));
              }
           }

         if(high1>high2 &&!conditionsBuy.isStep1Found)
           {
            conditionsBuy.isStep1Found=true;
            // Print("isStep1Found isStep1Found isStep1Found");
            drawStepLabel(1,nuColor,high1+Point()*labDist,iTime(Symbol(),PERIOD_CURRENT,1));
           }
        }
      if(high1>conditionsBuy.factVal) //Invalidating Fractal 071 337 32409
        {
         conditionsBuy=TRADE_CONDITIONS();
         // Print("Invalidating Conditions");
        }

      //----------Sell Code
      //-----------------------------------
      //-------------------------------------------

      time1=iTime(Symbol(),PERIOD_CURRENT,0);

      double swingLow1=getSwingLow(0);
      initFractal=swingIndex;
      currentSwingTime = iTime(Symbol(),PERIOD_CURRENT,initFractal);
      double swingLow2=getSwingLow(swingIndex+SwingRange-1);
      if(currentSwingTime!=prevSwingTimeSell &&!conditionsBuy.isfractalFound)
        {
         if(swingLow1<swingLow2 &&!conditionsSell.isfractalFound)
           {
            conditionsSell.isfractalFound=true;
            conditionsSell.factVal=swingLow1;
            drawStepLabel(0,nuColorSells,swingLow1-Point()*labDist,iTime(Symbol(),PERIOD_CURRENT,initFractal));
            // Print("Fract Found");
           }
        }
      prevSwingTimeSell=currentSwingTime;
      if(conditionsSell.isfractalFound)
        {
         double low1=iLow(Symbol(),PERIOD_CURRENT,1);
         double low2=iLow(Symbol(),PERIOD_CURRENT,2);


         if(conditionsSell.isStep1Found)
           {
            if(high1>high2 && !conditionsSell.isStep2Found)
              {
               conditionsSell.isStep2Found=true;
               conditionsSell.step2Time=iTime(Symbol(),PERIOD_CURRENT,0);
               // Print("isStep2Found isStep2Found isStep2Found");
               // conditionsSell.isfractalFound=false;
               drawStepLabel(2,nuColorSells,high1+Point()*labDist,iTime(Symbol(),PERIOD_CURRENT,1));
              }
           }

         if(low1<low2 &&!conditionsSell.isStep1Found)
           {
            conditionsSell.isStep1Found=true;
            // Print("isStep1Found isStep1Found isStep1Found");
            drawStepLabel(1,nuColorSells,low1-Point()*labDist,iTime(Symbol(),PERIOD_CURRENT,1));
           }
        }



      double low1=iLow(Symbol(),PERIOD_CURRENT,1);
      if(low1<conditionsSell.factVal) //Invalidating Fractal 071 337 32409
        {
         conditionsSell=TRADE_CONDITIONS();
         // Print("Invalidating Conditions");
        }
     }


///Entry Part for Buy
//----------------------------------
   if(conditionsBuy.isStep2Found)
     {
      double buffMA[];
      double low1=iLow(Symbol(),PERIOD_CURRENT,1);
      double cruLow=iLow(Symbol(),PERIOD_CURRENT,0);
      CopyBuffer(maHandle,0,1,1,buffMA);
      double close=iClose(Symbol(),PERIOD_CURRENT,0);
      double prev_high=iHigh(Symbol(),PERIOD_CURRENT,1);
      if(close>prev_high /*&&  conditionsBuy.step2Time!=iTime(Symbol(),PERIOD_CURRENT,0)*/)
        {

         drawStepLabel(3,nuColor,cruLow-Point()*labDist,iTime(Symbol(),PERIOD_CURRENT,0));
         if(low1<=buffMA[0])
           {
            bool isCandleAboveMA=iClose(Symbol(),PERIOD_CURRENT,1)>buffMA[0];

            if(close>buffMA[0] && isCandleBullish(1) && isCandleAboveMA)
              {
               double stopLoss=low1-pointsBelowAbove*Point();
               processTradeOpen(ORDER_TYPE_BUY,low1);

              }
           }
         conditionsBuy=TRADE_CONDITIONS();
        }
     }


///Entry Part for Sell
//----------------------------------
   if(conditionsSell.isStep2Found)
     {
      double buffMA[];
      double high1=iHigh(Symbol(),PERIOD_CURRENT,1);
      double cruHigh=iHigh(Symbol(),PERIOD_CURRENT,0);
      CopyBuffer(maHandle,0,1,1,buffMA);
      double close=iClose(Symbol(),PERIOD_CURRENT,0);
      double prev_low=iLow(Symbol(),PERIOD_CURRENT,1);
      if(close<prev_low /*&&  conditionsSell.step2Time!=iTime(Symbol(),PERIOD_CURRENT,0)*/)
        {
         drawStepLabel(3,nuColorSells,cruHigh+Point()*labDist,iTime(Symbol(),PERIOD_CURRENT,0));
         if(high1>=buffMA[0])
           {
            bool isCandleBelowMA=iClose(Symbol(),PERIOD_CURRENT,1)<buffMA[0];

            if(close<buffMA[0] && isCandleBearish(1) && isCandleBelowMA)
              {
               double stopLoss=high1+pointsBelowAbove*Point();
               processTradeOpen(ORDER_TYPE_SELL,stopLoss);
              }
           }
         conditionsSell=TRADE_CONDITIONS();
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isCandleBullish(int index)
  {
   if(iClose(Symbol(),PERIOD_CURRENT,index)>iOpen(Symbol(),PERIOD_CURRENT,index))
      return true;
   return false;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isCandleBearish(int index)
  {
   if(iClose(Symbol(),PERIOD_CURRENT,index)<iOpen(Symbol(),PERIOD_CURRENT,index))
      return true;
   return false;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ulong processTradeOpen(ENUM_ORDER_TYPE orderType,double stopLoss)
  {
   double price=0;

   double takeProfitPrice=0;

   if(orderType==ORDER_TYPE_BUY)
     {
      price=NormalizeDouble(SymbolInfoDouble(Symbol(),SYMBOL_ASK),Digits());
      double tp=price+MathAbs(price-stopLoss)*rrRatio;
      takeProfitPrice=NormalizeDouble(tp,Digits());
     }
   else
      if(orderType==ORDER_TYPE_SELL)
        {
         price=NormalizeDouble(SymbolInfoDouble(Symbol(),SYMBOL_BID),Digits());
         double tp=price-MathAbs(price-stopLoss)*rrRatio;
         takeProfitPrice=NormalizeDouble(tp,Digits());
        }

//  double lotSize=NormalizeDouble(SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN),Digits());; //3 to 1000 for volitility 50
//Trade.PositionClose(Symbol(),-1);
   double marketPrice=SymbolInfoDouble(Symbol(),SYMBOL_BID);
   double lots=getLotSize(price,stopLoss,marketPrice);

   Trade.PositionOpen(Symbol(),orderType,lots,price,stopLoss,takeProfitPrice,NULL);

   int num_pos = PositionsTotal();
   ulong ticket = PositionGetTicket(num_pos - 1);
   return ticket;
  }

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---

  }
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()
  {
//---

  }
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
  {
//---

  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---

  }
//+------------------------------------------------------------------+
//| BookEvent function                                               |
//+------------------------------------------------------------------+
void OnBookEvent(const string &symbol)
  {
//---

  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//This function calculates the lot size based on the risk percentage specified.
double getLotSize(double entry, double sl,double market_price)
  {
   double diff=MathAbs(entry-sl)/Point();
   double money;

   money=riskPercentage*AccountInfoDouble(ACCOUNT_BALANCE)/100;


   double lot=money/(diff*getPipValue(Symbol(),market_price,1));

   double minLot=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN);
   double maxLot=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX);

   if(lot<minLot)
      lot=minLot;

   if(lot>maxLot)
      lot=maxLot;

   double step=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_STEP);
   if(step==0.1)
     {

      lot=NormalizeDouble(lot,1);
     }
   else
      if(step==0.01)
        {

         lot=NormalizeDouble(lot,2);
        }
      else
         if(step==0.001)
           {

            lot=NormalizeDouble(lot,3);
           }
         else
            if(step==0.0001)
              {

               lot=NormalizeDouble(lot,4);
              }
            else
              {
               lot=NormalizeDouble(lot,0);
              }

   return lot;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//This function calculates pip value since the value of 1 Pip differs in different Symbols
double getPipValue(string symbol,double market_price,double lotSize0)
  {
   double pipValue;
   double pointSize = SymbolInfoDouble(symbol, SYMBOL_POINT);
// double lotSize0 = 1.0; // You can adjust this based on your trade size
   double contractSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
//  double marketPrice = SymbolInfoDouble(symbol, SYMBOL_BID);

   pipValue = pointSize * lotSize0 * contractSize;

   string accountCurrency;
   accountCurrency = AccountInfoString(ACCOUNT_CURRENCY);

// string accountCurrency = AccountInfoString(ACCOUNT_CURRENCY);
   string quoteCurrency = StringSubstr(symbol, 3, 3); // Get the quote currency (second in pair)

   if(quoteCurrency != accountCurrency)
     {
      // You need to convert the value into the account currency, e.g., for EURUSD on a USD account, no conversion is needed.
      string conversionSymbol =IsCurrencyPair(quoteCurrency, accountCurrency);
      string symA=quoteCurrency + accountCurrency;
      string symB=accountCurrency + quoteCurrency;
      if(conversionSymbol==symA)
        {
         double conversionRate = SymbolInfoDouble(conversionSymbol,SYMBOL_BID);
         pipValue *= conversionRate;
         // Print("Conversion symbol found = "+conversionSymbol);
        }
      else
         if(conversionSymbol==symB)
           {
            double conversionRate = SymbolInfoDouble(conversionSymbol,SYMBOL_BID);
            pipValue /= conversionRate;
            //   Print("Conversion symbol found = "+conversionSymbol);
           }
         else
           {
            conversionSymbol = accountCurrency+quoteCurrency;
            //  Print("Conversion symbol not found = "+conversionSymbol);
           }
     }

   return pipValue;
  }
//+------------------------------------------------------------------+
string currencyPairs[];
string IsCurrencyPair(string curr1,string curr2)
  {
// Check if the symbol is in the list
   for(int i = 0; i < ArraySize(currencyPairs); i++)
     {
      if(currencyPairs[i] == (curr1+curr2))
         return (curr1+curr2);
      if(currencyPairs[i] == (curr2+curr1))
         return (curr2+curr1);
     }

// If no match found, return false
   return "NONE";
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ListAllSymbols()
  {
   int totalSymbols = SymbolsTotal(false); // Get the total number of available symbols
   ArrayResize(currencyPairs,totalSymbols,0);
// Loop through all symbols
   for(int i = 0; i < totalSymbols; i++)
     {
      string symbol = SymbolName(i, false); // Get the symbol name by index
      currencyPairs[i]=symbol;
      // Print(symbol); // Print the symbol to the log
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

datetime prevSwingTimeBuy2=0;
datetime prevSwingTimeSell2=0;
void ProcessSwingStrategy_Strategy2()
  {
   /*  if(time1!=iTime(Symbol(),PERIOD_CURRENT,0))
       {
        time1=iTime(Symbol(),PERIOD_CURRENT,0);
        double swingHigh1=getSwingHigh(0);
        double swingHigh2=getSwingHigh(swingIndex+SwingRange-1);

       // Print("swingHigh1 = "+swingHigh1+"   swingHigh2  =  "+swingHigh2);

        double swingLow1=getSwingLow(0);
        double swingLow2=getSwingLow(swingIndex+SwingRange-1);

        Print("swingLow1 = "+DoubleToString(swingLow1,Digits())+"   swingLow2  =  "+DoubleToString(swingLow2,Digits()));

       }*/

   if(time1!=iTime(Symbol(),PERIOD_CURRENT,0))
     {
      datetime  currentSwingTime=0;
      time1=iTime(Symbol(),PERIOD_CURRENT,0);
      double high1=iHigh(Symbol(),PERIOD_CURRENT,1);
      double high2=iHigh(Symbol(),PERIOD_CURRENT,2);
      double high3=iHigh(Symbol(),PERIOD_CURRENT,3);

      double swingHigh1=getSwingHigh(0);
      int initFractal=swingIndex;
      currentSwingTime=iTime(Symbol(),PERIOD_CURRENT,initFractal);
      double swingHigh2=getSwingHigh(swingIndex+SwingRange-1);

      if(currentSwingTime!=prevSwingTimeBuy2 &&!conditionsBuy_strat2.isfractalFound)
        {
         if(swingHigh1<swingHigh2 &&!conditionsSell_strat2.isfractalFound)
           {
            conditionsSell_strat2.isfractalFound=true;
            conditionsSell_strat2.factVal=swingHigh1;
            drawStepLabel(0,nuColorSells,swingHigh1+Point()*labDist,iTime(Symbol(),PERIOD_CURRENT,initFractal));
            //  Print("Fract Found");
           }
        }
      prevSwingTimeBuy2=currentSwingTime;

      if(conditionsSell_strat2.isfractalFound)
        {
         double low1=iLow(Symbol(),PERIOD_CURRENT,1);
         double low2=iLow(Symbol(),PERIOD_CURRENT,2);

         if(conditionsSell_strat2.isStep2Found)
           {
            if(high1>high2 &&!conditionsSell_strat2.isStep3Found)
              {
               conditionsSell_strat2.isStep3Found=true;
               drawStepLabel(3,nuColorSells,low1-Point()*labDist,iTime(Symbol(),PERIOD_CURRENT,1));
               // Print("isStep3Found isStep3Found isStep3Found sell");
              }
           }

         if(conditionsSell_strat2.isStep1Found)
           {
            if(low1<low2 && !conditionsSell_strat2.isStep2Found)
              {
               conditionsSell_strat2.isStep2Found=true;
               // Print("isStep2Found isStep2Found isStep2Found sell");
               conditionsSell_strat2.step2Time=iTime(Symbol(),PERIOD_CURRENT,0);
               // conditionsBuy_strat2.isfractalFound=false;
               drawStepLabel(2,nuColorSells,low1-Point()*labDist,iTime(Symbol(),PERIOD_CURRENT,1));
              }
           }

         if(high1>high2 &&!conditionsSell_strat2.isStep1Found)
           {
            conditionsSell_strat2.isStep1Found=true;
            //Print("isStep1Found isStep1Found isStep1Found sell");
            drawStepLabel(1,nuColorSells,high1+Point()*labDist,iTime(Symbol(),PERIOD_CURRENT,1));
           }
        }
      /*  if(high1>conditionsBuy_strat2.factVal) //Invalidating Fractal 071 337 32409
          {
           conditionsBuy_strat2=TRADE_CONDITIONS();
           // Print("Invalidating Conditions");
          }*/

      //----------New Buy Code
      //-----------------------------------
      //-------------------------------------------

      time1=iTime(Symbol(),PERIOD_CURRENT,0);

      double swingLow1=getSwingLow(0);
      initFractal=swingIndex;
      currentSwingTime = iTime(Symbol(),PERIOD_CURRENT,initFractal);
      double swingLow2=getSwingLow(swingIndex+SwingRange-1);
      if(currentSwingTime!=prevSwingTimeSell2 &&!conditionsSell_strat2.isfractalFound)
        {
         if(swingLow1>swingLow2 &&!conditionsBuy_strat2.isfractalFound)
           {
            conditionsBuy_strat2.isfractalFound=true;
            conditionsBuy_strat2.factVal=swingLow1;
            drawStepLabel(0,nuColor,swingLow1-Point()*labDist,iTime(Symbol(),PERIOD_CURRENT,initFractal));
            // Print("Fract Found");
           }
        }
      prevSwingTimeSell2=currentSwingTime;
      if(conditionsBuy_strat2.isfractalFound)
        {
         double low1=iLow(Symbol(),PERIOD_CURRENT,1);
         double low2=iLow(Symbol(),PERIOD_CURRENT,2);


         if(conditionsBuy_strat2.isStep2Found)
           {
            if(low1<low2 &&!conditionsBuy_strat2.isStep3Found)
              {
               conditionsBuy_strat2.isStep3Found=true;
               drawStepLabel(3,nuColor,high1+Point()*labDist,iTime(Symbol(),PERIOD_CURRENT,1));
               //Print("isStep3Found isStep3Found isStep3Found");
              }
           }

         if(conditionsBuy_strat2.isStep1Found)
           {
            if(high1>high2 && !conditionsBuy_strat2.isStep2Found)
              {
               conditionsBuy_strat2.isStep2Found=true;
               conditionsBuy_strat2.step2Time=iTime(Symbol(),PERIOD_CURRENT,0);
               //Print("isStep2Found isStep2Found isStep2Found");
               // conditionsSell_strat2.isfractalFound=false;
               drawStepLabel(2,nuColor,high1+Point()*labDist,iTime(Symbol(),PERIOD_CURRENT,1));
              }
           }

         if(low1<low2 &&!conditionsBuy_strat2.isStep1Found)
           {
            conditionsBuy_strat2.isStep1Found=true;
            //Print("isStep1Found isStep1Found isStep1Found");
            drawStepLabel(1,nuColor,low1-Point()*labDist,iTime(Symbol(),PERIOD_CURRENT,1));
           }
        }


      /*
            double low1=iLow(Symbol(),PERIOD_CURRENT,1);
            if(low1<conditionsSell_strat2.factVal) //Invalidating Fractal 071 337 32409
              {
               conditionsSell_strat2=TRADE_CONDITIONS();
               // Print("Invalidating Conditions");
              }*/
     }


///Entry Part for Buy
//----------------------------------
   if(conditionsBuy_strat2.isStep3Found)
     {
      double buffMA[];
      double low1=iLow(Symbol(),PERIOD_CURRENT,1);
      double cruLow=iLow(Symbol(),PERIOD_CURRENT,0);
      CopyBuffer(maHandle,0,1,1,buffMA);
      double close=iClose(Symbol(),PERIOD_CURRENT,0);
      double prev_high=iHigh(Symbol(),PERIOD_CURRENT,1);
      if(close>prev_high /*&&  conditionsBuy_strat2.step2Time!=iTime(Symbol(),PERIOD_CURRENT,0)*/)
        {

         drawStepLabel(4,nuColor,cruLow-Point()*labDist,iTime(Symbol(),PERIOD_CURRENT,0));
         if(low1<=buffMA[0])
           {
            bool isCandleAboveMA=iClose(Symbol(),PERIOD_CURRENT,1)>buffMA[0];

            if(close>buffMA[0] && isCandleBullish(1) && isCandleAboveMA)
              {
               double stopLoss=low1-pointsBelowAbove*Point();
               processTradeOpen(ORDER_TYPE_BUY,low1);

              }
           }
         conditionsBuy_strat2=TRADE_CONDITIONS();
        }
     }


///Entry Part for Sell
//----------------------------------
   if(conditionsSell_strat2.isStep3Found)
     {
      double buffMA[];
      double high1=iHigh(Symbol(),PERIOD_CURRENT,1);
      double cruHigh=iHigh(Symbol(),PERIOD_CURRENT,0);
      CopyBuffer(maHandle,0,1,1,buffMA);
      double close=iClose(Symbol(),PERIOD_CURRENT,0);
      double prev_low=iLow(Symbol(),PERIOD_CURRENT,1);
      if(close<prev_low /*&&  conditionsSell_strat2.step2Time!=iTime(Symbol(),PERIOD_CURRENT,0)*/)
        {
         drawStepLabel(4,nuColorSells,cruHigh+Point()*labDist,iTime(Symbol(),PERIOD_CURRENT,0));
         if(high1>=buffMA[0])
           {
            bool isCandleBelowMA=iClose(Symbol(),PERIOD_CURRENT,1)<buffMA[0];

            if(close<buffMA[0] && isCandleBearish(1) && isCandleBelowMA)
              {
               double stopLoss=high1+pointsBelowAbove*Point();
               processTradeOpen(ORDER_TYPE_SELL,stopLoss);
              }
           }
         conditionsSell_strat2=TRADE_CONDITIONS();
        }
     }
  }
//+------------------------------------------------------------------+



//datetime prevPeakTime=0;
//datetime currentPeakTime=0;
//datetime peakTime=0;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ProcessZigZagStrategy_Strategy2()
  {
   static datetime time2;
   if(time2!=iTime(Symbol(),PERIOD_CURRENT,0))
     {
      time2=iTime(Symbol(),PERIOD_CURRENT,0);
      double ZigBuffer[];
      CopyBuffer(ZigZagHandle,0,2,500,ZigBuffer);
      double ZigVals[];

      int peakIndex=0;
      int count = 1;
      for(int x=ArraySize(ZigBuffer)-1;x>=0;x--)
        {
         if(!(ZigBuffer[x]==EMPTY_VALUE || ZigBuffer[x]==0))
           {
            int size=ArraySize(ZigVals);
            ArrayResize(ZigVals,size+1,0);
            ZigVals[size]=ZigBuffer[x];
            if(size==5)
               break;
            if(size==0)
              {
               peakIndex=count;
               peakTime=iTime(Symbol(),PERIOD_CURRENT,peakIndex+1);
              }
           }
         count++;
        }

      //   ArrayPrint(ZigVals,Digits(),NULL,0,WHOLE_ARRAY);

      //////Buying comditions
      if(peakTime!=prevPeakTime || prevPeakTime==0)
        {
         if(!ZigBuyConditions_strat2.isPeakFound &&!ZigSellConditions_strat2.isPeakFound)
            if(ZigVals[0]<ZigVals[1] && ZigVals[0]>ZigVals[2])
              {
               double buffMA[];
               CopyBuffer(maHandle,0,peakIndex,1,buffMA);
               //   if(ZigVals[0]>buffMA[0])
               //   {
               ZigBuyConditions_strat2.isPeakFound=true;
               ZigBuyConditions_strat2.PeakVal=ZigVals[0];
               ZigBuyConditions_strat2.prevPeak=ZigVals[2];
               drawStepLabel(0,nuColor,ZigVals[0]-Point()*labDist,peakTime);
               //  Print("Looking for Buy conditions peakIndex  =  "+peakIndex+"  buffMA[0] = "+buffMA[0]);
               currentPeakTime=peakTime;
               //     }
              }

         if(!ZigSellConditions_strat2.isPeakFound && !ZigBuyConditions_strat2.isPeakFound)
            if(ZigVals[0]>ZigVals[1] && ZigVals[0]<ZigVals[2])
              {
               double buffMA[];
               CopyBuffer(maHandle,0,peakIndex,1,buffMA);
               // if(ZigVals[0]<buffMA[0])
               ///    {
               ZigSellConditions_strat2.isPeakFound=true;
               ZigSellConditions_strat2.PeakVal=ZigVals[0];
               ZigSellConditions_strat2.prevPeak=ZigVals[2];
               drawStepLabel(0,nuColorSells,ZigVals[0]+Point()*labDist,peakTime);
               //  Print("Looking for Sell conditions  peakIndex = "+peakIndex+"  buffMA[0] = "+buffMA[0]);
               currentPeakTime=peakTime;
               //    }
              }
        }
      // Print("prevPeakTime = "+prevPeakTime+"  currentPeakTime = "+currentPeakTime);
      prevPeakTime=currentPeakTime;
      ///Invalidating
      //--------------------------------------
      if(ZigBuyConditions_strat2.isPeakFound)
        {
         double prevLow=iLow(Symbol(),PERIOD_CURRENT,1);
         double prevHigh=iHigh(Symbol(),PERIOD_CURRENT,1);
         if(prevLow<ZigBuyConditions_strat2.PeakVal)
           {
            ZigBuyConditions_strat2=ZIG_CONDITIONS();
            // Print("Invalidating High strategy 2");
           }
        }

      if(ZigSellConditions_strat2.isPeakFound)
        {
         double prevLow=iLow(Symbol(),PERIOD_CURRENT,1);
         double prevHigh=iHigh(Symbol(),PERIOD_CURRENT,1);
         if(prevHigh>ZigSellConditions_strat2.PeakVal)
           {
            ZigSellConditions_strat2=ZIG_CONDITIONS();
            // Print("Invalidating Low strategy 2");
           }
        }

      ////////////// New Sell
      ///Conditions after zigzag conditions
      if(ZigSellConditions_strat2.isPeakFound)
        {
         double high1=iHigh(Symbol(),PERIOD_CURRENT,1);
         double high2=iHigh(Symbol(),PERIOD_CURRENT,2);

         if(ZigSellConditions_strat2.step2)
           {
            if(high1>high2 &&!ZigSellConditions_strat2.step3)
              {
               ZigSellConditions_strat2.step3=true;
               // Print("isStep1Found isStep1Found isStep1Found");
               drawStepLabel(3,nuColorSells,high1+Point()*labDist,iTime(Symbol(),PERIOD_CURRENT,1));
              }
           }

         if(ZigSellConditions_strat2.step1)
           {
            double low1=iLow(Symbol(),PERIOD_CURRENT,1);
            double low2=iLow(Symbol(),PERIOD_CURRENT,2);
            if(low1<low2 && !ZigSellConditions_strat2.step2)
              {
               ZigSellConditions_strat2.step2=true;
               ZigSellConditions_strat2.step2Time=iTime(Symbol(),PERIOD_CURRENT,0);
               // Print("isStep2Found isStep2Found isStep2Found");
               drawStepLabel(2,nuColorSells,low1-Point()*labDist,iTime(Symbol(),PERIOD_CURRENT,1));

              }
           }

         if(high1>high2 &&!ZigSellConditions_strat2.step1)
           {
            ZigSellConditions_strat2.step1=true;
            // Print("isStep1Found isStep1Found isStep1Found");
            drawStepLabel(1,nuColorSells,high1+Point()*labDist,iTime(Symbol(),PERIOD_CURRENT,1));
           }
        }

      ////New Buy conditions after zigzag
      //----------------------------------------
      //----------------------------------------
      if(ZigBuyConditions_strat2.isPeakFound)
        {
         double low1=iLow(Symbol(),PERIOD_CURRENT,1);
         double low2=iLow(Symbol(),PERIOD_CURRENT,2);

         if(ZigBuyConditions_strat2.step2)
           {
            if(low1<low2 &&!ZigBuyConditions_strat2.step3)
              {
               ZigBuyConditions_strat2.step3=true;
               // Print("isStep1Found isStep1Found isStep1Found");
               drawStepLabel(3,nuColor,low1-Point()*labDist,iTime(Symbol(),PERIOD_CURRENT,1));
              }
           }

         if(ZigBuyConditions_strat2.step1)
           {
            double high1=iHigh(Symbol(),PERIOD_CURRENT,1);
            double high2=iHigh(Symbol(),PERIOD_CURRENT,2);
            if(high1>high2 && !ZigBuyConditions_strat2.step2)
              {
               ZigBuyConditions_strat2.step2=true;
               ZigBuyConditions_strat2.step2Time=iTime(Symbol(),PERIOD_CURRENT,0);
               // Print("isStep2Found isStep2Found isStep2Found");
               drawStepLabel(2,nuColor,high1+Point()*labDist,iTime(Symbol(),PERIOD_CURRENT,1));

              }
           }

         if(low1<low2 &&!ZigBuyConditions_strat2.step1)
           {
            ZigBuyConditions_strat2.step1=true;
            //Print("isStep1Found isStep1Found isStep1Found");
            drawStepLabel(1,nuColor,low1-Point()*labDist,iTime(Symbol(),PERIOD_CURRENT,1));
           }
        }
      //------------------------------------------
      //------------------------------------------


      //----------------------------------
      ///Finished Invalidating


     }



///Proccessing entry for Buys
//-----------------------------------
//  if(ZigBuyConditions_strat2.step2Time!=iTime(Symbol(),PERIOD_CURRENT,0))
//   {
   if(ZigBuyConditions_strat2.step3)
     {
      double prev_high=iHigh(Symbol(),PERIOD_CURRENT,1);
      double buffMA[];
      CopyBuffer(maHandle,0,1,1,buffMA);
      double cruLow=iLow(Symbol(),PERIOD_CURRENT,0);

      double close=iClose(Symbol(),PERIOD_CURRENT,0);
      if(close>prev_high)
        {
         // Print("Entry step met");
         drawStepLabel(4,nuColor,cruLow-Point()*labDist,iTime(Symbol(),PERIOD_CURRENT,0));
         double low1=iLow(Symbol(),PERIOD_CURRENT,1);
         bool isCandleAboveMA=iClose(Symbol(),PERIOD_CURRENT,1)>buffMA[0];
         if(low1<=buffMA[0]+pointsFromMA*Point() && isCandleAboveMA && isCandleBullish(1))
           {
            double stopLoss=low1-pointsBelowAbove*Point();
            processTradeOpen(ORDER_TYPE_BUY,stopLoss);
           }
         ZigBuyConditions_strat2=ZIG_CONDITIONS();
        }
     }
//  }
//-------------------------------------
//-------------------------------------
//  if(ZigSellConditions_strat2.step2Time!=iTime(Symbol(),PERIOD_CURRENT,0))
//    {
   if(ZigSellConditions_strat2.step3)
     {
      double prev_low=iLow(Symbol(),PERIOD_CURRENT,1);
      double buffMA[];
      CopyBuffer(maHandle,0,1,1,buffMA);
      double cruHigh=iHigh(Symbol(),PERIOD_CURRENT,0);

      double close=iClose(Symbol(),PERIOD_CURRENT,0);
      if(close<prev_low) //Done
        {
         //  Print("Entry step met");
         drawStepLabel(4,nuColorSells,cruHigh+Point()*labDist,iTime(Symbol(),PERIOD_CURRENT,0));
         double high1=iHigh(Symbol(),PERIOD_CURRENT,1);
         bool isCandleBelowMA=iClose(Symbol(),PERIOD_CURRENT,1)<buffMA[0];
         if(high1>=buffMA[0]-pointsFromMA*Point() && isCandleBelowMA && isCandleBearish(1))
           {
            double stopLoss=high1+pointsBelowAbove*Point();
            processTradeOpen(ORDER_TYPE_SELL,stopLoss);
           }
         ZigSellConditions_strat2=ZIG_CONDITIONS();
        }
     }
//  }
  }

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isTimeOK()
  {
   if(useSeeions)
     {
      if(London)
        {
         datetime London_Start=StringToTime("08:00");
         datetime London_End=StringToTime("16:00");
         if(TimeGMT()>=London_Start && TimeGMT()<=London_End)
            return true;
        }
      if(Tokyo)
        {
         datetime Tokyo_Start=StringToTime("00:00");
         datetime Tokyo_End=StringToTime("09:00");

         //Print("Tokyo_Start  = "+Tokyo_Start+"  Tokyo_End  = "+Tokyo_End+"    TimeGMT()  ="+TimeGMT());
         if(TimeGMT()>=Tokyo_Start && TimeGMT()<=Tokyo_End)
            return true;
        }
      if(Sydney)
        {
         datetime Sydney_Start;
         datetime Sydney_End;
         if(TimeGMT()<=StringToTime("07:00"))
           {
            Sydney_Start=StringToTime("22:00")-3600*24;
            Sydney_End=StringToTime("07:00");
           }
         else
           {
            Sydney_Start=StringToTime("22:00");
            Sydney_End=StringToTime("07:00")+3600*24;
           }

         if(TimeGMT()>=Sydney_Start && TimeGMT()<=Sydney_End)
            return true;
        }
      if(NewYork)
        {
         datetime NewYork_Start=StringToTime("13:00");
         datetime NewYork_End=StringToTime("22:00");
         if(TimeGMT()>=NewYork_Start && TimeGMT()<=NewYork_End)
            return true;
        }
     }
   else
     {
      return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
