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
#include "SignalConsolidation.mqh"
#include "SignalCandlestickBody.mqh"

class SignalMain: public CExpertSignal {
    protected:
        CPositionInfo     m_position;
        
        //--- adjusted parameters
        string            m_sig_symbol;
        int               m_sig_timeframe;
        
        //--- LSMA (linear squares moving averages / linear regression)
        SignalLinearRegression *m_sig_lsma;

        //--- TEMA (triple ema)
        SignalTema        *m_sig_tema;

        //--- parameters for MEMO (ema open)
        SignalMovingAverage *m_sig_memo;

        // parameters for CSO (candlestick increase limit) for close price
        SignalCandlestickLimit *m_sig_csoc;

        // parameters for CSO (candlestick increase limit) for open price
        SignalCandlestickLimit *m_sig_csoo;

        //--- parameters for MEMA (rma close)
        SignalMovingAverage *m_sig_mema;

        //--- parameters for ATR Trailing
        SignalATRTrailing *m_sig_atrt;

        //--- parameters for ZEMA
        SignalZema        *m_sig_zema;

        //--- parameters for Consolidation
        SignalConsolidation *m_sig_cons;
        int                m_cons_lookback_long;
        int                m_cons_length_long;
        int                m_cons_lookback_short;
        int                m_cons_length_short;

        //--- parameters for ATR indicator
        SignalATR         *m_sig_atr;
        int                m_atr_timeframe;
        int                m_atr_period;
        ENUM_MA_METHOD     m_atr_method;
        bool               m_atr_enable_atr_direction;
        bool               m_atr_enable_atr_increase;

        //--- parameters for Stochastic RSI indicator
        SignalStochRSI    *m_sig_stochrsi;
        ENUM_TIMEFRAMES    m_stochrsi_timeframe;
        int                m_stochrsi_rsi_period;
        int                m_stochrsi_stoch_period;
        int                m_stochrsi_k;
        int                m_stochrsi_d;
        ENUM_APPLIED_PRICE m_stochrsi_source;
        string             m_stochrsi_operator;

        //--- parameters for ST (Super Trend)
        SignalSuperTrend  *m_sig_st;
        SignalSuperTrend  *m_sig_st2;
        ENUM_TIMEFRAMES    m_st_timeframe;
        int                m_st_period;
        double             m_st_multiplier;
        ENUM_MA_METHOD     m_st_method;
        ENUM_APPLIED_PRICE m_st_source;

        //--- parameters for ma close indicator
        SignalMovingAverage *m_sig_ma;
        int                m_ma_timeframe;
        ENUM_APPLIED_PRICE m_ma_source;
        int                m_ma_period;
        ENUM_MA_METHOD     m_ma_method;
        ENUM_APPLIED_PRICE m_ma_target;

        // candlestick body
        SignalCandlestickBody *m_sig_csb;
        int                m_csb_pip_long;

        // TEMA Momentum
        SignalTema        *m_sig_tema_momentum;

        //--- parameters for ema fast
        SignalMovingAverage *m_sig_emaf;
        int                m_emaf_period;

        //--- parameters for ema medium
        SignalMovingAverage *m_sig_emam;
        int                m_emam_period;

        //--- parameters for ema slow
        SignalMovingAverage *m_sig_emas;
        int                m_emas_period;

    public:
        SignalMain(void);
        ~SignalMain(void);

        //--- methods of setting adjustable indicator parameters
        void SignalSymbol(string value)           { m_sig_symbol=value;                   }
        void SignalTimeframe(int value)           { m_sig_timeframe=value;                }

        //--- LSMA
        void LsmaTimeframe(int value)             { m_sig_lsma.IndicatorTimeframe(value); }
        void LsmaSource(ENUM_APPLIED_PRICE value) { m_sig_lsma.LsmaSource(value);           }
        void LsmaPeriod(int value)                { m_sig_lsma.LsmaPeriod(value);           }
        void LsmaOffset(int value)                { m_sig_lsma.LsmaOffset(value);           }
        void LsmaPipLong(int value)               { m_sig_lsma.LsmaPipLong(value);          }
        void LsmaPipShort(int value)              { m_sig_lsma.LsmaPipShort(value);         }

