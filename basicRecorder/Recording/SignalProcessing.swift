//
//  SignalProcessing.swift
//  basicRecorder
//
//  Created by Andy Freeman on 4/22/22.
//

import Accelerate

class SignalProcessing {
    static func rms(data: UnsafeMutablePointer<Float>, frameLength: UInt) -> Float {
        var val : Float = 0
        vDSP_measqv(data, 1, &val, frameLength)
        var db = 10*log10f(val)
        //inverse dB to +ve range where 0(silent) -> 160(loudest)
        db = 160 + db;
        //Only take into account range from 120->160, so FSR = 40
        db = db - 120
        let dividor = Float(40/0.3)
        var adjustedVal = 0.3 + db/dividor

        //cutoff
        if (adjustedVal < 0.3) {
            adjustedVal = 0.3
        } else if (adjustedVal > 0.6) {
            adjustedVal = 0.6
        }

        return adjustedVal
    }
    
    static func scaledPower(power: Float) -> Float {
          guard power.isFinite else {
              return 0.0
          }
        
        print(power)

          let minDb: Float = -160

          if power < minDb {
              return 0.0
          } else if power >= 1.0 {
              return 1.0
          } else {
              return (abs(minDb) - abs(power)) / abs(minDb)
          }
    }
}
