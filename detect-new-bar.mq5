// Detect a new bar in MQL5 (once per bar, any timeframe)
// Explained (key lines, pitfalls, variations, FAQ): https://edgoro.com/mql5-examples/detect-new-bar
// MIT License, Copyright (c) 2026 Edgoro. For education: test on a demo account before any live use.

input ENUM_TIMEFRAMES InpHigherTf = PERIOD_H4; // Second timeframe to watch

// Says when a new bar opens on one symbol and timeframe. One object per timeframe, so they never share state.
class CNewBar
  {
private:
   string            m_symbol;
   ENUM_TIMEFRAMES   m_tf;
   datetime          m_last;    // open time of the last bar seen
public:
                     CNewBar(void) : m_symbol(""), m_tf(PERIOD_CURRENT), m_last(0) {}
   void              Init(const string symbol, const ENUM_TIMEFRAMES tf, const bool skipCurrent)
     {
      m_symbol = symbol;
      m_tf     = tf;
      // skipCurrent: the bar already open when the EA starts doesn't count as new
      m_last   = skipCurrent ? iTime(symbol, tf, 0) : 0;
     }
   bool              IsNew(void)
     {
      datetime open = iTime(m_symbol, m_tf, 0);
      if(open == 0)            // history not ready yet: try again on the next tick
         return false;
      if(open == m_last)
         return false;
      m_last = open;
      return true;
     }
  };

CNewBar chartBar;
CNewBar higherBar;

int OnInit()
  {
   chartBar.Init(_Symbol, PERIOD_CURRENT, true);
   higherBar.Init(_Symbol, InpHigherTf, true);
   return INIT_SUCCEEDED;
  }

void OnTick()
  {
   if(chartBar.IsNew())
     {
      // Runs once per bar, on its first tick. Bar 1 is the bar that just closed.
      PrintFormat("New %s bar at %s. The last bar closed at %s", EnumToString(_Period),
                  TimeToString(iTime(_Symbol, PERIOD_CURRENT, 0)), DoubleToString(iClose(_Symbol, PERIOD_CURRENT, 1), _Digits));
     }
   if(higherBar.IsNew())
      PrintFormat("New %s bar at %s", EnumToString(InpHigherTf), TimeToString(iTime(_Symbol, InpHigherTf, 0)));
  }
