//+------------------------------------------------------------------+
//|                                             SignalTema.mq5 |
//|                                                  Mufraeli Rahman |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Mufraeli Rahman"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Expert/ExpertSignal.mqh>
#include <MovingAverages.mqh>
#include "Helper.mqh"
#include "IndicatorTema.mqh"

class SignalTema: public CExpertSignal {
    protected:
        CSignalExporter   m_exporter;

        CiTema           *m_tema_indicator;

        //--- adjusted parameters
        int               m_tema_period;
        ENUM_APPLIED_PRICE m_tema_source;
        bool              m_enable_tema_momentum;

    public:
        SignalTema(void);
       ~SignalTema(void);

        //--- export methods
        void              EnableExport(bool enable, bool common_folder = false) { m_exporter.Enable(enable, common_folder); }
        void              ExportFilename(string filename)                       { m_exporter.SetFilename(filename); }
        void              ExportConditions(void) {
            datetime dt = (m_time != NULL && m_time.GetData(0) > 0) ? m_time.GetData(0) : iTime(m_symbol != NULL ? m_symbol.Name() : _Symbol, m_period, 0);
            m_exporter.Export(dt);
        }

        //--- methods of setting adjustable indicator parameters
        void              TemaSymbol(string value)             { m_tema_indicator.Symbol(value); }
        void              TemaTimeframe(int value)             { m_tema_indicator.Period(value); }
        void              TemaSource(ENUM_APPLIED_PRICE value) { m_tema_source=value; m_tema_indicator.TemaSource(value); }
        void              TemaPeriod(int value)                { m_tema_period=value; m_tema_indicator.TemaPeriod(value); }
        void              TemaEnableMomentum(bool value)       { m_enable_tema_momentum=value; }
        
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
        virtual bool      LongTrendCondition(int idx);
        virtual bool      ShortTrendCondition(int idx);
        virtual bool      LongMomentumCondition(int idx);
        virtual bool      ShortMomentumCondition(int idx);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
SignalTema::SignalTema(void) {
    //--- initialization of protected data
    m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
    m_tema_period=72;
    m_tema_source=PRICE_CLOSE;
    m_enable_tema_momentum=false;

    m_tema_indicator = new CiTema();
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
SignalTema::~SignalTema(void){
    delete m_tema_indicator;
}

bool SignalTema::Initialize(string symbol,int period,bool every_tick) {
    if(m_symbol==NULL) {
        if((m_symbol=new CSymbolInfo)==NULL)
            return(false);
    }
    if(!m_symbol.Name(symbol))
        return(false);
    m_period    =period;
    m_every_tick=every_tick;
    
    m_tema_indicator.Initialize(symbol, period);

    CExpertBase::Init(m_symbol, (ENUM_TIMEFRAMES)period, 1);

    return (true);
}

//+------------------------------------------------------------------+
//| Validation settings protected data.                              |
//+------------------------------------------------------------------+
bool SignalTema::ValidationSettings(void) {
    //--- validation settings of additional filters
    if(!CExpertSignal::ValidationSettings())
        return(false);
    if(m_tema_period<=0) {
        printf(__FUNCTION__+": period TEMA must be greater than 0");
        return(false);
    }
    //--- ok
    return(true);
}

//+------------------------------------------------------------------+
//| Create indicators.                                               |
//+------------------------------------------------------------------+
bool SignalTema::InitIndicators(CIndicators *indicators) {
    if(indicators==NULL)
        return(false);
    if(!CExpertSignal::InitIndicators(indicators))
        return(false);
    indicators.Add(m_tema_indicator);
    return(true);
}

//+------------------------------------------------------------------+
//| "Voting" that price will grow.                                   |
//+------------------------------------------------------------------+
int SignalTema::LongCondition(void) {
    int result=0;
    int idx   =StartIndex();

    bool cond = Close(idx) > m_tema_indicator.Tema(idx);
    if (m_enable_tema_momentum) {
        cond = cond && m_tema_indicator.Tema(idx) > m_tema_indicator.Tema(idx+1);
    }
    result = cond ? 100 : 0;

    m_exporter.UpdateLong(result);
    ExportConditions();

    //--- return the result
    return(cond ? 100 : 0);
}

//+------------------------------------------------------------------+
//| "Voting" that price will fall.                                   |
//+------------------------------------------------------------------+
int SignalTema::ShortCondition(void) {
    int result=0;
    int idx   =StartIndex();
    
    bool cond = Close(idx) < m_tema_indicator.Tema(idx);
    if (m_enable_tema_momentum) {
        cond = cond && m_tema_indicator.Tema(idx) < m_tema_indicator.Tema(idx+1);
    }
    result = cond ? 100 : 0;

    m_exporter.UpdateShort(result);
    
    //--- return the result
    return(result);
}
//+------------------------------------------------------------------+

bool SignalTema::LongTrendCondition(int idx) {
    int startIdx   =StartIndex();
    return false; // Close(startIdx + idx) > m_tema_indicator.LinReg(startIdx + idx);
}

bool SignalTema::ShortTrendCondition(int idx) {
    int startIdx   =StartIndex();
    return false; //Close(startIdx + idx) < m_lsma_indicator.LinReg(startIdx + idx);
}

bool SignalTema::LongMomentumCondition(int idx) {
    int startIdx   =StartIndex();
    return false; //m_lsma_indicator.LinReg(startIdx + idx) > m_lsma_indicator.LinReg(startIdx + idx + 1);
}

bool SignalTema::ShortMomentumCondition(int idx) {
    int startIdx   =StartIndex();
    return false; //m_lsma_indicator.LinReg(startIdx + idx) < m_lsma_indicator.LinReg(startIdx + idx + 1);
}
