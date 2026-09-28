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
        //--- adjusted parameters
        string            m_sig_symbol;
        int               m_sig_timeframe;
        ENUM_APPLIED_PRICE m_ma_source;
        int               m_ma_period;
        ENUM_MA_METHOD    m_ma_method;

    public:
        SignalMovingAverage(void);
        ~SignalMovingAverage(void);

        //--- methods of setting adjustable indicator parameters
        void              IndicatorSymbol(string value)        { m_sig_symbol=value;    }
        void              IndicatorTimeframe(int value)        { m_sig_timeframe=value; }
        void              MaSource(ENUM_APPLIED_PRICE value)   { m_ma_source=value;     }
        void              MaPeriod(int value)                  { m_ma_period=value;     }
        void              MaMethod(ENUM_MA_METHOD value)       { m_ma_method=value;     }
        
        //--- method of verification of settings
        virtual bool      ValidationSettings(void);
        //--- method of creating the indicator and timeseries
        virtual bool      InitIndicators(CIndicators *indicators);
        //--- methods of checking if the market models are formed
        virtual int       LongCondition(void);
        virtual int       ShortCondition(void);

    protected:
        //--- method of initialization of the indicator
        bool              InitMA(CIndicators *indicators);
        //--- methods of getting data
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
SignalMovingAverage::SignalMovingAverage(void) : m_ma_source(PRICE_LOW),
                             m_ma_period(60),
                             m_ma_method(MODE_SMMA) {
    //--- initialization of protected data
    m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
SignalMovingAverage::~SignalMovingAverage(void){
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
    //--- initialization of indicators and timeseries of additional filters
    if(!CExpertSignal::InitIndicators(indicators))
        return(false);
    //--- create and initialize MA indicator
    if(!InitMA(indicators))
        return(false);
    //--- ok
    return(true);
}

//+------------------------------------------------------------------+
//| Initialize Super Trend indicators.                                        |
//+------------------------------------------------------------------+
bool SignalMovingAverage::InitMA(CIndicators *indicators) {
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
    
    int bars = BarsCustom(m_sig_symbol, m_sig_timeframe);
    double source[];
    CopyAppliedPrice(m_sig_symbol, m_sig_timeframe, m_ma_source, 0, bars, source);
    double ma[];
    MAOnBuffer(ArraySize(source), 0, 0, m_ma_period, m_ma_method, source, ma);
    
    ArraySetAsSeries(ma, true);
    bool cond = Close(idx) > ma[idx];

    //--- return the result
    return(cond ? 100 : 0);
}

//+------------------------------------------------------------------+
//| "Voting" that price will fall.                                   |
//+------------------------------------------------------------------+
int SignalMovingAverage::ShortCondition(void) {
    int result=0;
    int idx   =StartIndex();
    
    int bars = BarsCustom(m_sig_symbol, m_sig_timeframe);
    double source[];
    CopyAppliedPrice(m_sig_symbol, m_sig_timeframe, m_ma_source, 0, bars, source);
    double ma[];
    MAOnBuffer(ArraySize(source), 0, 0, m_ma_period, m_ma_method, source, ma);
    
    ArraySetAsSeries(ma, true);
    bool cond = Close(idx) < ma[idx];

    //--- return the result
    return(cond ? 100 : 0);
}
//+------------------------------------------------------------------+
