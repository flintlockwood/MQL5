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
        CiLinearRegression *m_lsma_indicator;

        //--- adjusted parameters
        double            m_lsma_pip_long;
        double            m_lsma_pip_short;

    public:
        SignalLinearRegression(void);
        ~SignalLinearRegression(void);

        //--- methods of setting adjustable indicator parameters
        void              LsmaSource(ENUM_APPLIED_PRICE value) { m_lsma_indicator.LsmaSource(value);}
        void              LsmaPeriod(int value)                { m_lsma_indicator.LsmaPeriod(value);}
        void              LsmaOffset(int value)                { m_lsma_indicator.LsmaOffset(value);}
        void              LsmaPipLong(double value)            { m_lsma_pip_long=value;   }
        void              LsmaPipShort(double value)           { m_lsma_pip_short=value;  }

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

    protected:
        bool              InitIndicators(CIndicators *indicators);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
SignalLinearRegression::SignalLinearRegression(void) {
    //--- initialization of protected data
    m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;

    m_lsma_indicator = new CiLinearRegression();
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
SignalLinearRegression::~SignalLinearRegression(void){
}

bool SignalLinearRegression::Initialize(string symbol,int period,bool every_tick) {
    if(m_symbol==NULL) {
        if((m_symbol=new CSymbolInfo)==NULL)
            return(false);
    }
    if(!m_symbol.Name(symbol))
        return(false);
    m_period    =period;
    m_every_tick=every_tick;
    
    m_lsma_indicator.Create(m_symbol.Name(), m_period);

    CExpertBase::Init(m_symbol, (ENUM_TIMEFRAMES)period, 1);

    return (true);
}

//+------------------------------------------------------------------+
//| Validation settings protected data.                              |
//+------------------------------------------------------------------+
bool SignalLinearRegression::ValidationSettings(void) {
    //--- validation settings of additional filters
    if(!CExpertBase::ValidationSettings())
        return(false);
    //--- ok
    return(true);
}

bool SignalLinearRegression::InitIndicators(CIndicators *indicators) {
    //--- check pointer
    if(indicators==NULL)
        return(false);

    indicators.Add(m_lsma_indicator);

    //--- ok
    return(true);
}

//+------------------------------------------------------------------+
//| "Voting" that price will grow.                                   |
//+------------------------------------------------------------------+
int SignalLinearRegression::LongCondition(void) {
    int result=0;
    int idx   =StartIndex();

    double d1 = Open(idx);
    double d2 = m_lsma_indicator.LinReg(idx);
    double d3 = m_lsma_pip_long;
    double d4 = GetPoint(m_symbol.Name());
    bool cond = Open(idx) < m_lsma_indicator.LinReg(idx) + m_lsma_pip_long * GetPoint(m_symbol.Name()) * 10;

    //--- return the result
    return(cond ? 100 : 0);
}

//+------------------------------------------------------------------+
//| "Voting" that price will fall.                                   |
//+------------------------------------------------------------------+
int SignalLinearRegression::ShortCondition(void) {
    int result=0;
    int idx   =StartIndex();
    
    bool cond = Close(idx) > m_lsma_indicator.LinReg(idx) - m_lsma_pip_short * GetPoint(m_symbol.Name()) * 10;
    
    //--- return the result
    return(cond ? 100 : 0);
}
//+------------------------------------------------------------------+

bool SignalLinearRegression::LongTrendCondition(int idx) {
    int startIdx   =StartIndex();
    return Close(startIdx + idx) > m_lsma_indicator.LinReg(startIdx + idx);
}

bool SignalLinearRegression::ShortTrendCondition(int idx) {
    int startIdx   =StartIndex();
    return Close(startIdx + idx) < m_lsma_indicator.LinReg(startIdx + idx);
}

bool SignalLinearRegression::LongMomentumCondition(int idx) {
    int startIdx   =StartIndex();
    return m_lsma_indicator.LinReg(startIdx + idx) > m_lsma_indicator.LinReg(startIdx + idx + 1);
}

bool SignalLinearRegression::ShortMomentumCondition(int idx) {
    int startIdx   =StartIndex();
    return m_lsma_indicator.LinReg(startIdx + idx) < m_lsma_indicator.LinReg(startIdx + idx + 1);
}
