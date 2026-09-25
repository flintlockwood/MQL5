//+------------------------------------------------------------------+
//|                                                       sniper.mq5 |
//|                                                  Mufraeli Rahman |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Mufraeli Rahman"
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include <Expert/Expert.mqh>
#include "Helper.mqh"
//--- available signals
#include "SignalSuperTrend.mqh"
#include "SignalStochRSI.mqh"
//--- available trailing
#include <Expert/Trailing/TrailingFixedPips.mqh>
//--- available money management
#include <Expert/Money/MoneyFixedRisk.mqh>
//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
//--- inputs for expert
input string             Expert_Title                  ="sniper";    // Document name
ulong                    Expert_MagicNumber            =-939731512;  //
bool                     Expert_EveryTick              =false;       //
//--- inputs for main signal
input int                Signal_ThresholdOpen          =100;         // Signal threshold value to open [0...100]
input int                Signal_ThresholdClose         =100;         // Signal threshold value to close [0...100]
input double             Signal_PriceLevel             =0.0;         // Price level to execute a deal
input double             Signal_StopLevel              =50.0;        // Stop Loss level (in points)
input double             Signal_TakeLevel              =50.0;        // Take Profit level (in points)
input int                Signal_Expiration             =4;           // Expiration of pending orders (in bars)
//--- inputs for super trend indicator
input string             Signal_ST_Symbol              ="GBPJPY";
input ENUM_TIMEFRAMES    Signal_ST_Timeframe           =PERIOD_M30;
input int                Signal_ST_Period              =10;
input double             Signal_ST_Multiplier          =3.1;
input ENUM_MA_METHOD     Signal_ST_MaMethod            =MODE_SMMA;
input ENUM_APPLIED_PRICE Signal_ST_AppliedPrice        =PRICE_OPEN;
//--- inputs for Stochastic RSI indicator
// input string             Signal_StochRsi_Symbol        ="GBPJPY";
// input ENUM_TIMEFRAMES    Signal_StochRsi_Timeframe     =PERIOD_M30;
// input int                Signal_StochRsi_RsiPeriod     =22;
// input int                Signal_StochRsi_StochLength   =2;
// input int                Signal_StochRsi_K             =19;
// input int                Signal_StochRsi_D             =2;
// input ENUM_APPLIED_PRICE Signal_StochRsi_AppliedPrice  =PRICE_HIGH;
// input string             Signal_StochRsi_KDOperator    =">";
//--- inputs for atr indicator
// input string             Signal_ATR_Symbol             ="GBPJPY";
// input int                Signal_ATR_Timeframe          =PERIOD_M45;
// input int                Signal_ATR_Period             =3;
// input ENUM_MA_METHOD     Signal_ATR_MaMethod           =MODE_SMMA;
// input bool               Signal_ATR_EnableATRDirection =true;
// input bool               Signal_ATR_EnableATRIncrease  =true;
//--- inputs for ma indicator
// input int                Signal_MA_PeriodMA            =12;          // Moving Average(12,0,...) Period of averaging
// input int                Signal_MA_Shift               =0;           // Moving Average(12,0,...) Time shift
// input ENUM_MA_METHOD     Signal_MA_Method              =MODE_SMA;    // Moving Average(12,0,...) Method of averaging
// input ENUM_APPLIED_PRICE Signal_MA_Applied             =PRICE_CLOSE; // Moving Average(12,0,...) Prices series
// input double             Signal_MA_Weight              =1.0;         // Moving Average(12,0,...) Weight [0...1.0]
//--- inputs for macd indicator
// input int                Signal_MACD_PeriodFast        =12;          // MACD(12,24,9,PRICE_CLOSE) Period of fast EMA
// input int                Signal_MACD_PeriodSlow        =24;          // MACD(12,24,9,PRICE_CLOSE) Period of slow EMA
// input int                Signal_MACD_PeriodSignal      =9;           // MACD(12,24,9,PRICE_CLOSE) Period of averaging of difference
// input ENUM_APPLIED_PRICE Signal_MACD_Applied           =PRICE_CLOSE; // MACD(12,24,9,PRICE_CLOSE) Prices series
// input double             Signal_MACD_Weight            =1.0;         // MACD(12,24,9,PRICE_CLOSE) Weight [0...1.0]
//--- input for rsi indicator
// input int                Signal_RSI_PeriodRSI          =8;           // Relative Strength Index(8,...) Period of calculation
// input ENUM_APPLIED_PRICE Signal_RSI_Applied            =PRICE_CLOSE; // Relative Strength Index(8,...) Prices series
// input double             Signal_RSI_Weight             =1.0;         // Relative Strength Index(8,...) Weight [0...1.0]

