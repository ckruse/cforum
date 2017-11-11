module DiffHelper
  def diff_posting(current, prev)
    options = {}
    lines = uconf('diff_context_lines')

    options[:diff] = '-U ' + lines.to_i.to_s unless lines.nil?

    Diffy::Diff.new(current,
                    prev,
                    options).to_s(:html).html_safe
  end
end

# eof
