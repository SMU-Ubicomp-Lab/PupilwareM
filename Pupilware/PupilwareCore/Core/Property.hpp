//
// It is short way to make setter and getter functions.
// This source code is from Moo-Juice and Adrian W
// http://stackoverflow.com/questions/4225087/c-like-properties-in-native-c
//
//

#ifndef Property_hpp
#define Property_hpp


template<typename T>
class Property
{
private:
    T& _value;
    
public:
    Property(T& value) : _value(value)
    {
    }   // eo ctor
    
    Property<T>& operator = (const T& val)
    {
        _value = val;
        return *this;
    };  // eo operator =
    
    operator const T&() const
    {
        return _value;
    };  // eo operator ()
    
    T& operator() ()
    {
        return _value;
    }
    
    T const& operator() () const
    {
        return _value;
    }
    
};

#endif /* Property_hpp */
