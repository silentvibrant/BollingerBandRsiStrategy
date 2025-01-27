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

//Percentage of available balance to risk in each individual trade
//% of balance to risk in one trade
extern double MAXRISKPERTRADE = 0.5;
extern double MINPIPDISTANCE = 10;
extern int EURUSDSL = 5;
extern int GBPAUDSL = 10;
extern int NZDCADSL = 5;
extern int CHFJPYSL = 5;

extern double Lots = 1;

extern int TIME_FRAME = 0;
extern int BB_DEVIATION = 2;
extern int BB_BANDSHIFT = 0;
extern int BB_APPLIEDPRICE = 0;
extern int BB_PERIOD = 20;
extern int RSI_PERIOD = 7;
extern int RSI_UPPERLEVEL = 80;
extern int RSI_LOWERLEVEL = 20;


static int StopLoss = 0;
static int CandlesRecognised =  0;

static int orderComparisonOne = -1;
static int orderComparisonTwo = -1;
static bool allowBUY = true;
static bool allowSELL = true;

void BreakPoint(string comment)
{
   //It is expecting, that this function should work
   //only in tester
   if (!IsVisualMode()) return;
   
   //Preparing a data for printing
   //Comment() function is used as 
   //it give quite clear visualisation
  /* string Comm="";
   Comm=Comm+"Bid="+Bid+"\n";
   Comm=Comm+"Ask="+Ask+"\n";*/
   
   Comment(comment);
   Alert(comment);
   
 /*  if(BBLevel > 0){
      Comment("BB Level:", BBLevel);
   }*/
   
   //Press/release Pause button
   //19 is a Virtual Key code of "Pause" button
   //Sleep() is needed, because of the probability
   //to misprocess too quick pressing/releasing
   //of the button
   keybd_event(19,0,0,0);
   Sleep(20000);
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
   
   Alert(MarketInfo(Symbol(), MODE_TICKVALUE), " - ", MarketInfo(Symbol(), MODE_LOTSIZE));
}

/*void calculateLotSize(double stopLoss){
   
   double minimumRisk = AccountBalance() * 0.004;
   double maximumRisk = AccountBalance() * 0.005;
   double currentMiniLotValue = MarketInfo(Symbol(), MODE_TICKVALUE); // 0.1
   double amountBeingRisked = currentMiniLotValue * stopLoss;
   
   while(amountBeingRisked > maximumRisk && currentRisk >= minimumRisk ){
      currentMiniLotValue = currentMiniLotValue / 10 * 9;
   }

}*/
/*
double  calculateLotSize(double risk,int tradetype,bool compound,double startbalance)
         {
         double   riskpercent,ttw,equity;
         switch ( Period() )
               {
               case PERIOD_MN1: riskpercent = 0.05; break;
               case PERIOD_W1:  riskpercent = 0.05; break;
               case PERIOD_D1:  riskpercent = 0.05; break;
               case PERIOD_H4:  riskpercent = 0.05; break;
               case PERIOD_H1:  riskpercent = 0.05; break;
               case PERIOD_M30: riskpercent = 0.025; break;
               case PERIOD_M15: riskpercent = 0.02; break;
               case PERIOD_M5:  riskpercent = 0.02; break;
               case PERIOD_M1:  riskpercent = 0.01; break;
               default:    Alert(" NO PERIOD_ID. POTENTIAL FIXED RISK% ISSUE"); riskpercent = 0.02; break;
               }
         switch(tradetype)
            {
            case 1:  ttw=1.0;   break;
            case 2:  ttw=1.0;   break;
            case 3:  ttw=1.0;   break;
            case 4:  ttw=1.0;   break;
            case 5:  ttw=1.0;   break;
            case 6:  ttw=1.0;   break;
            default: ttw=1.0;   break;
            }   
         
         if (compound)
            {
            equity=AccountBalance();
            }
         else
            {
            equity=startbalance;
            }
         double   stoploss             =  risk/Point;
         double   PipValuePerLot       =  MarketInfo(Symbol(),MODE_LOTSIZE) * MarketInfo(Symbol(),MODE_POINT);
         double riskweighting=atr/atr9;
         if (riskweighting>1)
            {
            riskweighting=1;
            }
         double weightedrisk=riskweighting*riskpercent*ttw;
         
         double NeededPipValue = (equity * weightedrisk) / stoploss; // Calculate the needed value per pip to risk correct amount of capital according to sl size
         switch(MarketInfo(Symbol(),MODE_MINLOT))
            {
            case 1.0:   lotdigits=0; break;           //" Standard account";
            case 0.1:   lotdigits=1; break;           //" Mini Lot account"
            case 0.01:  lotdigits=2; break;           //" Micro Lot account";
            default:    lotdigits=1; Alert("Uncoded lot sizeaccount"); break;
            }
         lot = NormalizeDouble((NeededPipValue / PipValuePerLot),lotdigits);         // Calculate the lot size 
         Alert("At risk : £",DoubleToStr(stoploss*lot,2));
         return (lot);
         }*/
         
  
