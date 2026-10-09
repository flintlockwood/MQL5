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
#include "SignalMain.mqh"
//--- available trailing
#include <Expert/Trailing/TrailingFixedPips.mqh>
//--- available money management
#include <Expert/Money/MoneyFixedRisk.mqh>
//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
//--- inputs for expert
input string             Expert_Title                  ="GBPJPY Sniper";    
ulong                    Expert_MagicNumber            =-939731512;  
bool                     Expert_EveryTick              =false;       // Use last confirmed bar only

//--- inputs for main signal
input string             Signal_Symbol                 ="GBPJPY";
input int                Signal_Timeframe              =PERIOD_CURRENT;
input int                Signal_ThresholdOpen          =100;         // Signal threshold value to open [0...100]
input int                Signal_ThresholdClose         =100;         // Signal threshold value to close [0...100]
input double             Signal_PriceLevel             =0.0;         // Price level to execute a deal
input double             Signal_StopLevel              =50.0;        // Stop Loss level (in points)
input double             Signal_TakeLevel              =50.0;        // Take Profit level (in points)
input int                Signal_Expiration             =4;           // Expiration of pending orders (in bars)

//--- inputs for LSMA
input int                Signal_Lsma_Timeframe         =PERIOD_CURRENT;
input ENUM_APPLIED_PRICE Signal_Lsma_Source            =PRICE_CLOSE;
input int                Signal_Lsma_Period            =18;
input int                Signal_Lsma_Offset            =5;
input int                Signal_Lsma_Pip_Long          =76;
input int                Signal_Lsma_Pip_Short         =113;

//--- inputs for TEMA
input int                Signal_Tema_Timeframe         =PERIOD_CURRENT;
input ENUM_APPLIED_PRICE Signal_Tema_Source            =PRICE_CLOSE;
input int                Signal_Tema_Period            =72;

//--- inputs for MEMO (ema open indicator)
input int                Signal_Memo_Timeframe         =PERIOD_H2;
input ENUM_APPLIED_PRICE Signal_Memo_Source            =PRICE_CLOSE;
input int                Signal_Memo_Period            =10;
input ENUM_MA_METHOD     Signal_Memo_Method            =MODE_EMA;
input ENUM_APPLIED_PRICE Signal_Memo_Target            =PRICE_OPEN;

//--- inputs for CSO Close 
input int                Signal_Csoc_Idx_Long               =4;
input double             Signal_Csoc_Pct_Long               =0.464;
input int                Signal_Csoc_Idx_Short              =2;
input double             Signal_Csoc_Pct_Short              =0.777;
input ENUM_APPLIED_PRICE Signal_Csoc_Target                 =PRICE_CLOSE;

//--- inputs for CSO Open
input int                Signal_Csoo_Idx_Long               =0;
input double             Signal_Csoo_Pct_Long               =0.255;
input int                Signal_Csoo_Idx_Short              =0;
input double             Signal_Csoo_Pct_Short              =0.325;
input ENUM_APPLIED_PRICE Signal_Csoo_Target                 =PRICE_OPEN;

//--- inputs for MEMA (rma close indicator)
input int                Signal_Mema_Timeframe         =PERIOD_M20;
input ENUM_APPLIED_PRICE Signal_Mema_Source            =PRICE_LOW;
input int                Signal_Mema_Period            =60;
input ENUM_MA_METHOD     Signal_Mema_Method            =MODE_SMMA;
input ENUM_APPLIED_PRICE Signal_Mema_Target            =PRICE_CLOSE;

//-- inputs for ATR Trailing
input int                Signal_Atrt_Period_Long       =10;
input double             Signal_Atrt_Multiplier_Long   =3.6;
input int                Signal_Atrt_Period_Short      =6;
input double             Signal_Atrt_Multiplier_Short  =2.2;

//--- inputs for zema indicator
input int                Signal_Zema_Timeframe         =PERIOD_CURRENT;
input int                Signal_Zema_Period_Long       =73;
input int                Signal_Zema_Period_Short      =52;
input bool               Signal_Zema_Enable_Momentum   =true;

//--- inputs for atr indicator
input int                Signal_ATR_Timeframe          =PERIOD_M45;
input int                Signal_ATR_Period             =3;
input ENUM_MA_METHOD     Signal_ATR_MaMethod           =MODE_SMMA;
input bool               Signal_ATR_EnableATRDirection =true;
input bool               Signal_ATR_EnableATRIncrease  =true;

//--- inputs for Stochastic RSI indicator
input ENUM_TIMEFRAMES    Signal_StochRsi_Timeframe     =PERIOD_M30;
input int                Signal_StochRsi_RsiPeriod     =22;
input int                Signal_StochRsi_StochLength   =2;
input int                Signal_StochRsi_K             =19;
input int                Signal_StochRsi_D             =2;
input ENUM_APPLIED_PRICE Signal_StochRsi_Source        =PRICE_HIGH;
input string             Signal_StochRsi_Operator      =">";

