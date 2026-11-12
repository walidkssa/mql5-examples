// Draw on the chart in MQL5: lines, arrows and text
// Explained (key lines, pitfalls, variations, FAQ): https://edgoro.com/mql5-examples/draw-objects-on-chart
// MIT License, Copyright (c) 2026 Edgoro. For education: test on a demo account before any live use.

#define PREFIX "exdraw_"   // every object this EA creates starts with it, so it can delete them all

input int   InpHistoryBars = 300;         // Bars to mark when the EA starts
input color InpLevelColor  = clrDodgerBlue; // Color of the previous day's high and low

// Creates a horizontal line, or moves it if it already exists
void HLine(const string name, const double price, const color clr, const string tooltip)
  {
   if(ObjectFind(0, name) < 0)
     {
      if(!ObjectCreate(0, name, OBJ_HLINE, 0, 0, price))
        {
         PrintFormat("ObjectCreate %s failed: error %d", name, GetLastError());
         return;
        }
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DASH);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_BACK, true);
      ObjectSetString(0, name, OBJPROP_TOOLTIP, tooltip);
     }
   else
      ObjectMove(0, name, 0, 0, price);
  }

// Arrow under a bar's low (up) or above its high (down), with a short text next to it
void Mark(const datetime time, const double price, const bool up, const string text)
  {
   string name = PREFIX + (up ? "up_" : "dn_") + IntegerToString((long)time);
   if(ObjectFind(0, name) >= 0)
      return;                                     // already drawn (names identify objects)
   if(!ObjectCreate(0, name, up ? OBJ_ARROW_UP : OBJ_ARROW_DOWN, 0, time, price))
      return;
   ObjectSetInteger(0, name, OBJPROP_COLOR, up ? clrSeaGreen : clrTomato);
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, up ? ANCHOR_TOP : ANCHOR_BOTTOM);  // the tip touches the price
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);

   string label = name + "_txt";
   if(ObjectCreate(0, label, OBJ_TEXT, 0, time, price))
     {
      ObjectSetString(0, label, OBJPROP_TEXT, text);
      ObjectSetString(0, label, OBJPROP_FONT, "Arial");
      ObjectSetInteger(0, label, OBJPROP_FONTSIZE, 8);
      ObjectSetInteger(0, label, OBJPROP_COLOR, up ? clrSeaGreen : clrTomato);
      ObjectSetInteger(0, label, OBJPROP_ANCHOR, up ? ANCHOR_LEFT_UPPER : ANCHOR_LEFT_LOWER);
      ObjectSetInteger(0, label, OBJPROP_SELECTABLE, false);
     }
  }

// Marks bar `shift` if it closed beyond the previous day's high or low while the bar before it hadn't
void CheckBar(const int shift)
  {
   datetime t = iTime(_Symbol, PERIOD_CURRENT, shift);
   int day = iBarShift(_Symbol, PERIOD_D1, t);    // the day this bar belongs to
   if(t == 0 || day < 0)
      return;
   double pdh = iHigh(_Symbol, PERIOD_D1, day + 1);
   double pdl = iLow(_Symbol, PERIOD_D1, day + 1);
   double c0  = iClose(_Symbol, PERIOD_CURRENT, shift);
   double c1  = iClose(_Symbol, PERIOD_CURRENT, shift + 1);
   if(pdh <= 0.0 || c1 <= 0.0)
      return;
   if(c0 > pdh && c1 <= pdh)
      Mark(t, iLow(_Symbol, PERIOD_CURRENT, shift), true, "Close above PDH");
   else if(c0 < pdl && c1 >= pdl)
      Mark(t, iHigh(_Symbol, PERIOD_CURRENT, shift), false, "Close below PDL");
  }

void OnTick()
  {
   static datetime lastBar = 0;
   datetime bar = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(bar == 0 || bar == lastBar)
      return;
   int from = (lastBar == 0) ? MathMin(InpHistoryBars, iBars(_Symbol, PERIOD_CURRENT) - 2) : 1;
   lastBar = bar;
   for(int shift = from; shift >= 1; shift--)       // first run: the history; then only the bar that just closed
      CheckBar(shift);
   HLine(PREFIX + "pdh", iHigh(_Symbol, PERIOD_D1, 1), InpLevelColor, "Previous day high");
   HLine(PREFIX + "pdl", iLow(_Symbol, PERIOD_D1, 1), InpLevelColor, "Previous day low");
   ChartRedraw();                                   // object changes show at the next redraw otherwise
  }

void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0, PREFIX);                     // objects outlive the EA unless it deletes them
   ChartRedraw();
  }
