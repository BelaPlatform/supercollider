#pragma once
#include "libraries/Scope/Scope_c.h"
#include <string.h>

class BelaScope {
public:
    BelaScope(uint32_t maxChannels_, float sampleRate, uint32_t blockSize):
        maxChannels(maxChannels_),
        bufferSamples(maxChannels_ * blockSize) {
        scope = Scope_new();
        Scope_setup(scope, maxChannels, sampleRate);
        buffer = new float[bufferSamples]();
    }

    ~BelaScope() {
        delete[] buffer;
        Scope_delete(scope);
    }

    void logBuffer() {
        if (touched) {
            float* data = buffer;
            for (unsigned int frame = 0; frame < bufferSamples; frame += maxChannels) {
                Scope_log(scope, data);
                data += maxChannels;
            }
            memset(buffer, 0, bufferSamples * sizeof(float));
            touched = false;
        }
    }

    float* buffer;
    uint32_t maxChannels;
    uint32_t bufferSamples;
    bool touched;

private:
    Scope* scope;
};
