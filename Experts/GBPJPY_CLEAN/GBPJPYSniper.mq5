//+------------------------------------------------------------------+
//|                                                GBPJPYSniper.mq5  |
//|                                                  Mufraeli Rahman |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Mufraeli Rahman"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property description "GBPJPY Sniper - Algorithmic EA converted from Pine Script CLEAN LVII"

//+------------------------------------------------------------------+
//| Includes                                                         |
//+------------------------------------------------------------------+
#include <Expert/Expert.mqh>
#include "ExpertSniper.mqh"
#include "Helper.mqh"
#include "SignalMain.mqh"
#include "MoneySniperRisk.mqh"
#include "TrailingSniper.mqh"

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
//--- Expert Settings
input string             Expert_Title                   = "GBPJPY Sniper";
input ulong              Expert_MagicNumber             = 939731512;
input bool               Expert_EveryTick               = false;       // Use last confirmed bar only

//--- Main Signal Settings
input string             Signal_Symbol                  = "GBPJPY";
input int                Signal_Timeframe               = PERIOD_CURRENT;
input int                Signal_ThresholdOpen           = 100;         // Signal threshold value to open [0...100]
input int                Signal_ThresholdClose          = 100;         // Signal threshold value to close [0...100]
input double             Signal_PriceLevel              = 0.0;         // Price level to execute deal
input double             Signal_StopLevel               = 50.0;        // Stop Loss level (in points)
input double             Signal_TakeLevel               = 50.0;        // Take Profit level (in points)
input int                Signal_Expiration              = 4;           // Expiration of pending orders (in bars)

//--- Strategy Activation Toggles
input bool               Strategy_Enable_Long           = true;        // Enable Strategy Long (choppy_buy & long3)
input bool               Strategy_Enable_Long2          = true;        // Enable Strategy Long2
input bool               Strategy_Enable_Short          = true;        // Enable Strategy Short (choppy_sell)
input bool               Strategy_Enable_Short2         = true;        // Enable Strategy Short2
input bool               Strategy_Enable_Short3         = true;        // Enable Strategy Short3
input bool               Strategy_Enable_Short4         = true;        // Enable Strategy Short4 (short33)

//--- Strategy Trade Comment / ID Settings (Pine Script strategy.entry IDs)
input string             Strategy_Id_Long               = "Long";      // Long Strategy ID / Comment
input string             Strategy_Id_Long2              = "Long2";     // Long2 Strategy ID / Comment
input string             Strategy_Id_Short              = "Short";     // Short Strategy ID / Comment
input string             Strategy_Id_Short2             = "Short2";    // Short2 Strategy ID / Comment
input string             Strategy_Id_Short3             = "Short3";    // Short3 Strategy ID / Comment
input string             Strategy_Id_Short4             = "Short";     // Short4 Strategy ID / Comment

//--- Money Management & Position Sizing
input ENUM_POSITION_SIZING_TYPE Money_Sizing_Type_Buy   = SIZING_RISK_EQUITY_PER_TRADE; // Buy Sizing Model
input double             Money_Sizing_Value_Buy         = 5.75;        // Buy Risk Value (% or lots)
input ENUM_POSITION_SIZING_TYPE Money_Sizing_Type_Sell  = SIZING_RISK_EQUITY_PER_TRADE; // Sell Sizing Model
input double             Money_Sizing_Value_Sell        = 5.25;        // Sell Risk Value (% or lots)
input bool               Money_Enable_Night_Session     = false;       // Night Session Multiplier
input double             Money_Night_Session_Pct        = 0.10;        // Night Session Boost (+10%)

//--- Trailing and Multi-Stage Exits
input int                Trailing_Stop_Pips             = 50;          // Stop Loss distance (in pips)
input double             Trailing_TP1_Pct               = 0.006;       // Stage 1 Partial TP (0.6%)
input double             Trailing_TP2_Pct               = 0.012;       // Stage 2 Partial TP (1.2%)
input double             Trailing_TP3_Pct               = 0.018;       // Stage 3 Full TP (1.8%)
input bool               Trailing_Enable_BreakEven      = true;        // Move to Break-Even on Profit
input double             Trailing_BreakEven_Trigger_Pct = 0.004;       // Break-Even Trigger (0.4%)
input bool               Trailing_Enable_SuperTrend     = true;        // Dynamic SuperTrend Trailing

//--- LSMA (Least Squares Moving Average / Linear Regression)
input int                Signal_Lsma_Timeframe          = PERIOD_CURRENT;
input ENUM_APPLIED_PRICE Signal_Lsma_Source             = PRICE_CLOSE;
input int                Signal_Lsma_Period             = 18;
input int                Signal_Lsma_Offset             = 5;
input double             Signal_Lsma_Pip_Long           = 76.0;
input double             Signal_Lsma_Pip_Short          = 113.0;

