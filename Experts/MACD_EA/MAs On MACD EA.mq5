// Complete EA with MA on MACD module and all features retained
#property copyright "Forexcoders Hub"
#property link      "fxcodershubs@gmail.com"
#property version   "1.0"

#include <Trade\Trade.mqh>

// Enums
enum ENUM_TRADES_ALLOWED {
    TA_BUY,  // Buy Only
    TA_SELL, // Sell Only
    TA_BOTH, // Both
};

enum ENUM_USE_INDICATORS {
    UI_PSAR,    // PSAR
    UI_MA,      // MAs on MACD
    UI_PSAR_MA, // PSAR + MAs on MACD
};

input group "GENERAL SETTINGS"
input ENUM_USE_INDICATORS strategy = UI_MA; // Trading Strategy
input ENUM_TRADES_ALLOWED tradesAllowed = TA_BOTH; // Trades Allowed
input int magicNumber = 447; // Magic Number
int slippage = 10; // Slippage (points)
input int numTrades = 1; // Number of Trades
input double lotSize = 0.01; // Lot Size
input int takeProfit = 20; // Take Profit (pips)
input int stopLoss = 20; // Stop Loss (pips)
input bool closeOnReversal = true; // Close trades on reversal
input bool usePSARTrailing = false; // Use PSAR Trailing Stop

input group "PSAR SETTINGS"
input bool usePSARFilter1 = false; // Use PSAR Filter #1
input bool PSARFilter1_reverse = false; // Reverse Conditions #1
input ENUM_TIMEFRAMES PSARFilter_TF1 = PERIOD_H1; // Timeframe #1
input int PSARFilter_bar1 = 1; // PSAR Bar (0 - live, 1+ - closed) #1
input double PSARFilter_step1 = 0.02; // PSAR Step #1
input double PSARFilter_maximum1 = 0.2; // PSAR Maximum #1

input bool usePSARFilter2 = false; // Use PSAR Filter #2
input bool PSARFilter2_reverse = false; // Reverse Conditions #2
input ENUM_TIMEFRAMES PSARFilter_TF2 = PERIOD_H4; // Timeframe #2
input int PSARFilter_bar2 = 1; // PSAR Bar (0 - live, 1+ - closed) #2
input double PSARFilter_step2 = 0.02; // PSAR Step #2
input double PSARFilter_maximum2 = 0.2; // PSAR Maximum #2

input double PSAR_step = 0.02; // PSAR Step for Trailing Stop
input double PSAR_maximum = 0.2; // PSAR Maximum for Trailing Stop

input group "MOVING AVERAGE SETTINGS"
input int fastMA_period = 3; // Fast MA Period
input ENUM_MA_METHOD fastMA_method = MODE_SMA; // Fast MA Method
input int slowMA_period = 10; // Slow MA Period
input ENUM_MA_METHOD slowMA_method = MODE_SMA; // Slow MA Method

input group "MACD SETTINGS"
input int MACD_fastEMA = 35; // MACD Fast EMA
input int MACD_slowEMA = 40; // MACD Slow EMA
input int MACD_signalSMA = 30; // MACD Signal SMA
input ENUM_APPLIED_PRICE MACD_price = PRICE_CLOSE; // MACD Apply to
input int MA1_period = 1; // Fast MA on MACD Histogram
input int MA2_period = 3; // Slow MA on MACD Histogram
input ENUM_MA_METHOD MA_method = MODE_SMA; // MA Method on MACD Histogram

input group "MULTI-TIMEFRAME SETTINGS"
input ENUM_TIMEFRAMES T1 = PERIOD_M5;   // Timeframe 1
input ENUM_TIMEFRAMES T2 = PERIOD_M15; // Timeframe 2
input ENUM_TIMEFRAMES T3 = PERIOD_H1;  // Timeframe 3

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
int MACD_handle;
datetime newBar = 0;
datetime lastTrade = 0;

// Function to calculate MA on array
double calculateMAOnArray(const double &array[], int period, ENUM_MA_METHOD method, int bar) {
    int size = ArraySize(array);
    if (size <= period) return 0;

    double sum = 0.0;
    for (int i = 0; i < period; i++) {
        sum += array[bar + i];
    }

    switch (method) {
        case MODE_SMA:
            return sum / period;
        default:
            return 0; // Implement other methods as needed
    }
}

