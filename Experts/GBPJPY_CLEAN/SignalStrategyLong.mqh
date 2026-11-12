//+------------------------------------------------------------------+
//|                                           SignalStrategyLong.mqh |
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
#include "SignalCandlestickBody.mqh"
#include "SignalATR.mqh"
#include "SignalATRTrailing.mqh"
#include "SignalZema.mqh"
#include "SignalConsolidation.mqh"
#include "SignalStochRSI.mqh"
#include "SignalSuperTrend.mqh"

//+------------------------------------------------------------------+
//| Class CSignalStrategyLong                                        |
//| Purpose: Entry "Long" strategy (Pine Script lines 2174 / 2183)   |
//|          evaluating choppy_buy (line 2063) and long3 (line 2125) |
//+------------------------------------------------------------------+
class CSignalStrategyLong : public CExpertSignal {
protected:
    CSignalExporter         m_exporter;
    CPositionInfo           m_position;

    //--- Strategy ID for Trade Comment (Pine Script: "Long")
    string                  m_strategy_id;

    //--- Strategy Inputs
    bool                    m_enable_long;              // ln input
    bool                    m_enable_long3;             // choppy_long3 input
    bool                    m_enable_reversal;          // e35 / e38 short-to-long reversal
    int                     m_long3_pip_limit;          // choppy_long3cpi

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
    SignalSuperTrend       *m_sig_st;                  // SuperTrend with close confirmation
    SignalSuperTrend       *m_sig_st2;                 // SuperTrend without close confirmation
    SignalCandlestickBody  *m_sig_csb;                 // Candlestick Body limit
    SignalTema             *m_sig_tema_mom;            // TEMA Momentum / BBMC
    SignalMovingAverage    *m_sig_emaf;                // Fast EMA (EMA 1502)
    SignalMovingAverage    *m_sig_emas;                // Slow EMA (EMA 2502)

public:
                     CSignalStrategyLong(void);
                    ~CSignalStrategyLong(void);

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

    //--- Parameter setters
    void             EnableLong(bool value)              { m_enable_long = value; }
    void             EnableLong3(bool value)             { m_enable_long3 = value; }
    void             EnableReversal(bool value)          { m_enable_reversal = value; }
    void             Long3PipLimit(int value)            { m_long3_pip_limit = value; }