//--- TEMA (Triple Exponential Moving Average)
input int                Signal_Tema_Timeframe          = PERIOD_CURRENT;
input ENUM_APPLIED_PRICE Signal_Tema_Source             = PRICE_CLOSE;
input int                Signal_Tema_Period             = 72;

//--- MEMO (EMA Open on H2)
input int                Signal_Memo_Timeframe          = PERIOD_H2;
input ENUM_APPLIED_PRICE Signal_Memo_Source             = PRICE_CLOSE;
input int                Signal_Memo_Period             = 10;
input ENUM_MA_METHOD     Signal_Memo_Method             = MODE_EMA;
input ENUM_APPLIED_PRICE Signal_Memo_Target             = PRICE_OPEN;

//--- CSO Close (Candlestick Limit for Close)
input int                Signal_Csoc_Idx_Long           = 4;
input double             Signal_Csoc_Pct_Long           = 0.464;
input int                Signal_Csoc_Idx_Short          = 2;
input double             Signal_Csoc_Pct_Short          = 0.777;
input ENUM_APPLIED_PRICE Signal_Csoc_Target             = PRICE_CLOSE;

//--- CSO Open (Candlestick Limit for Open)
input int                Signal_Csoo_Idx_Long           = 0;
input double             Signal_Csoo_Pct_Long           = 0.255;
input int                Signal_Csoo_Idx_Short          = 0;
input double             Signal_Csoo_Pct_Short          = 0.325;
input ENUM_APPLIED_PRICE Signal_Csoo_Target             = PRICE_OPEN;

//--- MEMA (RMA Close on M20)
input int                Signal_Mema_Timeframe          = PERIOD_M20;
input ENUM_APPLIED_PRICE Signal_Mema_Source             = PRICE_LOW;
input int                Signal_Mema_Period             = 60;
input ENUM_MA_METHOD     Signal_Mema_Method             = MODE_SMMA;
input ENUM_APPLIED_PRICE Signal_Mema_Target             = PRICE_CLOSE;

//--- ATR Trailing
input int                Signal_Atrt_Period_Long        = 10;
input double             Signal_Atrt_Multiplier_Long    = 3.6;
input int                Signal_Atrt_Period_Short       = 6;
input double             Signal_Atrt_Multiplier_Short   = 2.2;

//--- ZEMA (Zero-Lag EMA)
input int                Signal_Zema_Timeframe          = PERIOD_CURRENT;
input int                Signal_Zema_Period_Long        = 73;
input int                Signal_Zema_Period_Short       = 52;
input bool               Signal_Zema_Enable_Momentum    = true;
input string             Signal_Zema_Momentum_Cond_Long = "0|4";
input string             Signal_Zema_Momentum_Cond_Short= "0|1";

//--- Consolidation Zone
input int                Signal_Cons_Lookback_Long      = 16;
input int                Signal_Cons_Length_Long        = 7;
input int                Signal_Cons_Lookback_Short     = 8;
input int                Signal_Cons_Length_Short       = 2;

//--- ATR Indicator
input int                Signal_ATR_Timeframe           = PERIOD_M45;
input int                Signal_ATR_Period              = 3;
input ENUM_MA_METHOD     Signal_ATR_MaMethod            = MODE_SMMA;
input bool               Signal_ATR_EnableATRDirection  = true;
input bool               Signal_ATR_EnableATRIncrease   = true;

//--- Stochastic RSI
input ENUM_TIMEFRAMES    Signal_StochRsi_Timeframe      = PERIOD_M30;
input int                Signal_StochRsi_RsiPeriod      = 22;
input int                Signal_StochRsi_StochLength    = 2;
input int                Signal_StochRsi_K              = 19;
input int                Signal_StochRsi_D              = 2;
input ENUM_APPLIED_PRICE Signal_StochRsi_Source         = PRICE_HIGH;
input string             Signal_StochRsi_Operator       = ">";

//--- SuperTrend
input ENUM_TIMEFRAMES    Signal_ST_Timeframe            = PERIOD_M30;
input int                Signal_ST_Period               = 10;
input double             Signal_ST_Multiplier           = 3.1;
input ENUM_MA_METHOD     Signal_ST_MaMethod             = MODE_SMMA;
input ENUM_APPLIED_PRICE Signal_ST_Source               = PRICE_OPEN;

//--- Candlestick Body Filter
input int                Signal_Csb_Pip_Long            = 10;

//+------------------------------------------------------------------+
//| Global Expert Object                                             |
//+------------------------------------------------------------------+
CExpertSniper ExtExpert;