//We define the function to calculate the position size and return the lot to order
//Only parameter the Stop Loss, it will return a double
double CalculateLotSize(double SL){          //Calculate the size of the position size 
   double LotSize=0;
   //We get the value of a tick
   double nTickValue=MarketInfo(Symbol(),MODE_TICKVALUE);
   //If the digits are 3 or 5 we normalize multiplying by 10
   if(Digits==3 || Digits==5){
      nTickValue=nTickValue*10;
   }
   //We apply the formula to calculate the position size and assign the value to the variable
   LotSize=(AccountBalance()* MAXRISKPERTRADE /100)/(SL*nTickValue);
   return LotSize;
}
 

bool twoLossRule(){
   //Alert(OrdersHistoryTotal(), " - Number of Trades");
   if(OrdersHistoryTotal() >= 2){
      int totalNumberOfOrders = OrdersHistoryTotal();
      int lastOrder = totalNumberOfOrders - 1;
      int secondToLastOrder = totalNumberOfOrders - 2;
      
      if(( orderComparisonOne == secondToLastOrder || orderComparisonOne == lastOrder) && (orderComparisonTwo == secondToLastOrder || orderComparisonTwo == lastOrder)){
         return false;
      }
      
      double firstOrderClosePrice;
      double firstOrderSL;
      int firstOrderType;
      datetime firstOrderTime;
      bool firstOrderHitSL;
      
      double secondOrderClosePrice;
      double secondOrderSL;
      int secondOrderType;
      datetime secondOrderTime;
      bool secondOrderHitSL;
      
      bool selectFirstOrder = OrderSelect(lastOrder, SELECT_BY_POS, MODE_HISTORY);
      if(selectFirstOrder){
         firstOrderClosePrice = OrderClosePrice();
         firstOrderSL = OrderStopLoss();
         firstOrderType = OrderType();
         firstOrderTime = OrderCloseTime();
         firstOrderHitSL = (firstOrderType == OP_BUY ? (OrderClosePrice() <= OrderStopLoss()) : OrderClosePrice() >= OrderStopLoss());
      }else{
         return false;
      }
      
      bool selectSecondOrder = OrderSelect(secondToLastOrder, SELECT_BY_POS, MODE_HISTORY);
      if(selectSecondOrder){
         secondOrderClosePrice = OrderClosePrice();
         secondOrderSL = OrderStopLoss();
         secondOrderType = OrderType();
         secondOrderTime = OrderCloseTime();
         secondOrderHitSL = (secondOrderType == OP_BUY ? (OrderClosePrice() <= OrderStopLoss()) : OrderClosePrice() >= OrderStopLoss());
      }else{
         return false;
      }
      
      bool matchingOrderType = ((firstOrderType == OP_BUY && secondOrderType == OP_BUY) || (firstOrderType == OP_SELL && secondOrderType == OP_SELL));
      bool bothHitSL = (firstOrderHitSL && secondOrderHitSL);
      bool bothOrdersClosed = (firstOrderTime > 0 && secondOrderTime > 0); 
      if(!matchingOrderType || !bothHitSL || !bothOrdersClosed){
         return false;
      }
      
      orderComparisonOne = lastOrder;
      orderComparisonTwo = secondToLastOrder;
     
      if(firstOrderType == OP_BUY){
         allowBUY = false;
      }else{
         allowSELL = false;
      }
      return true;
      
      
   }else{
      Alert("Not two trades yet...");
      return false;
   }
   
   return false;
}