        //--- TEMA
        void TemaTimeframe(int value)             { m_sig_tema.IndicatorTimeframe(value);   }
        void TemaSource(ENUM_APPLIED_PRICE value) { m_sig_tema.TemaSource(value);           }
        void TemaPeriod(int value)                { m_sig_tema.TemaPeriod(value);           }

        //--- MEMO (EMA Open)
        void MemoTimeframe(int value)             { m_sig_memo.IndicatorTimeframe(value);   }
        void MemoSource(ENUM_APPLIED_PRICE value) { m_sig_memo.MaSource(value);             }
        void MemoPeriod(int value)                { m_sig_memo.MaPeriod(value);             }
        void MemoMethod(ENUM_MA_METHOD value)     { m_sig_memo.MaMethod(value);             }
        void MemoTarget(ENUM_APPLIED_PRICE value) { m_sig_memo.MaTarget(value);             }

        //--- CSO Close
        void CsoCloseIdxLong(int value)           { m_sig_csoc.CsoIdxLong(value);           }
        void CsoClosePctLong(double value)        { m_sig_csoc.CsoPctLong(value);           }
        void CsoCloseIdxShort(int value)          { m_sig_csoc.CsoIdxShort(value);          }
        void CsoClosePctShort(double value)       { m_sig_csoc.CsoPctShort(value);          }
        void CsoCloseTarget(ENUM_APPLIED_PRICE value) { m_sig_csoc.CsoTarget(value);        }

        //--- CSO Open
        void CsoOpenIdxLong(int value)            { m_sig_csoo.CsoIdxLong(value);          }
        void CsoOpenPctLong(double value)         { m_sig_csoo.CsoPctLong(value);          }
        void CsoOpenIdxShort(int value)           { m_sig_csoo.CsoIdxShort(value);         }
        void CsoOpenPctShort(double value)        { m_sig_csoo.CsoPctShort(value);         }
        void CsoOpenTarget(ENUM_APPLIED_PRICE value) { m_sig_csoo.CsoTarget(value);        }

        //--- MEMA (RMA Close)
        void MemaTimeframe(int value)             { m_sig_mema.IndicatorTimeframe(value);  }
        void MemaSource(ENUM_APPLIED_PRICE value) { m_sig_mema.MaSource(value);            }
        void MemaPeriod(int value)                { m_sig_mema.MaPeriod(value);            }
        void MemaMethod(ENUM_MA_METHOD value)     { m_sig_mema.MaMethod(value);            }
        void MemaTarget(ENUM_APPLIED_PRICE value) { m_sig_mema.MaTarget(value);            }

        //--- ATR Trailing
        void ATRTPeriodLong(int value)            { m_sig_atrt.ATRPeriodLong(value);       }
        void ATRTMultiplierLong(double value)     { m_sig_atrt.ATRMultiplierLong(value);   }
        void ATRTPeriodShort(int value)           { m_sig_atrt.ATRPeriodShort(value);      }
        void ATRTMultiplierShort(double value)    { m_sig_atrt.ATRMultiplierShort(value);  }

        //--- ZEMA
        void ZemaTimeframe(int value)             { m_sig_zema.IndicatorTimeframe(value);  }
        void ZemaPeriodLong(int value)            { m_sig_zema.ZemaPeriodLong(value);      }
        void ZemaPeriodShort(int value)           { m_sig_zema.ZemaPeriodShort(value);     }
        void ZemaEnableMomentum(bool value)       { m_sig_zema.EnableZemaMomentum(value);  }

        // Consolidation
        void ConsLookbackLong(int value)          { m_sig_cons.ConsLookbackLong(value);    }
        void ConsLengthLong(int value)            { m_sig_cons.ConsLengthLong(value);      }
        void ConsLookbackShort(int value)         { m_sig_cons.ConsLookbackShort(value);   }
        void ConsLengthShort(int value)           { m_sig_cons.ConsLengthShort(value);     }

        //--- ATR
        void               AtrTimeframe(int value)              { m_atr_timeframe=value;          }
        void               AtrPeriod(int value)                 { m_atr_period=value;             }
        void               AtrMethod(ENUM_MA_METHOD value)      { m_atr_method=value;             }
        void               AtrEnableAtrDirection(bool value)    { m_atr_enable_atr_direction=value; }
        void               AtrEnableAtrIncrease(bool value)     { m_atr_enable_atr_increase=value; }

