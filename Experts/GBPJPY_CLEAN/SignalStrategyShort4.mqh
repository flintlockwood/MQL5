//+------------------------------------------------------------------+
//|                                         SignalStrategyShort4.mqh |
//|                                                  Mufraeli Rahman |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Mufraeli Rahman"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Expert/ExpertSignal.mqh>
#include "Helper.mqh"
#include "SignalLinearRegression.mqh"
#include "SignalZema.mqh"
#include "SignalStochRSI.mqh"

//+------------------------------------------------------------------+
//| Class CSignalStrategyShort4                                      |
//| Purpose: Entry "Short" 4 (short33) strategy                      |
//|          (Pine Script lines 2627 - 2642)                         |
//+------------------------------------------------------------------+
class CSignalStrategyShort4 : public CExpertSignal {
protected:
    CSignalExporter         m_exporter;
    CPositionInfo           m_position;

    //--- Strategy ID for Trade Comment (Pine Script line 2642: "Short")
    string                  m_strategy_id;

    //--- Strategy Inputs
    bool                    m_enable_short4;            // choppy_short4
    int                     m_pip_limit;                // pips4

    //--- Attached Filters
    SignalLinearRegression *m_sig_lsma;                 // LSMA
    SignalZema             *m_sig_zema;                 // Zero-lag EMA
    SignalStochRSI         *m_sig_stochrsi;            // Stochastic RSI

public:
                     CSignalStrategyShort4(void);
                    ~CSignalStrategyShort4(void);

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

    void             EnableShort4(bool value)                    { m_enable_short4 = value; }
    void             PipLimit(int value)                         { m_pip_limit = value; }

    void             SetFilterLSMA(SignalLinearRegression *filter) { m_sig_lsma = filter; }
    void             SetFilterZEMA(SignalZema *filter)             { m_sig_zema = filter; }
    void             SetFilterStochRSI(SignalStochRSI *filter)     { m_sig_stochrsi = filter; }

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
CSignalStrategyShort4::CSignalStrategyShort4(void)
    : m_strategy_id("Short"),
      m_enable_short4(true),
      m_pip_limit(15),
      m_sig_lsma(NULL),
      m_sig_zema(NULL),
      m_sig_stochrsi(NULL) {
    m_used_series = USE_SERIES_OPEN + USE_SERIES_HIGH + USE_SERIES_LOW + USE_SERIES_CLOSE;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSignalStrategyShort4::~CSignalStrategyShort4(void) {
}

//+------------------------------------------------------------------+
//| ValidationSettings                                               |
//+------------------------------------------------------------------+
bool CSignalStrategyShort4::ValidationSettings(void) {
    if(!CExpertSignal::ValidationSettings())
        return(false);
    return(true);
}

//+------------------------------------------------------------------+
//| Position selection helper                                        |
//+------------------------------------------------------------------+
bool CSignalStrategyShort4::SelectPosition(void) {
    if((ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE) == ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)
        return(m_position.SelectByMagic(m_symbol.Name(), m_magic));
    return(m_position.Select(m_symbol.Name()));
}

//+------------------------------------------------------------------+
//| Long voting condition                                            |
//+------------------------------------------------------------------+
int CSignalStrategyShort4::LongCondition(void) {
    int result = 0;

    m_exporter.UpdateLong(result);
    ExportConditions();

    return(result);
}

//+------------------------------------------------------------------+
//| Short voting condition                                           |
//+------------------------------------------------------------------+
int CSignalStrategyShort4::ShortCondition(void) {
    int result = 100;

    if(!m_enable_short4)
        result = 0;

    // Pine Script line 2627: requires strategy.position_size == 0
    if(SelectPosition() && m_position.Volume() > 0)
        result = 0;

    int idx = StartIndex();

    // 1. Pip range constraint: abs(open - close) < pips4 * pipSize
    double pip_size = GetPoint(m_symbol.Name()) * 10.0;
    if(MathAbs(Open(idx) - Close(idx)) >= (m_pip_limit * pip_size))
        result = 0;

    // 2. LSMA momentum down
    if(m_sig_lsma != NULL && !m_sig_lsma.ShortMomentumCondition(idx))
        result = 0;

    // 3. LSMA crossunder or breakdown: close < lsma and (open > lsma || close[1] > lsma[1])
    if(m_sig_lsma != NULL && !m_sig_lsma.ShortTrendCondition(idx))
        result = 0;

    // 4. StochRSI sell condition
    if(m_sig_stochrsi != NULL && m_sig_stochrsi.ShortCondition() <= 0)
        result = 0;

    // 5. Zero-Lag EMA condition: open < ZEMA
    if(m_sig_zema != NULL && m_sig_zema.ShortCondition() <= 0)
        result = 0;


    m_exporter.UpdateShort(result);
    ExportConditions();

    return(result);
}
