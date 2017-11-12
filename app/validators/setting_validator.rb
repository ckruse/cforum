# rubocop:disable Style/ClassVars
class SettingValidator < ActiveModel::EachValidator
  @@validators = {}
  def self.validators
    @@validators
  end

  def validate_each(record, attribute, value)
    return if value.blank?

    @@validators  ||= {}
    invalid_options = []

    value.each do |k, v|
      if @@validators[k]
        invalid_options << k unless @@validators[k].call(k, v)
      end
    end

    invalid_options.each do |o|
      record.errors[attribute] << I18n.t('options.errors.' + o)
    end

    # (options[:message] || invalid_options.join(", ") + " are invalid") unless invalid_options.blank?
  end
end

SettingValidator.validators['pagination'] = ->(_nam, val) { val.blank? || val =~ /^\d+$/ }

# eof
