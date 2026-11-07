//+------------------------------------------------------------------+
//|                                             SignalConsolidation.mq5 |
//|                                                  Mufraeli Rahman |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Mufraeli Rahman"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Expert/ExpertSignal.mqh>
#include <MovingAverages.mqh>
#include "Helper.mqh"

class SignalConsolidation: public CExpertSignal {
    protected:
        CSignalExporter   m_exporter;

        //--- adjusted parameters
        string            m_cons_symbol;
        int               m_cons_lookback_long;
        int               m_cons_length_long;
        int               m_cons_lookback_short;
        int               m_cons_length_short;
        bool              m_long_condition;
        bool              m_short_condition;

    public:
        SignalConsolidation(void);
       ~SignalConsolidation(void);

        //--- export methods
        void              EnableExport(bool enable, bool common_folder = false) { m_exporter.Enable(enable, common_folder); }
        void              ExportFilename(string filename)                       { m_exporter.SetFilename(filename); }
        void              ExportConditions(void) {
            datetime dt = (m_time != NULL && m_time.GetData(0) > 0) ? m_time.GetData(0) : iTime(m_symbol != NULL ? m_symbol.Name() : _Symbol, m_period, 0);
            m_exporter.Export(dt);
        }

        //--- methods of setting adjustable indicator parameters
        void              ConsSymbol(string value)             { m_cons_symbol=value;            }
        void              ConsTimeframe(int value)             { m_period=value;                 }
        void              ConsLookbackLong(int value)          { m_cons_lookback_long=value;     }
        void              ConsLengthLong(int value)            { m_cons_length_long=value;       }
        void              ConsLookbackShort(int value)         { m_cons_lookback_short=value;    }
        void              ConsLengthShort(int value)           { m_cons_length_short=value;      }

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
SignalConsolidation::SignalConsolidation(void) {
    //--- initialization of protected data
    m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
    m_cons_symbol="";
    m_cons_lookback_long=16;
    m_cons_length_long=7;
    m_cons_lookback_short=8;
    m_cons_length_short=2;
    m_long_condition=false;
    m_short_condition=false;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
SignalConsolidation::~SignalConsolidation(void){
}

bool SignalConsolidation::Initialize(string symbol,int period,bool every_tick) {
    if(m_symbol==NULL) {
        if((m_symbol=new CSymbolInfo)==NULL)
            return(false);
    }
    if(!m_symbol.Name(symbol))
        return(false);
    m_cons_symbol = symbol;
    m_period      =period;
    m_every_tick  =every_tick;

    CExpertBase::Init(m_symbol, (ENUM_TIMEFRAMES)period, 1);

    return (true);
}

//+------------------------------------------------------------------+
//| Validation settings protected data.                              |
//+------------------------------------------------------------------+
bool SignalConsolidation::ValidationSettings(void) {
    //--- validation settings of additional filters
    if(!CExpertSignal::ValidationSettings())
        return(false);
    if(m_cons_lookback_long<=0 || m_cons_length_long<=0 || m_cons_lookback_short<=0 || m_cons_length_short<=0) {
        printf(__FUNCTION__+": Consolidation parameters must be greater than 0");
        return(false);
    }
    //--- ok
    return(true);
}

//+------------------------------------------------------------------+
//| "Voting" that price will grow.                                   |
//+------------------------------------------------------------------+
int SignalConsolidation::LongCondition(void) {
    int result=0;
    int idx   =StartIndex();
    
    MqlRates rates[];
    double high[];
    double low[];
    double close[];
    int bars = BarsCustom(m_cons_symbol, m_period);
    CopyRatesCustom(m_cons_symbol, m_period, 0, m_cons_lookback_long, rates);
    CopyHighFromMqlRates(rates, high);
    CopyLowFromMqlRates(rates, low);
    CopyCloseFromMqlRates(rates, close);
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(close, true);

    double hb_[]; 
    PivotHighOnBuffer(m_cons_lookback_long-1, 0, high, hb_);
    double lb_[];
    PivotLowOnBuffer(m_cons_lookback_long-1, 0, low, lb_);
    int dir[];
    double zz[];
    double pp[];
    InitializeArray(dir, ArraySize(high), 0);
    InitializeArray(zz, ArraySize(high), 0);
    InitializeArray(pp, ArraySize(high), 0);

    for (int i=0; i<ArraySize(hb_); i++) {
        dir[i] = (hb_[i] != EMPTY_VALUE && lb_[i] == EMPTY_VALUE) ? 1 : (hb_[i] == EMPTY_VALUE && lb_[i] != EMPTY_VALUE) ? -1 : 0;
        if (hb_[i] != EMPTY_VALUE && lb_[i] != EMPTY_VALUE) {
            if (dir[i] == 1) {
                zz[i] = hb_[i];
            }
            else {
                zz[i] = lb_[i];
            }
        }
        else {
            zz[i] = hb_[i] != EMPTY_VALUE ? hb_[i] : lb_[i] != EMPTY_VALUE ? lb_[i] : EMPTY_VALUE;
        }
    }

    ArraySetAsSeries(dir, true);
    ArraySetAsSeries(zz, true);
    ArraySetAsSeries(pp, true);
    int conscnt = 0;
    double condhigh = 0;
    double condlow = 0;
    for (int i=0; i<ArraySize(high); i++) {
        for (int x=0; x<ArraySize(high)-i; x++) {
            if (dir[i] != dir[i+x]) {
                break;
            }
            if (zz[x] != EMPTY_VALUE) {
                if (pp[i] == EMPTY_VALUE) {
                    pp[i] = zz[x];
                }
                else {
                    if (dir[x] == 1 && zz[x] > pp[i]) {
                        pp[i] = zz[x];
                    }
                    if (dir[x] == -1 && zz[x] < pp[i]) {
                        pp[i] = zz[x];
                    }
                }
            }
        }

        if (i >= ArraySize(high)-1) {
            break;
        }
        if (pp[i] != pp[i+1]) {
            if (conscnt > 0 && pp[i] <= condhigh && pp[i] >= condlow) {
                conscnt += 1;
            }
            else {
                conscnt = 0;
            }
        }
        else {
            conscnt += 1;
        }
    }

    result = conscnt > m_cons_length_long ? 100 : 0;

    m_exporter.UpdateLong(result);
    ExportConditions();

    //--- return the result
    return(result);
}

//+------------------------------------------------------------------+
//| "Voting" that price will fall.                                   |
//+------------------------------------------------------------------+
int SignalConsolidation::ShortCondition(void) {
    int result=0;
    int idx   =StartIndex();
    
    MqlRates rates[];
    double high[];
    double low[];
    double close[];
    int bars = BarsCustom(m_cons_symbol, m_period);
    CopyRatesCustom(m_cons_symbol, m_period, 0, m_cons_lookback_short, rates);
    CopyHighFromMqlRates(rates, high);
    CopyLowFromMqlRates(rates, low);
    CopyCloseFromMqlRates(rates, close);
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(close, true);

    double hb_[]; 
    PivotHighOnBuffer(m_cons_lookback_short-1, 0, high, hb_);
    double lb_[];
    PivotLowOnBuffer(m_cons_lookback_short-1, 0, low, lb_);
    int dir[];
    double zz[];
    double pp[];
    InitializeArray(dir, ArraySize(high), 0);
    InitializeArray(zz, ArraySize(high), 0);
    InitializeArray(pp, ArraySize(high), 0);

    for (int i=0; i<ArraySize(hb_); i++) {
        dir[i] = (hb_[i] != EMPTY_VALUE && lb_[i] == EMPTY_VALUE) ? 1 : (hb_[i] == EMPTY_VALUE && lb_[i] != EMPTY_VALUE) ? -1 : 0;
        if (hb_[i] != EMPTY_VALUE && lb_[i] != EMPTY_VALUE) {
            if (dir[i] == 1) {
                zz[i] = hb_[i];
            }
            else {
                zz[i] = lb_[i];
            }
        }
        else {
            zz[i] = hb_[i] != EMPTY_VALUE ? hb_[i] : lb_[i] != EMPTY_VALUE ? lb_[i] : EMPTY_VALUE;
        }
    }

    ArraySetAsSeries(dir, true);
    ArraySetAsSeries(zz, true);
    ArraySetAsSeries(pp, true);
    int conscnt = 0;
    double condhigh = 0;
    double condlow = 0;
    for (int i=0; i<ArraySize(high); i++) {
        for (int x=0; x<ArraySize(high)-i; x++) {
            if (dir[i] != dir[i+x]) {
                break;
            }
            if (zz[x] != EMPTY_VALUE) {
                if (pp[i] == EMPTY_VALUE) {
                    pp[i] = zz[x];
                }
                else {
                    if (dir[x] == 1 && zz[x] > pp[i]) {
                        pp[i] = zz[x];
                    }
                    if (dir[x] == -1 && zz[x] < pp[i]) {
                        pp[i] = zz[x];
                    }
                }
            }
        }

        if (i >= ArraySize(high)-1) {
            break;
        }
        if (pp[i] != pp[i+1]) {
            if (conscnt > 0 && pp[i] <= condhigh && pp[i] >= condlow) {
                conscnt += 1;
            }
            else {
                conscnt = 0;
            }
        }
        else {
            conscnt += 1;
        }
    }

    result = conscnt > m_cons_length_short ? 100 : 0;

    m_exporter.UpdateShort(result);
    ExportConditions();

    //--- return the result
    return(result);
}
//+------------------------------------------------------------------+
