//
//  SignalProcessing.swift
//  basicRecorder
//
//  Created by Andy Freeman on 4/22/22.
//

import Accelerate
import AVFAudio

class SignalProcessing {
    func translatedPower(buffer: AVAudioPCMBuffer) -> [Float] {
        var averagePowerForChannel0: Float = 0
        var averagePowerForChannel1: Float = 0
        let LEVEL_LOWPASS_TRIG: Float32 = 0.30
        
        let frameLength = buffer.frameLength
        
        let inNumberFrames:UInt = UInt(buffer.frameLength)
        
        if buffer.format.channelCount > 0 {
            let samples = (buffer.floatChannelData![0])
            var avgValue: Float32 = 0
            vDSP_meamgv(samples, 1, &avgValue, inNumberFrames)
            var v:Float = -100
            if avgValue != 0 {
                v = 20.0 * log10f(avgValue)
            }
            averagePowerForChannel0 = (LEVEL_LOWPASS_TRIG * v) + ((1-LEVEL_LOWPASS_TRIG) * averagePowerForChannel0)
            averagePowerForChannel1 = averagePowerForChannel0
        }
        
        if buffer.format.channelCount > 1 {
            let samples = buffer.floatChannelData![1]
            var avgValue:Float32 = 0
            vDSP_meamgv(samples, 1, &avgValue, inNumberFrames)
            var v:Float = -100
            if avgValue != 0 {
                v = 20.0 * log10f(avgValue)
            }
            averagePowerForChannel1 = (LEVEL_LOWPASS_TRIG * v) + ((1 - LEVEL_LOWPASS_TRIG) * averagePowerForChannel1)
        }
        
        return [averagePowerForChannel0,averagePowerForChannel1]
    }
    
    
}
