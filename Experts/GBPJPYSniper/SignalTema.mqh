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
        CiTema           *m_tema_indicator;

        //--- adjusted parameters
        bool              m_enable_tema_momentum;

    public:
        SignalTema(void);
       ~SignalTema(void);

        //--- methods of setting adjustable indicator parameters
        void              TemaSymbol(string value)             { m_tema_indicator.Symbol(value); }
        void              TemaTimeframe(int value)             { m_tema_indicator.Period(value); }
        void              TemaSource(ENUM_APPLIED_PRICE value) { m_tema_indicator.TemaSource(value); }
        void              TemaPeriod(int value)                { m_tema_indicator.TemaPeriod(value); }
        void              TemaEnableMomentum(bool value)       { m_enable_tema_momentum=value; }
        
        bool              Initialize(string symbol,int period,bool every_tick);
        //--- method of verification of settings
        virtual bool      ValidationSettings(void);
        //--- methods of checking if the market models are formed
        virtual int       LongCondition(void);
        virtual int       ShortCondition(void);
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
