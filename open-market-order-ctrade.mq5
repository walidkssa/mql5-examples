// MQL5 market buy and sell with CTrade (full script)
// Explained (key lines, pitfalls, variations, FAQ): https://edgoro.com/mql5-examples/open-market-order-ctrade
// MIT License, Copyright (c) 2026 Edgoro. For education: test on a demo account before any live use.

#property script_show_inputs
#include <Trade/Trade.mqh>

enum ENUM_SIDE
  {
   SIDE_BUY,  // Buy
   SIDE_SELL  // Sell
  };

input ENUM_SIDE InpSide       = SIDE_BUY; // Direction
input double    InpLots       = 0.01;     // Volume, lots
input int       InpStopPoints = 300;      // Stop-loss distance, points (0 = none)
input int       InpTakePoints = 600;      // Take-profit distance, points (0 = none)
input ulong     InpMagic      = 20261112; // Magic number
input ulong     InpSlippage   = 10;       // Maximum slippage, points

// Rounds a price to the symbol's tick size
double RoundToTick(const double price)
  {
   double tick = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tick <= 0.0)
      return NormalizeDouble(price, _Digits);
   return NormalizeDouble(MathRound(price / tick) * tick, _Digits);
  }

void OnStart()
  {
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED))
     {
      Print("Algo trading is off: switch on the Algo Trading button and allow it in the program's settings");
      return;
     }

   CTrade trade;
   trade.SetExpertMagicNumber(InpMagic);
   trade.SetDeviationInPoints(InpSlippage);
   trade.SetTypeFillingBySymbol(_Symbol);

   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick) || tick.bid <= 0.0)
     {
      Print("No price for ", _Symbol, " yet");
      return;
     }

   bool   buy   = (InpSide == SIDE_BUY);
   double entry = buy ? tick.ask : tick.bid;   // a buy opens at the Ask, a sell at the Bid
   double exit  = buy ? tick.bid : tick.ask;   // it closes at the other price, so stops are measured from there
   double sl    = 0.0;
   double tp    = 0.0;
   if(InpStopPoints > 0)
      sl = RoundToTick(buy ? exit - InpStopPoints * _Point : exit + InpStopPoints * _Point);
   if(InpTakePoints > 0)
      tp = RoundToTick(buy ? exit + InpTakePoints * _Point : exit - InpTakePoints * _Point);

   // Check the margin first: cheaper than a refused order
   double margin = 0.0;
   ENUM_ORDER_TYPE type = buy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   if(!OrderCalcMargin(type, _Symbol, InpLots, entry, margin) || margin > AccountInfoDouble(ACCOUNT_MARGIN_FREE))
     {
      PrintFormat("Not enough free margin for %.2f lots of %s (needs %.2f)", InpLots, _Symbol, margin);
      return;
     }

   bool sent = buy ? trade.Buy(InpLots, _Symbol, entry, sl, tp, "example")
                   : trade.Sell(InpLots, _Symbol, entry, sl, tp, "example");
   uint rc = trade.ResultRetcode();
   // true only means the request went out: the retcode says what the server did with it
   if(!sent || (rc != TRADE_RETCODE_DONE && rc != TRADE_RETCODE_DONE_PARTIAL))
     {
      PrintFormat("%s failed: retcode %u (%s)", buy ? "Buy" : "Sell", rc, trade.ResultRetcodeDescription());
      return;
     }
   PrintFormat("%s %.2f %s at %s, deal #%I64u", buy ? "Bought" : "Sold", trade.ResultVolume(), _Symbol,
               DoubleToString(trade.ResultPrice(), _Digits), trade.ResultDeal());
  }