//+------------------------------------------------------------------+
//| Expert Initialization                                            |
//+------------------------------------------------------------------+
int OnInit(void) {
    // 1. Initialize Expert base
    if(!ExtExpert.Init(Symbol(), Period(), Expert_EveryTick, Expert_MagicNumber)) {
        printf(__FUNCTION__ + ": error initializing expert base");
        ExtExpert.Deinit();
        return(INIT_FAILED);
    }

    // 2. Create and configure master Signal
    SignalMain *signal = new SignalMain();
    if(signal == NULL) {
        printf(__FUNCTION__ + ": error creating SignalMain");
        ExtExpert.Deinit();
        return(INIT_FAILED);
    }

    ExtExpert.InitSignal(signal);
    ExtExpert.SignalMainPtr(signal);
    signal.Initialize(Symbol(), Period(), Expert_EveryTick);
    signal.ThresholdOpen(Signal_ThresholdOpen);
    signal.ThresholdClose(Signal_ThresholdClose);
    signal.PriceLevel(Signal_PriceLevel);
    signal.StopLevel(Signal_StopLevel);
    signal.TakeLevel(Signal_TakeLevel);
    signal.Expiration(Signal_Expiration);
    signal.SignalSymbol(Signal_Symbol);
    signal.SignalTimeframe(Signal_Timeframe);

    // Strategy Toggles
    signal.EnableStrategyLong(Strategy_Enable_Long);
    signal.EnableStrategyLong2(Strategy_Enable_Long2);
    signal.EnableStrategyShort(Strategy_Enable_Short);
    signal.EnableStrategyShort2(Strategy_Enable_Short2);
    signal.EnableStrategyShort3(Strategy_Enable_Short3);
    signal.EnableStrategyShort4(Strategy_Enable_Short4);

    // Strategy Trade Comment IDs (Pine Script strategy.entry IDs)
    signal.StrategyIdLong(Strategy_Id_Long);
    signal.StrategyIdLong2(Strategy_Id_Long2);
    signal.StrategyIdShort(Strategy_Id_Short);
    signal.StrategyIdShort2(Strategy_Id_Short2);
    signal.StrategyIdShort3(Strategy_Id_Short3);
    signal.StrategyIdShort4(Strategy_Id_Short4);

    // Configure LSMA
    signal.LsmaTimeframe(Signal_Lsma_Timeframe);
    signal.LsmaSource(Signal_Lsma_Source);
    signal.LsmaPeriod(Signal_Lsma_Period);
    signal.LsmaOffset(Signal_Lsma_Offset);
    signal.LsmaPipLong(Signal_Lsma_Pip_Long);
    signal.LsmaPipShort(Signal_Lsma_Pip_Short);

    // Configure TEMA
    signal.TemaTimeframe(Signal_Tema_Timeframe);
    signal.TemaSource(Signal_Tema_Source);
    signal.TemaPeriod(Signal_Tema_Period);

    // Configure MEMO
    signal.MemoTimeframe(Signal_Memo_Timeframe);
    signal.MemoSource(Signal_Memo_Source);
    signal.MemoPeriod(Signal_Memo_Period);
    signal.MemoMethod(Signal_Memo_Method);
    signal.MemoTarget(Signal_Memo_Target);

    // Configure CSO Close
    signal.CsoCloseIdxLong(Signal_Csoc_Idx_Long);
    signal.CsoClosePctLong(Signal_Csoc_Pct_Long);
    signal.CsoCloseIdxShort(Signal_Csoc_Idx_Short);
    signal.CsoClosePctShort(Signal_Csoc_Pct_Short);
    signal.CsoCloseTarget(Signal_Csoc_Target);

    // Configure CSO Open
    signal.CsoOpenIdxLong(Signal_Csoo_Idx_Long);
    signal.CsoOpenPctLong(Signal_Csoo_Pct_Long);
    signal.CsoOpenIdxShort(Signal_Csoo_Idx_Short);
    signal.CsoOpenPctShort(Signal_Csoo_Pct_Short);
    signal.CsoOpenTarget(Signal_Csoo_Target);

    // Configure MEMA
    signal.MemaTimeframe(Signal_Mema_Timeframe);
    signal.MemaSource(Signal_Mema_Source);
    signal.MemaPeriod(Signal_Mema_Period);
    signal.MemaMethod(Signal_Mema_Method);
    signal.MemaTarget(Signal_Mema_Target);

    // Configure ATR Trailing
    signal.ATRTPeriodLong(Signal_Atrt_Period_Long);
    signal.ATRTMultiplierLong(Signal_Atrt_Multiplier_Long);
    signal.ATRTPeriodShort(Signal_Atrt_Period_Short);
    signal.ATRTMultiplierShort(Signal_Atrt_Multiplier_Short);

    // Configure ZEMA
    signal.ZemaTimeframe(Signal_Zema_Timeframe);
    signal.ZemaPeriodLong(Signal_Zema_Period_Long);
    signal.ZemaPeriodShort(Signal_Zema_Period_Short);
    signal.ZemaEnableMomentum(Signal_Zema_Enable_Momentum);
    signal.ZemaMomentumCondLong(Signal_Zema_Momentum_Cond_Long);
    signal.ZemaMomentumCondShort(Signal_Zema_Momentum_Cond_Short);

    // Configure ATR
    signal.AtrTimeframe(Signal_ATR_Timeframe);
    signal.AtrPeriod(Signal_ATR_Period);
    signal.AtrMethod(Signal_ATR_MaMethod);
    signal.AtrEnableAtrDirection(Signal_ATR_EnableATRDirection);
    signal.AtrEnableAtrIncrease(Signal_ATR_EnableATRIncrease);

    // Configure Stochastic RSI
    signal.StochRsiTimeframe(Signal_StochRsi_Timeframe);
    signal.StochRsiRsiPeriod(Signal_StochRsi_RsiPeriod);
    signal.StochRsiStochPeriod(Signal_StochRsi_StochLength);
    signal.StochRsiK(Signal_StochRsi_K);
    signal.StochRsiD(Signal_StochRsi_D);
    signal.StochRsiSource(Signal_StochRsi_Source);
    signal.StochRsiOperator(Signal_StochRsi_Operator);

    // Configure SuperTrend
    signal.StTimeframe(Signal_ST_Timeframe);
    signal.StPeriod(Signal_ST_Period);
    signal.StMultiplier(Signal_ST_Multiplier);
    signal.StMethod(Signal_ST_MaMethod);
    signal.StSource(Signal_ST_Source);

    // Configure Candlestick Body Filter
    signal.CsbPipLong(Signal_Csb_Pip_Long);

    // 3. Create and configure Trailing Stop class
    CTrailingSniper *trailing = new CTrailingSniper();
    if(trailing == NULL) {
        printf(__FUNCTION__ + ": error creating CTrailingSniper");
        ExtExpert.Deinit();
        return(INIT_FAILED);
    }

    if(!ExtExpert.InitTrailing(trailing)) {
        printf(__FUNCTION__ + ": error initializing trailing");
        ExtExpert.Deinit();
        return(INIT_FAILED);
    }

    trailing.StopPips(Trailing_Stop_Pips);
    trailing.TP1Pct(Trailing_TP1_Pct);
    trailing.TP2Pct(Trailing_TP2_Pct);
    trailing.TP3Pct(Trailing_TP3_Pct);
    trailing.EnableBreakEven(Trailing_Enable_BreakEven);
    trailing.BreakEvenTriggerPct(Trailing_BreakEven_Trigger_Pct);
    trailing.EnableSuperTrendTrail(Trailing_Enable_SuperTrend);

    // 4. Create and configure Money Management class
    CMoneySniperRisk *money = new CMoneySniperRisk();
    if(money == NULL) {
        printf(__FUNCTION__ + ": error creating CMoneySniperRisk");
        ExtExpert.Deinit();
        return(INIT_FAILED);
    }

    if(!ExtExpert.InitMoney(money)) {
        printf(__FUNCTION__ + ": error initializing money management");
        ExtExpert.Deinit();
        return(INIT_FAILED);
    }

    money.SizingTypeLong(Money_Sizing_Type_Buy);
    money.SizingValueLong(Money_Sizing_Value_Buy);
    money.SizingTypeShort(Money_Sizing_Type_Sell);
    money.SizingValueShort(Money_Sizing_Value_Sell);
    money.EnableNightSession(Money_Enable_Night_Session);
    money.NightSessionPct(Money_Night_Session_Pct);

    // 5. Validate all settings
    if(!ExtExpert.ValidationSettings()) {
        printf(__FUNCTION__ + ": failed settings validation");
        ExtExpert.Deinit();
        return(INIT_FAILED);
    }

    // 6. Tune and initialize all indicators
    if(!ExtExpert.InitIndicators()) {
        printf(__FUNCTION__ + ": error initializing indicators");
        ExtExpert.Deinit();
        return(INIT_FAILED);
    }

    printf("GBPJPY Sniper EA initialized successfully for %s on period %s", Symbol(), EnumToString(Period()));
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert Deinitialization                                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    ExtExpert.Deinit();
}

//+------------------------------------------------------------------+
//| Tick Event Handler                                               |
//+------------------------------------------------------------------+
void OnTick(void) {
    ExtExpert.OnTick();
}

//+------------------------------------------------------------------+
//| Trade Event Handler                                              |
//+------------------------------------------------------------------+
void OnTrade(void) {
    ExtExpert.OnTrade();
}

//+------------------------------------------------------------------+
//| Timer Event Handler                                              |
//+------------------------------------------------------------------+
void OnTimer(void) {
    ExtExpert.OnTimer();
}
//+------------------------------------------------------------------+
