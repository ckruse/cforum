module ScoresHelper
  def score_str
    s = score

    return '–' if no_votes.zero?

    if s.zero?
      '±' + s.to_s
    elsif s.negative?
      '−' + s.abs.to_s
    else
      '+' + s.to_s
    end
  end
end

# eof
