// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKit/

#import <AudioKit/AKDSPBase.hpp>

#include "Shakers.h"

class AKShakerDSP : public AKDSPBase {
private:
    stk::Shakers *shaker;

public:
    AKShakerDSP() {}
    ~AKShakerDSP() = default;

    /// Uses the ParameterAddress as a key
    float getParameter(AUParameterAddress address) override {
        return 0;
    }

    void init(int channelCount, double sampleRate) override {
        AKDSPBase::init(channelCount, sampleRate);

        stk::Stk::setSampleRate(sampleRate);
        shaker = new stk::Shakers();
    }

    void handleMIDIEvent(AUMIDIEvent const& midiEvent) override {
        uint8_t veloc = midiEvent.data[2];
        auto type = midiEvent.data[1];
        auto amplitude = (AUValue)veloc / 127.0;
        // As confusing as this looks, STK actually converts the frequency
        // back to a note number to choose the model.
        float frequency = pow(2.0, (type - 69.0) / 12.0) * 440.0;
        shaker->noteOn(frequency, amplitude);
    }

    void deinit() override {
        AKDSPBase::deinit();
        delete shaker;
    }

    void process(AUAudioFrameCount frameCount, AUAudioFrameCount bufferOffset) override {

        for (int frameIndex = 0; frameIndex < frameCount; ++frameIndex) {
            int frameOffset = int(frameIndex + bufferOffset);

            float outputSample = 0.0;
            if(isStarted) {
                outputSample = shaker->tick();
            }

            for (int channel = 0; channel < channelCount; ++channel) {
                float *out = (float *)outputBufferList->mBuffers[channel].mData + frameOffset;
                *out = outputSample;
            }
        }
    }
};

AK_REGISTER_DSP(AKShakerDSP)

