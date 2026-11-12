// MQL5 moving average crossover EA (complete code)
// Explained (key lines, pitfalls, variations, FAQ): https://edgoro.com/mql5-examples/moving-average-crossover-ea
// MIT License, Copyright (c) 2026 Edgoro. For education: test on a demo account before any live use.

#include <Trade/Trade.mqh>

input int            InpFastPeriod = 20;       // Fast MA period
input int            InpSlowPeriod = 50;       // Slow MA period
input ENUM_MA_METHOD InpMaMethod   = MODE_EMA; // MA method
input double         InpLots       = 0.10;     // Volume, lots
input int            InpStopPoints = 500;      // Stop-loss, points (0 = none)
input int            InpTakePoints = 1000;     // Take-profit, points (0 = none)
input bool           InpReverse    = true;     // Close the opposite position on a new cross
input ulong          InpMagic      = 20261112; // Magic number

CTrade   trade;
int      fastHandle = INVALID_HANDLE;
int      slowHandle = INVALID_HANDLE;
datetime lastBar    = 0;

int OnInit()
  {
   if(InpFastPeriod <= 0 || InpFastPeriod >= InpSlowPeriod)
     {
      Print("The fast period must be positive and shorter than the slow period");
      return INIT_PARAMETERS_INCORRECT;
     }
   fastHandle = iMA(_Symbol, PERIOD_CURRENT, InpFastPeriod, 0, InpMaMethod, PRICE_CLOSE);
   slowHandle = iMA(_Symbol, PERIOD_CURRENT, InpSlowPeriod, 0, InpMaMethod, PRICE_CLOSE);
   if(fastHandle == INVALID_HANDLE || slowHandle == INVALID_HANDLE)
     {
      PrintFormat("iMA failed: error %d", GetLastError());
      return INIT_FAILED;
     }
   trade.SetExpertMagicNumber(InpMagic);
   trade.SetDeviationInPoints(10);
   trade.SetTypeFillingBySymbol(_Symbol);
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   if(fastHandle != INVALID_HANDLE)
      IndicatorRelease(fastHandle);
   if(slowHandle != INVALID_HANDLE)
      IndicatorRelease(slowHandle);
  }

// Cross on the last closed bar: +1 fast crossed above slow, -1 below, 0 none. False if the values aren't ready.
bool ReadCross(int &signal)
  {
   double fast[], slow[];
   ArraySetAsSeries(fast, true);
   ArraySetAsSeries(slow, true);
   if(CopyBuffer(fastHandle, 0, 1, 2, fast) != 2 || CopyBuffer(slowHandle, 0, 1, 2, slow) != 2)
      return false;
   signal = 0;
   if(fast[1] <= slow[1] && fast[0] > slow[0])
      signal = 1;
   else if(fast[1] >= slow[1] && fast[0] < slow[0])
      signal = -1;
   return true;
  }

// This EA's position on this symbol: +1 long, -1 short, 0 none
int PositionDirection(ulong &ticket)
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong t = PositionGetTicket(i);
      if(t == 0 || PositionGetString(POSITION_SYMBOL) != _Symbol || PositionGetInteger(POSITION_MAGIC) != (long)InpMagic)
         continue;
      ticket = t;
      return PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? 1 : -1;
     }
   ticket = 0;
   return 0;
  }

double RoundToTick(const double price)
  {
   double tick = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tick <= 0.0)
      return NormalizeDouble(price, _Digits);
   return NormalizeDouble(MathRound(price / tick) * tick, _Digits);
  }

bool Open(const int direction)
  {
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick))
      return false;
   bool   buy  = direction > 0;
   double exit = buy ? tick.bid : tick.ask;   // stops are checked against the closing price
   double sl   = InpStopPoints > 0 ? RoundToTick(buy ? exit - InpStopPoints * _Point : exit + InpStopPoints * _Point) : 0.0;
   double tp   = InpTakePoints > 0 ? RoundToTick(buy ? exit + InpTakePoints * _Point : exit - InpTakePoints * _Point) : 0.0;
   bool   ok   = buy ? trade.Buy(InpLots, _Symbol, tick.ask, sl, tp, "MA cross")
                     : trade.Sell(InpLots, _Symbol, tick.bid, sl, tp, "MA cross");
   if(!ok || trade.ResultRetcode() != TRADE_RETCODE_DONE)
      PrintFormat("%s failed: retcode %u (%s)", buy ? "Buy" : "Sell", trade.ResultRetcode(), trade.ResultRetcodeDescription());
   return ok;
  }

void OnTick()
  {
   datetime bar = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(bar == 0 || bar == lastBar)
      return;                       // once per bar
   int signal;
   if(!ReadCross(signal))
      return;                       // indicator not ready: retry on the next tick
   lastBar = bar;
   if(signal == 0)
      return;

   ulong ticket;
   int   current = PositionDirection(ticket);
   if(current == signal)
      return;                       // already in the direction of the cross
   if(current != 0)
     {
      if(!InpReverse)
         return;
      if(!trade.PositionClose(ticket) || trade.ResultRetcode() != TRADE_RETCODE_DONE)
        {
         PrintFormat("Close failed: retcode %u (%s)", trade.ResultRetcode(), trade.ResultRetcodeDescription());
         return;                    // don't open the new trade while the old one is still there
        }
     }
   Open(signal);
  }
