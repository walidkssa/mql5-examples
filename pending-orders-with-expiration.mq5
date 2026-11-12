// MQL5 buy limit and buy stop orders with expiration
// Explained (key lines, pitfalls, variations, FAQ): https://edgoro.com/mql5-examples/pending-orders-with-expiration
// MIT License, Copyright (c) 2026 Edgoro. For education: test on a demo account before any live use.

#property script_show_inputs
#include <Trade/Trade.mqh>

enum ENUM_PENDING
  {
   PENDING_BUY_LIMIT,   // Buy limit (below the Ask)
   PENDING_BUY_STOP,    // Buy stop (above the Ask)
   PENDING_SELL_LIMIT,  // Sell limit (above the Bid)
   PENDING_SELL_STOP    // Sell stop (below the Bid)
  };

input ENUM_PENDING InpType       = PENDING_BUY_LIMIT; // Order type
input int          InpDistance   = 200;               // Distance from the market, points
input double       InpLots       = 0.01;              // Volume, lots
input int          InpStopPoints = 300;               // Stop-loss from the order price, points (0 = none)
input int          InpTakePoints = 600;               // Take-profit from the order price, points (0 = none)
input int          InpMinutes    = 240;               // Expires after, minutes (0 = good till cancelled)
input ulong        InpMagic      = 20261112;          // Magic number

double RoundToTick(const double price)
  {
   double tick = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tick <= 0.0)
      return NormalizeDouble(price, _Digits);
   return NormalizeDouble(MathRound(price / tick) * tick, _Digits);
  }

void OnStart()
  {
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick) || tick.ask <= 0.0)
      return;
   bool   buy   = (InpType == PENDING_BUY_LIMIT || InpType == PENDING_BUY_STOP);
   bool   limit = (InpType == PENDING_BUY_LIMIT || InpType == PENDING_SELL_LIMIT);
   double ref   = buy ? tick.ask : tick.bid;   // a buy order triggers on the Ask, a sell order on the Bid
   // Limits wait for a better price (buy below, sell above), stops for a breakout (buy above, sell below)
   double dir   = (buy == limit) ? -1.0 : 1.0;
   double price = RoundToTick(ref + dir * InpDistance * _Point);

   double stops = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
   if(MathAbs(price - ref) < MathMax(stops, _Point))
     {
      PrintFormat("The order must be at least %d points from the market", (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL));
      return;
     }
   // Stops of a pending order are measured from the order's own price
   double sl = InpStopPoints > 0 ? RoundToTick(buy ? price - InpStopPoints * _Point : price + InpStopPoints * _Point) : 0.0;
   double tp = InpTakePoints > 0 ? RoundToTick(buy ? price + InpTakePoints * _Point : price - InpTakePoints * _Point) : 0.0;

   // Expiry: use a specified time only if the symbol allows it. Expiration is in SERVER time.
   ENUM_ORDER_TYPE_TIME typeTime = ORDER_TIME_GTC;
   datetime expiration = 0;
   int modes = (int)SymbolInfoInteger(_Symbol, SYMBOL_EXPIRATION_MODE);
   if(InpMinutes > 0)
     {
      if((modes & SYMBOL_EXPIRATION_SPECIFIED) == SYMBOL_EXPIRATION_SPECIFIED)
        {
         typeTime   = ORDER_TIME_SPECIFIED;
         expiration = TimeTradeServer() + InpMinutes * 60;
        }
      else
         Print("This symbol doesn't accept an expiry time: the order is good till cancelled, delete it yourself");
     }

   CTrade trade;
   trade.SetExpertMagicNumber(InpMagic);
   bool ok = false;
   switch(InpType)
     {
      case PENDING_BUY_LIMIT:
         ok = trade.BuyLimit(InpLots, price, _Symbol, sl, tp, typeTime, expiration, "example");
         break;
      case PENDING_BUY_STOP:
         ok = trade.BuyStop(InpLots, price, _Symbol, sl, tp, typeTime, expiration, "example");
         break;
      case PENDING_SELL_LIMIT:
         ok = trade.SellLimit(InpLots, price, _Symbol, sl, tp, typeTime, expiration, "example");
         break;
      case PENDING_SELL_STOP:
         ok = trade.SellStop(InpLots, price, _Symbol, sl, tp, typeTime, expiration, "example");
         break;
     }
   // A pending order that was accepted returns 10008 (placed), not 10009 (done)
   if(!ok || trade.ResultRetcode() != TRADE_RETCODE_PLACED)
     {
      PrintFormat("Order refused: retcode %u (%s)", trade.ResultRetcode(), trade.ResultRetcodeDescription());
      return;
     }
   PrintFormat("Order #%I64u placed at %s, expires %s", trade.ResultOrder(), DoubleToString(price, _Digits),
               expiration > 0 ? TimeToString(expiration) : "never (good till cancelled)");
  }
