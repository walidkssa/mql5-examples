// MQL5 OnTimer example: run code without waiting for ticks
// Explained (key lines, pitfalls, variations, FAQ): https://edgoro.com/mql5-examples/ontimer-event
// MIT License, Copyright (c) 2026 Edgoro. For education: test on a demo account before any live use.

#include <Trade/Trade.mqh>

input int   InpSeconds     = 5;        // Timer period, seconds
input int   InpStaleAfter  = 120;      // Warn when no tick for this many seconds
input bool  InpFridayClose = true;     // Close this EA's positions before the weekend
input int   InpCloseHour   = 21;       // Friday closing time, server hour
input int   InpCloseMinute = 30;       // Friday closing time, minute (tries for 30 minutes from then)
input ulong InpMagic       = 20261112; // Magic number of the positions to close

CTrade trade;

int OnInit()
  {
   // One timer per program: calling EventSetTimer() again replaces it
   if(!EventSetTimer(InpSeconds))
     {
      PrintFormat("EventSetTimer failed: error %d", GetLastError());
      return INIT_FAILED;
     }
   trade.SetExpertMagicNumber(InpMagic);
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   EventKillTimer();
  }

void OnTick()
  {
   // Tick-driven logic stays here. OnTimer() runs even when no tick arrives.
  }

void CloseOwnPositions()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || PositionGetString(POSITION_SYMBOL) != _Symbol || PositionGetInteger(POSITION_MAGIC) != (long)InpMagic)
         continue;
      if(!trade.PositionClose(ticket) || trade.ResultRetcode() != TRADE_RETCODE_DONE)
         PrintFormat("Weekend close of #%I64u failed: retcode %u (%s)", ticket, trade.ResultRetcode(), trade.ResultRetcodeDescription());
     }
  }

void OnTimer()
  {
   // TimeCurrent() is the time of the last tick and stands still when ticks stop.
   // TimeTradeServer() keeps running: it's the server's clock as the terminal estimates it.
   datetime now = TimeTradeServer();
   MqlDateTime t;
   TimeToStruct(now, t);

   int minutes = t.hour * 60 + t.min;
   int closeAt = InpCloseHour * 60 + InpCloseMinute;
   // A 30-minute window: retries on every timer event, but stops before the market closes for the weekend
   if(InpFridayClose && t.day_of_week == 5 && minutes >= closeAt && minutes < closeAt + 30)
      CloseOwnPositions();

   static bool warned = false;
   MqlTick tick;
   if(SymbolInfoTick(_Symbol, tick) && tick.time > 0)
     {
      long silent = (long)now - (long)tick.time;
      bool weekday = t.day_of_week >= 1 && t.day_of_week <= 5;
      if(weekday && silent > InpStaleAfter && !warned)
        {
         PrintFormat("No %s tick for %d seconds: connection lost, or the market is closed?", _Symbol, (int)silent);
         warned = true;
        }
      else if(silent <= InpStaleAfter)
         warned = false;
     }
  }
