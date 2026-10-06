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
#include "SignalCandlestickLimit.mqh"
#include "SignalATRTrailing.mqh"

class SignalMain: public CExpertSignal {
    protected:
        CPositionInfo     m_position;
        
        //--- adjusted parameters
        string            m_sig_symbol;
        int               m_sig_timeframe;
        
        //--- parameters for LSMA (linear squares moving averages / linear regression)
        SignalLinearRegresssion *m_sig_lsma;
        int                m_lsma_timeframe;
        ENUM_APPLIED_PRICE m_lsma_source;
        int                m_lsma_period;
        int                m_lsma_offset;
        int                m_lsma_pip_long;
        int                m_lsma_pip_short;

        //--- parameters for TEMA (triple ema)
        SignalTema        *m_sig_tema;
        int                m_tema_timeframe;
        ENUM_APPLIED_PRICE m_tema_source;
        int                m_tema_period;

        //--- parameters for MEMO (ema open)
        SignalMovingAverage *m_sig_memo;
        int                m_memo_timeframe;
        ENUM_APPLIED_PRICE m_memo_source;
        int                m_memo_period;
        ENUM_MA_METHOD     m_memo_method;
        ENUM_APPLIED_PRICE m_memo_target;

        // parameters for CSO (candlestick increase limit) for close price
        SignalCandlestickLimit *m_sig_csoc;
        int                m_csoc_idx_long;
        double             m_csoc_pct_long;
        int                m_csoc_idx_short;
        double             m_csoc_pct_short;
        ENUM_APPLIED_PRICE m_csoc_target;

        // parameters for CSO (candlestick increase limit) for open price
        SignalCandlestickLimit *m_sig_csoo;
        int                m_csoo_idx_long;
        double             m_csoo_pct_long;
        int                m_csoo_idx_short;
        double             m_csoo_pct_short;
        ENUM_APPLIED_PRICE m_csoo_target;

        //--- parameters for MEMA (rma close)
        SignalSuperTrend  *m_sig_mema;
        int                m_mema_timeframe;
        ENUM_APPLIED_PRICE m_mema_source;
        int                m_mema_period;
        ENUM_MA_METHOD     m_mema_method;
        ENUM_APPLIED_PRICE m_mema_target;

        //--- parameters for ATR Trailing
        SignalATRTrailing *m_sig_atrt;
        int                m_atrt_period_long;
        double             m_atrt_multiplier_long;
        int                m_atrt_period_short;
        double             m_atrt_multiplier_short;

        //--- parameters for ZEMA
        int                m_zema_timeframe;
        int                m_zema_period_long;
        int                m_zema_period_short;
        bool               m_zema_enable_momentum;

        //--- parameters for ST (Super Trend)
        SignalSuperTrend  *m_sig_st;
        ENUM_TIMEFRAMES    m_st_timeframe;
        int                m_st_period;
        double             m_st_multiplier;
        ENUM_MA_METHOD     m_st_method;
        ENUM_APPLIED_PRICE m_st_source;

        //--- parameters for Stochastic RSI indicator
        ENUM_TIMEFRAMES    m_stochrsi_timeframe;
        int                m_stochrsi_rsi_period;
        int                m_stochrsi_stoch_period;
        int                m_stochrsi_k;
        int                m_stochrsi_d;
        ENUM_APPLIED_PRICE m_stochrsi_source;
        string             m_stochrsi_operator;

        //--- parameters for ATR indicator
        int                m_atr_timeframe;
        int                m_atr_period;
        ENUM_MA_METHOD     m_atr_method;
        bool               m_atr_enable_atr_direction;
        bool               m_atr_enable_atr_increase;

        //--- parameters for ma close indicator
        int                m_ma_timeframe;
        ENUM_APPLIED_PRICE m_ma_source;
        int                m_ma_period;
        ENUM_MA_METHOD     m_ma_method;
        ENUM_APPLIED_PRICE m_ma_target;

    public:
        SignalMain(void);
        ~SignalMain(void);

        //--- methods of setting adjustable indicator parameters
        void               SignalSymbol(string value)           { m_sig_symbol=value;             }
        void               SignalTimeframe(int value)           { m_sig_timeframe=value;          }
        
        //--- LSMA
        void               LsmaTimeframe(int value)             { m_lsma_timeframe=value;         }
        void               LsmaSource(ENUM_APPLIED_PRICE value) { m_lsma_source=value;            }
        void               LsmaPeriod(int value)                { m_lsma_period=value;            }
        void               LsmaOffset(int value)                { m_lsma_offset=value;            }
        void               LsmaPipLong(int value)               { m_lsma_pip_long=value;          }
        void               LsmaPipShort(int value)              { m_lsma_pip_short=value;         }

