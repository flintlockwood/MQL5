/*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*
* https://github.com/Roffild/RoffildLibrary
*/

template<typename T> 
interface ICompare
{
  int Compare(T &el1, T &el2);
};

template<typename T> 
interface IComparable
{
  int CompareTo(T &other);
};

template<typename T> 
interface IEquatable
{
  bool Equals(T &other);
};

/// ArrayList from Java for Class only
template<typename Type>
class CArrayListClass
{
protected:
   Type *elements[];
   int reserve;
   bool useDelete; ///< Use delete() when cleaning?

   // Всё, что требует сравнение классов мне сейчас не нужно...
   //bool removeList(const Type *&list[], bool saveOnlyList = false)
   //{
   //         if (elements[x].compare(list[y])) {
   //}

public:
   CArrayListClass(bool _useDelete = true, int _reserve = 0)
   {
      reserve = _reserve;
      useDelete = _useDelete;
   }

   ~CArrayListClass()
   {
      clear();
   }

   int getReserve()
   {
      return reserve;
   }
   void setReserve(int _reserve)
   {
      reserve = _reserve;
   }

   /// Use delete() when cleaning?
   bool getUseDelete()
   {
      return useDelete;
   }
   /// Use delete() when cleaning?
   void setUseDelete(bool _useDelete)
   {
      useDelete = _useDelete;
   }

   /// Appends the specified element to the end of this list.
   bool add(Type *element)
   {
      return add(ArraySize(elements), element);
   }

   /// Inserts the specified element at the specified position in this list.
   bool add(int index, Type *element)
   {
      if (index < 0) {
         return false;
      }

      int start = ArraySize(elements);
      if (ArrayResize(elements, start+1, reserve) > -1) {
         if (index < start) {
            for (int x = ArraySize(elements)-1; start > index; x--, start--) {
               elements[x] = elements[start-1];
            }
         }
         elements[start] = element;
         return true;
      }
      return false;
   }

   /// Appends all of the elements in the specified collection to the end of this list.
   bool addAll(const Type *&list[])
   {
      return addAll(ArraySize(elements), list);
   }
   /// Appends all of the elements in the specified collection to the end of this list.
   bool addAll(const CArrayListClass<Type> &list)
   {
      return addAll(ArraySize(elements), list);
   }

   /// Inserts all of the elements in the specified collection into this list,
   /// starting at the specified position.
   bool addAll(int index, const Type * const &list[])
   {
      if (index < 0) {
         return false;
      }

      int start = ArraySize(elements);
      int count = ArraySize(list);
      if (ArrayResize(elements, start + count, reserve) > -1) {
         if (index < start) {
            for (int x = ArraySize(elements)-1; start > index; x--, start--) {
               elements[x] = elements[start-1];
            }
         }
         return ArrayCopy(elements, list, start) > 0;
      }
      return false;
   }
   /// Inserts all of the elements in the specified collection into this list,
   /// starting at the specified position.
   bool addAll(int index, const CArrayListClass<Type> &list)
   {
      return addAll(index, list.elements);
   }

   /// Removes all of the elements from this list.
   void clear()
   {
      if (useDelete) {
         for (int x = ArraySize(elements) - 1; x > -1; x--) {
            delete(elements[x]);
         }
      }
      ArrayResize(elements, 0, reserve);
   }

   // / Returns a shallow copy of this ArrayList instance.
   //Object clone()

   // / Increases the capacity of this ArrayList instance, if necessary,
   // / to ensure that it can hold at least the number of elements
   // / specified by the minimum capacity argument.
   //void ensureCapacity(int minCapacity)

   // / Performs the given action for each element of the Iterable until all elements
   // / have been processed or the action throws an exception.
   //void forEach(Consumer<? super E> action)

   /// Returns the element at the specified position in this list.
   Type* get(int index)
   {
      return elements[index];
   }
   /// Returns the element at the specified position in this list.
   Type* operator[](int index)
   {
      return get(index);
   }

   /// Replaces the element at the specified position in this list with the specified element.
   void set(int index, Type *element)
   {
      if (useDelete) {
         delete(get(index));
      }
      elements[index] = element;
   }

