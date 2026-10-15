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
        CiTema            m_tema_indicator;

        //--- adjusted parameters
        ENUM_APPLIED_PRICE m_tema_source;
        int               m_tema_period;
        bool              m_enable_tema_momentum;

    public:
        SignalTema(void);
        ~SignalTema(void);

        //--- methods of setting adjustable indicator parameters
        void              TemaSource(ENUM_APPLIED_PRICE value) { m_tema_source=value;   }
        void              TemaPeriod(int value)                { m_tema_period=value;   }
        void              TemaEnableMomentum(bool value)       { m_enable_tema_momentum=value; }
        
        bool              Initialize(string symbol,int period,bool every_tick);
        //--- method of verification of settings
        virtual bool      ValidationSettings(void);
        //--- methods of checking if the market models are formed
        virtual int       LongCondition(void);
        virtual int       ShortCondition(void);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
SignalTema::SignalTema(void) : m_tema_source(PRICE_CLOSE),
                             m_tema_period(18) {
    //--- initialization of protected data
    m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;

    m_tema_indicator = new CiTema();
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
SignalTema::~SignalTema(void){
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
    
    m_tema_indicator.Create(m_symbol.Name(), m_period);

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
    //--- initial data checks
    if(m_tema_period<=0) {
        printf(__FUNCTION__+": period MA must be greater than 0");
        return(false);
    }
    //--- ok
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
    
    //--- return the result
    return(cond ? 100 : 0);
}
//+------------------------------------------------------------------+