void OnTick()
{
   bool twoLossRuleActivated = twoLossRule();
   if(twoLossRuleActivated){
      Alert("Two Loss Rule Activated");
   }else{
     //Alert("Two Loss Rule Not Activated");
   }
   //Alert("What is current server time: ",Hour(), ":",Minute(), "GMT: ", TimeGMT());
   double nDigits=CalculateNormalizedDigits();
   static bool EARunning = false;
   static bool tradeRunning = false;
   
   static int ticket = 0;
   static double ticketLots = 0;
   
   // BollingerBands
   double upperBollingerBand = iBands(Symbol(), TIME_FRAME, BB_PERIOD, BB_DEVIATION, BB_BANDSHIFT, BB_APPLIEDPRICE, 1, 0);
   double lowerBollingerBand = iBands(Symbol(), TIME_FRAME, BB_PERIOD, BB_DEVIATION, BB_BANDSHIFT, BB_APPLIEDPRICE, 2, 0);
   
   double prevUpperBollingerBand = iBands(Symbol(), TIME_FRAME, BB_PERIOD, BB_DEVIATION, BB_BANDSHIFT, BB_APPLIEDPRICE, 1, 1);
   double prevLowerBollingerBand = iBands(Symbol(), TIME_FRAME, BB_PERIOD, BB_DEVIATION, BB_BANDSHIFT, BB_APPLIEDPRICE, 2, 1);
   
   // RSI
   double RSI = iRSI(Symbol(), TIME_FRAME, RSI_PERIOD, 0, 0);
   
   
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
      
      //Alert("Minimum PIP Distance: ",((upperBollingerBand - lowerBollingerBand) / nDigits));
      bool minimumPipDistance = ((upperBollingerBand - lowerBollingerBand)/nDigits >= MINPIPDISTANCE ? true : false);      
      
         // Analyse using Bollinger Bands and RSI
         // If Ask more than last close and 2nd candle is lower than lower band and last candle is higher than lower band (means movement upwards)
         if(Close[0] <= lowerBollingerBand){
            // Open a buy after analysing RSI...
            Alert("minimum Pip Distance: " , minimumPipDistance);
            if(RSI < RSI_LOWERLEVEL && !tradeRunning && allowBUY && (Bars != CandlesRecognised) && minimumPipDistance){
               Alert("your rsi value is: ", RSI);               
               //double takeProfit = upperBollingerBand;
               double takeProfit = 0;
               // Open Buy for sure as currency pair is now been oversold            
                  double currentSpreadInPips = MarketInfo(Symbol(), MODE_SPREAD )/10;
                  if(currentSpreadInPips <= 1.0){
                     CandlesRecognised = Bars;
                     Alert((Bid - ((StopLoss + currentSpreadInPips) * nDigits)), " |  Lot Size: ",CalculateLotSize(StopLoss)," | SL Calculation Where BID: ", Bid, " StopLoss Pip: ", StopLoss, " Ndigits: ", nDigits, "Spread (Pts): ", MarketInfo(Symbol(), MODE_SPREAD )/10); 
                     ticketLots = CalculateLotSize(StopLoss);
                     ticket = OrderSend(Symbol(), OP_BUY, ticketLots, Ask, 3, (Bid - (StopLoss * nDigits)), takeProfit, "Set by Kman Test EA");
                     if(ticket < 0){
                        Alert("Error in the attempt to send the order!");
                     }else{
                        Alert("BUY Order executed successfully ticket #", ticket);
                        tradeRunning = true;
                        //bool orderSelected = OrderSelect(ticket, SELECT_BY_TICKET);
                        //if(orderSelected){
                           //BreakPoint("Price of Candle: " + Close[0] + " \nBB Val (Lower): " + lowerBollingerBand + " \n| RSI Value = "+ RSI +" \nEntry Price: "+ OrderOpenPrice() +"  \n| SL: "+((Bid - (((StopLoss * 10 * nDigits) + currentSpreadInPips))))+" \nSL PIPS: "+((StopLoss * 10 * nDigits) + currentSpreadInPips)+" \n[BUY OPENED]");
                        //}
                        allowSELL = true;    
                    }    
                 } 
            }
         else {
         
         if(ticket > 0){
             // Trade is running... 
            // Check if a sell trade is running and close it...
            bool selectedPotentialSellTrade = OrderSelect(ticket, SELECT_BY_TICKET);
            if(selectedPotentialSellTrade){
               if(OrderCloseTime() == 0 && OrderType() == OP_SELL){
                  // Ensure Trade at a minimum of 20 Pips Profit                  
                  // NormalizeDouble(value, no of digits) 
                  //#Digits is Open Price -  Current Price / Point for Instrument
                  //No Of Digits - Number of Digits for Instrument
                  //double PipsProfit = (NormalizeDouble(((OrderOpenPrice() - Bid) /MarketInfo(Symbol(),MODE_POINT)),(int)MarketInfo(Symbol(),MODE_DIGITS))) / point_compat;
                  double PipsProfit = 20;
                  if(PipsProfit >= 20){
                     bool orderClosed = OrderClose(ticket, ticketLots, OrderClosePrice(), 10);
                     if(!orderClosed){
                        Alert("Error Closing Order #", ticket);
                     }else{
                        ticket = 0;
                        Alert("Order closed successfully as it's fully touched the other side!");
                        //BreakPoint("Order closed #"+ ticket + "BB Val (Lower): " + lowerBollingerBand);
                     }
                  }
               }
            }else{
               Alert("Order is not selected!");
            }
            
            }        
         }
         // else If Bid less than last close and 2nd candle is higher than upper band and last candle is less than lower band (means movement downwards)   
         } 

         if(Close[0] >= upperBollingerBand){
            // Open a sell after analysing RSI...
            if(RSI > RSI_UPPERLEVEL && !tradeRunning && allowSELL && (Bars != CandlesRecognised) && minimumPipDistance){
               Alert("your rsi value is: ",RSI);
               //double takeProfit = lowerBollingerBand;
               double takeProfit = 0;
               // Open Sell for sure as currency pair is now been overbought
                  double currentSpreadInPips = MarketInfo(Symbol(), MODE_SPREAD )/10;
                  if(currentSpreadInPips <= 1.6){
                  CandlesRecognised = Bars;
                  //ticket = OrderSend(Symbol(), OP_SELL, Lots, Bid, 3, (Ask + (((StopLoss * 10 * nDigits) + currentSpreadInPips) * nDigits)), takeProfit, "Set by Kman Test EA");
                  ticketLots = CalculateLotSize(StopLoss);
                  ticket = OrderSend(Symbol(), OP_SELL, ticketLots, Bid, 3, (Ask + (StopLoss * nDigits)), takeProfit, "Set by Kman Test EA");
                  if(ticket < 0){
                     Alert("Error in the attempt to send the order!");
                  }else{
                     Alert("SELL Order executed successfully ticket #", ticket);
                     tradeRunning = true;
                    // orderSelected = OrderSelect(ticket, SELECT_BY_TICKET);
                    // if(orderSelected){
                        //BreakPoint("Price of Candle: " + Close[0] +" \nBB Val (upper): "+ upperBollingerBand + " \n| RSI Value = "+ RSI +" \nEntry Price: "+ OrderOpenPrice() +"  | SL: "+(Ask + (((StopLoss * 10 * nDigits) + currentSpreadInPips) * nDigits))+" \nSL PIPS: "+(((StopLoss * 10 * nDigits) + currentSpreadInPips) * nDigits)+" \n[SELL OPENED]");
                    // }
                     allowBUY = true;
                  }
                  }
              }else{
              
                  if(ticket > 0){
                  // Trade is running... 
                  // Check if a buy trade is running and close it...
                  bool selectedPotentialBuyTrade = OrderSelect(ticket, SELECT_BY_TICKET);
                  if(selectedPotentialBuyTrade){
                     if(OrderCloseTime() == 0 && OrderType() == OP_BUY){
                        // Ensure Trade at a minimum of 20 Pips Profit
                        
                        // NormalizeDouble(value, no of digits) 
                        //#Digits is Open Price -  Current Price / Point for Instrument
                        //No Of Digits - Number of Digits for Instrument
                        //double PipsProfit = (NormalizeDouble(((Ask - OrderOpenPrice()) /MarketInfo(Symbol(),MODE_POINT)),(int)MarketInfo(Symbol(),MODE_DIGITS))) / point_compat;
                        double PipsProfit = 20;
                        if(PipsProfit >= 20){
                           bool orderClosed = OrderClose(ticket, ticketLots, OrderClosePrice(), 10);
                           
                           if(!orderClosed){
                              Alert("Error Closing Order #", ticket);
                           }else{
                              ticket = 0;
                              Alert("Order closed successfully as it's fully touched the other side!");
                              //BreakPoint("Order closed #" + ticket + "BB Val (upper): " + upperBollingerBand);
                           }
                        }
                     }
                  }else{
                     Alert("Order not selected!");
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
               bool orderClosed = OrderClose(ticket, ticketLots, OrderClosePrice(), 10);
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
         ticketLots = 0;
         EARunning = false;
         tradeRunning = false;
     }
   }
  
  
   
}
//+------------------------------------------------------------------+