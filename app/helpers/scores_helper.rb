# -*- coding: utf-8 -*-

module ScoresHelper
  def score_str
    s = score

    return '–' if no_votes == 0

    if s == 0
      '±' + s.to_s
    elsif s < 0
      '−' + s.abs.to_s
    else
      '+' + s.to_s
    end
  end
end

# eof