        //--- TEMA
        void               TemaTimeframe(int value)             { m_tema_timeframe=value;         }
        void               TemaSource(ENUM_APPLIED_PRICE value) { m_tema_source=value;            }
        void               TemaPeriod(int value)                { m_tema_period=value;            }

        //--- MEMO (EMA Open)
        void               MemoTimeframe(int value)             { m_memo_timeframe=value;         }
        void               MemoSource(ENUM_APPLIED_PRICE value) { m_memo_source=value;            }
        void               MemoPeriod(int value)                { m_memo_period=value;            }
        void               MemoMethod(ENUM_MA_METHOD value)     { m_memo_method=value;            }
        void               MemoTarget(ENUM_APPLIED_PRICE value) { m_memo_target=value;            }

        //--- CSO Close
        void               CsoCloseIdxLong(int value)           { m_csoc_idx_long=value;          }
        void               CsoClosePctLong(double value)        { m_csoc_pct_long=value;          }
        void               CsoCloseIdxShort(int value)          { m_csoc_idx_short=value;         }
        void               CsoClosePctShort(double value)       { m_csoc_pct_short=value;         }
        void               CsoCloseTarget(ENUM_APPLIED_PRICE value) { m_csoc_target=value;        }

        //--- CSO Open
        void               CsoOpenIdxLong(int value)            { m_csoo_idx_long=value;          }
        void               CsoOpenPctLong(double value)         { m_csoo_pct_long=value;          }
        void               CsoOpenIdxShort(int value)           { m_csoo_idx_short=value;         }
        void               CsoOpenPctShort(double value)        { m_csoo_pct_short=value;         }
        void               CsoOpenTarget(ENUM_APPLIED_PRICE value) { m_csoo_target=value;         }

        //--- MEMA (RMA Close)
        void               MemaTimeframe(int value)             { m_mema_timeframe=value;         }
        void               MemaSource(ENUM_APPLIED_PRICE value) { m_mema_source=value;            }
        void               MemaPeriod(int value)                { m_mema_period=value;            }
        void               MemaMethod(ENUM_MA_METHOD value)     { m_mema_method=value;            }
        void               MemaTarget(ENUM_APPLIED_PRICE value) { m_mema_target=value;            }

        //--- ATR Trailing
        void               ATRTPeriodLong(int value)            { m_atrt_period_long=value;       }
        void               ATRTMultiplierLong(double value)     { m_atrt_multiplier_long=value;   }
        void               ATRTPeriodShort(int value)           { m_atrt_period_short=value;      }
        void               ATRTMultiplierShort(double value)    { m_atrt_multiplier_short=value;  }

        //--- ZEMA
        void               ZemaTimeframe(int value)             { m_zema_timeframe=value;         }
        void               ZemaPeriodLong(int value)            { m_zema_period_long=value;       }
        void               ZemaPeriodShort(int value)           { m_zema_period_short=value;      }
        void               ZemaEnableMomentum(bool value)       { m_zema_enable_momentum=value;   }

        // Consolidation

        //--- ATR
        void               AtrTimeframe(int value)              { m_atr_timeframe=value;          }
        void               AtrPeriod(int value)                 { m_atr_period=value;             }
        void               AtrMethod(ENUM_MA_METHOD value)      { m_atr_method=value;             }
        void               AtrEnableAtrDirection(bool value)    { m_atr_enable_atr_direction=value; }
        void               AtrEnableAtrIncrease(bool value)     { m_atr_enable_atr_increase=value; }

        //--- ST (Super Trend)
        void               StTimeframe(ENUM_TIMEFRAMES value)   { m_st_timeframe=value;           }
        void               StPeriod(int value)                  { m_st_period=value;              }
        void               StMultiplier(double value)           { m_st_multiplier=value;          }
        void               StMethod(ENUM_MA_METHOD value)       { m_st_method=value;              }
        void               StSource(ENUM_APPLIED_PRICE value)   { m_st_source=value;              }

        //--- Stochastic RSI
        void               StochRsiTimeframe(ENUM_TIMEFRAMES value) { m_stochrsi_timeframe=value; }
        void               StochRsiRsiPeriod(int value)         { m_stochrsi_rsi_period=value;    }
        void               StochRsiStochPeriod(int value)       { m_stochrsi_stoch_period=value;  }
        void               StochRsiK(int value)                 { m_stochrsi_k=value;             }
        void               StochRsiD(int value)                 { m_stochrsi_d=value;             }
        void               StochRsiSource(ENUM_APPLIED_PRICE value) { m_stochrsi_source=value;    }
        void               StochRsiOperator(string value)       { m_stochrsi_operator=value;      }

        //--- MA Close
        void               MaTimeframe(int value)               { m_ma_timeframe=value;           }
        void               MaSource(ENUM_APPLIED_PRICE value)   { m_ma_source=value;              }
        void               MaPeriod(int value)                  { m_ma_period=value;              }
        void               MaMethod(ENUM_MA_METHOD value)       { m_ma_method=value;              }
        void               MaTarget(ENUM_APPLIED_PRICE value)   { m_ma_target=value;              }

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

