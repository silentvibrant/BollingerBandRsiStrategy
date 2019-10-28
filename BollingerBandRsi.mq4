//+------------------------------------------------------------------+
//|                                            BollingerBandsRSI.mq4 |
//|                                     Copyright 2019, KmanOfficial |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, KmanOfficial"
#property link      ""
#property version   "1.00"
#property strict
#include <WinUser32.mqh>

extern int StartHour = 23;
extern int StartMin = 30;
extern int CloseHour = 21;

extern int EURUSDSL = 5;
extern int GBPAUDSL = 10;
extern int NZDCADSL = 5;
extern int CHFJPYSL = 5;

extern double Lots = 1;

extern int BB_PERIOD = 20;
extern int RSI_PERIOD = 14;

static int StopLoss = 0;

static int point_compat;

void BreakPoint(double BBLevel = 0)
{
   //It is expecting, that this function should work
   //only in tester
   if (!IsVisualMode()) return;
   
   //Preparing a data for printing
   //Comment() function is used as 
   //it give quite clear visualisation
   string Comm="";
   Comm=Comm+"Bid="+Bid+"\n";
   Comm=Comm+"Ask="+Ask+"\n";
   
   Comment(Comm);
   
   if(BBLevel > 0){
      Comment("BB Level:", BBLevel);
   }
   
   //Press/release Pause button
   //19 is a Virtual Key code of "Pause" button
   //Sleep() is needed, because of the probability
   //to misprocess too quick pressing/releasing
   //of the button
   keybd_event(19,0,0,0);
   Sleep(100);
   keybd_event(19,0,2,0);
}


double CalculateNormalizedDigits()
{
   //If there are 3 or less digits (JPY for example) then return 0.01 which is the pip value
   if(Digits<=3){
      return(0.01);
   }
   //If there are 4 or more digits then return 0.0001 which is the pip value
   else if(Digits>=4){
      return(0.0001);
   }
   //In all other cases (there shouldn't be any) return 0
   else return(0);
}

void OnInit()
{
   string financialInstrument = Symbol();
   if(financialInstrument == "EURUSD"){
      StopLoss = EURUSDSL;
   }else if(financialInstrument == "GBPAUD"){
      StopLoss = GBPAUDSL;
   }else if(financialInstrument == "NZDCAD"){
      StopLoss = NZDCADSL;
   }else if(financialInstrument == "CHFJPY"){
      StopLoss = CHFJPYSL;
   }else{
      Alert("This financial instrument is not setup to be used with this EA. Stopping....");
      ExpertRemove();
   } 
   
   if(Digits == 3 || Digits == 5) {
      static int point_compat = 10;
   }
}