// Function to validate direction alignment across timeframes
bool isDirectionAligned(ENUM_ORDER_TYPE type) {
    double macdHist_T1[], macdHist_T2[], macdHist_T3[];

    if (CopyBuffer(MACD_handle, 0, 0, 1, macdHist_T1) < 0 ||
        CopyBuffer(MACD_handle, 0, 0, 1, macdHist_T2) < 0 ||
        CopyBuffer(MACD_handle, 0, 0, 1, macdHist_T3) < 0) {
        Print("Error: Unable to copy MACD buffer for direction alignment.");
        return false;
    }

    bool T1_up = macdHist_T1[0] > 0;
    bool T2_up = macdHist_T2[0] > 0;
    bool T3_up = macdHist_T3[0] > 0;

    bool T1_down = macdHist_T1[0] < 0;
    bool T2_down = macdHist_T2[0] < 0;
    bool T3_down = macdHist_T3[0] < 0;

    if (type == ORDER_TYPE_BUY) {
        Print("Direction Alignment: BUY - T1=", T1_up, " T2=", T2_up, " T3=", T3_up);
        return T1_up && T2_up && T3_up;
    }
    if (type == ORDER_TYPE_SELL) {
        Print("Direction Alignment: SELL - T1=", T1_down, " T2=", T2_down, " T3=", T3_down);
        return T1_down && T2_down && T3_down;
    }

    return false;
}

// Function to check entry signal based on MA crossing on MACD histogram
bool checkMAonMACD(ENUM_ORDER_TYPE type, int bar = 1) {
    double macdHist[];
    ArraySetAsSeries(macdHist, true);

    if (CopyBuffer(MACD_handle, 0, 0, MathMin(500, iBars(NULL, 0)), macdHist) < 0) {
        Print("Error: Unable to copy MACD histogram buffer.");
        return false;
    }

    double fastMA = calculateMAOnArray(macdHist, MA1_period, MA_method, bar);
    double slowMA = calculateMAOnArray(macdHist, MA2_period, MA_method, bar);

    double fastMA_prev = calculateMAOnArray(macdHist, MA1_period, MA_method, bar + 1);
    double slowMA_prev = calculateMAOnArray(macdHist, MA2_period, MA_method, bar + 1);

    if (type == ORDER_TYPE_BUY) {
        Print("MA on MACD Check: BUY - FastMA=", fastMA, " SlowMA=", slowMA);
        return fastMA_prev <= slowMA_prev && fastMA > slowMA;
    }
    if (type == ORDER_TYPE_SELL) {
        Print("MA on MACD Check: SELL - FastMA=", fastMA, " SlowMA=", slowMA);
        return fastMA_prev >= slowMA_prev && fastMA < slowMA;
    }

    return false;
}

// Function to check for opposite signal for trade exit
bool checkOppositeSignal(ENUM_ORDER_TYPE currentType, int bar = 1) {
    ENUM_ORDER_TYPE oppositeType = (currentType == ORDER_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;

    if (checkMAonMACD(oppositeType, bar) && isDirectionAligned(oppositeType)) {
        Print("Opposite Signal Detected: ", (oppositeType == ORDER_TYPE_BUY ? "Buy" : "Sell"));
        return true;
    }
    return false;
}

// Function to send alerts
void sendAlert(string message) {
    Print("Alert: ", message);
    if (enableAlert) Alert(message);
    if (enablePush) SendNotification(message);
    if (enableEmail) SendMail("EA Alert", message);
    if (playSound) PlaySound(soundName);
}

// Function to close all positions
void closeAllPositions() {
    for (int i = PositionsTotal() - 1; i >= 0; i--) {
        if (PositionGetTicket(i)) {
            string symbol = PositionGetString(POSITION_SYMBOL);
            double lotSizePosition = PositionGetDouble(POSITION_VOLUME);

            if (symbol == _Symbol) {
                ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
                if (trade.PositionClose(symbol)) {
                    Print("Closed Position: Symbol=", symbol, " Type=", (type == POSITION_TYPE_BUY ? "Buy" : "Sell"), " Lot=", lotSizePosition);
                } else {
                    Print("Failed to Close Position: Symbol=", symbol, " Error=", GetLastError());
                }
            }
        }
    }
}

// Function to apply PSAR trailing stop
void applyPSARTrailing() {
    if (!usePSARTrailing || !PositionSelect(_Symbol)) return; // Ensure trailing stop is enabled and a position exists

    double PSAR_value = iSAR(_Symbol, _Period, PSAR_step, PSAR_maximum);
    if (PSAR_value == EMPTY_VALUE) {
        Print("Error: Invalid PSAR value.");
        return; // Exit if PSAR is not calculated correctly
    }

    ENUM_POSITION_TYPE positionType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    double currentSL = PositionGetDouble(POSITION_SL);
    double positionPrice = PositionGetDouble(POSITION_PRICE_OPEN);

    double newSL = 0;
    if (positionType == POSITION_TYPE_BUY) {
        if (PSAR_value > positionPrice || PSAR_value <= currentSL) return;
        newSL = NormalizeDouble(PSAR_value, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS));
    } else if (positionType == POSITION_TYPE_SELL) {
        if (PSAR_value < positionPrice || PSAR_value >= currentSL) return;
        newSL = NormalizeDouble(PSAR_value, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS));
    }

    if (trade.PositionModify(_Symbol, newSL, PositionGetDouble(POSITION_TP))) {
        Print("Trailing Stop Updated: New SL = ", newSL);
    } else {
        Print("Error: Failed to update trailing stop. Price: ", newSL);
    }
}

