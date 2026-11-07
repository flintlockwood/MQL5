//+------------------------------------------------------------------+
//|                                             SignalZema.mq5 |
//|                                                  Mufraeli Rahman |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Mufraeli Rahman"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Expert/ExpertSignal.mqh>
#include <MovingAverages.mqh>
#include "Helper.mqh"
#include "IndicatorZema.mqh"

class SignalZema: public CExpertSignal {
    protected:
        CSignalExporter   m_exporter;
        CiZema           *m_zema_indicator;

        //--- adjusted parameters
        int               m_zema_period_long;
        int               m_zema_period_short;
        bool              m_enable_zema_momentum;
        string            m_zema_momentum_cond_long;
        string            m_zema_momentum_cond_short;

    public:
        SignalZema(void);
       ~SignalZema(void);

        //--- export methods
        void              EnableExport(bool enable, bool common_folder = false) { m_exporter.Enable(enable, common_folder); }
        void              ExportFilename(string filename)                       { m_exporter.SetFilename(filename); }
        void              ExportConditions(void) {
            datetime dt = (m_time != NULL && m_time.GetData(0) > 0) ? m_time.GetData(0) : iTime(m_symbol != NULL ? m_symbol.Name() : _Symbol, m_period, 0);
            m_exporter.Export(dt);
        }

        //--- methods of setting adjustable indicator parameters
        void              ZemaSymbol(string value)             { m_zema_indicator.Symbol(value); }
        void              ZemaTimeframe(int value)             { m_zema_indicator.Period(value); }
        void              ZemaPeriodLong(int value)            { m_zema_period_long=value; m_zema_indicator.ZemaPeriodLong(value); }
        void              ZemaPeriodShort(int value)           { m_zema_period_short=value; m_zema_indicator.ZemaPeriodShort(value); }
        void              EnableZemaMomentum(bool value)       { m_enable_zema_momentum=value;   }
        void              ZemaMomentumCondLong(string value)   { m_zema_momentum_cond_long=value;}
        void              ZemaMomentumCondShort(string value)  { m_zema_momentum_cond_short=value;}

        bool              Initialize(string symbol,int period,bool every_tick);
        //--- method of verification of settings
        virtual bool      ValidationSettings(void);
        //--- method of creating the indicator and timeseries
        virtual bool      InitIndicators(CIndicators *indicators);
        virtual int       LongCondition(void);
        virtual int       ShortCondition(void);

        //--- Safe Price Accessors preventing EMPTY_VALUE
        double            Open(int ind) const  { double v = (m_open != NULL) ? m_open.GetData(ind) : EMPTY_VALUE; return (v != EMPTY_VALUE && v > 0.0) ? v : SafeOpen(m_symbol != NULL ? m_symbol.Name() : _Symbol, m_period, ind); }
        double            High(int ind) const  { double v = (m_high != NULL) ? m_high.GetData(ind) : EMPTY_VALUE; return (v != EMPTY_VALUE && v > 0.0) ? v : SafeHigh(m_symbol != NULL ? m_symbol.Name() : _Symbol, m_period, ind); }
        double            Low(int ind) const   { double v = (m_low != NULL) ? m_low.GetData(ind) : EMPTY_VALUE; return (v != EMPTY_VALUE && v > 0.0) ? v : SafeLow(m_symbol != NULL ? m_symbol.Name() : _Symbol, m_period, ind); }
        double            Close(int ind) const { double v = (m_close != NULL) ? m_close.GetData(ind) : EMPTY_VALUE; return (v != EMPTY_VALUE && v > 0.0) ? v : SafeClose(m_symbol != NULL ? m_symbol.Name() : _Symbol, m_period, ind); }
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
SignalZema::SignalZema(void) {
    //--- initialization of protected data
    m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
    m_zema_period_long=73;
    m_zema_period_short=52;
    m_enable_zema_momentum=false;
    m_zema_momentum_cond_long="";
    m_zema_momentum_cond_short="";

    m_zema_indicator = new CiZema();
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
SignalZema::~SignalZema(void){
    delete m_zema_indicator;
}

bool SignalZema::Initialize(string symbol,int period,bool every_tick) {
    if(m_symbol==NULL) {
        if((m_symbol=new CSymbolInfo)==NULL)
            return(false);
    }
    if(!m_symbol.Name(symbol))
        return(false);
    m_period    =period;
    m_every_tick=every_tick;
    
    m_zema_indicator.Initialize(symbol, period);

    CExpertBase::Init(m_symbol, (ENUM_TIMEFRAMES)period, 1);

    return (true);
}

//+------------------------------------------------------------------+
//| Validation settings protected data.                              |
//+------------------------------------------------------------------+
bool SignalZema::ValidationSettings(void) {
    //--- validation settings of additional filters
    if(!CExpertSignal::ValidationSettings())
        return(false);
    //--- initial data checks
    if(m_zema_period_long<=0) {
        printf(__FUNCTION__+": period Zema must be greater than 0");
        return(false);
    }
    //--- ok
    return(true);
}

//+------------------------------------------------------------------+
//| Create indicators.                                               |
//+------------------------------------------------------------------+
bool SignalZema::InitIndicators(CIndicators *indicators) {
    //--- check pointer
    if(indicators==NULL)
        return(false);

    indicators.Add(m_zema_indicator);

    //--- ok
    return(true);
}

//+------------------------------------------------------------------+
//| "Voting" that price will grow.                                   |
//+------------------------------------------------------------------+
int SignalZema::LongCondition(void) {
    int result=0;
    int idx   =StartIndex();
    
    bool cond = Close(idx) > m_zema_indicator.ZemaLong(idx);

    double momentum[];
    m_zema_indicator.GetData(0, 20, 2, momentum);
    bool cond2 = !m_enable_zema_momentum || CheckSeriesCondition(m_zema_momentum_cond_long, momentum);

    result = cond && cond2 ? 100 : 0;

    m_exporter.UpdateLong(result);
    ExportConditions();

    //--- return the result
    return(result);
}

//+------------------------------------------------------------------+
//| "Voting" that price will fall.                                   |
//+------------------------------------------------------------------+
int SignalZema::ShortCondition(void) {
    int result=0;
    int idx   =StartIndex();
    
    bool cond = Close(idx) < m_zema_indicator.ZemaShort(idx);

    double momentum[];
    m_zema_indicator.GetData(0, 20, 3, momentum);
    bool cond2 = !m_enable_zema_momentum || CheckSeriesCondition(m_zema_momentum_cond_short, momentum);

    result = cond && cond2 ? 100 : 0;

    m_exporter.UpdateShort(result);
    ExportConditions();

    //--- return the result
    return(result);
}
//+------------------------------------------------------------------+