    //--- parameters for super trend indicator
    m_sig_st                      = new SignalSuperTrend();
    m_st_timeframe                =PERIOD_M30;
    m_st_period                   =10;
    m_st_multiplier               =3.1;
    m_st_method                   =MODE_SMMA;
    m_st_source                   =PRICE_OPEN;

    //--- parameters for Stochastic RSI indicator
    m_stochrsi_timeframe     =PERIOD_M30;
    m_stochrsi_rsi_period     =22;
    m_stochrsi_stoch_period   =2;
    m_stochrsi_k             =19;
    m_stochrsi_d             =2;
    m_stochrsi_source  =PRICE_HIGH;
    m_stochrsi_operator    =">";

    //--- parameters for ma close indicator
    m_ma_timeframe            =PERIOD_M20;
    m_ma_source               =PRICE_LOW;
    m_ma_period               =60;
    m_ma_method               =MODE_SMMA;
    m_ma_target               =PRICE_CLOSE;
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
    filterEmaOpen.IndicatorTimeframe(m_memo_timeframe);
    filterEmaOpen.MaPeriod(m_memo_period);
    filterEmaOpen.MaSource(m_memo_source);
    filterEmaOpen.MaMethod(m_memo_method);
    filterEmaOpen.MaTarget(m_memo_target);

    //--- Createing filter Mema Close Signal
    SignalMovingAverage *m_sig_mema=new SignalMovingAverage;
    AddFilter(m_sig_mema);
    m_sig_mema.IndicatorSymbol(m_sig_symbol);
    m_sig_mema.IndicatorTimeframe(m_mema_timeframe);
    m_sig_mema.MaPeriod(m_mema_period);
    m_sig_mema.MaSource(m_mema_source);
    m_sig_mema.MaMethod(m_mema_method);
    m_sig_mema.MaTarget(m_mema_target);

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
    filterStochRsi.IndicatorTimeframe(m_stochrsi_timeframe);
    filterStochRsi.RSIPeriod(m_stochrsi_rsi_period);
    filterStochRsi.StochLength(m_stochrsi_stoch_period);
    filterStochRsi.StochK(m_stochrsi_k);
    filterStochRsi.StochD(m_stochrsi_d);
    filterStochRsi.KDOperator(m_stochrsi_operator);

//--- Createing filter ATR Signal
    SignalATR *filterATR=new SignalATR;
    AddFilter(filterATR);
    filterATR.IndicatorSymbol(m_sig_symbol);
    filterATR.IndicatorTimeframe(m_atr_timeframe);
    filterATR.ATRPeriod(m_atr_period);
    filterATR.SmootingMethod(m_atr_method);
    filterATR.EnableATRDirectionSignal(m_atr_enable_atr_direction);
    filterATR.EnableATRIncreaseBySignal(m_atr_enable_atr_increase);

//--- Createing filter Zema Signal
    SignalZema *filterZema=new SignalZema;
    AddFilter(filterZema);
    filterZema.IndicatorSymbol(m_sig_symbol);
    filterZema.IndicatorTimeframe(m_zema_timeframe);
    filterZema.ZemaPeriodLong(m_zema_period_long);
    filterZema.ZemaPeriodShort(m_zema_period_short);

//--- Createing filter Ma Signal
    SignalMovingAverage *filterMa=new SignalMovingAverage;
    AddFilter(filterMa);
    filterMa.IndicatorSymbol(m_sig_symbol);
    filterMa.IndicatorTimeframe(m_ma_timeframe);
    filterMa.MaPeriod(m_ma_period);
    filterMa.MaSource(m_ma_source);
    filterMa.MaMethod(m_ma_method);
    filterMa.MaTarget(m_ma_target);

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
    
    int idx   =StartIndex();

    return (m_sig_lsma.LongCondition()
        + m_sig_tema.LongCondition()
        + m_sig_memo.LongCondition()
        + m_sig_csoc.LongCondition()
        + m_sig_csoo.LongCondition()
        + (Close(idx) > Open(idx) ? 100 : 0)
        + m_sig_mema.LongCondition() ) / 7;
}

//+------------------------------------------------------------------+
//| "Voting" that price will fall.                                   |
//+------------------------------------------------------------------+
int SignalMain::ShortCondition(void) {
    return (0);
}

bool SignalMain::CheckCloseLong(double &price) {
    return false;
}

bool SignalMain::CheckCloseShort(double &price) {
    return false;
}

bool SignalMain::CheckReverseLong(double &price, double &sl, double &tp, datetime &expiration) {
    return false;
}

bool SignalMain::CheckReverseShort(double &price, double &sl, double &tp, datetime &expiration) {
    return false;
}
