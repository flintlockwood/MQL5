//+------------------------------------------------------------------+
//|                                             SignalLinearRegresssion.mq5 |
//|                                                  Mufraeli Rahman |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Mufraeli Rahman"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Expert/ExpertSignal.mqh>
#include <MovingAverages.mqh>
#include "Helper.mqh"
#include "IndicatorLinearRegression.mqh"

class SignalLinearRegression: public CExpertSignal {
    protected:
        CiLinearRegression *m_lsma_indicator;
        CSignalExporter   m_exporter;

        //--- adjusted parameters
        int               m_lsma_period;
        int               m_lsma_offset;
        ENUM_APPLIED_PRICE m_lsma_source;
        double            m_lsma_pip_long;
        double            m_lsma_pip_short;

    public:
        SignalLinearRegression(void);
        ~SignalLinearRegression(void);

        //--- export methods
        void              EnableExport(bool enable, bool common_folder = false) { m_exporter.Enable(enable, common_folder); }
        void              ExportFilename(string filename)                       { m_exporter.SetFilename(filename); }
        void              ExportConditions(void) {
            datetime dt = (m_time != NULL && m_time.GetData(0) > 0) ? m_time.GetData(0) : iTime(m_symbol != NULL ? m_symbol.Name() : _Symbol, m_period, 0);
            m_exporter.Export(dt);
        }

        //--- methods of setting adjustable indicator parameters
        void              LsmaSymbol(string value)             { m_lsma_indicator.Symbol(value); }
        void              LsmaTimeframe(int value)             { m_lsma_indicator.Period(value); }
        void              LsmaSource(ENUM_APPLIED_PRICE value) { m_lsma_source=value; m_lsma_indicator.LsmaSource(value);}
        void              LsmaPeriod(int value)                { m_lsma_period=value; m_lsma_indicator.LsmaPeriod(value);}
        void              LsmaOffset(int value)                { m_lsma_offset=value; m_lsma_indicator.LsmaOffset(value);}
        void              LsmaPipLong(double value)            { m_lsma_pip_long=value;   }
        void              LsmaPipShort(double value)           { m_lsma_pip_short=value;  }

        bool              Initialize(string symbol,int period,bool every_tick);
        virtual bool      ValidationSettings(void);
        //--- methods of checking if the market models are formed
        virtual int       LongCondition(void);
        virtual int       ShortCondition(void);

        //--- Safe Price Accessors preventing EMPTY_VALUE
        double            Open(int ind) const  { double v = (m_open != NULL) ? m_open.GetData(ind) : EMPTY_VALUE; return (v != EMPTY_VALUE && v > 0.0) ? v : SafeOpen(m_symbol != NULL ? m_symbol.Name() : _Symbol, m_period, ind); }
        double            High(int ind) const  { double v = (m_high != NULL) ? m_high.GetData(ind) : EMPTY_VALUE; return (v != EMPTY_VALUE && v > 0.0) ? v : SafeHigh(m_symbol != NULL ? m_symbol.Name() : _Symbol, m_period, ind); }
        double            Low(int ind) const   { double v = (m_low != NULL) ? m_low.GetData(ind) : EMPTY_VALUE; return (v != EMPTY_VALUE && v > 0.0) ? v : SafeLow(m_symbol != NULL ? m_symbol.Name() : _Symbol, m_period, ind); }
        double            Close(int ind) const { double v = (m_close != NULL) ? m_close.GetData(ind) : EMPTY_VALUE; return (v != EMPTY_VALUE && v > 0.0) ? v : SafeClose(m_symbol != NULL ? m_symbol.Name() : _Symbol, m_period, ind); }
        virtual bool      LongTrendCondition(int idx);
        virtual bool      ShortTrendCondition(int idx);
        virtual bool      LongMomentumCondition(int idx);
        virtual bool      ShortMomentumCondition(int idx);

        bool              InitIndicators(CIndicators *indicators);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
SignalLinearRegression::SignalLinearRegression(void) {
    //--- initialization of protected data
    m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
    m_lsma_period=18;
    m_lsma_offset=5;
    m_lsma_source=PRICE_CLOSE;
    m_lsma_pip_long=10.0;
    m_lsma_pip_short=10.0;

    m_exporter.SetFilename("SignalLinearRegression.csv");
    m_lsma_indicator = new CiLinearRegression();
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
SignalLinearRegression::~SignalLinearRegression(void){
    delete m_lsma_indicator;
}

bool SignalLinearRegression::Initialize(string symbol,int period,bool every_tick) {
    if(m_symbol==NULL) {
        if((m_symbol=new CSymbolInfo)==NULL)
            return(false);
    }
    if(!m_symbol.Name(symbol))
        return(false);
    m_period    =period;
    m_every_tick=every_tick;
    
    m_lsma_indicator.Initialize(symbol, period);

    CExpertBase::Init(m_symbol, (ENUM_TIMEFRAMES)period, 1);

    return (true);
}

//+------------------------------------------------------------------+
//| Validation settings protected data.                              |
//+------------------------------------------------------------------+
bool SignalLinearRegression::ValidationSettings(void) {
    //--- validation settings of additional filters
    if(!CExpertSignal::ValidationSettings())
        return(false);
    if(m_lsma_period<=0) {
        printf(__FUNCTION__+": period LSMA must be greater than 0");
        return(false);
    }
    //--- ok
    return(true);
}

bool SignalLinearRegression::InitIndicators(CIndicators *indicators) {
    //--- check pointer
    if(indicators==NULL)
        return(false);

    indicators.Add(m_lsma_indicator);

    //--- ok
    return(true);
}

//+------------------------------------------------------------------+
//| "Voting" that price will grow.                                   |
//+------------------------------------------------------------------+
int SignalLinearRegression::LongCondition(void) {
    int result=0;
    int idx   =StartIndex();

    bool cond = Open(idx) < m_lsma_indicator.LinReg(idx) + m_lsma_pip_long * GetPoint(m_symbol.Name()) * 10;

    result = cond ? 100 : 0;
    m_exporter.UpdateLong(result);
    ExportConditions();

    //--- return the result
    return(result);
}

//+------------------------------------------------------------------+
//| "Voting" that price will fall.                                   |
//+------------------------------------------------------------------+
int SignalLinearRegression::ShortCondition(void) {
    int result=0;
    int idx   =StartIndex();
    
    bool cond = Close(idx) > m_lsma_indicator.LinReg(idx) - m_lsma_pip_short * GetPoint(m_symbol.Name()) * 10;
    
    result = cond ? 100 : 0;
    m_exporter.UpdateShort(result);
    ExportConditions();

    //--- return the result
    return(result);
}
//+------------------------------------------------------------------+

bool SignalLinearRegression::LongTrendCondition(int idx) {
    int startIdx   =StartIndex();
    return Close(startIdx + idx) > m_lsma_indicator.LinReg(startIdx + idx);
}

bool SignalLinearRegression::ShortTrendCondition(int idx) {
    int startIdx   =StartIndex();
    return Close(startIdx + idx) < m_lsma_indicator.LinReg(startIdx + idx);
}

bool SignalLinearRegression::LongMomentumCondition(int idx) {
    int startIdx   =StartIndex();
    return m_lsma_indicator.LinReg(startIdx + idx) > m_lsma_indicator.LinReg(startIdx + idx + 1);
}

bool SignalLinearRegression::ShortMomentumCondition(int idx) {
    int startIdx   =StartIndex();
    return m_lsma_indicator.LinReg(startIdx + idx) < m_lsma_indicator.LinReg(startIdx + idx + 1);
}
