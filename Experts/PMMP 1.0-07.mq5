#property copyright "Quadri Adewale"
#property link      "waley.quad@gmail.com"
#property version   "1.00"

#define SUBJECT "PMMP"

#include <Trade\Trade.mqh>

enum ENUM_TRADES_ALLOWED {
    TA_BUY, // Buy Only
    TA_SELL, // Sell Only
    TA_BOTH, // Both
};

enum ENUM_USE_INDICATORS {
    UI_PSAR, // PSAR
    UI_MA, // MAs on MACD
    UI_PSAR_MA, // PSAR + MAs on MACD
};

input group "GENERAL SETTINGS"
input ENUM_USE_INDICATORS strategy = UI_PSAR; // Trading Strategy
input ENUM_TRADES_ALLOWED tradesAllowed = TA_BOTH; // Trades Allowed
input int magicNumber = 447; // Magic Number
int slippage = 10; // Slippage (points)
input int takeProfit = 20; // Take Profit (pips)
input int stopLoss = 20; // Stop Loss (pips)
input bool closeOnReversal = true; // Close trades on reversal
input bool usePSARTrailing = false; // Use PSAR Trailing Stop

input bool usePSARFilter1 = false; // Use PSAR Filter #1
input bool PSARFilter1_reverse = false; // -     Reverse Conditions
input ENUM_TIMEFRAMES PSARFilter_TF1 = PERIOD_H1; // -     Timeframe
input int PSARFilter_bar1 = 1; // -     PSAR Bar (0 - live, 1+ - closed)
input double PSARFilter_step1 = 0.02; // -     Step
input double PSARFilter_maximum1 = 0.2; // -     Maximum

input bool usePSARFilter2 = false; // Use PSAR Filter #2
input bool PSARFilter2_reverse = false; // -     Reverse Conditions
input ENUM_TIMEFRAMES PSARFilter_TF2 = PERIOD_H4; // -     Timeframe
input int PSARFilter_bar2 = 1; // -     PSAR Bar (0 - live, 1+ - closed)      
input double PSARFilter_step2 = 0.02; // -     Step
input double PSARFilter_maximum2 = 0.2; // -     Maximum

input int numTrades = 1; // Number of Trades
input double lotSize = 0.01; // Lot Size 

input group "."
input group "PSAR"
input double PSAR_step = 0.02; // Step
input double PSAR_maximum = 0.2; // Maximum
input group "."
input group "Fast Moving Average"
input int fastMA_period = 3; // Period
input ENUM_MA_METHOD fastMA_method = MODE_SMA; // Method
input group "Slow Moving Average"
input int slowMA_period = 10; // Period
input ENUM_MA_METHOD slowMA_method = MODE_SMA; // Method
input group "MACD"
input int MACD_fastEMA = 35; // Fast EMA
input int MACD_slowEMA = 40; // Slow EMA
input int MACD_SMA = 30; // MACD SMA
input ENUM_APPLIED_PRICE MACD_price = PRICE_CLOSE; // Apply to

input group "."
input group "ALERT SETTINGS"
input bool enableAlert = false; // Enable Alert
input bool enablePush = false; // Enable Push Notification
input bool enableEmail = false; // Enable E-mail Notification
input bool playSound = false; // Play Sound
input string soundName = "alert.wav"; // Sound Name

bool alertTakeProfit = true;
bool alertStopLoss = true;
bool alertNewOrders = true;
bool alertCloseOrders = true;

CTrade trade;
int mult = 1;
int PSAR_handle;
int PSARFilter1_handle;
int PSARFilter2_handle;
int MACD_handle;
datetime newBar = 0;
string varPrefix = "PMMP-";
datetime lastTrade = 0;

