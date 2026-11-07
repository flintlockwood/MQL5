//+------------------------------------------------------------------+
//|                                             SignalCandlestickLimit.mq5 |
//|                                                  Mufraeli Rahman |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Mufraeli Rahman"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Expert/ExpertSignal.mqh>
#include <MovingAverages.mqh>
#include "Helper.mqh"

class SignalCandlestickLimit: public CExpertSignal {
    protected:
        CSignalExporter   m_exporter;

        //--- adjusted parameters
        string            m_cso_symbol;
        int               m_cso_timeframe;
        int               m_cso_idx_long;
        double            m_cso_pct_long;
        int               m_cso_idx_short;
        double            m_cso_pct_short;
        ENUM_APPLIED_PRICE m_cso_target;

    public:
        SignalCandlestickLimit(void);
       ~SignalCandlestickLimit(void);

        //--- export methods
        void              EnableExport(bool enable, bool common_folder = false) { m_exporter.Enable(enable, common_folder); }
        void              ExportFilename(string filename)                       { m_exporter.SetFilename(filename); }
        void              ExportConditions(void) {
            datetime dt = (m_time != NULL && m_time.GetData(0) > 0) ? m_time.GetData(0) : iTime(m_symbol != NULL ? m_symbol.Name() : _Symbol, m_period, 0);
            m_exporter.Export(dt);
        }

        //--- methods of setting adjustable indicator parameters
        void              CsoSymbol(string value)               { m_cso_symbol=value;    }
        void              CsoTimeframe(int value)               { m_cso_timeframe=value; }
        void              CsoIdxLong(int value)                 { m_cso_idx_long=value;  }
        void              CsoPctLong(double value)              { m_cso_pct_long=value;  }
        void              CsoIdxShort(int value)                { m_cso_idx_short=value; }
        void              CsoPctShort(double value)             { m_cso_pct_short=value; }
        void              CsoTarget(ENUM_APPLIED_PRICE value)   { m_cso_target=value;    }
        
        bool              Initialize(string symbol,int period,bool every_tick);
        //--- method of verification of settings
        virtual bool      ValidationSettings(void);
        virtual int       LongCondition(void);
        virtual int       ShortCondition(void);

        //--- Safe Price Accessors preventing EMPTY_VALUE
        double            Open(int ind) const  { double v = (m_open != NULL) ? m_open.GetData(ind) : EMPTY_VALUE; return (v != EMPTY_VALUE && v > 0.0) ? v : SafeOpen(m_symbol != NULL ? m_symbol.Name() : _Symbol, m_period, ind); }
        double            High(int ind) const  { double v = (m_high != NULL) ? m_high.GetData(ind) : EMPTY_VALUE; return (v != EMPTY_VALUE && v > 0.0) ? v : SafeHigh(m_symbol != NULL ? m_symbol.Name() : _Symbol, m_period, ind); }
        double            Low(int ind) const   { double v = (m_low != NULL) ? m_low.GetData(ind) : EMPTY_VALUE; return (v != EMPTY_VALUE && v > 0.0) ? v : SafeLow(m_symbol != NULL ? m_symbol.Name() : _Symbol, m_period, ind); }
        double            Close(int ind) const { double v = (m_close != NULL) ? m_close.GetData(ind) : EMPTY_VALUE; return (v != EMPTY_VALUE && v > 0.0) ? v : SafeClose(m_symbol != NULL ? m_symbol.Name() : _Symbol, m_period, ind); }

        //--- method of creating the indicator and timeseries
        virtual bool      InitIndicators(CIndicators *indicators);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
SignalCandlestickLimit::SignalCandlestickLimit(void) {
    //--- initialization of protected data
    m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
    m_exporter.SetFilename("SignalCandlestickLimit.csv");
    m_cso_symbol="";
    m_cso_timeframe=PERIOD_CURRENT;
    m_cso_idx_long=0;
    m_cso_pct_long=0.0;
    m_cso_idx_short=0;
    m_cso_pct_short=0.0;
    m_cso_target=PRICE_CLOSE;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
SignalCandlestickLimit::~SignalCandlestickLimit(void){
}

bool SignalCandlestickLimit::Initialize(string symbol,int period,bool every_tick) {
    if(m_symbol==NULL) {
        if((m_symbol=new CSymbolInfo)==NULL)
            return(false);
    }
    if(!m_symbol.Name(symbol))
        return(false);
    m_cso_symbol = symbol;
    m_cso_timeframe = period;
    m_period    =period;
    m_every_tick=every_tick;

    CExpertBase::Init(m_symbol, (ENUM_TIMEFRAMES)period, 1);

    return (true);
}

//+------------------------------------------------------------------+
//| Validation settings protected data.                              |
//+------------------------------------------------------------------+
bool SignalCandlestickLimit::ValidationSettings(void) {
    //--- validation settings of additional filters
    if(!CExpertSignal::ValidationSettings())
        return(false);

    //--- ok
    return(true);
}

//+------------------------------------------------------------------+
//| Create indicators.                                               |
//+------------------------------------------------------------------+
bool SignalCandlestickLimit::InitIndicators(CIndicators *indicators) {
    //--- check pointer
    if(indicators==NULL)
        return(false);

    //--- ok
    return(true);
}

//+------------------------------------------------------------------+
//| "Voting" that price will grow.                                   |
//+------------------------------------------------------------------+
int SignalCandlestickLimit::LongCondition(void) {
    int result=0;
    int idx   =StartIndex();
    
    int bars = BarsCustom(m_symbol.Name(), m_period);
    double target[];
    CopyAppliedPrice(m_symbol.Name(), m_period, m_cso_target, 0, bars, target);
    
    ArraySetAsSeries(target, true);
    bool cond = target[idx] < Open(m_cso_idx_long + idx) * (1 + m_cso_pct_long / 100);
    result = cond ? 100 : 0;

    m_exporter.UpdateLong(result);
    ExportConditions();

    //--- return the result
    return(result);
}

//+------------------------------------------------------------------+
//| "Voting" that price will fall.                                   |
//+------------------------------------------------------------------+
int SignalCandlestickLimit::ShortCondition(void) {
    int result=0;
    int idx   =StartIndex();
    
    int bars = BarsCustom(m_symbol.Name(), m_period);
    double target[];
    CopyAppliedPrice(m_symbol.Name(), m_period, m_cso_target, 0, bars, target);
    
    ArraySetAsSeries(target, true);
    bool cond = target[idx] > Open(m_cso_idx_short + idx) * (1 - m_cso_pct_short / 100);
    result = cond ? 100 : 0;

    m_exporter.UpdateShort(result);
    ExportConditions();

    //--- return the result
    return(result);
}
//+------------------------------------------------------------------+