   /// Returns true if this list contains no elements.
   bool isEmpty()
   {
      return ArraySize(elements) == 0;
   }

   /// Removes the element at the specified position in this list.
   void remove(int index)
   {
      int count = ArraySize(elements);
      if (index < 0) {
         return;
      }
      if (useDelete) {
         delete(get(index));
      }
      if (index < count-1) {
         ArrayCopy(elements, elements, index, index+1);
      }
      ArrayResize(elements, count-1, reserve);
   }

   /// Returns the number of elements in this list.
   int size()
   {
      return ArraySize(elements);
   }

   /// @see https://www.mql5.com/en/docs/array/arraycopy
   int subList(Type *&dst_array[], int dst_start = 0, int src_start = 0, int count = WHOLE_ARRAY)
   {
      return ArrayCopy(dst_array, elements, dst_start, src_start, count);
   }

   /// Returns an array containing all of the elements in this list in proper sequence
   /// (from first to last element).
   void toArray(Type *&dst_array[])
   {
      ArrayCopy(dst_array, elements);
   }
   
   void Sort()
   {
      IComparable<Type*>* elmnt = dynamic_cast<IComparable<Type*>*>(elements[0]);
      if (elmnt == NULL) {
         return;
      }
      
      int minKey;
      for (int j = 0; j < ArraySize(elements)-1; j++)
      {
         minKey = j;
         for (int k = j + 1; k < ArraySize(elements); k++)
         {
            IComparable<Type*>* cmp = dynamic_cast<IComparable<Type*>*>(elements[k]);
            if (cmp.CompareTo(elements[minKey]) < 0) {
               minKey = k;
            }
         }
         
         if (minKey != j)
         {
            Type *tmp          = elements[minKey];
            elements[minKey]   = elements[j];
            elements[j]        = tmp;
         }
      }
   }
   
   void SortDesc()
   {
      IComparable<Type*>* elmnt = dynamic_cast<IComparable<Type*>*>(elements[0]);
      if (elmnt == NULL) {
         return;
      }
      
      int maxKey;
      for (int j = 0; j < ArraySize(elements)-1; j++)
      {
         maxKey = j;
         for (int k = j + 1; k < ArraySize(elements); k++)
         {
            IComparable<Type*>* cmp = dynamic_cast<IComparable<Type*>*>(elements[k]);
            if (cmp.CompareTo(elements[maxKey]) > 0) {
               maxKey = k;
            }
         }
         
         if (maxKey != j)
         {
            Type *tmp          = elements[maxKey];
            elements[maxKey]   = elements[j];
            elements[j]        = tmp;
         }
      }
   }
   
   void SortBy(ICompare<Type*>* comparer)
   {
      int minKey;
      for (int j = 0; j < ArraySize(elements)-1; j++)
      {
         minKey = j;
         for (int k = j + 1; k < ArraySize(elements); k++)
         {
            if ( comparer.Compare(elements[k] , elements[minKey]) < 0)
            {
               minKey = k;
            }
         }
         
         if (minKey != j)
         {
            Type* tmp           = elements[minKey];
            elements[minKey]   = elements[j];
            elements[j]        = tmp;
         }
      }
   }
   
   bool exist(Type* other) {
      if (ArraySize(elements) == 0) {
         return false;
      }
      IEquatable<Type*>* elmnt = dynamic_cast<IEquatable<Type*>*>(elements[0]);
      if (elmnt == NULL) {
         return false;
      }
      for (int j = 0; j < ArraySize(elements)-1; j++)
      {
         IEquatable<Type*>* eq = dynamic_cast<IEquatable<Type*>*>(elements[j]);
         if (eq.Equals(other)) {
            return true;
         }
      }
      return false;
   }
   
   int indexOf(Type* other) {
      if (ArraySize(elements) == 0) {
         return -1;
      }
      IEquatable<Type*>* elmnt = dynamic_cast<IEquatable<Type*>*>(elements[0]);
      if (elmnt == NULL) {
         return -1;
      }
      for (int j = 0; j < ArraySize(elements)-1; j++)
      {
         IEquatable<Type*>* eq = dynamic_cast<IEquatable<Type*>*>(elements[j]);
         if (eq.Equals(other)) {
            return j;
         }
      }
      return -1;
   }
};