double iMAOnArrayMQL4(double &array[], int total, int period, int ma_shift, int ma_method, int shift) {
    double buf[], arr[];
    
    if (total == 0) total = ArraySize(array);
    if (total > 0 && total <= period) return 0;
    if (shift > total - period - ma_shift) return 0;
    
    switch (ma_method) {
        case MODE_SMA:
        {
            total = ArrayCopy(arr, array, 0, shift + ma_shift, period);
                
            if (ArrayResize(buf, total) < 0) return 0;
                
            double sum = 0;
            int i, pos = total - 1;
                
            for (i = 1; i < period; i ++, pos --)
                sum += arr[pos];
                
            while (pos >= 0) {
                sum += arr[pos];
                buf[pos] = sum / period;
                sum -= arr[pos + period - 1];
                pos --;
            }
                
            return buf[0];
        }
        break;
            
        case MODE_EMA:
        {
            if (ArrayResize(buf, total) < 0) return 0;
            
            double pr = 2.0 / (period + 1);
            int pos = total - 2;
            
            while (pos >= 0) {
                if (pos == total - 2) buf[pos + 1] = array[pos + 1];
                buf[pos] = array[pos] * pr + buf[pos + 1] * (1 - pr);
                pos --;
            }
            
            return buf[shift + ma_shift];
        }
        
        case MODE_SMMA:
        {
            if (ArrayResize(buf, total) < 0) return 0;
            
            double sum = 0;
            int i, k, pos;
            
            pos = total - period;
            
            while (pos >= 0) {
                if (pos == total - period) {
                    for(i = 0, k = pos; i < period; i ++, k ++) {
                        sum += array[k];
                        buf[k] = 0;
                    }
                }
                else {
                    sum = buf[pos + 1] * (period - 1) + array[pos];
                }    
                
                buf[pos] = sum / period;
                pos --;
            }
            
            return buf[shift + ma_shift];
        }
        
        case MODE_LWMA:
        {
            if (ArrayResize(buf, total) < 0) return 0;
            
            double sum = 0.0,lsum = 0.0;
            double price;
            int i, weight = 0,pos = total - 1;
            
            for (i = 1;i <= period; i ++, pos --) {
                price = array[pos];
                sum += price * i;
                lsum += price;
                weight += i;
            }
            
            pos ++;
            i = pos + period;
            
            while (pos >= 0) {
                buf[pos] = sum / weight;
                
                if (pos == 0) break;
                
                pos --;
                i --;
                price = array[pos];
                sum = sum - lsum + price * period;
                lsum -= array[i];
                lsum += price;
            }
            
            return buf[shift + ma_shift];
        }
        
        default: return 0;
    }
     
    return 0;
}
  
double getMAonMACD(int _period, ENUM_MA_METHOD _method, int bar = 1) {
    double array[];
    ArraySetAsSeries(array, true);

    if (CopyBuffer(MACD_handle, 0, 0, MathMin(500, iBars(NULL, 0)), array) < 0) {
        return EMPTY_VALUE;
    }

    return iMAOnArrayMQL4(array, 0, _period, 0, _method, bar);
}

double getMACD(int bar = 1, int var = 0) {
    double array[];
    ArraySetAsSeries(array, true);
  
    if (CopyBuffer(MACD_handle, var, bar, /*bar + */1, array) < 0) {
        return EMPTY_VALUE;
    }

    return array[0];
}

double getPSAR(int bar = 1) {
   double array[];
   ArraySetAsSeries(array, true);
  
    if (CopyBuffer(PSAR_handle, 0, bar, /*bar + */1, array) < 0) {
        return EMPTY_VALUE;
    }

    return array[0];
}

double getPSARFilter1(int bar = 1) {
   double array[];
   ArraySetAsSeries(array, true);
  
    if (CopyBuffer(PSARFilter1_handle, 0, bar, /*bar + */1, array) < 0) {
        return EMPTY_VALUE;
    }

    return array[0];
}

double getPSARFilter2(int bar = 1) {
   double array[];
   ArraySetAsSeries(array, true);
  
    if (CopyBuffer(PSARFilter2_handle, 0, bar, /*bar + */1, array) < 0) {
        return EMPTY_VALUE;
    }

    return array[0];
}

bool checkPSARFilter(ENUM_ORDER_TYPE _type) {
    if (usePSARFilter1 == false && usePSARFilter2 == false) {
        return true;
    }
    
    bool PSARFilter1_condition = usePSARFilter1 ? false : true;
    bool PSARFilter2_condition = usePSARFilter2 ? false : true;
    
    if (usePSARFilter1) {
        double psar1 = getPSARFilter1(PSARFilter_bar1);
        double close1 = iClose(NULL, PSARFilter_TF1, PSARFilter_bar1);
        
        switch (_type) {
            case ORDER_TYPE_BUY:
                PSARFilter1_condition = PSARFilter1_reverse ? close1 < psar1 : close1 > psar1;
            break;
            
            case ORDER_TYPE_SELL:
                PSARFilter1_condition = PSARFilter1_reverse ? close1 > psar1 : close1 < psar1;
            break;
        }
    }

    if (usePSARFilter2) {
        double psar1 = getPSARFilter2(PSARFilter_bar2);
        double close1 = iClose(NULL, PSARFilter_TF2, PSARFilter_bar2);
        
        switch (_type) {
            case ORDER_TYPE_BUY:
                PSARFilter2_condition = PSARFilter2_reverse ? close1 < psar1 : close1 > psar1;
            break;
            
            case ORDER_TYPE_SELL:
                PSARFilter2_condition = PSARFilter2_reverse ? close1 > psar1 : close1 < psar1;
            break;
        }
    }
            
    return PSARFilter1_condition && PSARFilter2_condition;
}

