NB: the fits in this directory were made with a model that specified the drift rate as follows:

def drift_weights(t, trueCue, trueCongruence, signal1_onset, noise2_onset, signal2_onset,
                       m_noise1, m50_noise1, m_signal1, m50_signal1, v_signal1, v50_signal1,
                       m_noise2, m50_noise2, m_signal2, m50_signal2, v_signal2, v50_signal2):
     coherence = 0.7
     if t < signal1_onset:
         if trueCongruence == 'congruent':
             return trueCue * m_noise1
         elif trueCongruence == 'incongruent':
             return -trueCue * m_noise1
         else:
             return trueCue * m50_noise1
     if t <= noise2_onset and t >= signal1_onset:
         if trueCongruence == 'congruent':
             return trueCue * m_signal1 + coherence * v_signal1 
         elif trueCongruence == 'incongruent':
             return -trueCue * m_signal1 + coherence * v_signal1
         else:
             return trueCue * m50_signal1
     if t > noise2_onset and t < signal2_onset:
         if trueCongruence == 'congruent':
             return trueCue * m_noise2
         elif trueCongruence == 'incongruent':
             return -trueCue * m_noise2
         else:
             return trueCue * m50_noise2
     if t >= signal2_onset:
         if trueCongruence == 'congruent':
             return trueCue * m_signal2
         elif trueCongruence == 'incongruent':
             return -trueCue * m_signal2
         else:
             return trueCue * m50_signal2


TLDR: no addition of visual signal or a visual weight on that signal for the 50% cue in signal1, or for any cues in signal2
