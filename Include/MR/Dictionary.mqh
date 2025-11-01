//+------------------------------------------------------------------+
//|                                                   Dictionary.mqh |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
// #define MacrosHello   "Hello, world!"
// #define MacrosYear    2010
//+------------------------------------------------------------------+
//| DLL imports                                                      |
//+------------------------------------------------------------------+
// #import "user32.dll"
//   int      SendMessageA(int hWnd,int Msg,int wParam,int lParam);
// #import "my_expert.dll"
//   int      ExpertRecalculate(int wParam,int lParam);
// #import
//+------------------------------------------------------------------+
//| EX5 imports                                                      |
//+------------------------------------------------------------------+
// #import "stdlib.ex5"
//   string ErrorDescription(int error_code);
// #import
//+------------------------------------------------------------------+
template <typename TKey, typename TValue>
class Dictionary {
 protected:
   TKey keyArray[];
   TValue valueArray[];
   int pos;
   int capacity;
 public:
   //--- constructor creates an array for 10 elements by default
   void Dictionary() {
      pos = 0;
      ArrayResize(keyArray,5);
      ArrayResize(valueArray,5);
   }
   //--- constructor for creating a vector with a specified array size
   void Dictionary(int size) {
      pos = 0;
      capacity = size;
      ArrayResize(keyArray, capacity);
      ArrayResize(valueArray, capacity);
   }

   void Add(TKey key, TValue &value) {
      if (pos+1 > ArraySize(keyArray)) {
         ArrayResize(keyArray, pos+1, 5);
         ArrayResize(valueArray, pos+1, 5);
      }
      keyArray[pos] = key;
      valueArray[pos] = value;
      pos++;
   }

   void RemoveAll() {
      ArrayResize(keyArray, 0);
      ArrayResize(valueArray, 0);
      ArrayResize(keyArray, capacity);
      ArrayResize(valueArray, capacity);
   }

   bool ContainsKey(TKey key) {
      for(int i=0; i<ArraySize(keyArray); i++) {
         if (keyArray[i] == key) {
            return true;
         }
      }
      return false;
   }

   int Length() {
      return pos;
   }

   TValue GetValueAt(int i) {
      return valueArray[i];
   }

   void Sort() {
      for (int i = 0; i < pos - 1; i++)
         for (int j = 0; j < pos - i - 1; j++)
            if (keyArray[j] > keyArray[j + 1]) {
               // swap temp and arr[i]
               TKey temp = keyArray[j];
               keyArray[j] = keyArray[j + 1];
               keyArray[j + 1] = temp;

               TValue temp2 = valueArray[j];
               valueArray[j] = valueArray[j + 1];
               valueArray[j + 1] = temp2;
            }
   }
};
//+------------------------------------------------------------------+
