//+------------------------------------------------------------------+
//|                                             SignalMovingAverage.mq5 |
//|                                                  Mufraeli Rahman |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Mufraeli Rahman"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Expert/ExpertSignal.mqh>
#include <MovingAverages.mqh>
#include "Helper.mqh"

class SignalMovingAverage: public CExpertSignal {
    protected:
        //--- private data
        CSignalExporter   m_exporter;
        double            m_data[];

        //--- adjusted parameters
        string            m_ma_symbol;
        int               m_ma_timeframe;
        ENUM_APPLIED_PRICE m_ma_source;
        int               m_ma_period;
        ENUM_MA_METHOD    m_ma_method;
        ENUM_APPLIED_PRICE m_ma_target;

    public:
        SignalMovingAverage(void);
       ~SignalMovingAverage(void);

        //--- export methods
        void              EnableExport(bool enable, bool common_folder = false) { m_exporter.Enable(enable, common_folder); }
        void              ExportFilename(string filename)                       { m_exporter.SetFilename(filename); }
        void              ExportConditions(void) {
            datetime dt = (m_time != NULL && m_time.GetData(0) > 0) ? m_time.GetData(0) : iTime(m_symbol != NULL ? m_symbol.Name() : _Symbol, m_period, 0);
            m_exporter.Export(dt);
        }

        //--- methods of setting adjustable indicator parameters
        void              MaSymbol(string value)               { m_ma_symbol=value;    }
        void              MaTimeframe(int value)               { m_ma_timeframe=value; }
        void              MaSource(ENUM_APPLIED_PRICE value)   { m_ma_source=value;     }
        void              MaPeriod(int value)                  { m_ma_period=value;     }
        void              MaMethod(ENUM_MA_METHOD value)       { m_ma_method=value;     }
        void              MaTarget(ENUM_APPLIED_PRICE value)   { m_ma_target=value;     }
 
        bool              Initialize(string symbol,int period,bool every_tick);
        //--- method of verification of settings
        virtual bool      ValidationSettings(void);
        //--- methods of checking if the market models are formed
        virtual int       LongCondition(void);
        virtual int       ShortCondition(void);

        //--- method of creating the indicator and timeseries
        virtual bool      InitIndicators(CIndicators *indicators);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
SignalMovingAverage::SignalMovingAverage(void) {
    //--- initialization of protected data
    m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
    m_ma_symbol="";
    m_ma_timeframe=PERIOD_CURRENT;
    m_ma_period=10;
    m_ma_method=MODE_EMA;
    m_ma_source=PRICE_CLOSE;
    m_ma_target=PRICE_OPEN;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
SignalMovingAverage::~SignalMovingAverage(void){
}

bool SignalMovingAverage::Initialize(string symbol,int period,bool every_tick) {
    if(m_symbol==NULL) {
        if((m_symbol=new CSymbolInfo)==NULL)
            return(false);
    }
    if(!m_symbol.Name(symbol))
        return(false);
    m_ma_symbol = symbol;
    m_ma_timeframe = period;
    m_period    =period;
    m_every_tick=every_tick;

    CExpertBase::Init(m_symbol, (ENUM_TIMEFRAMES)period, 1);

    return (true);
}

//+------------------------------------------------------------------+
//| Validation settings protected data.                              |
//+------------------------------------------------------------------+
bool SignalMovingAverage::ValidationSettings(void) {
    //--- validation settings of additional filters
    if(!CExpertSignal::ValidationSettings())
        return(false);
    //--- initial data checks
    if(m_ma_period<=0) {
        printf(__FUNCTION__+": period MA must be greater than 0");
        return(false);
    }
    //--- ok
    return(true);
}

//+------------------------------------------------------------------+
//| Create indicators.                                               |
//+------------------------------------------------------------------+
bool SignalMovingAverage::InitIndicators(CIndicators *indicators) {
    //--- check pointer
    if(indicators==NULL)
        return(false);

    //--- ok
    return(true);
}

//+------------------------------------------------------------------+
//| "Voting" that price will grow.                                   |
//+------------------------------------------------------------------+
int SignalMovingAverage::LongCondition(void) {
    int result=0;
    int idx   =StartIndex();
    
    int bars = BarsCustom(m_symbol.Name(), m_period);
    double source[];
    CopyAppliedPrice(m_symbol.Name(), m_ma_timeframe, m_ma_source, 0, bars, source);
    double ma[];
    MAOnBuffer(ArraySize(source), 0, 0, m_ma_period, m_ma_method, source, ma);
    
    ArraySetAsSeries(ma, true);
    double target_price = GetAppliedPrice(m_symbol.Name(), m_ma_timeframe, m_ma_target, idx);
    bool cond = target_price > ma[idx];
    result = cond ? 100 : 0;

    m_exporter.UpdateLong(result);
    ExportConditions();

    //--- return the result
    return(result);
}

//+------------------------------------------------------------------+
//| "Voting" that price will fall.                                   |
//+------------------------------------------------------------------+
int SignalMovingAverage::ShortCondition(void) {
    int result=0;
    int idx   =StartIndex();
    
    int bars = BarsCustom(m_symbol.Name(), m_ma_timeframe);
    double source[];
    CopyAppliedPrice(m_symbol.Name(), m_ma_timeframe, m_ma_source, 0, bars, source);
    double ma[];
    MAOnBuffer(ArraySize(source), 0, 0, m_ma_period, m_ma_method, source, ma);
    
    ArraySetAsSeries(ma, true);
    double target_price = GetAppliedPrice(m_symbol.Name(), m_ma_timeframe, m_ma_target, idx);
    bool cond = target_price < ma[idx];
    result = cond ? 100 : 0;

    m_exporter.UpdateShort(result);
    ExportConditions();

    //--- return the result
    return(result);
}
//+------------------------------------------------------------------+
