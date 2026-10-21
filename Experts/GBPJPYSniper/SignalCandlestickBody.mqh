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
        //--- adjusted parameters
        string            m_csb_symbol;
        int               m_csb_timeframe;
        int               m_csb_pip_long;

    public:
        SignalCandlestickBody(void);
       ~SignalCandlestickBody(void);

        //--- methods of setting adjustable indicator parameters
        void              IndicatorSymbol(string value)         { m_csb_symbol=value;    }
        void              IndicatorTimeframe(int value)         { m_csb_timeframe=value; }
        void              CsbPipLong(int value)                 { m_csb_pip_long=value;  }
        
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
SignalCandlestickBody::SignalCandlestickBody(void) {
    //--- initialization of protected data
    m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
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

    //--- return the result
    return(cond ? 100 : 0);
}

//+------------------------------------------------------------------+
//| "Voting" that price will fall.                                   |
//+------------------------------------------------------------------+
int SignalCandlestickBody::ShortCondition(void) {
    int result=0;
    int idx   =StartIndex();

    //--- return the result
    return(0);
}
//+------------------------------------------------------------------+
