//+------------------------------------------------------------------+
//|                                             SignalCandlestickBody.mq5 |
//|                                                  Mufraeli Rahman |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Mufraeli Rahman"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Expert/ExpertSignal.mqh>
#include <MovingAverages.mqh>
#include "Helper.mqh"

class SignalCandlestickBody: public CExpertSignal {
    protected:
        CSignalExporter   m_exporter;

        //--- adjusted parameters
        string            m_csb_symbol;
        int               m_csb_timeframe;
        int               m_csb_pip_long;

    public:
        SignalCandlestickBody(void);
       ~SignalCandlestickBody(void);

        //--- export methods
        void              EnableExport(bool enable, bool common_folder = false) { m_exporter.Enable(enable, common_folder); }
        void              ExportFilename(string filename)                       { m_exporter.SetFilename(filename); }
        void              ExportConditions(void) {
            datetime dt = (m_time != NULL && m_time.GetData(0) > 0) ? m_time.GetData(0) : iTime(m_symbol != NULL ? m_symbol.Name() : _Symbol, m_period, 0);
            m_exporter.Export(dt);
        }

        //--- methods of setting adjustable indicator parameters
        void              IndicatorSymbol(string value)         { m_csb_symbol=value;    }
        void              IndicatorTimeframe(int value)         { m_csb_timeframe=value; }
        void              CsbPipLong(int value)                 { m_csb_pip_long=value;  }
        
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
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
SignalCandlestickBody::SignalCandlestickBody(void) {
    //--- initialization of protected data
    m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
    m_exporter.SetFilename("SignalCandlestickBody.csv");
    m_csb_symbol="";
    m_csb_timeframe=PERIOD_CURRENT;
    m_csb_pip_long=10;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
SignalCandlestickBody::~SignalCandlestickBody(void){
}

bool SignalCandlestickBody::Initialize(string symbol,int period,bool every_tick) {
    if(m_symbol==NULL) {
        if((m_symbol=new CSymbolInfo)==NULL)
            return(false);
    }
    if(!m_symbol.Name(symbol))
        return(false);
    m_period    =period;
    m_every_tick=every_tick;
    if(m_csb_symbol=="")
        m_csb_symbol = symbol;
    if(m_csb_timeframe<=0)
        m_csb_timeframe = period;

    CExpertBase::Init(m_symbol, (ENUM_TIMEFRAMES)period, 1);

    return (true);
}

//+------------------------------------------------------------------+
//| Validation settings protected data.                              |
//+------------------------------------------------------------------+
bool SignalCandlestickBody::ValidationSettings(void) {
    //--- validation settings of additional filters
    if(!CExpertSignal::ValidationSettings())
        return(false);
    if(m_csb_pip_long<=0) {
        printf(__FUNCTION__+": pip size must be greater than 0");
        return(false);
    }
    //--- ok
    return(true);
}

//+------------------------------------------------------------------+
//| "Voting" that price will grow.                                   |
//+------------------------------------------------------------------+
int SignalCandlestickBody::LongCondition(void) {
    int result=0;
    int idx   =StartIndex();
        
    bool cond = MathAbs(Close(idx) - Open(idx)) < m_csb_pip_long * GetPoint(m_csb_symbol) * 10;
    result = cond ? 100 : 0;

    m_exporter.UpdateLong(result);
    ExportConditions();

    //--- return the result
    return(result);
}

//+------------------------------------------------------------------+
//| "Voting" that price will fall.                                   |
//+------------------------------------------------------------------+
int SignalCandlestickBody::ShortCondition(void) {
    int result=0;
    int idx   =StartIndex();

    m_exporter.UpdateShort(result);
    ExportConditions();

    //--- return the result
    return(result);
}
//+------------------------------------------------------------------+