//--- inputs for trailing
input int                Trailing_FixedPips_StopLevel  =30;          // Stop Loss trailing level (in points)
input int                Trailing_FixedPips_ProfitLevel=50;          // Take Profit trailing level (in points)

//--- inputs for money
input double             Money_FixRisk_Percent         =10.0;        // Risk percentage

//+------------------------------------------------------------------+
//| Global expert object                                             |
//+------------------------------------------------------------------+
CExpert ExtExpert;
//+------------------------------------------------------------------+
//| Initialization function of the expert                            |
//+------------------------------------------------------------------+
int OnInit() {
//--- Initializing expert
    if(!ExtExpert.Init(Symbol(), Period(), Expert_EveryTick, Expert_MagicNumber)) {
        //--- failed
        printf(__FUNCTION__+": error initializing expert");
        ExtExpert.Deinit();
        return(INIT_FAILED);
    }
//--- Creating signal
    CExpertSignal *signal=new CExpertSignal;
    if(signal==NULL) {
        //--- failed
        printf(__FUNCTION__+": error creating signal");
        ExtExpert.Deinit();
        return(INIT_FAILED);
    }
//---
    ExtExpert.InitSignal(signal);
    signal.ThresholdOpen(Signal_ThresholdOpen);
    signal.ThresholdClose(Signal_ThresholdClose);
    signal.PriceLevel(Signal_PriceLevel);
    signal.StopLevel(Signal_StopLevel);
    signal.TakeLevel(Signal_TakeLevel);
    signal.Expiration(Signal_Expiration);
//--- Createing filter SuperTrend
    SignalSuperTrend *filterST=new SignalSuperTrend;
    if(filterST==NULL) {
        //--- failed
        printf(__FUNCTION__+": error creating super trend filter");
        ExtExpert.Deinit();
        return(INIT_FAILED);
    }
    signal.AddFilter(filterST);
//--- Set filter parameters
    filterST.SignalSymbol(Signal_ST_Symbol);
    filterST.SignalTimeframe(Signal_ST_Timeframe);
    filterST.PeriodMA(Signal_ST_Period);
    filterST.Multiplier(Signal_ST_Multiplier);
    filterST.MaMethod(Signal_ST_MaMethod);
    filterST.Applied(Signal_ST_AppliedPrice);

//--- Createing filter StochRSI
    // SignalStochRSI *filterStochRsi=new SignalStochRSI;
    // if(filterStochRsi==NULL) {
    //     //--- failed
    //     printf(__FUNCTION__+": error creating Stochastic RSI filter");
    //     ExtExpert.Deinit();
    //     return(INIT_FAILED);
    // }
    // signal.AddFilter(filterStochRsi);
//--- Set filter parameters
    // filterStochRsi.IndicatorSymbol(Signal_StochRsi_Symbol);
    // filterStochRsi.IndicatorTimeframe(Signal_StochRsi_Timeframe);
    // filterStochRsi.RSIPeriod(Signal_StochRsi_RsiPeriod);
    // filterStochRsi.StochLength(Signal_StochRsi_StochLength);
    // filterStochRsi.StochK(Signal_StochRsi_K);
    // filterStochRsi.StochD(Signal_StochRsi_D);
    // filterStochRsi.KDOperator(Signal_StochRsi_KDOperator);

//--- Creating filter CSignalMA
   //  CSignalMA *filter0=new CSignalMA;
   //  if(filter0==NULL) {
   //      //--- failed
   //      printf(__FUNCTION__+": error creating filter0");
   //      ExtExpert.Deinit();
   //      return(INIT_FAILED);
   //  }
   //  signal.AddFilter(filter0);
//--- Set filter parameters
   //  filter0.PeriodMA(Signal_MA_PeriodMA);
   //  filter0.Shift(Signal_MA_Shift);
   //  filter0.Method(Signal_MA_Method);
   //  filter0.Applied(Signal_MA_Applied);
   //  filter0.Weight(Signal_MA_Weight);

//--- Creating filter CSignalMACD
   //  CSignalMACD *filter1=new CSignalMACD;
   //  if(filter1==NULL) {
   //      //--- failed
   //      printf(__FUNCTION__+": error creating filter1");
   //      ExtExpert.Deinit();
   //      return(INIT_FAILED);
   //  }
   //  signal.AddFilter(filter1);
//--- Set filter parameters
   //  filter1.PeriodFast(Signal_MACD_PeriodFast);
   //  filter1.PeriodSlow(Signal_MACD_PeriodSlow);
   //  filter1.PeriodSignal(Signal_MACD_PeriodSignal);
   //  filter1.Applied(Signal_MACD_Applied);
   //  filter1.Weight(Signal_MACD_Weight);

//--- Creating filter CSignalRSI
   //  CSignalRSI *filter2=new CSignalRSI;
   //  if(filter2==NULL) {
   //      //--- failed
   //      printf(__FUNCTION__+": error creating filter2");
   //      ExtExpert.Deinit();
   //      return(INIT_FAILED);
   //  }
   //  signal.AddFilter(filter2);
//--- Set filter parameters
   //  filter2.PeriodRSI(Signal_RSI_PeriodRSI);
   //  filter2.Applied(Signal_RSI_Applied);
   //  filter2.Weight(Signal_RSI_Weight);

//--- Creation of trailing object
    CTrailingFixedPips *trailing=new CTrailingFixedPips;
    if(trailing==NULL) {
        //--- failed
        printf(__FUNCTION__+": error creating trailing");
        ExtExpert.Deinit();
        return(INIT_FAILED);
    }
//--- Add trailing to expert (will be deleted automatically))
    if(!ExtExpert.InitTrailing(trailing)) {
        //--- failed
        printf(__FUNCTION__+": error initializing trailing");
        ExtExpert.Deinit();
        return(INIT_FAILED);
    }
//--- Set trailing parameters
    trailing.StopLevel(Trailing_FixedPips_StopLevel);
    trailing.ProfitLevel(Trailing_FixedPips_ProfitLevel);

//--- Creation of money object
    CMoneyFixedRisk *money=new CMoneyFixedRisk;
    if(money==NULL) {
        //--- failed
        printf(__FUNCTION__+": error creating money");
        ExtExpert.Deinit();
        return(INIT_FAILED);
    }
//--- Add money to expert (will be deleted automatically))
    if(!ExtExpert.InitMoney(money)) {
        //--- failed
        printf(__FUNCTION__+": error initializing money");
        ExtExpert.Deinit();
        return(INIT_FAILED);
    }
//--- Set money parameters
    money.Percent(Money_FixRisk_Percent);
//--- Check all trading objects parameters
    if(!ExtExpert.ValidationSettings()) {
        //--- failed
        ExtExpert.Deinit();
        return(INIT_FAILED);
    }
//--- Tuning of all necessary indicators
    if(!ExtExpert.InitIndicators()) {
        //--- failed
        printf(__FUNCTION__+": error initializing indicators");
        ExtExpert.Deinit();
        return(INIT_FAILED);
    }
//--- ok
    return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Deinitialization function of the expert                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    ExtExpert.Deinit();
}
//+------------------------------------------------------------------+
//| "Tick" event handler function                                    |
//+------------------------------------------------------------------+
void OnTick() {
    ExtExpert.OnTick();
}
//+------------------------------------------------------------------+
//| "Trade" event handler function                                   |
//+------------------------------------------------------------------+
void OnTrade() {
    ExtExpert.OnTrade();
}
//+------------------------------------------------------------------+
//| "Timer" event handler function                                   |
//+------------------------------------------------------------------+
void OnTimer() {
    ExtExpert.OnTimer();
}
//+------------------------------------------------------------------+
