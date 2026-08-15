module JsonWebToken
  SECRET = ENV.fetch("JWT_SECRET", Rails.application.secret_key_base)
  ALGORITHM = "HS256"
  EXPIRY = 30.days

  def self.encode(payload)
    payload[:exp] = EXPIRY.from_now.to_i
    JWT.encode(payload, SECRET, ALGORITHM)
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET, true, { algorithm: ALGORITHM })
    HashWithIndifferentAccess.new(decoded.first)
  rescue JWT::ExpiredSignature
    Rails.logger.info "jwt expired"
    nil
  rescue JWT::DecodeError => e
    # not expiry: malformed, wrong signature, or tampered
    Rails.logger.warn "jwt rejected: #{e.class}: #{e.message}"
    nil
  end
end
