//+------------------------------------------------------------------+
//|                                          SignalStrategyLong2.mqh |
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
#include "SignalCandlestickLimit.mqh"

//+------------------------------------------------------------------+
//| Class CSignalStrategyLong2                                       |
//| Purpose: Entry "Long2" strategy (Pine Script line 2526)          |
//+------------------------------------------------------------------+
class CSignalStrategyLong2 : public CExpertSignal {
protected:
    CSignalExporter         m_exporter;
    CPositionInfo           m_position;

    //--- Strategy Inputs
    bool                    m_enable_long2;             // choppy_longre
    double                  m_candlestick_pct;          // csp2
    int                     m_entry_sl_pip;             // longrepip

    //--- Attached Filters
    SignalZema             *m_sig_zema;
    SignalSuperTrend       *m_sig_st;
    SignalCandlestickLimit *m_sig_cso;
    SignalMovingAverage    *m_sig_emaf;
    SignalMovingAverage    *m_sig_emas;

public:
                     CSignalStrategyLong2(void);
                    ~CSignalStrategyLong2(void);

    //--- export methods
    void              EnableExport(bool enable, bool common_folder = false) { m_exporter.Enable(enable, common_folder); }
    void              ExportFilename(string filename)                       { m_exporter.SetFilename(filename); }
    void              ExportConditions(void) {
        datetime dt = (m_time != NULL && m_time.GetData(0) > 0) ? m_time.GetData(0) : iTime(m_symbol != NULL ? m_symbol.Name() : _Symbol, m_period, 0);
        m_exporter.Export(dt);
    }

    void             EnableLong2(bool value)                     { m_enable_long2 = value; }
    void             CandlestickPct(double value)                { m_candlestick_pct = value; }
    void             EntrySLPip(int value)                       { m_entry_sl_pip = value; }

    void             SetFilterZEMA(SignalZema *filter)           { m_sig_zema = filter; }
    void             SetFilterST(SignalSuperTrend *filter)       { m_sig_st = filter; }
    void             SetFilterCSO(SignalCandlestickLimit *filter){ m_sig_cso = filter; }
    void             SetFilterEMAF(SignalMovingAverage *filter)  { m_sig_emaf = filter; }
    void             SetFilterEMAS(SignalMovingAverage *filter)  { m_sig_emas = filter; }

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
CSignalStrategyLong2::CSignalStrategyLong2(void)
    : m_enable_long2(true),
      m_candlestick_pct(0.25),
      m_entry_sl_pip(50),
      m_sig_zema(NULL),
      m_sig_st(NULL),
      m_sig_cso(NULL),
      m_sig_emaf(NULL),
      m_sig_emas(NULL) {
    m_used_series = USE_SERIES_OPEN + USE_SERIES_HIGH + USE_SERIES_LOW + USE_SERIES_CLOSE;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSignalStrategyLong2::~CSignalStrategyLong2(void) {
}

//+------------------------------------------------------------------+
//| ValidationSettings                                               |
//+------------------------------------------------------------------+
bool CSignalStrategyLong2::ValidationSettings(void) {
    if(!CExpertSignal::ValidationSettings())
        return(false);
    return(true);
}

//+------------------------------------------------------------------+
//| Position selection helper                                        |
//+------------------------------------------------------------------+
bool CSignalStrategyLong2::SelectPosition(void) {
    if((ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE) == ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)
        return(m_position.SelectByMagic(m_symbol.Name(), m_magic));
    return(m_position.Select(m_symbol.Name()));
}

//+------------------------------------------------------------------+
//| Long voting condition                                            |
//+------------------------------------------------------------------+
int CSignalStrategyLong2::LongCondition(void) {
    int result = 100;

    if(!m_enable_long2)
        result = 0;

    // Pine Script line 2516: requires strategy.position_size == 0
    if(SelectPosition() && m_position.Volume() > 0)
        result = 0;

    int idx = StartIndex();

    // 1. Bullish candle: close > open
    if(Close(idx) <= Open(idx))
        result = 0;

    // 2. Candlestick limit condition: open < open[1] * (1 + csp2)
    if(Open(idx) >= Open(idx + 1) * (1.0 + m_candlestick_pct / 100.0))
        result = 0;

    // 3. SuperTrend buy
    if(m_sig_st != NULL && m_sig_st.LongCondition() <= 0)
        result = 0;

    // 4. Zero-Lag EMA condition & momentum
    if(m_sig_zema != NULL && m_sig_zema.LongCondition() <= 0)
        result = 0;

    // 5. EMA Cloud 1 up condition (EMA 150 > EMA 250)
    if(m_sig_emaf != NULL && m_sig_emas != NULL) {
        if(m_sig_emaf.LongCondition() <= 0)
            result = 0;
    }

    m_exporter.UpdateLong(result);
    ExportConditions();

    return(result);
}

//+------------------------------------------------------------------+
//| Short voting condition                                           |
//+------------------------------------------------------------------+
int CSignalStrategyLong2::ShortCondition(void) {
    int result = 0;

    m_exporter.UpdateShort(result);
    ExportConditions();

    return(result);
}