//--- inputs for super trend indicator
input ENUM_TIMEFRAMES    Signal_ST_Timeframe           =PERIOD_M30;
input int                Signal_ST_Period              =10;
input double             Signal_ST_Multiplier          =3.1;
input ENUM_MA_METHOD     Signal_ST_MaMethod            =MODE_SMMA;
input ENUM_APPLIED_PRICE Signal_ST_Source              =PRICE_OPEN;

//--- inputs for ma close indicator
input int                Signal_Ma_Timeframe            =PERIOD_M20;
input ENUM_APPLIED_PRICE Signal_Ma_Source               =PRICE_LOW;
input int                Signal_Ma_Period               =60;
input ENUM_MA_METHOD     Signal_Ma_Method               =MODE_SMMA;
input ENUM_APPLIED_PRICE Signal_Ma_Target               =PRICE_CLOSE;

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
    SignalMain *signal=new SignalMain;
    if(signal==NULL) {
        //--- failed
        printf(__FUNCTION__+": error creating signal");
        ExtExpert.Deinit();
        return(INIT_FAILED);
    }
    signal.Initialize();
//--- Set main signal parameters
    ExtExpert.InitSignal(signal);
    signal.ThresholdOpen(Signal_ThresholdOpen);
    signal.ThresholdClose(Signal_ThresholdClose);
    signal.PriceLevel(Signal_PriceLevel);
    signal.StopLevel(Signal_StopLevel);
    signal.TakeLevel(Signal_TakeLevel);
    signal.Expiration(Signal_Expiration);
    signal.SignalSymbol(Signal_Symbol);
    signal.SignalTimeframe(Signal_Timeframe);

// Set LSMA parameters
    signal.LsmaTimeframe(Signal_Lsma_Timeframe);
    signal.LsmaSource(Signal_Lsma_Source);
    signal.LsmaPeriod(Signal_Lsma_Period);
    signal.LsmaOffset(Signal_Lsma_Offset);
    signal.LsmaPipLong(Signal_Lsma_Pip_Long);
    signal.LsmaPipShort(Signal_Lsma_Pip_Short);

// Set TEMA parameters
    signal.TemaTimeframe(Signal_Tema_Timeframe);
    signal.TemaSource(Signal_Tema_Source);
    signal.TemaPeriod(Signal_Tema_Period);

// Set MEMO parameters
    signal.MemoTimeframe(Signal_Memo_Timeframe);
    signal.MemoSource(Signal_Memo_Source);
    signal.MemoPeriod(Signal_Memo_Period);
    signal.MemoMethod(Signal_Memo_Method);
    signal.MemoTarget(Signal_Memo_Target);

// Set CSO Close parameters
    signal.CsoCloseIdxLong(Signal_Csoc_Idx_Long);
    signal.CsoClosePctLong(Signal_Csoc_Pct_Long);
    signal.CsoCloseIdxShort(Signal_Csoc_Idx_Short);
    signal.CsoClosePctShort(Signal_Csoc_Pct_Short);
    signal.CsoCloseTarget(Signal_Csoc_Target);

// Set CSO Open parameters
    signal.CsoOpenIdxLong(Signal_Csoo_Idx_Long);
    signal.CsoOpenPctLong(Signal_Csoo_Pct_Short);
    signal.CsoOpenIdxShort(Signal_Csoo_Idx_Short);
    signal.CsoOpenPctShort(Signal_Csoo_Pct_Short);
    signal.CsoOpenTarget(Signal_Csoo_Target);

// Set ATR Trailing parameters
    signal.ATRTPeriodLong(Signal_Atrt_Period_Long);
    signal.ATRTMultiplierLong(Signal_Atrt_Multiplier_Long);
    signal.ATRTPeriodShort(Signal_Atrt_Period_Short);
    signal.ATRTMultiplierShort(Signal_Atrt_Multiplier_Short);

// Set ZEMA parameters
    signal.ZemaTimeframe(Signal_Zema_Timeframe);
    signal.ZemaPeriodLong(Signal_Zema_Period_Long);
    signal.ZemaPeriodShort(Signal_Zema_Period_Short);
    signal.ZemaEnableMomentum(Signal_Zema_Enable_Momentum);
    
// Set ATR parameter
    signal.AtrTimeframe(Signal_ATR_Timeframe);
    signal.AtrPeriod(Signal_ATR_Period);
    signal.AtrMethod(Signal_ATR_MaMethod);
    signal.AtrEnableAtrDirection(Signal_ATR_EnableATRDirection);
    signal.AtrEnableAtrIncrease(Signal_ATR_EnableATRIncrease);

    signal.StochRsiRsiPeriod(Signal_StochRsi_RsiPeriod);
    signal.StochRsiStochPeriod(Signal_StochRsi_StochLength);
    signal.StochRsiK(Signal_StochRsi_K);
    signal.StochRsiD(Signal_StochRsi_D);
    signal.StochRsiSource(Signal_StochRsi_Source);
    signal.StochRsiOperator(Signal_StochRsi_Operator);

    signal.StTimeframe(Signal_ST_Timeframe);
    signal.StPeriod(Signal_ST_Period);
    signal.StMultiplier(Signal_ST_Multiplier);
    signal.StMethod(Signal_ST_MaMethod);
    signal.StSource(Signal_ST_Source);

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
