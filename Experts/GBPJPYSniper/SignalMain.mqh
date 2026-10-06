//+------------------------------------------------------------------+
//|                                             SignalMain.mq5 |
//|                                                  Mufraeli Rahman |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Mufraeli Rahman"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Expert/ExpertSignal.mqh>
#include <MovingAverages.mqh>
#include "Helper.mqh"
#include "SignalSuperTrend.mqh"
#include "SignalStochRSI.mqh"
#include "SignalATR.mqh"
#include "SignalZema.mqh"
#include "SignalMovingAverage.mqh"
#include "SignalLinearRegression.mqh"
#include "SignalTema.mqh"

class SignalMain: public CExpertSignal {
    protected:
        //--- adjusted parameters
        string            m_sig_symbol;
        int               m_sig_timeframe;
        CPositionInfo     m_position;
        
        //--- parameters for lsma (linear squares moving averages / linear regression)
        SignalLinearRegresssion *m_sig_lsma;
        int                m_lsma_timeframe;
        ENUM_APPLIED_PRICE m_lsma_source;
        int                m_lsma_period;
        int                m_lsma_offset;
        int                m_lsma_pip_long;
        int                m_lsma_pip_short;

        //--- parameters for tema (triple ema)
        SignalTema        *m_sig_tema;
        int                m_tema_timeframe;
        ENUM_APPLIED_PRICE m_tema_source;
        int                m_tema_period;

        //--- parameters for ema open
        SignalMovingAverage *m_sig_ema_open;
        int                m_ema_open_timeframe;
        ENUM_APPLIED_PRICE m_ema_open_source;
        int                m_ema_open_period;
        ENUM_MA_METHOD     m_ema_open_method;
        ENUM_APPLIED_PRICE m_ema_open_target;

        //--- parameters for super trend indicator
        SignalSuperTrend  *m_sig_st;
        ENUM_TIMEFRAMES    m_st_timeframe;
        int                m_st_period;
        double             m_st_multiplier;
        ENUM_MA_METHOD     m_st_method;
        ENUM_APPLIED_PRICE m_st_source;

        //--- parameters for Stochastic RSI indicator
        ENUM_TIMEFRAMES    Signal_StochRsi_Timeframe;
        int                Signal_StochRsi_RsiPeriod;
        int                Signal_StochRsi_StochLength;
        int                Signal_StochRsi_K;
        int                Signal_StochRsi_D;
        ENUM_APPLIED_PRICE Signal_StochRsi_AppliedPrice;
        string             Signal_StochRsi_KDOperator;

        //--- parameters for atr indicator
        int                Signal_ATR_Timeframe;
        int                Signal_ATR_Period;
        ENUM_MA_METHOD     Signal_ATR_MaMethod;
        bool               Signal_ATR_EnableATRDirection;
        bool               Signal_ATR_EnableATRIncrease;

        //--- parameters for zema indicator
        int                Signal_Zema_Timeframe;
        int                Signal_Zema_Period_Long;
        int                Signal_Zema_Period_Short;

        //--- parameters for ma close indicator
        int                Signal_Ma_Timeframe;
        ENUM_APPLIED_PRICE Signal_Ma_Source;
        int                Signal_Ma_Period;
        ENUM_MA_METHOD     Signal_Ma_Method;
        ENUM_APPLIED_PRICE Signal_Ma_Target;

        //--- parameters for rma close indicator
        int                Signal_MemaClose_Timeframe;
        ENUM_APPLIED_PRICE Signal_MemaClose_Source;
        int                Signal_MemaClose_Period;
        ENUM_MA_METHOD     Signal_MemaClose_Method;
        ENUM_APPLIED_PRICE Signal_MemaClose_Target;

    public:
        SignalMain(void);
        ~SignalMain(void);

        //--- methods of setting adjustable indicator parameters
        void               IndicatorSymbol(string value)        { m_sig_symbol=value;             }
        void               IndicatorTimeframe(int value)        { m_sig_timeframe=value;          }
        

        //--- method of verification of settings
        virtual bool       ValidationSettings(void);
        //--- method of creating the indicator and timeseries
        virtual bool       Initialize();
        //--- methods of checking if the market models are formed
        virtual int        LongCondition(void);
        virtual int        ShortCondition(void);
        virtual bool       CheckCloseLong(double &price);
        virtual bool       CheckCloseShort(double &price);
        virtual bool       CheckReverseLong(double &price, double &sl, double &tp, datetime &expiration);
        virtual bool       CheckReverseShort(double &price, double &sl, double &tp, datetime &expiration);

