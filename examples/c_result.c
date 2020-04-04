#include <stdio.h>

// 2 component vector

typedef struct
{   float v[2];
} vector2;

vector2 vec2_add (vector2 a, vector2 b)
{
    vector2 new;
    for (int i = 0; i < 2; ++i)
        new.v[i] = a.v[i] + b.v[i];
    return new;
}



// 3 component vector

typedef struct
{   float v[3];
} vector3;

vector3 vec3_add (vector3 a, vector3 b)
{
    vector3 new;
    for (int i = 0; i < 3; ++i)
        new.v[i] = a.v[i] + b.v[i];
    return new;
}



// End of macro

//EOF
