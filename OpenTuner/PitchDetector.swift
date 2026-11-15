import Accelerate

/// YIN pitch detection (de Cheveigné & Kawahara, 2002).
enum PitchDetector {
    static func detect(_ samples: [Float], sampleRate: Double,
                       minFrequency: Double = 38, maxFrequency: Double = 2000,
                       threshold: Float = 0.15) -> Double? {
        let window = samples.count / 2
        let tauMax = min(Int(sampleRate / minFrequency), window - 1)
        let tauMin = max(2, Int(sampleRate / maxFrequency))
        guard tauMax > tauMin + 2 else { return nil }

        // Difference function d(tau) = sum (x[j] - x[j+tau])^2
        var diff = [Float](repeating: 0, count: tauMax + 1)
        var scratch = [Float](repeating: 0, count: window)
        samples.withUnsafeBufferPointer { x in
            let base = x.baseAddress!
            for tau in 1...tauMax {
                vDSP_vsub(base, 1, base + tau, 1, &scratch, 1, vDSP_Length(window))
                var sum: Float = 0
                vDSP_svesq(scratch, 1, &sum, vDSP_Length(window))
                diff[tau] = sum
            }
        }

        // Cumulative mean normalized difference
        var cmnd = [Float](repeating: 1, count: tauMax + 1)
        var running: Float = 0
        for tau in 1...tauMax {
            running += diff[tau]
            cmnd[tau] = running > 0 ? diff[tau] * Float(tau) / running : 1
        }

        // First dip below threshold, then walk to its local minimum
        var tau = tauMin
        while tau < tauMax {
            if cmnd[tau] < threshold {
                while tau + 1 < tauMax && cmnd[tau + 1] < cmnd[tau] { tau += 1 }
                break
            }
            tau += 1
        }
        guard tau < tauMax else { return nil }

        // Parabolic interpolation for sub-sample accuracy
        let s0 = cmnd[tau - 1], s1 = cmnd[tau], s2 = cmnd[tau + 1]
        let denom = s0 + s2 - 2 * s1
        let shift = denom != 0 ? (s0 - s2) / (2 * denom) : 0
        return sampleRate / (Double(tau) + Double(shift))
    }
}