        //--- Stochastic RSI
        void               StochRsiTimeframe(ENUM_TIMEFRAMES value) { m_stochrsi_timeframe=value; }
        void               StochRsiRsiPeriod(int value)         { m_stochrsi_rsi_period=value;    }
        void               StochRsiStochPeriod(int value)       { m_stochrsi_stoch_period=value;  }
        void               StochRsiK(int value)                 { m_stochrsi_k=value;             }
        void               StochRsiD(int value)                 { m_stochrsi_d=value;             }
        void               StochRsiSource(ENUM_APPLIED_PRICE value) { m_stochrsi_source=value;    }
        void               StochRsiOperator(string value)       { m_stochrsi_operator=value;      }

        //--- ST (Super Trend)
        void               StTimeframe(ENUM_TIMEFRAMES value)   { m_st_timeframe=value;           }
        void               StPeriod(int value)                  { m_st_period=value;              }
        void               StMultiplier(double value)           { m_st_multiplier=value;          }
        void               StMethod(ENUM_MA_METHOD value)       { m_st_method=value;              }
        void               StSource(ENUM_APPLIED_PRICE value)   { m_st_source=value;              }

        //--- MA Close
        void               MaTimeframe(int value)               { m_ma_timeframe=value;           }
        void               MaSource(ENUM_APPLIED_PRICE value)   { m_ma_source=value;              }
        void               MaPeriod(int value)                  { m_ma_period=value;              }
        void               MaMethod(ENUM_MA_METHOD value)       { m_ma_method=value;              }
        void               MaTarget(ENUM_APPLIED_PRICE value)   { m_ma_target=value;              }

        //--- Candlestick Body
        void               CSBPipLong(int value)                { m_csb_pip_long=value;           }

        //--- EMA FAST
        void               EmafPeriod(int value)                { m_ma_period=value;              }

        //--- EMA MEDIUM
        void               EmamPeriod(int value)                { m_ma_period=value;              }

        //--- EMA SLOW
        void               EmasPeriod(int value)                { m_ma_period=value;              }

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
    m_sig_lsma=new SignalLinearRegression;
    AddFilter(m_sig_lsma);
    m_sig_lsma.IndicatorSymbol(m_sig_symbol);
    m_sig_lsma.IndicatorTimeframe(PERIOD_CURRENT);
    m_sig_lsma.LsmaSource(PRICE_CLOSE);
    m_sig_lsma.LsmaPeriod(18);
    m_sig_lsma.LsmaOffset(5);
    m_sig_lsma.LsmaPipLong(76);
    m_sig_lsma.LsmaPipShort(113);

    //--- Createing filter TEMA
    m_sig_tema=new SignalTema;
    AddFilter(m_sig_tema);
    m_sig_tema.IndicatorSymbol(m_sig_symbol);
    m_sig_tema.IndicatorTimeframe(PERIOD_CURRENT);
    m_sig_tema.TemaSource(PRICE_CLOSE);
    m_sig_tema.TemaPeriod(72);
    m_sig_tema.TemaEnableMomentum(false);

    //--- Createing filter EMA Open
    m_sig_memo=new SignalMovingAverage;
    AddFilter(m_sig_memo);
    m_sig_memo.IndicatorSymbol(m_sig_symbol);
    m_sig_memo.IndicatorTimeframe(PERIOD_H2);
    m_sig_memo.MaPeriod(10);
    m_sig_memo.MaSource(PRICE_CLOSE);
    m_sig_memo.MaMethod(MODE_EMA);
    m_sig_memo.MaTarget(PRICE_OPEN);

    // Creating filter Candlestick Limit for Close
    m_sig_csoc=new SignalCandlestickLimit();
    AddFilter(m_sig_csoc);
    m_sig_csoc.IndicatorSymbol(m_sig_symbol);
    m_sig_csoc.IndicatorTimeframe(PERIOD_CURRENT);
    m_sig_csoc.CsoIdxLong(4);
    m_sig_csoc.CsoPctLong(0.464);
    m_sig_csoc.CsoIdxShort(2);
    m_sig_csoc.CsoPctShort(0.777);
    m_sig_csoc.CsoTarget(PRICE_CLOSE);