bool checkSignal(ENUM_ORDER_TYPE _type, int bar = 1) {
    if (strategy == UI_PSAR) {
        double close1 = iClose(NULL, 0, bar);
        double close2 = iClose(NULL, 0, bar + 1);
        double psar1 = getPSAR(bar);
        double psar2 = getPSAR(bar + 1);
        
        return _type == ORDER_TYPE_BUY ? close1 > psar1 && close2 < psar2 : close1 < psar1 && close2 > psar2;
    }
    
    if (strategy == UI_MA || strategy == UI_PSAR_MA) {
        double fastMA1 = getMAonMACD(fastMA_period, fastMA_method, bar);
        double slowMA1 = getMAonMACD(slowMA_period, slowMA_method, bar);
        double fastMA2 = getMAonMACD(fastMA_period, fastMA_method, bar + 1);
        double slowMA2 = getMAonMACD(slowMA_period, slowMA_method, bar + 1);
        
        if (strategy == UI_MA) {
            return _type == ORDER_TYPE_BUY ? fastMA2 <= slowMA2 && fastMA1 > slowMA1 : fastMA2 >= slowMA2 && fastMA1 < slowMA1;
        }
        
        double close1 = iClose(NULL, 0, bar);
        double psar1 = getPSAR(bar);

        return _type == ORDER_TYPE_BUY ? fastMA2 <= slowMA2 && fastMA1 > slowMA1 && close1 > psar1 : fastMA2 >= slowMA2 && fastMA1 < slowMA1 && close1 < psar1;
    }
    
    return false;
}

bool isLongSignal(int bar = 1) {
    return checkSignal(ORDER_TYPE_BUY, bar);
}

bool isShortSignal(int bar = 1) {
    return checkSignal(ORDER_TYPE_SELL, bar);
}

int OnInit() {
    newBar = 0;
    
    PSAR_handle = iSAR(_Symbol, _Period, PSAR_step, PSAR_maximum);
        
    if (PSAR_handle == INVALID_HANDLE) {
        PrintFormat("Failed to create handle of the iSAR indicator for the symbol %s(%s), error code %d", _Symbol, TF2Str(_Period), GetLastError());        
            
        return INIT_FAILED;
    }
    
    if (usePSARFilter1) {
        PSARFilter1_handle = iSAR(_Symbol, PSARFilter_TF1, PSARFilter_step1, PSARFilter_maximum1);
        
        if (PSARFilter1_handle == INVALID_HANDLE) {
            PrintFormat("Failed to create handle of the iSAR indicator for the symbol %s(%s), error code %d", _Symbol, TF2Str(PSARFilter_TF1), GetLastError());        
                
            return INIT_FAILED;
        }
    }
    
    if (usePSARFilter2) {
        PSARFilter2_handle = iSAR(_Symbol, PSARFilter_TF2, PSARFilter_step2, PSARFilter_maximum2);
        
        if (PSARFilter2_handle == INVALID_HANDLE) {
            PrintFormat("Failed to create handle of the iSAR indicator for the symbol %s(%s), error code %d", _Symbol, TF2Str(PSARFilter_TF1), GetLastError());        
                
            return INIT_FAILED;
        }
    }
    
    if (strategy == UI_MA || strategy == UI_PSAR_MA) {
        MACD_handle = iMACD(_Symbol, _Period, MACD_fastEMA, MACD_slowEMA, MACD_SMA, MACD_price);
        
        if (MACD_handle == INVALID_HANDLE) {
            PrintFormat("Failed to create handle of the iMACD indicator for the symbol %s(%s), error code %d", _Symbol, TF2Str(_Period), GetLastError());        
            
            return INIT_FAILED;
        }
    }
        
    trade.SetDeviationInPoints(slippage);
    trade.SetExpertMagicNumber(magicNumber);

    if (_Digits % 2 == 1) {    
        mult = 10;
    }
    
    lastTrade = restoreLastTrade();
    
    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
    if (MQLInfoInteger(MQL_TESTER) == true) {
        GlobalVariablesDeleteAll(varPrefix);
    }
}