int OnInit() {
    MACD_handle = iMACD(_Symbol, _Period, MACD_fastEMA, MACD_slowEMA, MACD_signalSMA, MACD_price);

    if (MACD_handle == INVALID_HANDLE) {
        Print("Failed to create MACD handle.");
        return INIT_FAILED;
    }

    trade.SetDeviationInPoints(slippage);
    trade.SetExpertMagicNumber(magicNumber);
    lastTrade = restoreLastTrade();
    Print("EA Initialized Successfully.");
    return INIT_SUCCEEDED;
}

void OnTick() {
    if (newBar != iTime(NULL, 0, 0)) {
        newBar = iTime(NULL, 0, 0);

        // Check for open position
        if (PositionSelect(_Symbol)) {
            ENUM_POSITION_TYPE currentType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            Print("Existing Position Found: Type=", (currentType == POSITION_TYPE_BUY ? "Buy" : "Sell"), " Volume=", PositionGetDouble(POSITION_VOLUME));

            // Check for reversal condition
            if (closeOnReversal && checkOppositeSignal((currentType == POSITION_TYPE_BUY) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, 1)) {
                Print("Reversal Condition Met. Closing Current Trades.");
                closeAllPositions();
                Print("Reversal Exit Completed. Resuming Check for New Entries.");
                return; // Wait for the next tick to check for new entries
            }
        } else {
            // No position, check for new entry signals
            ENUM_ORDER_TYPE type = ORDER_TYPE_BUY;
            if (checkMAonMACD(type, 1) && isDirectionAligned(type)) {
                Print("Buy Signal Validated. Placing Orders.");
                placeOrders(type);
                lastTrade = iTime(NULL, 0, 0);
                saveLastTrade(lastTrade);
                sendAlert("New Buy Order Placed");
            } else {
                type = ORDER_TYPE_SELL;
                if (checkMAonMACD(type, 1) && isDirectionAligned(type)) {
                    Print("Sell Signal Validated. Placing Orders.");
                    placeOrders(type);
                    lastTrade = iTime(NULL, 0, 0);
                    saveLastTrade(lastTrade);
                    sendAlert("New Sell Order Placed");
                } else {
                    Print("No Valid Entry Signal Detected on Current Tick.");
                }
            }
        }
    }

    applyPSARTrailing();
    Print("Tick Processed: Time=", TimeToString(TimeCurrent()), " Open Positions=", PositionsTotal());
}

void placeOrders(ENUM_ORDER_TYPE type) {
    for (int i = 0; i < numTrades; i++) {
        int ticket = placeOrder(type, takeProfit * Point(), stopLoss * Point(), lotSize);
        if (ticket != -1) {
            Print("Order Placed Successfully. Ticket=", ticket);
        } else {
            Print("Error Placing Order. Type=", type, " Volume=", lotSize);
        }
    }
}

int placeOrder(ENUM_ORDER_TYPE type, double localTakeProfit, double localStopLoss, double orderLotSize) {
    int newTicket = -1;

    if (type == ORDER_TYPE_BUY) {
        double sl = localTakeProfit > 0 ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) - localTakeProfit : 0;
        double tp = localTakeProfit > 0 ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) + localTakeProfit : 0;
        Print("Placing Buy Order: SL=", sl, " TP=", tp);
        if (trade.PositionOpen(_Symbol, type, orderLotSize, SymbolInfoDouble(_Symbol, SYMBOL_ASK), sl, tp)) {
            newTicket = (int)trade.ResultOrder();
        }
    } else if (type == ORDER_TYPE_SELL) {
        double sl = localTakeProfit > 0 ? SymbolInfoDouble(_Symbol, SYMBOL_BID) + localTakeProfit : 0;
        double tp = localTakeProfit > 0 ? SymbolInfoDouble(_Symbol, SYMBOL_BID) - localTakeProfit : 0;
        Print("Placing Sell Order: SL=", sl, " TP=", tp);
        if (trade.PositionOpen(_Symbol, type, orderLotSize, SymbolInfoDouble(_Symbol, SYMBOL_BID), sl, tp)) {
            newTicket = (int)trade.ResultOrder();
        }
    }

    if (newTicket != -1) {
        Print("Order Successfully Opened: Ticket=", newTicket);
    } else {
        Print("Failed to Open Order of Type=", type, " Error=", GetLastError());
    }

    return newTicket;
}

void saveLastTrade(datetime dt) {
    Print("Saving Last Trade Time: ", dt);
    GlobalVariableSet("LastTrade", dt);
}

datetime restoreLastTrade() {
    if (GlobalVariableCheck("LastTrade")) {
        datetime lastTradeTime = (datetime)GlobalVariableGet("LastTrade");
        Print("Restored Last Trade Time: ", lastTradeTime);
        return lastTradeTime;
    }
    Print("No Last Trade Time Found.");
    return 0;
}