    // Creating filter Candlestick Limit for Open
    m_sig_csoo=new SignalCandlestickLimit();
    AddFilter(m_sig_csoo);
    m_sig_csoo.IndicatorSymbol(m_sig_symbol);
    m_sig_csoo.IndicatorTimeframe(PERIOD_CURRENT);
    m_sig_csoo.CsoIdxLong(0);
    m_sig_csoo.CsoPctLong(0.255);
    m_sig_csoo.CsoIdxShort(0);
    m_sig_csoo.CsoPctShort(0.325);
    m_sig_csoo.CsoTarget(PRICE_OPEN);

    //--- Creating filter Mema Close Signal
    m_sig_mema=new SignalMovingAverage();
    AddFilter(m_sig_mema);
    m_sig_mema.IndicatorSymbol(m_sig_symbol);
    m_sig_mema.IndicatorTimeframe(PERIOD_M20);
    m_sig_mema.MaPeriod(60);
    m_sig_mema.MaSource(PRICE_LOW);
    m_sig_mema.MaMethod(MODE_SMMA);
    m_sig_mema.MaTarget(PRICE_CLOSE);

    //--- Creating filter ATR Trailing
    m_sig_atrt=new SignalATRTrailing();
    AddFilter(m_sig_atrt);
    m_sig_atrt.IndicatorSymbol(m_sig_symbol);
    m_sig_atrt.IndicatorTimeframe(m_sig_timeframe);
    m_sig_atrt.ATRPeriodLong(10);
    m_sig_atrt.ATRMultiplierLong(3.6);
    m_sig_atrt.ATRPeriodShort(6);
    m_sig_atrt.ATRMultiplierShort(2.2);

    //--- Creating filter Zema Signal
    m_sig_zema=new SignalZema;
    AddFilter(m_sig_zema);
    m_sig_zema.IndicatorSymbol(m_sig_symbol);
    m_sig_zema.IndicatorTimeframe(PERIOD_CURRENT);
    m_sig_zema.ZemaPeriodLong(73);
    m_sig_zema.ZemaPeriodShort(52);
    m_sig_zema.EnableZemaMomentum(true);

    //--- Creating filter Consolidation
    m_sig_cons=new SignalConsolidation;
    AddFilter(m_sig_cons);
    m_sig_cons.ConsLookbackLong(m_cons_lookback_long);
    m_sig_cons.ConsLengthLong(m_cons_length_long);
    m_sig_cons.ConsLookbackShort(m_cons_lookback_short);
    m_sig_cons.ConsLengthShort(m_cons_length_short);

    //--- Createing filter ATR Signal
    m_sig_atr=new SignalATR;
    AddFilter(m_sig_atr);
    m_sig_atr.IndicatorSymbol(m_sig_symbol);
    m_sig_atr.IndicatorTimeframe(m_atr_timeframe);
    m_sig_atr.ATRPeriod(m_atr_period);
    m_sig_atr.SmootingMethod(m_atr_method);
    m_sig_atr.EnableATRDirectionSignal(m_atr_enable_atr_direction);
    m_sig_atr.EnableATRIncreaseBySignal(m_atr_enable_atr_increase);

    //--- Createing filter StochRSI
    m_sig_stochrsi=new SignalStochRSI;
    AddFilter(m_sig_stochrsi);
    m_sig_stochrsi.IndicatorSymbol(m_sig_symbol);
    m_sig_stochrsi.IndicatorTimeframe(m_stochrsi_timeframe);
    m_sig_stochrsi.RSIPeriod(m_stochrsi_rsi_period);
    m_sig_stochrsi.StochLength(m_stochrsi_stoch_period);
    m_sig_stochrsi.StochK(m_stochrsi_k);
    m_sig_stochrsi.StochD(m_stochrsi_d);
    m_sig_stochrsi.KDOperator(m_stochrsi_operator);

    //--- Creating filter Super Trend with Close signal
    m_sig_st=new SignalSuperTrend;
    AddFilter(GetPointer(m_sig_st));
    m_sig_st.SignalSymbol(m_sig_symbol);
    m_sig_st.SignalTimeframe(m_st_timeframe);
    m_sig_st.PeriodMA(m_st_period);
    m_sig_st.Multiplier(m_st_multiplier);
    m_sig_st.MaMethod(m_st_method);
    m_sig_st.Applied(m_st_source);
    m_sig_st.EnableClose(true);

//--- Createing filter Ma Signal
    m_sig_ma=new SignalMovingAverage;
    AddFilter(m_sig_ma);
    m_sig_ma.IndicatorSymbol(m_sig_symbol);
    m_sig_ma.IndicatorTimeframe(m_ma_timeframe);
    m_sig_ma.MaPeriod(m_ma_period);
    m_sig_ma.MaSource(m_ma_source);
    m_sig_ma.MaMethod(m_ma_method);
    m_sig_ma.MaTarget(m_ma_target);

//--- Creating filter Candlestick Body
    m_sig_csb=new SignalCandlestickBody;
    AddFilter(m_sig_csb);
    m_sig_csb.CsbPipLong(m_csb_pip_long);

