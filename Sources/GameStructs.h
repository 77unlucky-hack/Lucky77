#import <Foundation/Foundation.h>

typedef struct {
    uintptr_t address;
    float x, y, z;
    float health;
    int team;
    BOOL isAlive;
    float distance;
    char name[32];
} Player;

typedef struct {
    float x, y, z;
} Vector3;

typedef struct {
    float m[4][4];
} Matrix4x4;
