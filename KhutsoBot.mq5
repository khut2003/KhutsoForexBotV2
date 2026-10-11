
#property strict
#property version "1.00"
#property description "Khutso Forex Bot V2 - EMA crossover"

#include <Trade/Trade.mqh>

CTrade trade;

input int FastEMA = 9;
input int SlowEMA = 21;
input double LotSize = 0.01;
input int StopLossPoints = 300;
input int TakeProfitPoints = 600;
input ulong MagicNumber = 20261011;

int fastHandle;
int slowHandle;
datetime lastBar = 0;

int OnInit()
{
   if(FastEMA <= 0 || SlowEMA <= FastEMA ||
      LotSize <= 0 || StopLossPoints <= 0 ||
      TakeProfitPoints <= 0)
      return INIT_PARAMETERS_INCORRECT;

   fastHandle = iMA(_Symbol, PERIOD_CURRENT,
                    FastEMA, 0, MODE_EMA, PRICE_CLOSE);
   slowHandle = iMA(_Symbol, PERIOD_CURRENT,
                    SlowEMA, 0, MODE_EMA, PRICE_CLOSE);

   if(fastHandle == INVALID_HANDLE ||
      slowHandle == INVALID_HANDLE)
      return INIT_FAILED;

   trade.SetExpertMagicNumber(MagicNumber);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   IndicatorRelease(fastHandle);
   IndicatorRelease(slowHandle);
}

void OnTick()
{
   datetime bar = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(bar == lastBar || bar == 0)
      return;
   lastBar = bar;

   double fast[3], slow[3];

   if(CopyBuffer(fastHandle, 0, 1, 2, fast) != 2 ||
      CopyBuffer(slowHandle, 0, 1, 2, slow) != 2)
      return;

   bool buySignal = fast[1] <= slow[1] &&
                    fast[0] > slow[0];
   bool sellSignal = fast[1] >= slow[1] &&
                     fast[0] < slow[0];

   if(!buySignal && !sellSignal)
      return;

   if(PositionSelect(_Symbol))
      return;

   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick))
      return;

   double sl, tp;
   bool sent = false;

   if(buySignal)
   {
      sl = NormalizeDouble(
         tick.ask - StopLossPoints * _Point, _Digits);
      tp = NormalizeDouble(
         tick.ask + TakeProfitPoints * _Point, _Digits);

      sent = trade.Buy(LotSize, _Symbol, 0, sl, tp,
                        "Khutso EMA Buy");
   }
   else if(sellSignal)
   {
      sl = NormalizeDouble(
         tick.bid + StopLossPoints * _Point, _Digits);
      tp = NormalizeDouble(
         tick.bid - TakeProfitPoints * _Point, _Digits);

      sent = trade.Sell(LotSize, _Symbol, 0, sl, tp,
                         "Khutso EMA Sell");
   }

   if(!sent)
      Print("Trade failed: ", trade.ResultRetcodeDescription());
}
