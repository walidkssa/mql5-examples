// Close all positions in MQL5 (by symbol and magic number)
// Explained (key lines, pitfalls, variations, FAQ): https://edgoro.com/mql5-examples/close-all-positions
// MIT License, Copyright (c) 2026 Edgoro. For education: test on a demo account before any live use.

#property script_show_inputs
#include <Trade/Trade.mqh>

input string InpSymbol   = "";    // Symbol to close ("" = every symbol)
input long   InpMagic    = -1;    // Magic number to close (-1 = any, 0 = manual trades)
input bool   InpPending  = false; // Also delete pending orders
input int    InpAttempts = 3;     // Attempts per position

CTrade trade;

bool Matches(const string symbol, const long magic)
  {
   if(InpSymbol != "" && symbol != InpSymbol)
      return false;
   return InpMagic < 0 || magic == InpMagic;
  }

// Price moved or no quote: worth another try. Anything else (market closed, trading disabled...) won't fix itself.
bool Retryable(const uint rc)
  {
   return rc == TRADE_RETCODE_REQUOTE || rc == TRADE_RETCODE_PRICE_CHANGED || rc == TRADE_RETCODE_PRICE_OFF;
  }

int CloseMatchingPositions()
  {
   int failed = 0;
   // Walk backwards: closing a position shifts the index of every position after it
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);   // also selects the position
      if(ticket == 0)
         continue;
      if(!Matches(PositionGetString(POSITION_SYMBOL), PositionGetInteger(POSITION_MAGIC)))
         continue;

      bool closed = false;
      for(int attempt = 1; attempt <= InpAttempts && !closed; attempt++)
        {
         trade.PositionClose(ticket);
         uint rc = trade.ResultRetcode();
         if(rc == TRADE_RETCODE_DONE)
            closed = true;
         else if(rc == TRADE_RETCODE_DONE_PARTIAL)
            continue;                         // part of it is still open: close the rest
         else
           {
            PrintFormat("Position #%I64u: retcode %u (%s)", ticket, rc, trade.ResultRetcodeDescription());
            if(!Retryable(rc))
               break;
            Sleep(300);
           }
        }
      if(!closed)
         failed++;
     }
   return failed;
  }

int DeleteMatchingOrders()
  {
   int failed = 0;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong ticket = OrderGetTicket(i);   // also selects the order
      if(ticket == 0)
         continue;
      if(!Matches(OrderGetString(ORDER_SYMBOL), OrderGetInteger(ORDER_MAGIC)))
         continue;
      if(!trade.OrderDelete(ticket) || trade.ResultRetcode() != TRADE_RETCODE_DONE)
        {
         PrintFormat("Order #%I64u: retcode %u (%s)", ticket, trade.ResultRetcode(), trade.ResultRetcodeDescription());
         failed++;
        }
     }
   return failed;
  }

void OnStart()
  {
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED))
     {
      Print("Algo trading is off: nothing was closed");
      return;
     }
   trade.SetDeviationInPoints(20);
   int failed = CloseMatchingPositions();
   if(InpPending)
      failed += DeleteMatchingOrders();
   if(failed > 0)
      PrintFormat("%d position(s) or order(s) are still open: see the messages above", failed);
   else
      Print("Done: every matching position is closed");
  }
