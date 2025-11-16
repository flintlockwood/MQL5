//+------------------------------------------------------------------+
//|                                                        Array.mqh |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
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
template <typename T>
void ArrayShift(T &arr[], T &value) {
   T temp[];
   ArrayCopy(temp, arr, 0, 1, ArraySize(arr)-1);
   ArrayResize(temp, ArraySize(temp)+1, 100);
   temp[ArraySize(temp)-1] = value;
   ArrayCopy(arr, temp, 0, 0, WHOLE_ARRAY);
}

template <typename T>
void ArrayShifObject(T &arr[], T &value) {
   T temp[];
   ArrayResize(temp, ArraySize(m_array)-1);
   for(int i=1; i<ArraySize(m_array); i++) {
      temp[i-1] = m_array[i];
   }
   ArrayResize(temp, ArraySize(temp)+1);
   temp[ArraySize(temp)-1] = value;
   for(int i=0; i<ArraySize(temp); i++) {
      m_array[i] = temp[i];
   }
}

template <typename T>
class TArrayStack {
 protected:
   T m_array[];
   int pos;
   int capacity;
 public:
   //--- constructor creates an array for 10 elements by default
   void TArrayStack() {
      pos = 0;
      ArrayResize(m_array,5);
   }
   //--- constructor for creating a vector with a specified array size
   void TArrayStack(int size) {
      pos = 0;
      capacity = size;
      ArrayResize(m_array,capacity);
   }

   void Push(T &value) {
      if (pos >= ArraySize(m_array)) {
         T temp[];
         ArrayResize(temp, ArraySize(m_array)-1);
         for(int i=1; i<ArraySize(m_array); i++) {
            temp[i-1] = m_array[i];
         }
         ArrayResize(temp, ArraySize(temp)+1);
         temp[ArraySize(temp)-1] = value;
         for(int i=0; i<ArraySize(temp); i++) {
            m_array[i] = temp[i];
         }
      } else {
         m_array[pos] = value;
         pos++;
         if (pos > ArraySize(m_array)) {
            pos = ArraySize(m_array);
         }
      }
   }

   void PushRange(T &value[]) {
      for(int i=0; i<=ArraySize(value)-1; i++) {
         this.Push(value[i]);
      }
   }

   void RemoveAll() {
      pos = 0;
      ArrayResize(m_array, 0);
      ArrayResize(m_array, capacity);
   }

   int Length() {
      return pos;
   }

   T GetValueAt(int i) {
      return m_array[i];
   }
};
//+------------------------------------------------------------------+