    protected:
        bool               SelectPosition(void);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
SignalMain::SignalMain(void) {
    //--- initialization of protected data
    m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;

    m_sig_symbol                  ="GBPJPY";
    m_sig_timeframe               =PERIOD_CURRENT;
    
    //--- parameters for lsma (linear squares moving averages / linear regression)
    m_sig_lsma                    = new SignalLinearRegresssion();
    m_lsma_timeframe              =PERIOD_CURRENT;
    m_lsma_source                 =PRICE_CLOSE;
    m_lsma_period                 =18;
    m_lsma_offset                 =5;
    m_lsma_pip_long               =76;
    m_lsma_pip_short              =113;

    //--- parameters for tema (triple ema)
    m_sig_tema                    = new SignalTema();
    m_tema_timeframe              =PERIOD_CURRENT;
    m_tema_source                 =PRICE_CLOSE;
    m_tema_period                 =72;

    //--- parameters for ema open
    m_sig_ema_open                = new SignalMovingAverage();
    m_ema_open_timeframe          =PERIOD_H2;
    m_ema_open_source             =PRICE_CLOSE;
    m_ema_open_period             =10;
    m_ema_open_method             =MODE_EMA;
    m_ema_open_target             =PRICE_OPEN;

    //--- parameters for super trend indicator
    m_sig_st                      = new SignalSuperTrend();
    m_st_timeframe                =PERIOD_M30;
    m_st_period                   =10;
    m_st_multiplier               =3.1;
    m_st_method                   =MODE_SMMA;
    m_st_source                   =PRICE_OPEN;

    //--- parameters for Stochastic RSI indicator
    Signal_StochRsi_Timeframe     =PERIOD_M30;
    Signal_StochRsi_RsiPeriod     =22;
    Signal_StochRsi_StochLength   =2;
    Signal_StochRsi_K             =19;
    Signal_StochRsi_D             =2;
    Signal_StochRsi_AppliedPrice  =PRICE_HIGH;
    Signal_StochRsi_KDOperator    =">";

    //--- parameters for atr indicator
    Signal_ATR_Timeframe          =PERIOD_M45;
    Signal_ATR_Period             =3;
    Signal_ATR_MaMethod           =MODE_SMMA;
    Signal_ATR_EnableATRDirection =true;
    Signal_ATR_EnableATRIncrease  =true;

    //--- parameters for zema indicator
    Signal_Zema_Timeframe          =PERIOD_CURRENT;
    Signal_Zema_Period_Long        =73;
    Signal_Zema_Period_Short       =52;

    //--- parameters for ma close indicator
    Signal_Ma_Timeframe            =PERIOD_M20;
    Signal_Ma_Source               =PRICE_LOW;
    Signal_Ma_Period               =60;
    Signal_Ma_Method               =MODE_SMMA;
    Signal_Ma_Target               =PRICE_CLOSE;

    //--- parameters for rma close indicator
    Signal_MemaClose_Timeframe     =PERIOD_M20;
    Signal_MemaClose_Source        =PRICE_LOW;
    Signal_MemaClose_Period        =60;
    Signal_MemaClose_Method        =MODE_SMMA;
    Signal_MemaClose_Target        =PRICE_CLOSE;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
SignalMain::~SignalMain(void) {
}

//+------------------------------------------------------------------+
//| Validation settings protected data.                              |
//+------------------------------------------------------------------+
bool SignalMain::ValidationSettings(void) {
    //--- validation settings of additional filters
    if(!CExpertSignal::ValidationSettings())
        return(false);
    //--- ok
    return(true);
}

//+------------------------------------------------------------------+
//| Create indicators.                                               |
//+------------------------------------------------------------------+
bool SignalMain::Initialize() {
    //--- Creating filter LSMA
    m_sig_lsma=new SignalLinearRegresssion;
    AddFilter(m_sig_lsma);
    m_sig_lsma.IndicatorSymbol(m_sig_symbol);
    m_sig_lsma.IndicatorTimeframe(m_lsma_timeframe);
    m_sig_lsma.LrSource(m_lsma_source);
    m_sig_lsma.LrPeriod(m_lsma_period);
    m_sig_lsma.LrOffset(m_lsma_offset);
    m_sig_lsma.LrPipLong(m_lsma_pip_long);
    m_sig_lsma.LrPipShort(m_lsma_pip_short);

    //--- Createing filter TEMA
    m_sig_tema=new SignalTema;
    AddFilter(m_sig_tema);
    m_sig_tema.IndicatorSymbol(m_sig_symbol);
    m_sig_tema.IndicatorTimeframe(m_tema_timeframe);
    m_sig_tema.TemaSource(m_tema_source);
    m_sig_tema.TemaPeriod(m_tema_period);

    //--- Createing filter EMA Open
    SignalMovingAverage *filterEmaOpen=new SignalMovingAverage;
    AddFilter(filterEmaOpen);
    filterEmaOpen.IndicatorSymbol(m_sig_symbol);
    filterEmaOpen.IndicatorTimeframe(m_ema_open_timeframe);
    filterEmaOpen.MaPeriod(m_ema_open_period);
    filterEmaOpen.MaSource(m_ema_open_source);
    filterEmaOpen.MaMethod(m_ema_open_method);
    filterEmaOpen.MaTarget(m_ema_open_target);

    m_sig_st=new SignalSuperTrend;
    AddFilter(GetPointer(m_sig_st));
    m_sig_st.SignalSymbol(m_sig_symbol);
    m_sig_st.SignalTimeframe(m_st_timeframe);
    m_sig_st.PeriodMA(m_st_period);
    m_sig_st.Multiplier(m_st_multiplier);
    m_sig_st.MaMethod(m_st_method);
    m_sig_st.Applied(m_st_source);

//--- Createing filter StochRSI
    SignalStochRSI *filterStochRsi=new SignalStochRSI;
    AddFilter(filterStochRsi);
    filterStochRsi.IndicatorSymbol(m_sig_symbol);
    filterStochRsi.IndicatorTimeframe(Signal_StochRsi_Timeframe);
    filterStochRsi.RSIPeriod(Signal_StochRsi_RsiPeriod);
    filterStochRsi.StochLength(Signal_StochRsi_StochLength);
    filterStochRsi.StochK(Signal_StochRsi_K);
    filterStochRsi.StochD(Signal_StochRsi_D);
    filterStochRsi.KDOperator(Signal_StochRsi_KDOperator);

//--- Createing filter ATR Signal
    SignalATR *filterATR=new SignalATR;
    AddFilter(filterATR);
    filterATR.IndicatorSymbol(m_sig_symbol);
    filterATR.IndicatorTimeframe(Signal_ATR_Timeframe);
    filterATR.ATRPeriod(Signal_ATR_Period);
    filterATR.SmootingMethod(Signal_ATR_MaMethod);
    filterATR.EnableATRDirectionSignal(Signal_ATR_EnableATRDirection);
    filterATR.EnableATRIncreaseBySignal(Signal_ATR_EnableATRIncrease);

//--- Createing filter Zema Signal
    SignalZema *filterZema=new SignalZema;
    AddFilter(filterZema);
    filterZema.IndicatorSymbol(m_sig_symbol);
    filterZema.IndicatorTimeframe(Signal_Zema_Timeframe);
    filterZema.ZemaPeriodLong(Signal_Zema_Period_Long);
    filterZema.ZemaPeriodShort(Signal_Zema_Period_Short);

//--- Createing filter Ma Signal
    SignalMovingAverage *filterMa=new SignalMovingAverage;
    AddFilter(filterMa);
    filterMa.IndicatorSymbol(m_sig_symbol);
    filterMa.IndicatorTimeframe(Signal_Ma_Timeframe);
    filterMa.MaPeriod(Signal_Ma_Period);
    filterMa.MaSource(Signal_Ma_Source);
    filterMa.MaMethod(Signal_Ma_Method);
    filterMa.MaTarget(Signal_Ma_Target);

//--- Createing filter Mema Close Signal
    SignalMovingAverage *filterMemaClose=new SignalMovingAverage;
    AddFilter(filterMemaClose);
    filterMemaClose.IndicatorSymbol(m_sig_symbol);
    filterMemaClose.IndicatorTimeframe(Signal_MemaClose_Timeframe);
    filterMemaClose.MaPeriod(Signal_MemaClose_Period);
    filterMemaClose.MaSource(Signal_MemaClose_Source);
    filterMemaClose.MaMethod(Signal_MemaClose_Method);
    filterMemaClose.MaTarget(Signal_MemaClose_Target);

    //--- ok
    return(true);
}

bool SignalMain::SelectPosition(void) {
    bool res=false;
    if((ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE) == ACCOUNT_MARGIN_MODE_RETAIL_HEDGING) {
        res=m_position.SelectByMagic(m_symbol.Name(),m_magic);
    }
    else {
        res=m_position.Select(m_symbol.Name());
    }
    return(res);
}

//+------------------------------------------------------------------+
//| "Voting" that price will grow.                                   |
//+------------------------------------------------------------------+
int SignalMain::LongCondition(void) {
    if (SelectPosition())
        return (0);
    if (m_position.Volume() > 0)
        return (0);
    
    return (m_sig_lsma.LongCondition()
        + m_sig_tema.LongCondition()
        + m_sig_ema_open.LongCondition()) / 3;
}

//+------------------------------------------------------------------+
//| "Voting" that price will fall.                                   |
//+------------------------------------------------------------------+
int SignalMain::ShortCondition(void) {
    return (0);
}

bool CheckCloseLong(double &price) {
    return false;
}

bool CheckCloseShort(double &price) {
    return false;
}

bool CheckReverseLong(double &price, double &sl, double &tp, datetime &expiration) {
    return false;
}

bool CheckReverseShort(double &price, double &sl, double &tp, datetime &expiration) {
    return false;
}
