//+------------------------------------------------------------------+
//|                                                   SignalMain.mqh |
//|                                                  Mufraeli Rahman |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Mufraeli Rahman"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Expert/ExpertSignal.mqh>
#include <MovingAverages.mqh>
#include "Helper.mqh"
#include "SignalLinearRegression.mqh"
#include "SignalTema.mqh"
#include "SignalZema.mqh"
#include "SignalSuperTrend.mqh"
#include "SignalStochRSI.mqh"
#include "SignalATR.mqh"
#include "SignalATRTrailing.mqh"
#include "SignalMovingAverage.mqh"
#include "SignalCandlestickLimit.mqh"
#include "SignalCandlestickBody.mqh"
#include "SignalConsolidation.mqh"
#include "SignalStrategyLong.mqh"
#include "SignalStrategyLong2.mqh"
#include "SignalStrategyShort.mqh"
#include "SignalStrategyShort2.mqh"
#include "SignalStrategyShort3.mqh"
#include "SignalStrategyShort4.mqh"

//+------------------------------------------------------------------+
//| Class SignalMain                                                 |
//| Purpose: Master coordinator signal managing shared indicators,   |
//|          sub-strategies, and immediate position exits            |
//+------------------------------------------------------------------+
class SignalMain : public CExpertSignal {
protected:
    CSignalExporter          m_exporter;
    CPositionInfo            m_position;

    //--- Symbol & Timeframe
    string                   m_sig_symbol;
    int                      m_sig_timeframe;

    //--- Strategy Classes (Each strategy.entry from Pine Script)
    CSignalStrategyLong     *m_strat_long;
    CSignalStrategyLong2    *m_strat_long2;
    CSignalStrategyShort    *m_strat_short;
    CSignalStrategyShort2   *m_strat_short2;
    CSignalStrategyShort3   *m_strat_short3;
    CSignalStrategyShort4   *m_strat_short4;

    //--- Active Strategy ID tracking for trade comment
    string                   m_active_long_id;
    string                   m_active_short_id;

    //--- Shared Indicator Filters
    SignalLinearRegression  *m_sig_lsma;
    SignalTema              *m_sig_tema;
    SignalMovingAverage     *m_sig_memo;         // 2H EMA Open
    SignalCandlestickLimit  *m_sig_csoc;         // CSO Close
    SignalCandlestickLimit  *m_sig_csoo;         // CSO Open
    SignalMovingAverage     *m_sig_mema;         // 20M RMA Close
    SignalATRTrailing       *m_sig_atrt;         // ATR Trailing
    SignalZema              *m_sig_zema;         // Zero-lag EMA
    SignalConsolidation     *m_sig_cons;         // Consolidation
    SignalATR               *m_sig_atr;          // ATR Direction
    SignalStochRSI          *m_sig_stochrsi;     // Stochastic RSI
    SignalSuperTrend        *m_sig_st;           // SuperTrend with close
    SignalSuperTrend        *m_sig_st2;          // SuperTrend without close
    SignalCandlestickBody   *m_sig_csb;          // Candlestick Body limit
    SignalTema              *m_sig_tema_mom;     // TEMA Momentum / BBMC
    SignalMovingAverage     *m_sig_emaf;         // Fast EMA Cloud
    SignalMovingAverage     *m_sig_emam;         // Medium EMA Cloud
    SignalMovingAverage     *m_sig_emas;         // Slow EMA Cloud

    //--- Immediate Exit Configuration (from Pine Script strategy.close)
    bool                     m_exit_stage_enabled;       // e53
    int                      m_stage_state;              // ft (0: stage 1, 1: stage 2)
    bool                     m_exit_short_filter;        // e34
    bool                     m_exit_buy_filter;          // e35
    bool                     m_exit_long_enabled;        // e89
    bool                     m_exit_wick_enabled;        // e48
    bool                     m_exit_csd_oppo;            // e56
    bool                     m_exit_tp_x;                // abuye
    double                   m_exit_profit_threshold;    // e58p

    //--- Parameter storage for initialization
    int                      m_lsma_timeframe;
    int                      m_tema_timeframe;
    int                      m_memo_timeframe;
    int                      m_csoc_timeframe;
    int                      m_csoo_timeframe;
    int                      m_mema_timeframe;
    int                      m_atrt_timeframe;
    int                      m_zema_timeframe;
    int                      m_atr_timeframe;
    int                      m_stochrsi_timeframe;
    int                      m_st_timeframe;
    int                      m_csb_pip_long;

public:
                             SignalMain(void);
                            ~SignalMain(void);

    //--- export methods
    void              EnableExport(bool enable, bool common_folder = false) { m_exporter.Enable(enable, common_folder); }
    void              ExportFilename(string filename)                       { m_exporter.SetFilename(filename); }
    void              ExportConditions(void) {
        datetime dt = (m_time != NULL && m_time.GetData(0) > 0) ? m_time.GetData(0) : iTime(m_symbol != NULL ? m_symbol.Name() : _Symbol, m_period, 0);
        m_exporter.Export(dt);
    }

    //--- Configuration Setters
    void                     SignalSymbol(string value)             { m_sig_symbol = value; }
    void                     SignalTimeframe(int value)             { m_sig_timeframe = value; }

