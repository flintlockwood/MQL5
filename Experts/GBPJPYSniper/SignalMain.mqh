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
        int m_lsma_timeframe;

        //--- TEMA (triple ema)
        SignalTema         *m_sig_tema;
        int m_tema_timeframe;

        //--- parameters for MEMO (ema open)
        SignalMovingAverage *m_sig_memo;
        int m_memo_timeframe;

        // parameters for CSO (candlestick increase limit) for close price
        SignalCandlestickLimit *m_sig_csoc;
        int m_csoc_timeframe;

        // parameters for CSO (candlestick increase limit) for open price
        SignalCandlestickLimit *m_sig_csoo;
        int m_csoo_timeframe;

        //--- parameters for MEMA (rma close)
        SignalMovingAverage *m_sig_mema;
        int m_mema_timeframe;

        //--- parameters for ATR Trailing
        SignalATRTrailing *m_sig_atrt;
        int m_atrt_timeframe;

        //--- parameters for ZEMA
        SignalZema        *m_sig_zema;
        int m_zema_timeframe;

        //--- parameters for Consolidation
        SignalConsolidation *m_sig_cons;
        int m_cons_timeframe;

        //--- parameters for ATR indicator
        SignalATR         *m_sig_atr;
        int m_atr_timeframe;

        //--- parameters for Stochastic RSI indicator
        SignalStochRSI    *m_sig_stochrsi;
        int m_stochrsi_timeframe;

        //--- parameters for ST (Super Trend)
        SignalSuperTrend  *m_sig_st;
        SignalSuperTrend  *m_sig_st2;
        int m_st_timeframe;
        int m_st2_timeframe;

        // candlestick body
        SignalCandlestickBody *m_sig_csb;
        int                m_csb_pip_long;
        int m_csb_timeframe;

        // TEMA Momentum
        SignalTema        *m_sig_tema_momentum;
        int m_temam_timeframe;

        //--- parameters for ema fast
        SignalMovingAverage *m_sig_emaf;
        int m_emaf_timeframe;

        //--- parameters for ema medium
        SignalMovingAverage *m_sig_emam;
        int m_emam_timeframe;

        //--- parameters for ema slow
        SignalMovingAverage *m_sig_emas;
        int m_emas_timeframe;

    public:
        SignalMain(void);
        ~SignalMain(void);

        //--- methods of setting adjustable indicator parameters
        void SignalSymbol(string value)           { m_sig_symbol=value;                     }
        void SignalTimeframe(int value)           { m_sig_timeframe=value;                  }

        //--- LSMA
        void LsmaTimeframe(int value)             { m_sig_lsma.LsmaTimeframe(value);        }
        void LsmaSource(ENUM_APPLIED_PRICE value) { m_sig_lsma.LsmaSource(value);           }
        void LsmaPeriod(int value)                { m_sig_lsma.LsmaPeriod(value);           }
        void LsmaOffset(int value)                { m_sig_lsma.LsmaOffset(value);           }
        void LsmaPipLong(int value)               { m_sig_lsma.LsmaPipLong(value);          }
        void LsmaPipShort(int value)              { m_sig_lsma.LsmaPipShort(value);         }

        //--- TEMA
        void TemaTimeframe(int value)             { m_sig_tema.TemaTimeframe(value);   }
        void TemaSource(ENUM_APPLIED_PRICE value) { m_sig_tema.TemaSource(value);           }
        void TemaPeriod(int value)                { m_sig_tema.TemaPeriod(value);           }

        //--- MEMO (EMA Open)
        void MemoTimeframe(int value)             { m_sig_memo.MaTimeframe(value);   }
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
        void MemaTimeframe(int value)             { m_sig_mema.MaTimeframe(value);  }
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
        void ZemaTimeframe(int value)             { m_sig_zema.ZemaTimeframe(value);  }
        void ZemaPeriodLong(int value)            { m_sig_zema.ZemaPeriodLong(value);      }
        void ZemaPeriodShort(int value)           { m_sig_zema.ZemaPeriodShort(value);     }
        void ZemaEnableMomentum(bool value)       { m_sig_zema.EnableZemaMomentum(value);  }
        void ZemaMomentumCondLong(string value)   { m_sig_zema.ZemaMomentumCondLong(value);}
        void ZemaMomentumCondShort(string value)  { m_sig_zema.ZemaMomentumCondShort(value);}

        // Consolidation
        void ConsLookbackLong(int value)          { m_sig_cons.ConsLookbackLong(value);    }
        void ConsLengthLong(int value)            { m_sig_cons.ConsLengthLong(value);      }
        void ConsLookbackShort(int value)         { m_sig_cons.ConsLookbackShort(value);   }
        void ConsLengthShort(int value)           { m_sig_cons.ConsLengthShort(value);     }

        //--- ATR
        void AtrTimeframe(int value)              { m_sig_atr.IndicatorTimeframe(value);   }
        void AtrPeriod(int value)                 { m_sig_atr.ATRPeriod(value);            }
        void AtrMethod(ENUM_MA_METHOD value)      { m_sig_atr.SmootingMethod(value);       }
        void AtrEnableAtrDirection(bool value)    { m_sig_atr.EnableATRDirectionSignal(value);}
        void AtrEnableAtrIncrease(bool value)     { m_sig_atr.EnableATRIncreaseBySignal(value);}

        //--- Stochastic RSI
        void StochRsiTimeframe(ENUM_TIMEFRAMES value) { m_sig_stochrsi.IndicatorTimeframe(value);}
        void StochRsiRsiPeriod(int value)         { m_sig_stochrsi.RSIPeriod(value);       }
        void StochRsiStochPeriod(int value)       { m_sig_stochrsi.StochLength(value);     }
        void StochRsiK(int value)                 { m_sig_stochrsi.StochK(value);          }
        void StochRsiD(int value)                 { m_sig_stochrsi.StochD(value);          }
        void StochRsiSource(ENUM_APPLIED_PRICE value) { m_sig_stochrsi.RsiSource(value);   }
        void StochRsiOperator(string value)       { m_sig_stochrsi.KDOperator(value);      }

        //--- ST (Super Trend)
        void StTimeframe(ENUM_TIMEFRAMES value)   { m_sig_st.SignalTimeframe(value);       }
        void StPeriod(int value)                  { m_sig_st.PeriodMA(value);              }
        void StMultiplier(double value)           { m_sig_st.Multiplier(value);            }
        void StMethod(ENUM_MA_METHOD value)       { m_sig_st.MaMethod(value);              }
        void StSource(ENUM_APPLIED_PRICE value)   { m_sig_st.Applied(value);               }

        //--- Candlestick Body
        void CSBPipLong(int value)                { m_sig_csb.CsbPipLong(value);           }

        //--- EMA FAST
        void EmafPeriod(int value)                { m_sig_emaf.MaPeriod(value);            }

        //--- EMA MEDIUM
        void EmamPeriod(int value)                { m_sig_emam.MaPeriod(value);            }

        //--- EMA SLOW
        void EmasPeriod(int value)                { m_sig_emas.MaPeriod(value);            }

        //--- method of creating the indicator and timeseries
        virtual bool       Initialize(string symbol,ENUM_TIMEFRAMES period,bool every_tick);
        //--- method of verification of settings
        virtual bool       ValidationSettings(void);
        //--- methods of checking if the market models are formed
        virtual int        LongCondition(void);
        virtual int        ShortCondition(void);
        virtual bool       CheckCloseLong(double &price);
        virtual bool       CheckCloseShort(double &price);
        virtual bool       CheckReverseLong(double &price, double &sl, double &tp, datetime &expiration);
        virtual bool       CheckReverseShort(double &price, double &sl, double &tp, datetime &expiration);

    protected:
        bool               SelectPosition(void);
        bool               InitIndicators(CIndicators *indicators);
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
bool SignalMain::Initialize(string symbol,ENUM_TIMEFRAMES period,bool every_tick) {
    if(m_symbol==NULL) {
    if((m_symbol=new CSymbolInfo)==NULL)
        return(false);
    }
    if(!m_symbol.Name(symbol))
        return(false);
    m_period    =period;
    m_every_tick=every_tick;

    //--- Creating filter LSMA
    m_sig_lsma=new SignalLinearRegression;
    m_sig_lsma.Initialize(m_sig_symbol, m_lsma_timeframe, every_tick);

    //--- Createing filter TEMA
    m_sig_tema=new SignalTema;
    m_sig_tema.Initialize(m_sig_symbol, m_tema_timeframe, every_tick);

    //--- Createing filter EMA Open
    m_sig_memo=new SignalMovingAverage;
    m_sig_memo.Initialize(m_sig_symbol, m_memo_timeframe, every_tick);

    // Creating filter Candlestick Limit for Close
    m_sig_csoc=new SignalCandlestickLimit();
    m_sig_csoc.Initialize(m_sig_symbol, m_csoc_timeframe, every_tick);

    // Creating filter Candlestick Limit for Open
    m_sig_csoo=new SignalCandlestickLimit();
    m_sig_csoo.Initialize(m_sig_symbol, m_csoo_timeframe, every_tick);

    //--- Creating filter Mema Close Signal
    m_sig_mema=new SignalMovingAverage();
    m_sig_mema.Initialize(m_sig_symbol, m_mema_timeframe, every_tick);

    //--- Creating filter ATR Trailing
    m_sig_atrt=new SignalATRTrailing();
    m_sig_atrt.Initialize(m_sig_symbol, m_atrt_timeframe, every_tick);

    //--- Creating filter Zema Signal
    m_sig_zema=new SignalZema;
    m_sig_zema.Initialize(m_sig_symbol, m_zema_timeframe, every_tick);

    //--- Creating filter Consolidation
    m_sig_cons=new SignalConsolidation();
    m_sig_cons.Initialize(m_sig_symbol, m_zema_timeframe, every_tick);

    //--- Createing filter ATR Signal
    m_sig_atr=new SignalATR();
    m_sig_atr.Initialize(m_sig_symbol, m_zema_timeframe, every_tick);

    //--- Createing filter StochRSI
    m_sig_stochrsi=new SignalStochRSI();
    m_sig_stochrsi.Initialize(m_sig_symbol, m_zema_timeframe, every_tick);

    //--- Creating filter Super Trend with Close signal
    m_sig_st=new SignalSuperTrend();
    m_sig_st.Initialize(m_sig_symbol, m_zema_timeframe, every_tick);

//--- Creating filter Candlestick Body
    m_sig_csb=new SignalCandlestickBody();
    m_sig_csb.CsbPipLong(m_csb_pip_long);

    //--- Creating filter Super Trend without Close signal
    m_sig_st2=new SignalSuperTrend();
    m_sig_st2.Initialize(m_sig_symbol, m_zema_timeframe, every_tick);

    //--- Createing filter TEMA (BBMC)
    m_sig_tema_momentum=new SignalTema();
    m_sig_tema_momentum.Initialize(m_sig_symbol, m_temam_timeframe, every_tick);

    //--- Createing filter EMA SLOW
    m_sig_emaf=new SignalMovingAverage();
    m_sig_emaf.Initialize(m_sig_symbol, m_temam_timeframe, every_tick);

    //--- Createing filter EMA MEDIUM
    m_sig_emam=new SignalMovingAverage();
    m_sig_emam.Initialize(m_sig_symbol, m_temam_timeframe, every_tick);

    //--- Createing filter EMA FAST
    m_sig_emas=new SignalMovingAverage();
    m_sig_emas.Initialize(m_sig_symbol, m_temam_timeframe, every_tick);

    //--- ok
    return(true);
}

bool SignalMain::InitIndicators(CIndicators *indicators) {
    //--- check pointer
    if(indicators==NULL)
        return(false);
    //--- initialization of indicators and timeseries of additional filters
    if(!CExpertSignal::InitIndicators(indicators))
        return(false);

    if(!m_sig_lsma.ValidationSettings())
        return false;
    m_sig_lsma.SetPriceSeries(m_open,m_high,m_low,m_close);
    m_sig_lsma.SetOtherSeries(m_spread,m_time,m_tick_volume,m_real_volume);
    if(!m_sig_lsma.InitIndicators(indicators))
        return(false);

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

    double d1 = Open(idx);

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