bool isAllowed(ENUM_ORDER_TYPE _type) {
    if (_type == ORDER_TYPE_BUY) {
        return tradesAllowed == TA_BOTH || tradesAllowed == TA_BUY;
    }
    
    return tradesAllowed == TA_BOTH || tradesAllowed == TA_SELL;
}

void saveLastTrade(datetime dt) {
    GlobalVariableSet(varPrefix + _Symbol + "-" + TF2Str(_Period) + "-LT", dt);
}

datetime restoreLastTrade() {
    string name = varPrefix + _Symbol + "-" + TF2Str(_Period) + "-LT";
    
    return GlobalVariableCheck(name) ? (datetime)GlobalVariableGet(name) : 0;
}

void OnTick() {
    if (newBar != iTime(NULL, 0, 0)) {
        if (isLongSignal(1)) {
            if (closeOnReversal && getOrdersByType(ORDER_TYPE_SELL, magicNumber) > 0) {
                closeOrdersByType(ORDER_TYPE_SELL, magicNumber);
                
                if (alertCloseOrders) {
                    sendMessage(SUBJECT, "Sell order(s) have been closed due to reversal");
                }
            }
            
            if (isAllowed(ORDER_TYPE_BUY) && lastTrade != iTime(NULL, 0, 0) && checkPSARFilter(ORDER_TYPE_BUY)) {
                placeOrders(ORDER_TYPE_BUY);
                
                if (alertNewOrders) {
                    sendMessage(SUBJECT, "Buy order(s) have been placed");
                }
                
                lastTrade = iTime(NULL, 0, 0);
                saveLastTrade(lastTrade);
            }    
        }
        
        if (isShortSignal(1)) {
            if (closeOnReversal && getOrdersByType(ORDER_TYPE_BUY, magicNumber) > 0) {
                closeOrdersByType(ORDER_TYPE_BUY, magicNumber);

                if (alertCloseOrders) {
                    sendMessage(SUBJECT, "Buy order(s) have been closed due to reversal");
                }
            }
            
            if (isAllowed(ORDER_TYPE_SELL) && lastTrade != iTime(NULL, 0, 0) && checkPSARFilter(ORDER_TYPE_SELL)) {
                placeOrders(ORDER_TYPE_SELL);

                if (alertNewOrders) {
                    sendMessage(SUBJECT, "Sell order(s) have been placed");
                }

                lastTrade = iTime(NULL, 0, 0);
                saveLastTrade(lastTrade);
            }    
        }
        
        if (usePSARTrailing) {
            manageTS();
        }    
    }
    newBar = iTime(NULL, 0, 0);
}

void OnTrade(void) {
    //Print("ON TRADE");
}

void  OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &request, const MqlTradeResult &result) {
    if (trans.type == TRADE_TRANSACTION_DEAL_ADD) {
        long entry = 0;
        long reason = 0;

        if (HistoryDealSelect(trans.deal)) {
            entry = HistoryDealGetInteger(trans.deal, DEAL_ENTRY);
            reason = HistoryDealGetInteger(trans.deal, DEAL_REASON);
            
            if (alertTakeProfit && entry == DEAL_ENTRY_OUT && reason == DEAL_REASON_TP) {
                sendMessage(SUBJECT, "Order #" + IntegerToString(trans.order) + " has been closed by take profit");
            }
            
            if (alertStopLoss && entry == DEAL_ENTRY_OUT && reason == DEAL_REASON_SL) {
                sendMessage(SUBJECT, "Order #" + IntegerToString(trans.order) + " has been closed by stop loss");
            }
        }       
    }
}