    //--- Indicator Setters
    void                     LsmaTimeframe(int value)               { m_lsma_timeframe = value; }
    void                     LsmaSource(ENUM_APPLIED_PRICE value)   { m_sig_lsma.LsmaSource(value); }
    void                     LsmaPeriod(int value)                  { m_sig_lsma.LsmaPeriod(value); }
    void                     LsmaOffset(int value)                  { m_sig_lsma.LsmaOffset(value); }
    void                     LsmaPipLong(double value)              { m_sig_lsma.LsmaPipLong(value); }
    void                     LsmaPipShort(double value)             { m_sig_lsma.LsmaPipShort(value); }

    void                     TemaTimeframe(int value)               { m_tema_timeframe = value; }
    void                     TemaSource(ENUM_APPLIED_PRICE value)   { m_sig_tema.TemaSource(value); }
    void                     TemaPeriod(int value)                  { m_sig_tema.TemaPeriod(value); }

    void                     MemoTimeframe(int value)               { m_memo_timeframe = value; }
    void                     MemoSource(ENUM_APPLIED_PRICE value)   { m_sig_memo.MaSource(value); }
    void                     MemoPeriod(int value)                  { m_sig_memo.MaPeriod(value); }
    void                     MemoMethod(ENUM_MA_METHOD value)       { m_sig_memo.MaMethod(value); }
    void                     MemoTarget(ENUM_APPLIED_PRICE value)   { m_sig_memo.MaTarget(value); }

    void                     CsoCloseIdxLong(int value)             { m_sig_csoc.CsoIdxLong(value); }
    void                     CsoClosePctLong(double value)          { m_sig_csoc.CsoPctLong(value); }
    void                     CsoCloseIdxShort(int value)            { m_sig_csoc.CsoIdxShort(value); }
    void                     CsoClosePctShort(double value)         { m_sig_csoc.CsoPctShort(value); }
    void                     CsoCloseTarget(ENUM_APPLIED_PRICE val) { m_sig_csoc.CsoTarget(val); }

    void                     CsoOpenIdxLong(int value)              { m_sig_csoo.CsoIdxLong(value); }
    void                     CsoOpenPctLong(double value)           { m_sig_csoo.CsoPctLong(value); }
    void                     CsoOpenIdxShort(int value)             { m_sig_csoo.CsoIdxShort(value); }
    void                     CsoOpenPctShort(double value)          { m_sig_csoo.CsoPctShort(value); }
    void                     CsoOpenTarget(ENUM_APPLIED_PRICE val)  { m_sig_csoo.CsoTarget(val); }

    void                     MemaTimeframe(int value)               { m_mema_timeframe = value; }
    void                     MemaSource(ENUM_APPLIED_PRICE value)   { m_sig_mema.MaSource(value); }
    void                     MemaPeriod(int value)                  { m_sig_mema.MaPeriod(value); }
    void                     MemaMethod(ENUM_MA_METHOD value)       { m_sig_mema.MaMethod(value); }
    void                     MemaTarget(ENUM_APPLIED_PRICE value)   { m_sig_mema.MaTarget(value); }

    void                     ATRTPeriodLong(int value)              { m_sig_atrt.ATRPeriodLong(value); }
    void                     ATRTMultiplierLong(double value)       { m_sig_atrt.ATRMultiplierLong(value); }
    void                     ATRTPeriodShort(int value)             { m_sig_atrt.ATRPeriodShort(value); }
    void                     ATRTMultiplierShort(double value)      { m_sig_atrt.ATRMultiplierShort(value); }

    void                     ZemaTimeframe(int value)               { m_zema_timeframe = value; }
    void                     ZemaPeriodLong(int value)              { m_sig_zema.ZemaPeriodLong(value); }
    void                     ZemaPeriodShort(int value)             { m_sig_zema.ZemaPeriodShort(value); }
    void                     ZemaEnableMomentum(bool value)         { m_sig_zema.EnableZemaMomentum(value); }
    void                     ZemaMomentumCondLong(string value)     { m_sig_zema.ZemaMomentumCondLong(value); }
    void                     ZemaMomentumCondShort(string value)    { m_sig_zema.ZemaMomentumCondShort(value); }

    void                     AtrTimeframe(int value)                { m_atr_timeframe = value; }
    void                     AtrPeriod(int value)                   { m_sig_atr.ATRPeriod(value); }
    void                     AtrMethod(ENUM_MA_METHOD value)        { m_sig_atr.SmootingMethod(value); }
    void                     AtrEnableAtrDirection(bool value)      { m_sig_atr.EnableATRDirectionSignal(value); }
    void                     AtrEnableAtrIncrease(bool value)       { m_sig_atr.EnableATRIncreaseBySignal(value); }

    void                     StochRsiTimeframe(int value)           { m_stochrsi_timeframe = value; }
    void                     StochRsiRsiPeriod(int value)           { m_sig_stochrsi.RsiPeriod(value); }
    void                     StochRsiStochPeriod(int value)         { m_sig_stochrsi.StochPeriod(value); }
    void                     StochRsiK(int value)                   { m_sig_stochrsi.K(value); }
    void                     StochRsiD(int value)                   { m_sig_stochrsi.D(value); }
    void                     StochRsiSource(ENUM_APPLIED_PRICE val) { m_sig_stochrsi.Source(val); }
    void                     StochRsiOperator(string value)         { m_sig_stochrsi.Operator(value); }

