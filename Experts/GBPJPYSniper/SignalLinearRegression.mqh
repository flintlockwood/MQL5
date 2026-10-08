//+------------------------------------------------------------------+
//|                                             SignalLinearRegresssion.mq5 |
//|                                                  Mufraeli Rahman |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Mufraeli Rahman"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Expert/ExpertSignal.mqh>
#include <MovingAverages.mqh>
#include "Helper.mqh"
#include "IndicatorLinearRegression.mqh"

class SignalLinearRegression: public CExpertSignal {
    protected:
        CiLinearRegression m_lr_indicator;

        //--- adjusted parameters
        string            m_sig_symbol;
        int               m_sig_timeframe;
        ENUM_APPLIED_PRICE m_lsma_source;
        int               m_lsma_period;
        int               m_lsma_offset;
        double            m_lsma_pip_long;
        double            m_lsma_pip_short;

    public:
        SignalLinearRegression(void);
        ~SignalLinearRegression(void);

        //--- methods of setting adjustable indicator parameters
        void              IndicatorSymbol(string value)        { m_sig_symbol=value;    }
        void              IndicatorTimeframe(int value)        { m_sig_timeframe=value; }
        void              LrSource(ENUM_APPLIED_PRICE value)   { m_lsma_source=value;     }
        void              LrPeriod(int value)                  { m_lsma_period=value;     }
        void              LrOffset(int value)                  { m_lsma_offset=value;     }
        void              LrPipLong(double value)              { m_lsma_pip_long=value;   }
        void              LrPipShort(double value)             { m_lsma_pip_short=value;  }
        
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
SignalLinearRegression::SignalLinearRegression(void) : m_lsma_source(PRICE_CLOSE),
                             m_lsma_period(18),
                             m_lsma_offset(5) {
    //--- initialization of protected data
    m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
SignalLinearRegression::~SignalLinearRegression(void){
}

//+------------------------------------------------------------------+
//| Validation settings protected data.                              |
//+------------------------------------------------------------------+
bool SignalLinearRegression::ValidationSettings(void) {
    //--- validation settings of additional filters
    if(!CExpertSignal::ValidationSettings())
        return(false);
    //--- initial data checks
    if(m_lsma_period<=0) {
        printf(__FUNCTION__+": period MA must be greater than 0");
        return(false);
    }
    //--- ok
    return(true);
}

//+------------------------------------------------------------------+
//| "Voting" that price will grow.                                   |
//+------------------------------------------------------------------+
int SignalLinearRegression::LongCondition(void) {
    int result=0;
    int idx   =StartIndex();

    bool cond = Open(idx) < m_lr_indicator.LinReg(idx) + m_lsma_pip_long * GetPoint(m_sig_symbol) * 10;

    //--- return the result
    return(cond ? 100 : 0);
}

//+------------------------------------------------------------------+
//| "Voting" that price will fall.                                   |
//+------------------------------------------------------------------+
int SignalLinearRegression::ShortCondition(void) {
    int result=0;
    int idx   =StartIndex();
    
    bool cond = Close(idx) > m_lr_indicator.LinReg(idx) - m_lsma_pip_short * GetPoint(m_sig_symbol) * 10;
    
    //--- return the result
    return(cond ? 100 : 0);
}
//+------------------------------------------------------------------+

bool SignalLinearRegression::LongTrendCondition(int idx) {
    int startIdx   =StartIndex();
    return Close(startIdx + idx) > m_lr_indicator.LinReg(startIdx + idx);
}

bool SignalLinearRegression::ShortTrendCondition(int idx) {
    int startIdx   =StartIndex();
    return Close(startIdx + idx) < m_lr_indicator.LinReg(startIdx + idx);
}

bool SignalLinearRegression::LongMomentumCondition(int idx) {
    int startIdx   =StartIndex();
    return m_lr_indicator.LinReg(startIdx + idx) > m_lr_indicator.LinReg(startIdx + idx + 1);
}

bool SignalLinearRegression::ShortMomentumCondition(int idx) {
    int startIdx   =StartIndex();
    return m_lr_indicator.LinReg(startIdx + idx) < m_lr_indicator.LinReg(startIdx + idx + 1);
}
