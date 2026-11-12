// MQL5 iCustom example: read a custom indicator's buffers
// Explained (key lines, pitfalls, variations, FAQ): https://edgoro.com/mql5-examples/icustom-read-custom-indicator
// MIT License, Copyright (c) 2026 Edgoro. For education: test on a demo account before any live use.

// Ships the indicator to the Strategy Tester's agents. Detected on its own when iCustom() gets a constant name,
// required when the name is built at run time: harmless here, and it keeps working if you make the name an input.
#property tester_indicator "Examples\\ZigZag.ex5"

input int InpDepth     = 12;  // ZigZag depth
input int InpDeviation = 5;   // ZigZag deviation
input int InpBackstep  = 3;   // ZigZag back step
input int InpLookback  = 300; // Bars to search for swing points

int zigzag = INVALID_HANDLE;

int OnInit()
  {
   // Path relative to MQL5\Indicators, without the extension. Inputs in the indicator's own order and types.
   zigzag = iCustom(_Symbol, PERIOD_CURRENT, "Examples\\ZigZag", InpDepth, InpDeviation, InpBackstep);
   if(zigzag == INVALID_HANDLE)
     {
      PrintFormat("iCustom failed: error %d. Is MQL5\\Indicators\\Examples\\ZigZag.ex5 there?", GetLastError());
      return INIT_FAILED;
     }
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   if(zigzag != INVALID_HANDLE)
      IndicatorRelease(zigzag);
  }

// The newest `max` swing points, newest first. ZigZag writes 0.0 on every bar that isn't a swing point.
int SwingPoints(double &price[], int &shift[], const int max)
  {
   int count = MathMin(InpLookback, BarsCalculated(zigzag));
   if(count <= 0)
      return 0;                                                // not calculated yet
   double buf[];
   ArraySetAsSeries(buf, true);
   int copied = CopyBuffer(zigzag, 0, 0, count, buf);         // buffer 0: the ZigZag line
   if(copied <= 0)
      return 0;
   int found = 0;
   for(int i = 0; i < copied && found < max; i++)
     {
      if(buf[i] == 0.0 || buf[i] == EMPTY_VALUE)
         continue;
      price[found] = buf[i];
      shift[found] = i;
      found++;
     }
   return found;
  }

void OnTick()
  {
   static datetime lastBar = 0;
   datetime bar = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(bar == 0 || bar == lastBar)
      return;
   double price[3];
   int    shift[3];
   if(SwingPoints(price, shift, 3) < 3)
      return;                                                  // retry on the next tick
   lastBar = bar;
   // Point 0 is the end of the leg still being drawn: it moves until the next swing confirms it.
   // Points 1 and 2 are the last two confirmed swings.
   bool lastIsHigh = price[1] > price[2];
   PrintFormat("Last confirmed swing %s %s (%d bars ago), the one before %s %s",
               lastIsHigh ? "high" : "low", DoubleToString(price[1], _Digits), shift[1],
               lastIsHigh ? "low" : "high", DoubleToString(price[2], _Digits));
  }