    void                     StTimeframe(int value)                 { m_st_timeframe = value; }
    void                     StPeriod(int value)                    { m_sig_st.PeriodMA(value); m_sig_st2.PeriodMA(value); }
    void                     StMultiplier(double value)             { m_sig_st.Multiplier(value); m_sig_st2.Multiplier(value); }
    void                     StMethod(ENUM_MA_METHOD value)         { m_sig_st.MaMethod(value); m_sig_st2.MaMethod(value); }
    void                     StSource(ENUM_APPLIED_PRICE value)     { m_sig_st.Applied(value); m_sig_st2.Applied(value); }

    void                     CsbPipLong(int value)                  { m_csb_pip_long = value; m_sig_csb.CsbPipLong(value); }

    //--- Strategy Enable toggles
    void                     EnableStrategyLong(bool value)         { m_strat_long.EnableLong(value); }
    void                     EnableStrategyLong2(bool value)        { m_strat_long2.EnableLong2(value); }
    void                     EnableStrategyShort(bool value)        { m_strat_short.EnableShort(value); }
    void                     EnableStrategyShort2(bool value)       { m_strat_short2.EnableShort2(value); }
    void                     EnableStrategyShort3(bool value)       { m_strat_short3.EnableShort3(value); }
    void                     EnableStrategyShort4(bool value)       { m_strat_short4.EnableShort4(value); }

    //--- Strategy ID accessors
    string                   ActiveLongId(void) const               { return m_active_long_id; }
    string                   ActiveShortId(void) const              { return m_active_short_id; }
    void                     ActiveLongId(string id)                { m_active_long_id = id; }
    void                     ActiveShortId(string id)               { m_active_short_id = id; }

    //--- Strategy ID configuration setters
    void                     StrategyIdLong(string id)              { if(m_strat_long != NULL) m_strat_long.StrategyId(id); }
    void                     StrategyIdLong2(string id)             { if(m_strat_long2 != NULL) m_strat_long2.StrategyId(id); }
    void                     StrategyIdShort(string id)             { if(m_strat_short != NULL) m_strat_short.StrategyId(id); }
    void                     StrategyIdShort2(string id)            { if(m_strat_short2 != NULL) m_strat_short2.StrategyId(id); }
    void                     StrategyIdShort3(string id)            { if(m_strat_short3 != NULL) m_strat_short3.StrategyId(id); }
    void                     StrategyIdShort4(string id)            { if(m_strat_short4 != NULL) m_strat_short4.StrategyId(id); }

    //--- Virtual standard overrides
    bool                     Initialize(string symbol, int period, bool every_tick);
    virtual bool             ValidationSettings(void);
    virtual bool             InitIndicators(CIndicators *indicators);
    virtual int              LongCondition(void);
    virtual int              ShortCondition(void);
    virtual bool             CheckCloseLong(double &price);
    virtual bool             CheckCloseShort(double &price);
    virtual bool             CheckReverseLong(double &price, double &sl, double &tp, datetime &expiration);
    virtual bool             CheckReverseShort(double &price, double &sl, double &tp, datetime &expiration);

