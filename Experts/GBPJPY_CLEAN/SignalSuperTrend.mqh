//+------------------------------------------------------------------+
//|                                             SignalSuperTrend.mq5 |
//|                                                  Mufraeli Rahman |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Mufraeli Rahman"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Expert/ExpertSignal.mqh>
#include "Helper.mqh"
#include "IndicatorSuperTrend.mqh"

class SignalSuperTrend: public CExpertSignal {
    protected:
        CSignalExporter   m_exporter;
        CiSuperTrend     *m_st_indicator;
        
        //--- adjusted signal & indicator parameters
        int               m_st_period;
        double            m_st_multiplier;
        ENUM_MA_METHOD    m_st_ma_method;
        ENUM_APPLIED_PRICE m_st_applied_price;
        bool              m_enable_close;

    public:
        SignalSuperTrend(void);
       ~SignalSuperTrend(void);

        //--- export methods
        void              EnableExport(bool enable, bool common_folder = false) { m_exporter.Enable(enable, common_folder); }
        void              ExportFilename(string filename)                       { m_exporter.SetFilename(filename); }
        void              ExportConditions(void) {
            datetime dt = (m_time != NULL && m_time.GetData(0) > 0) ? m_time.GetData(0) : iTime(m_symbol != NULL ? m_symbol.Name() : _Symbol, m_period, 0);
            m_exporter.Export(dt);
        }

        //--- methods of setting adjustable indicator parameters
        void              SignalSymbol(string value)          { m_st_indicator.Symbol(value);         }
        void              SignalTimeframe(int value)          { m_st_indicator.Timeframe(value); }
        void              PeriodMA(int value)                 { m_st_period=value; m_st_indicator.AtrPeriod(value);          }
        void              Multiplier(double value)            { m_st_multiplier=value; m_st_indicator.AtrMultiplier(value);      }
        void              MaMethod(ENUM_MA_METHOD value)      { m_st_ma_method=value; m_st_indicator.MaMethod(value);       }
        void              Applied(ENUM_APPLIED_PRICE value)   { m_st_applied_price=value; m_st_indicator.Applied(value);   }
        void              EnableClose(bool value)             { m_enable_close=value;       }

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
SignalSuperTrend::SignalSuperTrend(void) {
    //--- initialization of protected data
    m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
    m_st_period=10;
    m_st_multiplier=3.1;
    m_st_ma_method=MODE_SMMA;
    m_st_applied_price=PRICE_OPEN;
    m_enable_close=false;

    m_st_indicator = new CiSuperTrend();
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
SignalSuperTrend::~SignalSuperTrend(void){
    delete m_st_indicator;
}

bool SignalSuperTrend::Initialize(string symbol,int period,bool every_tick) {
    if(m_symbol==NULL) {
        if((m_symbol=new CSymbolInfo)==NULL)
            return(false);
    }
    if(!m_symbol.Name(symbol))
        return(false);
    m_period    =period;
    m_every_tick=every_tick;
    
    m_st_indicator.Initialize(symbol, period);

    CExpertBase::Init(m_symbol, (ENUM_TIMEFRAMES)period, 1);

    return (true);
}

//+------------------------------------------------------------------+
//| Validation settings protected data.                              |
//+------------------------------------------------------------------+
bool SignalSuperTrend::ValidationSettings(void) {
    //--- validation settings of additional filters
    if(!CExpertSignal::ValidationSettings())
        return(false);
    //--- initial data checks
    if(m_st_period<=0) {
        printf(__FUNCTION__+": period MA must be greater than 0");
        return(false);
    }
    //--- ok
    return(true);
}

//+------------------------------------------------------------------+
//| Create indicators.                                               |
//+------------------------------------------------------------------+
bool SignalSuperTrend::InitIndicators(CIndicators *indicators) {
    //--- check pointer
    if(indicators==NULL)
        return(false);
    //--- initialization of indicators and timeseries of additional filters
    if(!CExpertSignal::InitIndicators(indicators))
        return(false);
    
    indicators.Add(m_st_indicator);
    
    //--- ok
    return(true);
}

//+------------------------------------------------------------------+
//| "Voting" that price will grow.                                   |
//+------------------------------------------------------------------+
int SignalSuperTrend::LongCondition(void) {
    int result=0;
    int idx   =StartIndex();
    bool cond = m_st_indicator.Trend(idx) == 1;
    if (m_enable_close) {
        cond = cond && Close(idx) > Close(idx+1);
    }

    result = cond == 1 ? 100 : 0;

    m_exporter.UpdateLong(result);
    ExportConditions();

    //--- return the result
    return(result);
}

//+------------------------------------------------------------------+
//| "Voting" that price will fall.                                   |
//+------------------------------------------------------------------+
int SignalSuperTrend::ShortCondition(void) {
    int result=0;
    int idx   =StartIndex();
    bool cond = m_st_indicator.Trend(idx) == -1;
    if (m_enable_close) {
        cond = cond && Close(idx) > Close(idx+1);
    }

    result = cond ? 100 : 0;

    m_exporter.UpdateShort(result);
    ExportConditions();
    
    //--- return the result
    return(result);
}
//+------------------------------------------------------------------+
