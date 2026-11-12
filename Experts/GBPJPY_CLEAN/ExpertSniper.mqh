//+------------------------------------------------------------------+
//|                                                 ExpertSniper.mqh |
//|                                                  Mufraeli Rahman |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Mufraeli Rahman"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Expert/Expert.mqh>
#include "SignalMain.mqh"

//+------------------------------------------------------------------+
//| Class CExpertSniper                                              |
//| Purpose: Custom Expert Advisor class derived from CExpert        |
//|          attaching Pine Script strategy IDs as trade comments    |
//+------------------------------------------------------------------+
class CExpertSniper : public CExpert {
protected:
    SignalMain      *m_signal_main;
    string           m_comment_long;
    string           m_comment_short;

public:
                     CExpertSniper(void);
                    ~CExpertSniper(void);

    //--- Signal initialization override & explicit pointer setter
    virtual bool     InitSignal(CExpertSignal *signal=NULL);
    void             SignalMainPtr(SignalMain *signal)  { m_signal_main = signal; }
    SignalMain*      SignalMainPtr(void) const          { return m_signal_main; }

    //--- Trade open methods with comment support
    virtual bool     CheckOpenLong(void);
    virtual bool     CheckOpenShort(void);
    virtual bool     OpenLong(double price, double sl, double tp);
    virtual bool     OpenShort(double price, double sl, double tp);

    //--- Overloaded open methods accepting an explicit comment string
    virtual bool     OpenLong(double price, double sl, double tp, const string comment);
    virtual bool     OpenShort(double price, double sl, double tp, const string comment);

    //--- Comment setters and getters
    void             CommentLong(string comment)        { m_comment_long = comment; }
    void             CommentShort(string comment)       { m_comment_short = comment; }
    string           CommentLong(void) const            { return m_comment_long; }
    string           CommentShort(void) const           { return m_comment_short; }
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CExpertSniper::CExpertSniper(void)
    : m_signal_main(NULL),
      m_comment_long(""),
      m_comment_short("") {
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CExpertSniper::~CExpertSniper(void) {
}

//+------------------------------------------------------------------+
//| Initialize Signal object and store SignalMain pointer            |
//+------------------------------------------------------------------+
bool CExpertSniper::InitSignal(CExpertSignal *signal) {
    if(signal != NULL) {
        m_signal_main = dynamic_cast<SignalMain*>(signal);
        if(m_signal_main == NULL)
            m_signal_main = (SignalMain*)signal;
    }
    return(CExpert::InitSignal(signal));
}

//+------------------------------------------------------------------+
//| Check the possibility of opening a long position                 |
//+------------------------------------------------------------------+
bool CExpertSniper::CheckOpenLong(void) {
    if(m_signal == NULL)
        return(false);

    double   price=EMPTY_VALUE;
    double   sl=0.0;
    double   tp=0.0;
    datetime expiration=TimeCurrent();

    m_comment_long = "";

    //--- check the possibility of opening a long position
    if(m_signal.CheckOpenLong(price, sl, tp, expiration)) {
        // Retrieve the trade comment / strategy ID from SignalMain
        if(m_signal_main != NULL && StringLen(m_signal_main.ActiveLongId()) > 0)
            m_comment_long = m_signal_main.ActiveLongId();
        else
            m_comment_long = "Long";

        if(!m_trade.SetOrderExpiration(expiration)) {
            m_trade.SetTypeFillingBySymbol(m_symbol.Name());
            return(false);
        }
        return(OpenLong(price, sl, tp));
    }

    return(false);
}

//+------------------------------------------------------------------+
//| Check the possibility of opening a short position                |
//+------------------------------------------------------------------+
bool CExpertSniper::CheckOpenShort(void) {
    if(m_signal == NULL)
        return(false);

    double   price=EMPTY_VALUE;
    double   sl=0.0;
    double   tp=0.0;
    datetime expiration=TimeCurrent();

    m_comment_short = "";

    //--- check the possibility of opening a short position
    if(m_signal.CheckOpenShort(price, sl, tp, expiration)) {
        // Retrieve the trade comment / strategy ID from SignalMain
        if(m_signal_main != NULL && StringLen(m_signal_main.ActiveShortId()) > 0)
            m_comment_short = m_signal_main.ActiveShortId();
        else
            m_comment_short = "Short";

        if(!m_trade.SetOrderExpiration(expiration)) {
            m_trade.SetTypeFillingBySymbol(m_symbol.Name());
            return(false);
        }
        return(OpenShort(price, sl, tp));
    }

    return(false);
}

//+------------------------------------------------------------------+
//| Open long position with strategy ID as comment                   |
//+------------------------------------------------------------------+
bool CExpertSniper::OpenLong(double price, double sl, double tp) {
    string comment = m_comment_long;
    if(StringLen(comment) == 0 && m_signal_main != NULL)
        comment = m_signal_main.ActiveLongId();
    if(StringLen(comment) == 0)
        comment = "Long";

    return(OpenLong(price, sl, tp, comment));
}

//+------------------------------------------------------------------+
//| Open long position with explicit comment                         |
//+------------------------------------------------------------------+
bool CExpertSniper::OpenLong(double price, double sl, double tp, const string comment) {
    if(price == EMPTY_VALUE)
        return(false);

    //--- calculate lot size
    double lot = LotOpenLong(price, sl);
    if(lot == 0.0)
        return(false);

    //--- execute buy order with comment
    return(m_trade.Buy(lot, price, sl, tp, comment));
}

//+------------------------------------------------------------------+
//| Open short position with strategy ID as comment                  |
//+------------------------------------------------------------------+
bool CExpertSniper::OpenShort(double price, double sl, double tp) {
    string comment = m_comment_short;
    if(StringLen(comment) == 0 && m_signal_main != NULL)
        comment = m_signal_main.ActiveShortId();
    if(StringLen(comment) == 0)
        comment = "Short";

    return(OpenShort(price, sl, tp, comment));
}

//+------------------------------------------------------------------+
//| Open short position with explicit comment                        |
//+------------------------------------------------------------------+
bool CExpertSniper::OpenShort(double price, double sl, double tp, const string comment) {
    if(price == EMPTY_VALUE)
        return(false);

    //--- calculate lot size
    double lot = LotOpenShort(price, sl);
    if(lot == 0.0)
        return(false);

    //--- execute sell order with comment
    return(m_trade.Sell(lot, price, sl, tp, comment));
}
//+------------------------------------------------------------------+