    //--- Safe Price Accessors preventing EMPTY_VALUE
    double                   Open(int ind) const  { double v = (m_open != NULL) ? m_open.GetData(ind) : EMPTY_VALUE; return (v != EMPTY_VALUE && v > 0.0) ? v : SafeOpen(m_symbol != NULL ? m_symbol.Name() : _Symbol, m_period, ind); }
    double                   High(int ind) const  { double v = (m_high != NULL) ? m_high.GetData(ind) : EMPTY_VALUE; return (v != EMPTY_VALUE && v > 0.0) ? v : SafeHigh(m_symbol != NULL ? m_symbol.Name() : _Symbol, m_period, ind); }
    double                   Low(int ind) const   { double v = (m_low != NULL) ? m_low.GetData(ind) : EMPTY_VALUE; return (v != EMPTY_VALUE && v > 0.0) ? v : SafeLow(m_symbol != NULL ? m_symbol.Name() : _Symbol, m_period, ind); }
    double                   Close(int ind) const { double v = (m_close != NULL) ? m_close.GetData(ind) : EMPTY_VALUE; return (v != EMPTY_VALUE && v > 0.0) ? v : SafeClose(m_symbol != NULL ? m_symbol.Name() : _Symbol, m_period, ind); }

protected:
    bool                     SelectPosition(void);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
SignalMain::SignalMain(void)
    : m_exit_stage_enabled(true),
      m_stage_state(0),
      m_exit_short_filter(true),
      m_exit_buy_filter(true),
      m_exit_long_enabled(true),
      m_exit_wick_enabled(true),
      m_exit_csd_oppo(true),
      m_exit_tp_x(true),
      m_exit_profit_threshold(0.005),
      m_lsma_timeframe(0),
      m_tema_timeframe(0),
      m_memo_timeframe(PERIOD_H2),
      m_csoc_timeframe(0),
      m_csoo_timeframe(0),
      m_mema_timeframe(PERIOD_M20),
      m_atrt_timeframe(0),
      m_zema_timeframe(0),
      m_atr_timeframe(PERIOD_M45),
      m_stochrsi_timeframe(PERIOD_M30),
      m_st_timeframe(PERIOD_M30),
      m_csb_pip_long(10),
      m_active_long_id(""),
      m_active_short_id("") {
    m_used_series = USE_SERIES_OPEN + USE_SERIES_HIGH + USE_SERIES_LOW + USE_SERIES_CLOSE;

    // Instantiate Sub-filters
    m_sig_lsma      = new SignalLinearRegression();
    m_sig_tema      = new SignalTema();
    m_sig_memo      = new SignalMovingAverage();
    m_sig_csoc      = new SignalCandlestickLimit();
    m_sig_csoo      = new SignalCandlestickLimit();
    m_sig_mema      = new SignalMovingAverage();
    m_sig_atrt      = new SignalATRTrailing();
    m_sig_zema      = new SignalZema();
    m_sig_cons      = new SignalConsolidation();
    m_sig_atr       = new SignalATR();
    m_sig_stochrsi  = new SignalStochRSI();
    m_sig_st        = new SignalSuperTrend();
    m_sig_st.EnableClose(true);
    m_sig_st2       = new SignalSuperTrend();
    m_sig_st2.EnableClose(false);
    m_sig_csb       = new SignalCandlestickBody();
    m_sig_tema_mom  = new SignalTema();
    m_sig_emaf      = new SignalMovingAverage();
    m_sig_emam      = new SignalMovingAverage();
    m_sig_emas      = new SignalMovingAverage();

    // Instantiate Entry Strategy classes
    m_strat_long    = new CSignalStrategyLong();
    m_strat_long2   = new CSignalStrategyLong2();
    m_strat_short   = new CSignalStrategyShort();
    m_strat_short2  = new CSignalStrategyShort2();
    m_strat_short3  = new CSignalStrategyShort3();
    m_strat_short4  = new CSignalStrategyShort4();
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
SignalMain::~SignalMain(void) {
    delete m_strat_long;
    delete m_strat_long2;
    delete m_strat_short;
    delete m_strat_short2;
    delete m_strat_short3;
    delete m_strat_short4;

    delete m_sig_lsma;
    delete m_sig_tema;
    delete m_sig_memo;
    delete m_sig_csoc;
    delete m_sig_csoo;
    delete m_sig_mema;
    delete m_sig_atrt;
    delete m_sig_zema;
    delete m_sig_cons;
    delete m_sig_atr;
    delete m_sig_stochrsi;
    delete m_sig_st;
    delete m_sig_st2;
    delete m_sig_csb;
    delete m_sig_tema_mom;
    delete m_sig_emaf;
    delete m_sig_emam;
    delete m_sig_emas;
}

//+------------------------------------------------------------------+
//| Initialize                                                       |
//+------------------------------------------------------------------+
bool SignalMain::Initialize(string symbol, int period, bool every_tick) {
    if(m_symbol == NULL) {
        if((m_symbol = new CSymbolInfo) == NULL)
            return(false);
    }
    if(!m_symbol.Name(symbol))
        return(false);

    m_sig_symbol    = symbol;
    m_sig_timeframe = period;
    m_period        = period;
    m_every_tick    = every_tick;

    CExpertBase::Init(m_symbol, (ENUM_TIMEFRAMES)period, 1);

    // Initialize Sub-Filters with timeframe settings
    m_sig_lsma.Initialize(symbol, m_lsma_timeframe == 0 ? period : m_lsma_timeframe, every_tick);
    m_sig_tema.Initialize(symbol, m_tema_timeframe == 0 ? period : m_tema_timeframe, every_tick);
    m_sig_memo.Initialize(symbol, m_memo_timeframe, every_tick);
    m_sig_csoc.Initialize(symbol, m_csoc_timeframe == 0 ? period : m_csoc_timeframe, every_tick);
    m_sig_csoo.Initialize(symbol, m_csoo_timeframe == 0 ? period : m_csoo_timeframe, every_tick);
    m_sig_mema.Initialize(symbol, m_mema_timeframe, every_tick);
    m_sig_atrt.Initialize(symbol, m_atrt_timeframe == 0 ? period : m_atrt_timeframe, every_tick);
    m_sig_zema.Initialize(symbol, m_zema_timeframe == 0 ? period : m_zema_timeframe, every_tick);
    m_sig_cons.Initialize(symbol, m_zema_timeframe == 0 ? period : m_zema_timeframe, every_tick);
    m_sig_atr.Initialize(symbol, m_atr_timeframe, every_tick);
    m_sig_stochrsi.Initialize(symbol, m_stochrsi_timeframe, every_tick);
    m_sig_st.Initialize(symbol, m_st_timeframe, every_tick);
    m_sig_st2.Initialize(symbol, m_st_timeframe, every_tick);
    m_sig_csb.Initialize(symbol, period, every_tick);
    m_sig_tema_mom.Initialize(symbol, period, every_tick);
    m_sig_emaf.Initialize(symbol, period, every_tick);
    m_sig_emam.Initialize(symbol, period, every_tick);
    m_sig_emas.Initialize(symbol, period, every_tick);

    // Initialize Entry Strategy instances
    m_strat_long.Init(m_symbol, (ENUM_TIMEFRAMES)period, 1);
    m_strat_long.SetFilterLSMA(m_sig_lsma);
    m_strat_long.SetFilterTEMA(m_sig_tema);
    m_strat_long.SetFilterMEMO(m_sig_memo);
    m_strat_long.SetFilterCSOC(m_sig_csoc);
    m_strat_long.SetFilterCSOO(m_sig_csoo);
    m_strat_long.SetFilterMEMA(m_sig_mema);
    m_strat_long.SetFilterCons(m_sig_cons);
    m_strat_long.SetFilterATR(m_sig_atr);
    m_strat_long.SetFilterStochRSI(m_sig_stochrsi);
    m_strat_long.SetFilterST(m_sig_st);
    m_strat_long.SetFilterST2(m_sig_st2);
    m_strat_long.SetFilterCSB(m_sig_csb);
    m_strat_long.SetFilterTemaMom(m_sig_tema_mom);
    m_strat_long.SetFilterEMAF(m_sig_emaf);
    m_strat_long.SetFilterEMAS(m_sig_emas);

    m_strat_long2.Init(m_symbol, (ENUM_TIMEFRAMES)period, 1);
    m_strat_long2.SetFilterZEMA(m_sig_zema);
    m_strat_long2.SetFilterST(m_sig_st2);
    m_strat_long2.SetFilterCSO(m_sig_csoo);
    m_strat_long2.SetFilterEMAF(m_sig_emaf);
    m_strat_long2.SetFilterEMAS(m_sig_emas);

    m_strat_short.Init(m_symbol, (ENUM_TIMEFRAMES)period, 1);
    m_strat_short.SetFilterLSMA(m_sig_lsma);
    m_strat_short.SetFilterTEMA(m_sig_tema);
    m_strat_short.SetFilterMEMO(m_sig_memo);
    m_strat_short.SetFilterCSOC(m_sig_csoc);
    m_strat_short.SetFilterCSOO(m_sig_csoo);
    m_strat_short.SetFilterMEMA(m_sig_mema);
    m_strat_short.SetFilterCons(m_sig_cons);
    m_strat_short.SetFilterATR(m_sig_atr);
    m_strat_short.SetFilterStochRSI(m_sig_stochrsi);
    m_strat_short.SetFilterST(m_sig_st);
    m_strat_short.SetFilterZEMA(m_sig_zema);

    m_strat_short2.Init(m_symbol, (ENUM_TIMEFRAMES)period, 1);
    m_strat_short2.SetFilterLSMA(m_sig_lsma);
    m_strat_short2.SetFilterTEMA(m_sig_tema);
    m_strat_short2.SetFilterZEMA(m_sig_zema);
    m_strat_short2.SetFilterST(m_sig_st2);
    m_strat_short2.SetFilterEMAF(m_sig_emaf);
    m_strat_short2.SetFilterEMAS(m_sig_emas);

    m_strat_short3.Init(m_symbol, (ENUM_TIMEFRAMES)period, 1);
    m_strat_short3.SetFilterZEMA(m_sig_zema);
    m_strat_short3.SetFilterST(m_sig_st);

    m_strat_short4.Init(m_symbol, (ENUM_TIMEFRAMES)period, 1);
    m_strat_short4.SetFilterLSMA(m_sig_lsma);
    m_strat_short4.SetFilterZEMA(m_sig_zema);
    m_strat_short4.SetFilterStochRSI(m_sig_stochrsi);

    return(true);
}

//+------------------------------------------------------------------+
//| ValidationSettings                                               |
//+------------------------------------------------------------------+
bool SignalMain::ValidationSettings(void) {
    if(!CExpertSignal::ValidationSettings())
        return(false);

    if(!m_sig_lsma.ValidationSettings())
        return(false);
    if(!m_sig_tema.ValidationSettings())
        return(false);
    if(!m_sig_zema.ValidationSettings())
        return(false);
    if(!m_sig_st.ValidationSettings())
        return(false);

    return(true);
}

//+------------------------------------------------------------------+
//| InitIndicators                                                   |
//+------------------------------------------------------------------+
bool SignalMain::InitIndicators(CIndicators *indicators) {
    if(indicators == NULL)
        return(false);
    if(!CExpertSignal::InitIndicators(indicators))
        return(false);

    this.EnableExport(true, false);
    this.ExportFilename("signal_main.csv");

    // Pass price series to sub-indicators
    m_sig_lsma.SetPriceSeries(m_open, m_high, m_low, m_close);
    m_sig_lsma.SetOtherSeries(m_spread, m_time, m_tick_volume, m_real_volume);
    m_sig_lsma.InitIndicators(indicators);
    m_sig_lsma.EnableExport(true, false);
    m_sig_lsma.ExportFilename("signal_lsma.csv");

    m_sig_tema.SetPriceSeries(m_open, m_high, m_low, m_close);
    m_sig_tema.SetOtherSeries(m_spread, m_time, m_tick_volume, m_real_volume);
    m_sig_tema.InitIndicators(indicators);
    m_sig_tema.EnableExport(true, false);
    m_sig_tema.ExportFilename("signal_tema.csv");

    m_sig_memo.SetPriceSeries(m_open, m_high, m_low, m_close);
    m_sig_memo.SetOtherSeries(m_spread, m_time, m_tick_volume, m_real_volume);
    m_sig_memo.InitIndicators(indicators);
    m_sig_memo.EnableExport(true, false);
    m_sig_memo.ExportFilename("signal_memo.csv");

    m_sig_csoc.SetPriceSeries(m_open, m_high, m_low, m_close);
    m_sig_csoc.SetOtherSeries(m_spread, m_time, m_tick_volume, m_real_volume);
    m_sig_csoc.InitIndicators(indicators);
    m_sig_csoc.EnableExport(true, false);
    m_sig_csoc.ExportFilename("signal_csoc.csv");

    m_sig_csoo.SetPriceSeries(m_open, m_high, m_low, m_close);
    m_sig_csoo.SetOtherSeries(m_spread, m_time, m_tick_volume, m_real_volume);
    m_sig_csoo.InitIndicators(indicators);
    m_sig_csoo.EnableExport(true, false);
    m_sig_csoo.ExportFilename("signal_csoo.csv");

    m_sig_mema.SetPriceSeries(m_open, m_high, m_low, m_close);
    m_sig_mema.SetOtherSeries(m_spread, m_time, m_tick_volume, m_real_volume);
    m_sig_mema.InitIndicators(indicators);
    m_sig_mema.EnableExport(true, false);
    m_sig_mema.ExportFilename("signal_mema.csv");

    m_sig_atrt.SetPriceSeries(m_open, m_high, m_low, m_close);
    m_sig_atrt.SetOtherSeries(m_spread, m_time, m_tick_volume, m_real_volume);
    m_sig_atrt.InitIndicators(indicators);
    m_sig_atrt.EnableExport(true, false);
    m_sig_atrt.ExportFilename("signal_atrt.csv");

    m_sig_zema.SetPriceSeries(m_open, m_high, m_low, m_close);
    m_sig_zema.SetOtherSeries(m_spread, m_time, m_tick_volume, m_real_volume);
    m_sig_zema.InitIndicators(indicators);
    m_sig_zema.EnableExport(true, false);
    m_sig_zema.ExportFilename("signal_zema.csv");

    m_sig_cons.SetPriceSeries(m_open, m_high, m_low, m_close);
    m_sig_cons.SetOtherSeries(m_spread, m_time, m_tick_volume, m_real_volume);
    m_sig_cons.InitIndicators(indicators);
    m_sig_cons.EnableExport(true, false);
    m_sig_cons.ExportFilename("signal_cons.csv");

    m_sig_atr.SetPriceSeries(m_open, m_high, m_low, m_close);
    m_sig_atr.SetOtherSeries(m_spread, m_time, m_tick_volume, m_real_volume);
    m_sig_atr.InitIndicators(indicators);
    m_sig_atr.EnableExport(true, false);
    m_sig_atr.ExportFilename("signal_atr.csv");

    m_sig_stochrsi.SetPriceSeries(m_open, m_high, m_low, m_close);
    m_sig_stochrsi.SetOtherSeries(m_spread, m_time, m_tick_volume, m_real_volume);
    m_sig_stochrsi.InitIndicators(indicators);
    m_sig_stochrsi.EnableExport(true, false);
    m_sig_stochrsi.ExportFilename("signal_stochrsi.csv");

    m_sig_st.SetPriceSeries(m_open, m_high, m_low, m_close);
    m_sig_st.SetOtherSeries(m_spread, m_time, m_tick_volume, m_real_volume);
    m_sig_st.InitIndicators(indicators);
    m_sig_st.EnableExport(true, false);
    m_sig_st.ExportFilename("signal_st.csv");

    m_sig_st2.SetPriceSeries(m_open, m_high, m_low, m_close);
    m_sig_st2.SetOtherSeries(m_spread, m_time, m_tick_volume, m_real_volume);
    m_sig_st2.InitIndicators(indicators);
    m_sig_st2.EnableExport(true, false);
    m_sig_st2.ExportFilename("signal_st2.csv");

    m_sig_csb.SetPriceSeries(m_open, m_high, m_low, m_close);
    m_sig_csb.SetOtherSeries(m_spread, m_time, m_tick_volume, m_real_volume);
    m_sig_csb.InitIndicators(indicators);
    m_sig_csb.EnableExport(true, false);
    m_sig_csb.ExportFilename("signal_csb.csv");

    m_sig_tema_mom.SetPriceSeries(m_open, m_high, m_low, m_close);
    m_sig_tema_mom.SetOtherSeries(m_spread, m_time, m_tick_volume, m_real_volume);
    m_sig_tema_mom.InitIndicators(indicators);
    m_sig_tema_mom.EnableExport(true, false);
    m_sig_tema_mom.ExportFilename("signal_tema_mom.csv");

    m_sig_emaf.SetPriceSeries(m_open, m_high, m_low, m_close);
    m_sig_emaf.SetOtherSeries(m_spread, m_time, m_tick_volume, m_real_volume);
    m_sig_emaf.InitIndicators(indicators);
    m_sig_emaf.EnableExport(true, false);
    m_sig_emaf.ExportFilename("signal_emaf.csv");

    m_sig_emam.SetPriceSeries(m_open, m_high, m_low, m_close);
    m_sig_emam.SetOtherSeries(m_spread, m_time, m_tick_volume, m_real_volume);
    m_sig_emam.InitIndicators(indicators);
    m_sig_emam.EnableExport(true, false);
    m_sig_emam.ExportFilename("signal_emam.csv");

    m_sig_emas.SetPriceSeries(m_open, m_high, m_low, m_close);
    m_sig_emas.SetOtherSeries(m_spread, m_time, m_tick_volume, m_real_volume);
    m_sig_emas.InitIndicators(indicators);
    m_sig_emas.EnableExport(true, false);
    m_sig_emas.ExportFilename("signal_emas.csv");

    // Pass price series to strategy instances
    m_strat_long.SetPriceSeries(m_open, m_high, m_low, m_close);
    m_strat_long.SetOtherSeries(m_spread, m_time, m_tick_volume, m_real_volume);
    m_strat_long.InitIndicators(indicators);
    m_strat_long.EnableExport(true, false);
    m_strat_long.ExportFilename("signal_strat_long.csv");

    m_strat_long2.SetPriceSeries(m_open, m_high, m_low, m_close);
    m_strat_long2.SetOtherSeries(m_spread, m_time, m_tick_volume, m_real_volume);
    m_strat_long2.InitIndicators(indicators);
    m_strat_long2.EnableExport(true, false);
    m_strat_long2.ExportFilename("signal_strat_long2.csv");

    m_strat_short.SetPriceSeries(m_open, m_high, m_low, m_close);
    m_strat_short.SetOtherSeries(m_spread, m_time, m_tick_volume, m_real_volume);
    m_strat_short.InitIndicators(indicators);
    m_strat_short.EnableExport(true, false);
    m_strat_short.ExportFilename("signal_strat_short.csv");

    m_strat_short2.SetPriceSeries(m_open, m_high, m_low, m_close);
    m_strat_short2.SetOtherSeries(m_spread, m_time, m_tick_volume, m_real_volume);
    m_strat_short2.InitIndicators(indicators);
    m_strat_short2.EnableExport(true, false);
    m_strat_short2.ExportFilename("signal_strat_short2.csv");

    m_strat_short3.SetPriceSeries(m_open, m_high, m_low, m_close);
    m_strat_short3.SetOtherSeries(m_spread, m_time, m_tick_volume, m_real_volume);
    m_strat_short3.InitIndicators(indicators);
    m_strat_short3.EnableExport(true, false);
    m_strat_short3.ExportFilename("signal_strat_short3.csv");

    m_strat_short4.SetPriceSeries(m_open, m_high, m_low, m_close);
    m_strat_short4.SetOtherSeries(m_spread, m_time, m_tick_volume, m_real_volume);
    m_strat_short4.InitIndicators(indicators);
    m_strat_short4.EnableExport(true, false);
    m_strat_short4.ExportFilename("signal_start_short4.csv");

    return(true);
}

//+------------------------------------------------------------------+
//| SelectPosition helper                                            |
//+------------------------------------------------------------------+
bool SignalMain::SelectPosition(void) {
    if((ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE) == ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)
        return(m_position.SelectByMagic(m_symbol.Name(), m_magic));
    return(m_position.Select(m_symbol.Name()));
}

//+------------------------------------------------------------------+
//| Long voting condition: Combines Strategy Long and Long2         |
//+------------------------------------------------------------------+
int SignalMain::LongCondition(void) {
    m_active_long_id = "";

    int vote1 = m_strat_long.LongCondition();

    m_exporter.UpdateLong(vote1);
    ExportConditions();

    if(vote1 > 0) {
        m_active_long_id = m_strat_long.StrategyId();
        return(vote1);
    }

    int vote2 = m_strat_long2.LongCondition();

    m_exporter.UpdateLong(vote2);
    ExportConditions();

    if(vote2 > 0) {
        m_active_long_id = m_strat_long2.StrategyId();
        return(vote2);
    }

    return(0);
}

//+------------------------------------------------------------------+
//| Short voting condition: Combines Strategy Short, Short2, 3, 4   |
//+------------------------------------------------------------------+
int SignalMain::ShortCondition(void) {
    m_active_short_id = "";

    int vote1 = m_strat_short.ShortCondition();
    m_exporter.UpdateShort(vote1);
    ExportConditions();
    if(vote1 > 0) {
        m_active_short_id = m_strat_short.StrategyId();
        return(vote1);
    }

    int vote2 = m_strat_short2.ShortCondition();
    m_exporter.UpdateShort(vote2);
    ExportConditions();
    if(vote2 > 0) {
        m_active_short_id = m_strat_short2.StrategyId();
        return(vote2);
    }

    int vote3 = m_strat_short3.ShortCondition();
    m_exporter.UpdateShort(vote3);
    ExportConditions();
    if(vote3 > 0) {
        m_active_short_id = m_strat_short3.StrategyId();
        return(vote3);
    }

    int vote4 = m_strat_short4.ShortCondition();
    m_exporter.UpdateShort(vote4);
    ExportConditions();
    if(vote4 > 0) {
        m_active_short_id = m_strat_short4.StrategyId();
        return(vote4);
    }

    return(0);
}

//+------------------------------------------------------------------+
//| CheckCloseLong: Evaluates all immediate Long exit rules          |
//| (Pine Script strategy.close for Long positions)                  |
//+------------------------------------------------------------------+
bool SignalMain::CheckCloseLong(double &price) {
    if(!SelectPosition() || m_position.Volume() <= 0)
        return(false);
    if(m_position.PositionType() != POSITION_TYPE_BUY)
        return(false);

    int idx = StartIndex();
    double current_bid = m_symbol.Bid();
    double open_price  = m_position.PriceOpen();

    // 1. Short Filter Exit (Pine line 2195: short signal occurs while holding long)
    if(m_exit_short_filter && ShortCondition() > 0) {
        price = current_bid;
        return(true);
    }

    // 2. Stage Exit Logic (Pine lines 2101-2110)
    // If long condition occurs again while holding long:
    if(m_exit_stage_enabled && LongCondition() > 0) {
        if(m_stage_state == 0) {
            m_stage_state = 1; // Stage 1 Exit reached
            price = current_bid;
            return(true);
        }
        else if(m_stage_state == 1) {
            price = current_bid; // Stage 2 Exit
            m_stage_state = 0;
            return(true);
        }
    }

    // 3. Take Profit X (Pine line 2559: in profit and SuperTrend flips)
    if(m_exit_tp_x && current_bid > open_price) {
        if(m_sig_st != NULL && m_sig_st.LongCondition() <= 0) {
            price = current_bid;
            return(true);
        }
    }

    // 4. CSD Opposite Exit (Pine line 2561: bearish bar with close < open)
    if(m_exit_csd_oppo && (Close(idx) < Open(idx)) && current_bid > open_price) {
        if(m_sig_csoo != NULL && m_sig_csoo.ShortCondition() > 0) {
            price = current_bid;
            return(true);
        }
    }

    // 5. Wick Exit (Pine line 2565: large upper wick rejection)
    if(m_exit_wick_enabled) {
        double bar_high  = High(idx);
        double bar_close = Close(idx);
        double bar_open  = Open(idx);
        double bar_low   = Low(idx);

        if(bar_close > bar_open && (bar_high - bar_close) > (2.0 * (bar_open - bar_low))) {
            price = current_bid;
            return(true);
        }
    }

    return(false);
}

//+------------------------------------------------------------------+
//| CheckCloseShort: Evaluates all immediate Short exit rules         |
//| (Pine Script strategy.close for Short positions)                 |
//+------------------------------------------------------------------+
bool SignalMain::CheckCloseShort(double &price) {
    if(!SelectPosition() || m_position.Volume() <= 0)
        return(false);
    if(m_position.PositionType() != POSITION_TYPE_SELL)
        return(false);

    int idx = StartIndex();
    double current_ask = m_symbol.Ask();
    double open_price  = m_position.PriceOpen();

    // 1. Buy Filter Exit (Pine line 2134: long signal occurs while holding short)
    if(m_exit_buy_filter && LongCondition() > 0) {
        price = current_ask;
        return(true);
    }

    // 2. LC/SSL exit (Pine line 2607: close > kernelEstimate and close > BBMC)
    if(m_sig_lsma != NULL && m_sig_tema != NULL) {
        if(m_sig_lsma.LongTrendCondition(idx) && m_sig_tema.LongCondition() > 0) {
            price = current_ask;
            return(true);
        }
    }

    // 3. Zero-lag EMA trend exit (Pine line 2658: trend flips bullish)
    if(m_sig_zema != NULL && m_sig_zema.LongCondition() > 0) {
        price = current_ask;
        return(true);
    }

    // 4. Wick Exit (Pine line 2565: large lower wick rejection)
    if(m_exit_wick_enabled) {
        double bar_high  = High(idx);
        double bar_close = Close(idx);
        double bar_open  = Open(idx);
        double bar_low   = Low(idx);

        if(bar_close < bar_open && (bar_open - bar_low) > (2.0 * (bar_high - bar_close))) {
            price = current_ask;
            return(true);
        }
    }

    return(false);
}

//+------------------------------------------------------------------+
//| CheckReverseLong: Immediate reversal from Short to Long         |
//+------------------------------------------------------------------+
bool SignalMain::CheckReverseLong(double &price, double &sl, double &tp, datetime &expiration) {
    if(!SelectPosition() || m_position.Volume() <= 0)
        return(false);
    if(m_position.PositionType() != POSITION_TYPE_SELL)
        return(false);

    if(m_exit_buy_filter && LongCondition() > 0) {
        price = m_symbol.Ask();
        sl = 0.0;
        tp = 0.0;
        expiration = 0;
        return(true);
    }
    return(false);
}

//+------------------------------------------------------------------+
//| CheckReverseShort: Immediate reversal from Long to Short        |
//+------------------------------------------------------------------+
bool SignalMain::CheckReverseShort(double &price, double &sl, double &tp, datetime &expiration) {
    if(!SelectPosition() || m_position.Volume() <= 0)
        return(false);
    if(m_position.PositionType() != POSITION_TYPE_BUY)
        return(false);

    if(m_exit_short_filter && ShortCondition() > 0) {
        price = m_symbol.Bid();
        sl = 0.0;
        tp = 0.0;
        expiration = 0;
        return(true);
    }
    return(false);
}