    //--- Filter links
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
    void             SetFilterST2(SignalSuperTrend *filter)        { m_sig_st2 = filter; }
    void             SetFilterCSB(SignalCandlestickBody *filter)   { m_sig_csb = filter; }
    void             SetFilterTemaMom(SignalTema *filter)          { m_sig_tema_mom = filter; }
    void             SetFilterEMAF(SignalMovingAverage *filter)    { m_sig_emaf = filter; }
    void             SetFilterEMAS(SignalMovingAverage *filter)    { m_sig_emas = filter; }

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
    bool             EvaluateChoppyBuy(int idx);
    bool             EvaluateLong3(int idx);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSignalStrategyLong::CSignalStrategyLong(void)
    : m_strategy_id("Long"),
      m_enable_long(true),
      m_enable_long3(true),
      m_enable_reversal(true),
      m_long3_pip_limit(10),
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
      m_sig_st2(NULL),
      m_sig_csb(NULL),
      m_sig_tema_mom(NULL),
      m_sig_emaf(NULL),
      m_sig_emas(NULL) {
    m_used_series = USE_SERIES_OPEN + USE_SERIES_HIGH + USE_SERIES_LOW + USE_SERIES_CLOSE;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSignalStrategyLong::~CSignalStrategyLong(void) {
}

//+------------------------------------------------------------------+
//| ValidationSettings                                               |
//+------------------------------------------------------------------+
bool CSignalStrategyLong::ValidationSettings(void) {
    if(!CExpertSignal::ValidationSettings())
        return(false);
    return(true);
}

//+------------------------------------------------------------------+
//| Position selection helper                                        |
//+------------------------------------------------------------------+
bool CSignalStrategyLong::SelectPosition(void) {
    if((ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE) == ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)
        return(m_position.SelectByMagic(m_symbol.Name(), m_magic));
    return(m_position.Select(m_symbol.Name()));
}

//+------------------------------------------------------------------+
//| Evaluate Pine Script choppy_buy conditions (lines 2063-2065)    |
//+------------------------------------------------------------------+
bool CSignalStrategyLong::EvaluateChoppyBuy(int idx) {
    bool ok = true;
    if(m_sig_lsma != NULL)
        ok = ok && (m_sig_lsma.LongCondition() > 0);
    if(m_sig_tema != NULL)
        ok = ok && (m_sig_tema.LongCondition() > 0);
    if(m_sig_memo != NULL)
        ok = ok && (m_sig_memo.LongCondition() > 0);
    if(m_sig_csoc != NULL)
        ok = ok && (m_sig_csoc.LongCondition() > 0);
    if(m_sig_csoo != NULL)
        ok = ok && (m_sig_csoo.LongCondition() > 0);

    // Candle color: close > open
    ok = ok && (Close(idx) > Open(idx));

    if(m_sig_mema != NULL)
        ok = ok && (m_sig_mema.LongCondition() > 0);
    if(m_sig_cons != NULL)
        ok = ok && (m_sig_cons.LongCondition() > 0);
    if(m_sig_atr != NULL)
        ok = ok && (m_sig_atr.LongCondition() > 0);
    if(m_sig_stochrsi != NULL)
        ok = ok && (m_sig_stochrsi.LongCondition() > 0);
    if(m_sig_st != NULL)
        ok = ok && (m_sig_st.LongCondition() > 0);

    return(ok);
}

//+------------------------------------------------------------------+
//| Evaluate Pine Script long3 conditions (line 2125)                |
//+------------------------------------------------------------------+
bool CSignalStrategyLong::EvaluateLong3(int idx) {
    if(!m_enable_long3)
        return(false);

    // Pip size limit: abs(open - close) < choppy_long3cpi * pips
    double pip_size = GetPoint(m_symbol.Name()) * 10.0;
    if(MathAbs(Open(idx) - Close(idx)) >= (m_long3_pip_limit * pip_size))
        return(false);

    // SuperTrend buy signal
    if(m_sig_st2 != NULL && m_sig_st2.LongCondition() <= 0)
        return(false);

    // Candle must be bullish
    if(Close(idx) <= Open(idx))
        return(false);

    // LSMA / Kernel estimate check: close > LSMA
    if(m_sig_lsma != NULL && !m_sig_lsma.LongTrendCondition(idx))
        return(false);

    // EMA Cloud 2: EMA 1502 > EMA 2502
    if(m_sig_emaf != NULL && m_sig_emas != NULL) {
        if(m_sig_emaf.LongCondition() <= 0)
            return(false);
    }

    // TEMA / BBMC condition: close > TEMA
    if(m_sig_tema != NULL && m_sig_tema.LongCondition() <= 0)
        return(false);

    return(true);
}

//+------------------------------------------------------------------+
//| Long voting condition                                            |
//+------------------------------------------------------------------+
int CSignalStrategyLong::LongCondition(void) {
    if(!m_enable_long)
        return(0);

    // Check position state
    bool has_pos = SelectPosition() && (m_position.Volume() > 0);
    if(has_pos) {
        // If we have a sell position and reversal is enabled, signal can fire
        if(m_position.PositionType() == POSITION_TYPE_BUY)
            return(0); // already long
        if(m_position.PositionType() == POSITION_TYPE_SELL && !m_enable_reversal)
            return(0); // sell reversal disabled
    }

    int idx = StartIndex();
    bool buy1 = EvaluateChoppyBuy(idx);
    bool buy3 = EvaluateLong3(idx);

    int result = buy1 || buy3 ? 100 : 0;

    m_exporter.UpdateLong(result);
    ExportConditions();

    return(result);
}

//+------------------------------------------------------------------+
//| Short voting condition (not used in Long strategy)              |
//+------------------------------------------------------------------+
int CSignalStrategyLong::ShortCondition(void) {
    int result = 0;

    m_exporter.UpdateShort(result);
    ExportConditions();

    return(result);
}
