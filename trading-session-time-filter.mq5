// MQL5 trading session filter: server time, GMT and DST
// Explained (key lines, pitfalls, variations, FAQ): https://edgoro.com/mql5-examples/trading-session-time-filter
// MIT License, Copyright (c) 2026 Edgoro. For education: test on a demo account before any live use.

enum ENUM_CLOCK
  {
   CLOCK_SERVER,   // Broker server time
   CLOCK_UTC,      // UTC (GMT)
   CLOCK_LONDON,   // London time, with UK daylight saving
   CLOCK_NEW_YORK  // New York time, with US daylight saving
  };

input ENUM_CLOCK InpClock        = CLOCK_LONDON; // Clock the session hours are in
input int        InpStartHour    = 8;            // Session start, hour
input int        InpStartMinute  = 0;            // Session start, minute
input int        InpEndHour      = 16;           // Session end, hour
input int        InpEndMinute    = 30;           // Session end, minute
input int        InpTesterOffset = 2;            // Strategy Tester only: server UTC offset in winter, hours
input bool       InpTesterUsDst  = true;         // Strategy Tester only: server clock follows US daylight saving

// 00:00 of the n-th Sunday (n = 1..4) of a month, or of the last Sunday of a 31-day month (n = 0), as UTC
datetime Sunday(const int year, const int mon, const int n)
  {
   MqlDateTime d = {};
   d.year = year;
   d.mon  = mon;
   d.day  = (n == 0) ? 31 : 1;
   datetime t = StructToTime(d);
   MqlDateTime w;
   TimeToStruct(t, w);
   if(n == 0)
      return t - w.day_of_week * 86400;               // back to the last Sunday
   return t + (((7 - w.day_of_week) % 7) + 7 * (n - 1)) * 86400;
  }

// UK summer time: last Sunday of March to last Sunday of October, at 01:00 UTC
bool UkSummer(const datetime utc)
  {
   MqlDateTime t;
   TimeToStruct(utc, t);
   return utc >= Sunday(t.year, 3, 0) + 3600 && utc < Sunday(t.year, 10, 0) + 3600;
  }

// US daylight time: second Sunday of March 02:00 EST (07:00 UTC) to first Sunday of November 02:00 EDT (06:00 UTC)
bool UsSummer(const datetime utc)
  {
   MqlDateTime t;
   TimeToStruct(utc, t);
   return utc >= Sunday(t.year, 3, 2) + 7 * 3600 && utc < Sunday(t.year, 11, 1) + 6 * 3600;
  }

// Server time minus UTC, in seconds
int ServerOffset(const datetime server)
  {
   if(MQLInfoInteger(MQL_TESTER))
     {
      // In the tester TimeGMT() returns the simulated server time, so the offset has to come from the inputs
      int offset = InpTesterOffset * 3600;
      if(InpTesterUsDst && UsSummer(server - offset))
         offset += 3600;
      return offset;
     }
   // TimeGMT() comes from this computer's clock and time zone: round to 30 minutes to absorb small drifts
   double diff = (double)((long)TimeTradeServer() - (long)TimeGMT());
   return (int)MathRound(diff / 1800.0) * 1800;
  }

// The server time expressed on the session's clock
datetime SessionClock(const datetime server)
  {
   if(InpClock == CLOCK_SERVER)
      return server;
   datetime utc = server - ServerOffset(server);
   if(InpClock == CLOCK_UTC)
      return utc;
   if(InpClock == CLOCK_LONDON)
      return utc + (UkSummer(utc) ? 3600 : 0);
   return utc - 5 * 3600 + (UsSummer(utc) ? 3600 : 0);
  }

bool InSession(const datetime server)
  {
   MqlDateTime t;
   TimeToStruct(SessionClock(server), t);
   if(t.day_of_week == 0 || t.day_of_week == 6)
      return false;                                   // Saturday and Sunday on the session's clock
   int now   = t.hour * 60 + t.min;
   int start = InpStartHour * 60 + InpStartMinute;
   int end   = InpEndHour * 60 + InpEndMinute;
   if(start < end)
      return now >= start && now < end;
   return now >= start || now < end;                  // a session that crosses midnight, e.g. 22:00-02:00
  }

void OnTick()
  {
   static int state = -1;
   datetime server = TimeCurrent();                   // time of the last tick, on the broker's clock
   int open = InSession(server) ? 1 : 0;
   if(open != state)
     {
      PrintFormat("Session %s: server %s, session clock %s", open == 1 ? "open" : "closed",
                  TimeToString(server, TIME_DATE | TIME_MINUTES), TimeToString(SessionClock(server), TIME_DATE | TIME_MINUTES));
      state = open;
     }
   if(open == 0)
      return;
   // Entry logic goes here: it only runs inside the session
  }
