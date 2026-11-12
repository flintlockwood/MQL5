//+------------------------------------------------------------------+
//|                                          SignalStrategyShort.mqh |
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
#include "SignalMovingAverage.mqh"
#include "SignalCandlestickLimit.mqh"
#include "SignalATR.mqh"
#include "SignalATRTrailing.mqh"
#include "SignalZema.mqh"
#include "SignalConsolidation.mqh"
#include "SignalStochRSI.mqh"
#include "SignalSuperTrend.mqh"

//+------------------------------------------------------------------+
//| Class CSignalStrategyShort                                       |
//| Purpose: Entry "Short" strategy (Pine Script lines 2228 / 2235)  |
//|          evaluating choppy_sell (line 2064)                      |
//+------------------------------------------------------------------+
class CSignalStrategyShort : public CExpertSignal {
protected:
    CSignalExporter         m_exporter;
    CPositionInfo           m_position;

    //--- Strategy ID for Trade Comment (Pine Script: "Short")
    string                  m_strategy_id;

    //--- Strategy Inputs
    bool                    m_enable_short;             // sn input
    bool                    m_enable_reversal;          // e34 / e38 long-to-short reversal

    //--- Attached Sub-filters & Indicators
    SignalLinearRegression *m_sig_lsma;
    SignalTema             *m_sig_tema;
    SignalMovingAverage    *m_sig_memo;                // 2H EMA Open
    SignalCandlestickLimit *m_sig_csoc;                // CSO Close
    SignalCandlestickLimit *m_sig_csoo;                // CSO Open
    SignalMovingAverage    *m_sig_mema;                // 20M RMA Close
    SignalConsolidation    *m_sig_cons;                // Consolidation
    SignalATR              *m_sig_atr;                 // ATR Direction
    SignalStochRSI         *m_sig_stochrsi;            // Stochastic RSI
    SignalSuperTrend       *m_sig_st;                  // SuperTrend
    SignalZema             *m_sig_zema;                // Zero-lag EMA

public:
                     CSignalStrategyShort(void);
                    ~CSignalStrategyShort(void);

    //--- export methods
    void              EnableExport(bool enable, bool common_folder = false) { m_exporter.Enable(enable, common_folder); }
    void              ExportFilename(string filename)                       { m_exporter.SetFilename(filename); }
    void              ExportConditions(void) {
        datetime dt = (m_time != NULL && m_time.GetData(0) > 0) ? m_time.GetData(0) : iTime(m_symbol != NULL ? m_symbol.Name() : _Symbol, m_period, 0);
        m_exporter.Export(dt);
    }

    //--- Strategy ID
    string           StrategyId(void) const                      { return m_strategy_id; }
    void             StrategyId(string id)                       { m_strategy_id = id; }

    void             EnableShort(bool value)                     { m_enable_short = value; }
    void             EnableReversal(bool value)                  { m_enable_reversal = value; }

    void             SetFilterLSMA(SignalLinearRegression *filter) { m_sig_lsma = filter; }
    void             SetFilterTEMA(SignalTema *filter)             { m_sig_tema = filter; }
    void             SetFilterMEMO(SignalMovingAverage *filter)    { m_sig_memo = filter; }
    void             SetFilterCSOC(SignalCandlestickLimit *filter) { m_sig_csoc = filter; }
    void             SetFilterCSOO(SignalCandlestickLimit *filter) { m_sig_csoo = filter; }
    void             SetFilterMEMA(SignalMovingAverage *filter)    { m_sig_mema = filter; }
    void             SetFilterCons(SignalConsolidation *filter)    { m_sig_cons = filter; }
    void             SetFilterATR(SignalATR *filter)               { m_sig_atr = filter; }
    void             SetFilterStochRSI(SignalStochRSI *filter)     { m_sig_stochrsi = filter; }
    void             SetFilterST(SignalSuperTrend *filter)         { m_sig_st = filter; }
    void             SetFilterZEMA(SignalZema *filter)             { m_sig_zema = filter; }

    virtual bool     ValidationSettings(void);
    virtual int      LongCondition(void);
    virtual int      ShortCondition(void);

