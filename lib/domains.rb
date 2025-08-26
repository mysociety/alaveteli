# Helpers related to generic domains
class Domains
  cattr_accessor :webmail_providers, default: %w[
    aol.com
    gmail.com
    googlemail.com
    gmx.com
    hotmail.com
    icloud.com
    live.com
    mac.com
    mail.com
    mail.ru
    me.com
    outlook.com
    protonmail.com
    qq.com
    yahoo.com
    yandex.com
    ymail.com
    zoho.com
  ]
end