void manageTS() {
    double psar = getPSAR(1);
    double close = iClose(NULL, 0, 1);
    
    ENUM_ORDER_TYPE allowed = close > psar ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
    
    for (int i = 0; i < PositionsTotal(); i ++) {
        ulong ticket = PositionGetTicket(i);
        if (ticket == 0) continue;
        if (PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
        if (PositionGetInteger(POSITION_MAGIC) != magicNumber) continue;
        if (PositionGetInteger(POSITION_TYPE) != allowed) continue;
        
        double SL = PositionGetDouble(POSITION_SL);
        double th = 1 * mult * _Point;
        
        if (PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_BUY && (psar > SL + th || SL == 0.0) && psar < SymbolInfoDouble(_Symbol, SYMBOL_ASK)) {
            trade.PositionModify(ticket, NormalizeDouble(psar, _Digits), PositionGetDouble(POSITION_TP));
        }
        else if (PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_SELL && (psar < SL - th || SL == 0.0) && psar > SymbolInfoDouble(_Symbol, SYMBOL_BID)) {
            trade.PositionModify(ticket, NormalizeDouble(psar, _Digits), PositionGetDouble(POSITION_TP));
        }
    }    
}

string TF2Str(ENUM_TIMEFRAMES tf) {
    switch (tf) {
        case PERIOD_M1: return("M1"); 
        case PERIOD_M5: return("M5");
        case PERIOD_M15: return("M15");
        case PERIOD_M30: return("M30");
        case PERIOD_H1: return("H1");
        case PERIOD_H4: return("H4");
        case PERIOD_D1: return("D1");
        case PERIOD_W1: return("W1");
        case PERIOD_MN1: return("MN1");
        default: return "";
    }
}

void closeOrdersByType(int _type, int _magic) {
    while (getOrdersByType(_type, _magic) != 0) {
        int total = PositionsTotal();
   
        for (int i = 0; i < total; i ++) {
            ulong ticket = PositionGetTicket(i);
            if (ticket == 0) continue;
            
            if (PositionGetInteger(POSITION_MAGIC) == _magic && PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_TYPE) == _type) {
                if (PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_SELL || PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_BUY) {                
                    trade.PositionClose(ticket);                  
                }
            }
        }
    }        
}

int getOrdersByType(int _type, int _magic) {
    int _orders = 0;
    
    for (int i = PositionsTotal() - 1; i >= 0; i --) {
        ulong ticket = PositionGetTicket(i);
        if (ticket == 0) continue;

        if (PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
        if (PositionGetInteger(POSITION_MAGIC) != _magic) continue;
        
        if (PositionGetInteger(POSITION_TYPE) == _type) {
            _orders ++;
        }
    }    
    
    return _orders;
}

int getOrders(int _magic) {
    return getOrdersByType(ORDER_TYPE_BUY, _magic) + getOrdersByType(ORDER_TYPE_SELL, _magic);
}

void placeOrders(ENUM_ORDER_TYPE _type) {
    for (int i = 0; i < numTrades; i ++) {
        placeOrder(_type, takeProfit * mult, stopLoss * mult, lotSize);
    }
}

int placeOrder(int _type, int _takeProfit, int _stopLoss, double _lotSize) {
    int newTicket = -1;
    
    if (_type == ORDER_TYPE_BUY) {
        double SL = _stopLoss > 0 ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) - _stopLoss * _Point : 0;
        double TP = _takeProfit > 0 ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) + _takeProfit * _Point : 0;
         
        if (trade.PositionOpen(_Symbol, ORDER_TYPE_BUY, _lotSize, SymbolInfoDouble(_Symbol, SYMBOL_ASK), 
            NormalizeDouble(SL, _Digits), NormalizeDouble(TP, _Digits))) {
            newTicket = (int)trade.ResultOrder();
        }
        else {
            Print("place Order error: ", GetLastError());
        }
    }
    else if (_type == ORDER_TYPE_SELL) {    
        double SL = _stopLoss > 0 ? SymbolInfoDouble(_Symbol, SYMBOL_BID) + _stopLoss * _Point : 0;
        double TP = _takeProfit > 0 ? SymbolInfoDouble(_Symbol, SYMBOL_BID) - _takeProfit * _Point : 0;    
        
        if (trade.PositionOpen(_Symbol, ORDER_TYPE_SELL, _lotSize, SymbolInfoDouble(_Symbol, SYMBOL_BID), 
            NormalizeDouble(SL, _Digits), NormalizeDouble(TP, _Digits))) {
            newTicket = (int)trade.ResultOrder();
        }
        else {
            Print("place Order error: ", GetLastError());
        }
    }
    
    return newTicket;
}

void sendMessage(string subject, string message) {
    if (playSound) {
        PlaySound(soundName);
    }
    
    if (enablePush) {
        SendNotification(message);
    }
                            
    if (enableAlert) {
        Alert(message);
    }
                            
    if (enableEmail) {
        SendMail(subject, message);
    }
}