    //--- Safe Price Accessors preventing EMPTY_VALUE
    double           Open(int ind) const  { double v = (m_open != NULL) ? m_open.GetData(ind) : EMPTY_VALUE; return (v != EMPTY_VALUE && v > 0.0) ? v : SafeOpen(m_symbol != NULL ? m_symbol.Name() : _Symbol, m_period, ind); }
    double           High(int ind) const  { double v = (m_high != NULL) ? m_high.GetData(ind) : EMPTY_VALUE; return (v != EMPTY_VALUE && v > 0.0) ? v : SafeHigh(m_symbol != NULL ? m_symbol.Name() : _Symbol, m_period, ind); }
    double           Low(int ind) const   { double v = (m_low != NULL) ? m_low.GetData(ind) : EMPTY_VALUE; return (v != EMPTY_VALUE && v > 0.0) ? v : SafeLow(m_symbol != NULL ? m_symbol.Name() : _Symbol, m_period, ind); }
    double           Close(int ind) const { double v = (m_close != NULL) ? m_close.GetData(ind) : EMPTY_VALUE; return (v != EMPTY_VALUE && v > 0.0) ? v : SafeClose(m_symbol != NULL ? m_symbol.Name() : _Symbol, m_period, ind); }

protected:
    bool             SelectPosition(void);
    bool             EvaluateChoppySell(int idx);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSignalStrategyShort::CSignalStrategyShort(void)
    : m_strategy_id("Short"),
      m_enable_short(true),
      m_enable_reversal(true),
      m_sig_lsma(NULL),
      m_sig_tema(NULL),
      m_sig_memo(NULL),
      m_sig_csoc(NULL),
      m_sig_csoo(NULL),
      m_sig_mema(NULL),
      m_sig_cons(NULL),
      m_sig_atr(NULL),
      m_sig_stochrsi(NULL),
      m_sig_st(NULL),
      m_sig_zema(NULL) {
    m_used_series = USE_SERIES_OPEN + USE_SERIES_HIGH + USE_SERIES_LOW + USE_SERIES_CLOSE;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSignalStrategyShort::~CSignalStrategyShort(void) {
}

//+------------------------------------------------------------------+
//| ValidationSettings                                               |
//+------------------------------------------------------------------+
bool CSignalStrategyShort::ValidationSettings(void) {
    if(!CExpertSignal::ValidationSettings())
        return(false);
    return(true);
}

//+------------------------------------------------------------------+
//| Position selection helper                                        |
//+------------------------------------------------------------------+
bool CSignalStrategyShort::SelectPosition(void) {
    if((ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE) == ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)
        return(m_position.SelectByMagic(m_symbol.Name(), m_magic));
    return(m_position.Select(m_symbol.Name()));
}

//+------------------------------------------------------------------+
//| Evaluate Pine Script choppy_sell conditions (line 2064)          |
//+------------------------------------------------------------------+
bool CSignalStrategyShort::EvaluateChoppySell(int idx) {
    bool ok = true;
    if(m_sig_lsma != NULL)
        ok = ok && (m_sig_lsma.ShortCondition() > 0);
    if(m_sig_tema != NULL)
        ok = ok && (m_sig_tema.ShortCondition() > 0);
    if(m_sig_memo != NULL)
        ok = ok && (m_sig_memo.ShortCondition() > 0);
    if(m_sig_csoc != NULL)
        ok = ok && (m_sig_csoc.ShortCondition() > 0);
    if(m_sig_csoo != NULL)
        ok = ok && (m_sig_csoo.ShortCondition() > 0);

    // Candle color: close < open
    ok = ok && (Close(idx) < Open(idx));

    if(m_sig_mema != NULL)
        ok = ok && (m_sig_mema.ShortCondition() > 0);
    if(m_sig_cons != NULL)
        ok = ok && (m_sig_cons.ShortCondition() > 0);
    if(m_sig_atr != NULL)
        ok = ok && (m_sig_atr.ShortCondition() > 0);
    if(m_sig_stochrsi != NULL)
        ok = ok && (m_sig_stochrsi.ShortCondition() > 0);
    if(m_sig_st != NULL)
        ok = ok && (m_sig_st.ShortCondition() > 0);
    if(m_sig_zema != NULL)
        ok = ok && (m_sig_zema.ShortCondition() > 0);

    return(ok);
}

//+------------------------------------------------------------------+
//| Long voting condition                                            |
//+------------------------------------------------------------------+
int CSignalStrategyShort::LongCondition(void) {
    int result = 0;

    m_exporter.UpdateLong(result);
    ExportConditions();

    return(result);
}

//+------------------------------------------------------------------+
//| Short voting condition                                           |
//+------------------------------------------------------------------+
int CSignalStrategyShort::ShortCondition(void) {
    int result = 0;

    if(!m_enable_short)
        result = 0;

    // Check position state
    bool has_pos = SelectPosition() && (m_position.Volume() > 0);
    if(has_pos) {
        // If we already have a sell position, do not re-enter
        if(m_position.PositionType() == POSITION_TYPE_SELL)
            result = 0;
        // If we have a buy position and reversal is disabled, do not fire
        if(m_position.PositionType() == POSITION_TYPE_BUY && !m_enable_reversal)
            result = 0;
    }

    int idx = StartIndex();
    if(EvaluateChoppySell(idx))
        result = 100;

    m_exporter.UpdateShort(result);
    ExportConditions();
    
    return(result);
}
