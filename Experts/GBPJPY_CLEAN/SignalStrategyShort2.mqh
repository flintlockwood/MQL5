//+------------------------------------------------------------------+
//|                                         SignalStrategyShort2.mqh |
//|                                                  Mufraeli Rahman |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Mufraeli Rahman"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Expert/ExpertSignal.mqh>
#include "Helper.mqh"
#include "SignalLinearRegression.mqh"
#include "SignalTema.mqh"
#include "SignalZema.mqh"
#include "SignalSuperTrend.mqh"
#include "SignalMovingAverage.mqh"

//+------------------------------------------------------------------+
//| Class CSignalStrategyShort2                                      |
//| Purpose: Entry "Short2" strategy (Pine Script line 2626)         |
//+------------------------------------------------------------------+
class CSignalStrategyShort2 : public CExpertSignal {
protected:
    CSignalExporter         m_exporter;
    CPositionInfo           m_position;

    //--- Strategy ID for Trade Comment (Pine Script: "Short2")
    string                  m_strategy_id;

    //--- Strategy Inputs
    bool                    m_enable_short2;            // choppy_short2
    double                  m_candlestick_pct;          // csps2

    //--- Attached Filters
    SignalLinearRegression *m_sig_lsma;                 // Kernel Estimate / LSMA
    SignalTema             *m_sig_tema;                 // BBMC / TEMA
    SignalZema             *m_sig_zema;                 // Zero-lag EMA
    SignalSuperTrend       *m_sig_st;                   // SuperTrend
    SignalMovingAverage    *m_sig_emaf;                 // Fast EMA (EMA 1502)
    SignalMovingAverage    *m_sig_emas;                 // Slow EMA (EMA 2502)

public:
                     CSignalStrategyShort2(void);
                    ~CSignalStrategyShort2(void);

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

    void             EnableShort2(bool value)                    { m_enable_short2 = value; }
    void             CandlestickPct(double value)                { m_candlestick_pct = value; }

    void             SetFilterLSMA(SignalLinearRegression *filter) { m_sig_lsma = filter; }
    void             SetFilterTEMA(SignalTema *filter)             { m_sig_tema = filter; }
    void             SetFilterZEMA(SignalZema *filter)             { m_sig_zema = filter; }
    void             SetFilterST(SignalSuperTrend *filter)         { m_sig_st = filter; }
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
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSignalStrategyShort2::CSignalStrategyShort2(void)
    : m_strategy_id("Short2"),
      m_enable_short2(true),
      m_candlestick_pct(0.325),
      m_sig_lsma(NULL),
      m_sig_tema(NULL),
      m_sig_zema(NULL),
      m_sig_st(NULL),
      m_sig_emaf(NULL),
      m_sig_emas(NULL) {
    m_used_series = USE_SERIES_OPEN + USE_SERIES_HIGH + USE_SERIES_LOW + USE_SERIES_CLOSE;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSignalStrategyShort2::~CSignalStrategyShort2(void) {
}

//+------------------------------------------------------------------+
//| ValidationSettings                                               |
//+------------------------------------------------------------------+
bool CSignalStrategyShort2::ValidationSettings(void) {
    if(!CExpertSignal::ValidationSettings())
        return(false);
    return(true);
}

//+------------------------------------------------------------------+
//| Position selection helper                                        |
//+------------------------------------------------------------------+
bool CSignalStrategyShort2::SelectPosition(void) {
    if((ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE) == ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)
        return(m_position.SelectByMagic(m_symbol.Name(), m_magic));
    return(m_position.Select(m_symbol.Name()));
}

//+------------------------------------------------------------------+
//| Long voting condition                                            |
//+------------------------------------------------------------------+
int CSignalStrategyShort2::LongCondition(void) {
    int result = 0;

    m_exporter.UpdateLong(result);
    ExportConditions();

    return(result);
}

//+------------------------------------------------------------------+
//| Short voting condition                                           |
//+------------------------------------------------------------------+
int CSignalStrategyShort2::ShortCondition(void) {
    int result = 100;

    if(!m_enable_short2)
        result = 0;

    // Pine Script line 2612: requires strategy.position_size == 0
    if(SelectPosition() && m_position.Volume() > 0)
        result = 0;

    int idx = StartIndex();

    // 1. Bearish candle: close < open
    if(Close(idx) >= Open(idx))
        result = 0;

    // 2. Candlestick limit condition: open > open[1] * (1 - csps2)
    if(Open(idx) <= Open(idx + 1) * (1.0 - m_candlestick_pct / 100.0))
        result = 0;

    // 3. SuperTrend sell
    if(m_sig_st != NULL && m_sig_st.ShortCondition() <= 0)
        result = 0;

    // 4. Zero-Lag EMA condition
    if(m_sig_zema != NULL && m_sig_zema.ShortCondition() <= 0)
        result = 0;

    // 5. TEMA condition: open < TEMA and close < TEMA
    if(m_sig_tema != NULL && m_sig_tema.ShortCondition() <= 0)
        result = 0;

    // 6. LSMA / Kernel estimate: close < LSMA
    if(m_sig_lsma != NULL && !m_sig_lsma.ShortTrendCondition(idx))
        result = 0;

    // 7. EMA Cloud 2 down: EMA 1502 < EMA 2502
    if(m_sig_emaf != NULL && m_sig_emas != NULL) {
        if(m_sig_emaf.ShortCondition() <= 0)
            result = 0;
    }

    m_exporter.UpdateShort(result);
    ExportConditions();

    return(result);
}
