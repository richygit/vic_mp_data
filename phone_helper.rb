class PhoneHelper
  PHONE_PATTERN = '\(*\d{2}\)*\s*\d*\s*\d*'

  def self.clean_phone_no(phone_no)
    return phone_no unless phone_no
    phone_no.scan(/#{PHONE_PATTERN}/).first.gsub(/[\(|\)|\s]/, '')
  end

end