void OnTick()
{
   double nDigits=CalculateNormalizedDigits();
   static bool EARunning = false;
   static bool tradeRunning = false;
   
   static int ticket = 0;
   
   // BollingerBands
   double upperBollingerBand = iBands(Symbol(), 0, BB_PERIOD, 2, 0, 0, 1, 0);
   double lowerBollingerBand = iBands(Symbol(), 0, BB_PERIOD, 2, 0, 0, 2, 0);
   
   double prevUpperBollingerBand = iBands(Symbol(), 0, BB_PERIOD, 2, 0, 0, 1, 1);
   double prevLowerBollingerBand = iBands(Symbol(), 0, BB_PERIOD, 2, 0, 0, 2, 1);
   
   // RSI
   double RSI = iRSI(Symbol(), 0, RSI_PERIOD, 0, 0);
   
   
   // If not between 9pm and 11:30pm, run the EA..
   if(!((Hour() <= StartHour && Minute() <= StartMin) && (Hour() >= CloseHour))){
      EARunning = true;
      // Check if trade is running..
      bool orderSelected = OrderSelect(ticket, SELECT_BY_TICKET);
      if(orderSelected){
         if(OrderCloseTime() == 0){
            tradeRunning = true;
         }else{
            tradeRunning = false;
         }
      }else{
         tradeRunning = false;
      }
      
         // Analyse using Bollinger Bands and RSI
         // If Ask more than last close and 2nd candle is lower than lower band and last candle is higher than lower band (means movement upwards)
         if(Close[0] <= lowerBollingerBand){
            // Open a buy after analysing RSI...
            if(RSI < 20 && !tradeRunning){
               Alert("your rsi value is: ", RSI);               
               double takeProfit = upperBollingerBand;
               // Open Buy for sure as currency pair is now been oversold            
                  double currentSpreadInPips = MarketInfo(Symbol(), MODE_SPREAD )/10;
                  Alert((Bid - ((StopLoss + currentSpreadInPips) * nDigits)), " SL Calculation Where BID: ", Bid, " StopLoss Pip: ", StopLoss, " Ndigits: ", nDigits, "Spread (Pts): ", MarketInfo(Symbol(), MODE_SPREAD )/10); 
                  ticket = OrderSend(Symbol(), OP_BUY, Lots, Ask, 3, (Bid - (StopLoss * 10 * nDigits)), takeProfit, "Set by Kman Test EA");
                  if(ticket < 0){
                     Alert("Error in the attempt to send the order!");
                  }else{
                     Alert("BUY Order executed successfully ticket #", ticket);
                     tradeRunning = true;
                  }               
            }
         else {
             // Trade is running... 
            // Check if a sell trade is running and close it...
            bool orderSelected = OrderSelect(ticket, SELECT_BY_TICKET);
            if(orderSelected){
               if(OrderCloseTime() == 0 && OrderType() == OP_SELL){
                  // Ensure Trade at a minimum of 20 Pips Profit                  
                  // NormalizeDouble(value, no of digits) 
                  //#Digits is Open Price -  Current Price / Point for Instrument
                  //No Of Digits - Number of Digits for Instrument
                  //double PipsProfit = (NormalizeDouble(((OrderOpenPrice() - Bid) /MarketInfo(Symbol(),MODE_POINT)),(int)MarketInfo(Symbol(),MODE_DIGITS))) / point_compat;
                  double PipsProfit = 20;
                  if(PipsProfit >= 20){
                     bool orderClosed = OrderClose(ticket, Lots, OrderClosePrice(), 10);
                     if(!orderClosed){
                        Alert("Error Closing Order #", ticket);
                     }
                  }
               }
            }
         }
         // else If Bid less than last close and 2nd candle is higher than upper band and last candle is less than lower band (means movement downwards)   
         } 

         if(Close[0] >= upperBollingerBand){
            // Open a sell after analysing RSI...
            if(RSI > 80 && !tradeRunning){
               Alert("your rsi value is: ",RSI);
               double takeProfit = lowerBollingerBand;
               // Open Sell for sure as currency pair is now been overbought
                  double currentSpreadInPips = MarketInfo(Symbol(), MODE_SPREAD )/10;
                  ticket = OrderSend(Symbol(), OP_SELL, Lots, Bid, 3, (Ask + (((StopLoss * 10) + currentSpreadInPips) * nDigits)), takeProfit, "Set by Kman Test EA");
                  if(ticket < 0){
                     Alert("Error in the attempt to send the order!");
                  }else{
                     Alert("SELL Order executed successfully ticket #", ticket);
                     tradeRunning = true;
                  }
                  
               }
            else{
             // Trade is running... 
            // Check if a buy trade is running and close it...
            bool orderSelected = OrderSelect(ticket, SELECT_BY_TICKET);
            if(orderSelected){
               if(OrderCloseTime() == 0 && OrderType() == OP_BUY){
                  // Ensure Trade at a minimum of 20 Pips Profit
                  
                  // NormalizeDouble(value, no of digits) 
                  //#Digits is Open Price -  Current Price / Point for Instrument
                  //No Of Digits - Number of Digits for Instrument
                  //double PipsProfit = (NormalizeDouble(((Ask - OrderOpenPrice()) /MarketInfo(Symbol(),MODE_POINT)),(int)MarketInfo(Symbol(),MODE_DIGITS))) / point_compat;
                  double PipsProfit = 20;
                  if(PipsProfit >= 20){
                     bool orderClosed = OrderClose(ticket, Lots, OrderClosePrice(), 10);
                     if(!orderClosed){
                        Alert("Error Closing Order #", ticket);
                     }
                  }
               }
            }
            }
         }
      
   }else{
      // Ensure EA has stopped running. E.g. close trades and reset ticket to 0.
      if(EARunning){
         bool orderSelected = OrderSelect(ticket, SELECT_BY_TICKET);
         if(orderSelected){
            if(OrderCloseTime() == 0){
               bool orderClosed = OrderClose(ticket, Lots, OrderClosePrice(), 10);
               if(!orderClosed){
                  Alert("Error Closing Order #", ticket);
               }else{
                  Alert("Trade #",ticket," has been closed. Ending EA runtime.");
               }
            }else{
                  Alert("Trade #",ticket," is already closed. Ending EA runtime.");
            }
         }
         
         ticket = 0;
         EARunning = false;
         tradeRunning = false;
     }
   }
   
}
//+------------------------------------------------------------------+