    //--- Creating filter Super Trend without Close signal
    m_sig_st2=new SignalSuperTrend;
    AddFilter(GetPointer(m_sig_st2));
    m_sig_st2.SignalSymbol(m_sig_symbol);
    m_sig_st2.SignalTimeframe(m_st_timeframe);
    m_sig_st2.PeriodMA(m_st_period);
    m_sig_st2.Multiplier(m_st_multiplier);
    m_sig_st2.MaMethod(m_st_method);
    m_sig_st2.Applied(m_st_source);
    m_sig_st2.EnableClose(false);

    //--- Createing filter TEMA
    m_sig_tema_momentum=new SignalTema;
    AddFilter(m_sig_tema_momentum);
    m_sig_tema_momentum.IndicatorSymbol(m_sig_symbol);
    m_sig_tema_momentum.IndicatorTimeframe(m_tema_timeframe);
    m_sig_tema_momentum.TemaSource(m_tema_source);
    m_sig_tema_momentum.TemaPeriod(m_tema_period);
    m_sig_tema_momentum.TemaEnableMomentum(true);

    //--- Createing filter EMA SLOW
    m_sig_emaf=new SignalMovingAverage;
    AddFilter(m_sig_emaf);
    m_sig_emaf.IndicatorSymbol(m_sig_symbol);
    m_sig_emaf.IndicatorTimeframe(m_sig_timeframe);
    m_sig_emaf.MaSource(PRICE_CLOSE);
    m_sig_emaf.MaPeriod(m_emaf_period);
    m_sig_emaf.MaMethod(MODE_EMA);
    m_sig_emaf.MaTarget(PRICE_CLOSE);

    //--- Createing filter EMA MEDIUM
    m_sig_emam=new SignalMovingAverage;
    AddFilter(m_sig_emam);
    m_sig_emam.IndicatorSymbol(m_sig_symbol);
    m_sig_emam.IndicatorTimeframe(m_sig_timeframe);
    m_sig_emam.MaSource(PRICE_CLOSE);
    m_sig_emam.MaPeriod(m_emam_period);
    m_sig_emam.MaMethod(MODE_EMA);
    m_sig_emam.MaTarget(PRICE_CLOSE);

    //--- Createing filter EMA FAST
    m_sig_emas=new SignalMovingAverage;
    AddFilter(m_sig_emas);
    m_sig_emas.IndicatorSymbol(m_sig_symbol);
    m_sig_emas.IndicatorTimeframe(m_sig_timeframe);
    m_sig_emas.MaSource(PRICE_CLOSE);
    m_sig_emas.MaPeriod(m_emas_period);
    m_sig_emas.MaMethod(MODE_EMA);
    m_sig_emas.MaTarget(PRICE_CLOSE);

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

    bool cond1 = (m_sig_lsma.LongCondition() > 0)
        && (m_sig_tema.LongCondition() > 0)
        && (m_sig_memo.LongCondition() > 0)
        && (m_sig_csoc.LongCondition() > 0)
        && (m_sig_csoo.LongCondition() > 0)
        && (Close(idx) > Open(idx))
        && (m_sig_mema.LongCondition() > 0)
        && (m_sig_cons.LongCondition() > 0)
        && (m_sig_atr.LongCondition() > 0)
        && (m_sig_stochrsi.LongCondition() > 0)
        && (m_sig_st.LongCondition() > 0);

    bool cond2 = (m_sig_csb.LongCondition() > 0)
        && (m_sig_st2.LongCondition() > 0)
        && (m_sig_tema_momentum.LongCondition() > 0)
        && (m_sig_tema.LongCondition() > 0) 
        && (m_sig_lsma.LongTrendCondition(idx))
        && (m_sig_emaf.LongCondition() > 0);

    return cond1 || cond2;
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
