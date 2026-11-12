// Read indicator values in MQL5: iMA, iRSI and CopyBuffer
// Explained (key lines, pitfalls, variations, FAQ): https://edgoro.com/mql5-examples/read-indicator-values-copybuffer
// MIT License, Copyright (c) 2026 Edgoro. For education: test on a demo account before any live use.

input int            InpMaPeriod  = 50;       // Moving average period
input ENUM_MA_METHOD InpMaMethod  = MODE_EMA; // Moving average method
input int            InpRsiPeriod = 14;       // RSI period

int maHandle  = INVALID_HANDLE;
int rsiHandle = INVALID_HANDLE;

int OnInit()
  {
   // Create each indicator once. The handle is a reference to it, not a value.
   maHandle  = iMA(_Symbol, PERIOD_CURRENT, InpMaPeriod, 0, InpMaMethod, PRICE_CLOSE);
   rsiHandle = iRSI(_Symbol, PERIOD_CURRENT, InpRsiPeriod, PRICE_CLOSE);
   if(maHandle == INVALID_HANDLE || rsiHandle == INVALID_HANDLE)
     {
      PrintFormat("Indicator creation failed: error %d", GetLastError());
      return INIT_FAILED;
     }
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   if(maHandle != INVALID_HANDLE)
      IndicatorRelease(maHandle);
   if(rsiHandle != INVALID_HANDLE)
      IndicatorRelease(rsiHandle);
  }

// Copies `count` values of buffer `buffer`, starting at bar `shift`, newest first: values[0] is bar `shift`.
bool ReadBuffer(const int handle, const int buffer, const int shift, const int count, double &values[])
  {
   if(BarsCalculated(handle) < shift + count)   // still calculating, or not enough bars
      return false;
   ArraySetAsSeries(values, true);
   ResetLastError();
   int copied = CopyBuffer(handle, buffer, shift, count, values);
   if(copied != count)
     {
      PrintFormat("CopyBuffer copied %d of %d values, error %d", copied, count, GetLastError());
      return false;
     }
   return true;
  }

void OnTick()
  {
   static datetime lastBar = 0;
   datetime bar = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(bar == 0 || bar == lastBar)
      return;

   double ma[], rsi[];
   // Bars 1 and 2: the last two closed bars. Bar 0 is still forming and its value moves with every tick.
   if(!ReadBuffer(maHandle, 0, 1, 2, ma) || !ReadBuffer(rsiHandle, 0, 1, 2, rsi))
      return;   // lastBar isn't updated, so the next tick tries again
   lastBar = bar;

   double close1 = iClose(_Symbol, PERIOD_CURRENT, 1);
   PrintFormat("Last closed bar: close %s, %s(%d) %s, RSI(%d) %.1f (bar before: %.1f)",
               DoubleToString(close1, _Digits), StringSubstr(EnumToString(InpMaMethod), 5), InpMaPeriod,
               DoubleToString(ma[0], _Digits), InpRsiPeriod, rsi[0], rsi[1]);
   if(close1 > ma[0] && rsi[1] < 50.0 && rsi[0] >= 50.0)
      Print("Close above the moving average and RSI back above 50");
  }
